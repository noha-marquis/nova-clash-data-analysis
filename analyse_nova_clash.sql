-- #####################################################################
--  NOVA CLASH - Recueil de requetes (propre, pret a copier)
--  Base : game_analytics.db  |  tables : players, sessions, purchases
-- #####################################################################


-- =====================================================================
--  PARTIE 1 - SANTE  |  Manche 1
-- =====================================================================

-- P1.M1.Q1 - Nb joueurs / nb sessions / joueurs actifs / sessions par joueur
SELECT COUNT(*) AS nb_joueurs_inscrits FROM players;                      -- 5000
SELECT COUNT(*) AS nb_sessions FROM sessions;                            -- 50184
SELECT COUNT(DISTINCT player_id) AS nb_joueurs_actifs FROM sessions;      -- 4845

SELECT
  (SELECT COUNT(*) FROM sessions) * 1.0 / (SELECT COUNT(*) FROM players)                   AS sessions_par_inscrit, -- 10.04
  (SELECT COUNT(*) FROM sessions) * 1.0 / (SELECT COUNT(DISTINCT player_id) FROM sessions) AS sessions_par_actif;   -- 10.36

-- P1.M1.Q2 - Duree moyenne et mediane d'une session
SELECT ROUND(AVG(duration_minutes), 2) AS duree_moyenne_min FROM sessions; -- 15.96

SELECT ROUND(AVG(duration_minutes), 2) AS duree_mediane_min
FROM (
  SELECT duration_minutes FROM sessions
  ORDER BY duration_minutes
  LIMIT  2 - (SELECT COUNT(*) FROM sessions) % 2
  OFFSET (SELECT (COUNT(*) - 1) / 2 FROM sessions)
);                                                                        -- 13.40

-- P1.M1.Q3 - DAU (15/02/2025) et MAU (fevrier 2025)
SELECT COUNT(DISTINCT player_id) AS dau_15_02
FROM sessions WHERE session_start LIKE '2025-02-15%';                     -- 255

SELECT COUNT(DISTINCT player_id) AS mau_02_2025
FROM sessions WHERE strftime('%Y-%m', session_start) = '2025-02';        -- 2099

-- P1.M1.Q4 - Retention J1
SELECT ROUND(100.0 *
    COUNT(DISTINCT CASE WHEN date(s.session_start) = date(p.signup_date, '+1 day') THEN p.player_id END)
    / COUNT(DISTINCT p.player_id), 1) AS retention_j1_pct
FROM players p
LEFT JOIN sessions s ON s.player_id = p.player_id;                        -- 57.6


-- =====================================================================
--  PARTIE 1 - ENGAGEMENT & FIDELITE  |  Manche 2
-- =====================================================================

-- P1.M2.Q1 - MAU janvier + inscriptions par mois
SELECT COUNT(DISTINCT player_id) AS mau_01_2025
FROM sessions WHERE strftime('%Y-%m', session_start) = '2025-01';        -- 1684

SELECT strftime('%Y-%m', signup_date) AS mois, COUNT(*) AS nb_inscrits
FROM players GROUP BY mois;                                               -- 01:1757 / 02:1535 / 03:1708

-- P1.M2.Q2 - Retention J7 : jour exact (=) puis rolling (>=)
SELECT ROUND(100.0 *
    COUNT(DISTINCT CASE WHEN date(s.session_start) = date(p.signup_date, '+7 day') THEN p.player_id END)
    / COUNT(DISTINCT p.player_id), 1) AS retention_j7_exact_pct
FROM players p
LEFT JOIN sessions s ON s.player_id = p.player_id;                        -- 20.4

SELECT ROUND(100.0 *
    COUNT(DISTINCT CASE WHEN date(s.session_start) >= date(p.signup_date, '+7 day') THEN p.player_id END)
    / COUNT(DISTINCT p.player_id), 1) AS retention_j7_rolling_pct
FROM players p
LEFT JOIN sessions s ON s.player_id = p.player_id;                        -- 54.8

-- P1.M2.Q3 - Stickiness (DAU/MAU) : approx 1 jour, puis rigoureux
SELECT ROUND(
    (SELECT COUNT(DISTINCT player_id) FROM sessions WHERE session_start LIKE '2025-02-15%') * 1.0
    / (SELECT COUNT(DISTINCT player_id) FROM sessions WHERE strftime('%Y-%m',session_start)='2025-02')
, 3) AS stickiness_1jour;                                                 -- 0.121

SELECT ROUND(
    (SELECT COUNT(*) FROM (SELECT DISTINCT player_id, date(session_start)
                           FROM sessions WHERE strftime('%Y-%m',session_start)='2025-02')) * 1.0
    / (SELECT COUNT(DISTINCT player_id) FROM sessions WHERE strftime('%Y-%m',session_start)='2025-02')
, 2) AS jours_actifs_par_joueur;                                         -- 3.67


-- =====================================================================
--  PARTIE 2 - MONETISATION  |  Manche 1
-- =====================================================================
-- Nombre de payeurs : 372


-- P2.M1.1 - Taux de conversion
SELECT ROUND(
    (SELECT COUNT(DISTINCT player_id) FROM purchases) * 100.0
    / (SELECT COUNT(*) FROM players)
, 1) AS taux_conversion_pct;                                             -- 7.4

-- P2.M1.2 - Revenu total, ARPU, ARPPU
SELECT SUM(amount_eur) AS revenu_total FROM purchases;                    -- 11803

SELECT ROUND((SELECT SUM(amount_eur) FROM purchases) / (SELECT COUNT(*) FROM players), 2)                    AS arpu_eur;  -- 2.36
SELECT ROUND((SELECT SUM(amount_eur) FROM purchases) / (SELECT COUNT(DISTINCT player_id) FROM purchases), 2) AS arppu_eur; -- 31.81

-- P2.M1.3 - Revenu total + nb payeurs par canal
SELECT p.acquisition_channel AS canal,
       ROUND(SUM(pu.amount_eur), 2) AS ca,
       COUNT(DISTINCT pu.player_id) AS nb_payeurs
FROM purchases pu
JOIN players p ON p.player_id = pu.player_id
GROUP BY p.acquisition_channel
ORDER BY ca DESC;

-- P2.M1.4 - ARPU par canal (comparaison equitable : LEFT JOIN depuis players)
SELECT p.acquisition_channel AS canal,
       ROUND(SUM(pu.amount_eur) / COUNT(DISTINCT p.player_id), 2) AS arpu_canal
FROM players p
LEFT JOIN purchases pu ON pu.player_id = p.player_id
GROUP BY p.acquisition_channel
ORDER BY arpu_canal DESC;


-- =====================================================================
--  PARTIE 2 - MONETISATION  |  Manche 2 (whales)
-- =====================================================================

-- P2.M2.1 - Top 10 des plus gros depensiers (+ nb d'achats)
SELECT player_id,
       SUM(amount_eur) AS depense_totale,
       COUNT(*) AS nb_achats
FROM purchases
GROUP BY player_id
ORDER BY depense_totale DESC
LIMIT 10;

-- 1) sous-requete interne : SUM/GROUP BY/ORDER BY/LIMIT 74 -> depense de chaque top-payeur (les 20% supérieurs)
-- 2) SUM(depense) par-dessus -> total du top 20% = 6489 EUR (le NUMERATEUR)
-- 3) * 100.0 -> pour exprimer en pourcentage (les montants sont deja decimaux)
-- 4) / SUM(amount_eur) total -> part dans le CA total (11803 EUR)
-- 5) ROUND(..., 1) -> arrondit le POURCENTAGE FINAL a 1 decimale (55.0)

-- P2.M2.2 - Pareto : part du CA du top 20% des payeurs (74 sur 371)
SELECT ROUND(
    (SELECT SUM(depense) FROM (
        SELECT SUM(amount_eur) AS depense FROM purchases
        GROUP BY player_id ORDER BY depense DESC LIMIT 74
    )) * 100.0 / (SELECT SUM(amount_eur) FROM purchases)
, 1) AS part_top20pct;                                                    -- 55.0

-- P2.M2.3 - Tableau de concentration (top 1/5/10/20/50 %)
SELECT '01%' AS tranche, 4 AS nb_payeurs,
  ROUND((SELECT SUM(d) FROM (SELECT SUM(amount_eur) d FROM purchases GROUP BY player_id ORDER BY d DESC LIMIT 4))
        * 100.0 / (SELECT SUM(amount_eur) FROM purchases), 1) AS pct_ca
UNION ALL SELECT '05%', 19,
  ROUND((SELECT SUM(d) FROM (SELECT SUM(amount_eur) d FROM purchases GROUP BY player_id ORDER BY d DESC LIMIT 19))
        * 100.0 / (SELECT SUM(amount_eur) FROM purchases), 1)
UNION ALL SELECT '10%', 37,
  ROUND((SELECT SUM(d) FROM (SELECT SUM(amount_eur) d FROM purchases GROUP BY player_id ORDER BY d DESC LIMIT 37))
        * 100.0 / (SELECT SUM(amount_eur) FROM purchases), 1)
UNION ALL SELECT '20%', 74,
  ROUND((SELECT SUM(d) FROM (SELECT SUM(amount_eur) d FROM purchases GROUP BY player_id ORDER BY d DESC LIMIT 74))
        * 100.0 / (SELECT SUM(amount_eur) FROM purchases), 1)
UNION ALL SELECT '50%', 186,
  ROUND((SELECT SUM(d) FROM (SELECT SUM(amount_eur) d FROM purchases GROUP BY player_id ORDER BY d DESC LIMIT 186))
        * 100.0 / (SELECT SUM(amount_eur) FROM purchases), 1);

-- P2.M2.4 - Segmentation minnow / dolphin / whale (avec parts)
SELECT
    CASE WHEN depense >= 75 THEN 'whale'
         WHEN depense >= 20 THEN 'dolphin'
         ELSE 'minnow' END AS segment,
    COUNT(*) AS nb_payeurs,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT player_id) FROM purchases), 1) AS pct_payeurs,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM players), 1)                     AS pct_tous_joueurs,
    ROUND(SUM(depense), 0) AS revenu,
    ROUND(100.0 * SUM(depense) / (SELECT SUM(amount_eur) FROM purchases), 1)        AS pct_revenu
FROM (SELECT player_id, SUM(amount_eur) AS depense FROM purchases GROUP BY player_id)
GROUP BY segment
ORDER BY revenu DESC;


