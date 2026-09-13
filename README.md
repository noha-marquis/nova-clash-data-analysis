# Nova Clash : Analyse de données & Tableau de bord décisionnel

> Extraction d'indicateurs clés (KPI) en **SQL** et restitution dans un **tableau de bord Power BI**, à partir des données d'un jeu mobile.

`SQL` · `SQLite` · `Power BI` · `Data analysis` · `Gaming analytics`

---

## Contexte

**Nova Clash** est un jeu mobile **free-to-play** (gratuit, monétisé par des achats intégrés), **lancé en janvier 2025**. L'objectif de ce projet est de se mettre dans la peau d'un *data analyst* du studio et de répondre à trois questions concrètes :

1. **Acquisition** : d'où viennent les joueurs, et lesquels ont le plus de valeur ?
2. **Engagement** : est-ce que les joueurs reviennent et prennent l'habitude de jouer ?
3. **Monétisation** : qui paie, combien, et le revenu est-il solide ?

> ⚠️ **Données simulées.** Le jeu et son jeu de données sont **fictifs**, générés pour ce projet afin de démontrer une démarche d'analyse. Aucune donnée réelle d'utilisateur n'est utilisée.

**Périmètre observé :** janvier → mars 2025 (~120 premiers jours du jeu).
**Volumétrie :** 5 000 joueurs · 50 184 sessions · 1 109 achats.
**Modèle de données :** 3 tables : `players`, `sessions`, `purchases`.

---

## Aperçu du tableau de bord

![Dashboard Nova Clash](Dashboard_Nova_Clash-1.png)

Le tableau de bord est construit comme une **histoire de haut en bas**, en suivant le parcours du joueur : **Acquisition → Engagement → Monétisation**.

---

## Principaux enseignements

**Acquisition**
- Le canal **organic** génère le plus gros chiffre d'affaires **total**… mais seulement la **3ᵉ** valeur par joueur (**ARPU**) : son volume masque une valeur moyenne. Les canaux **store_featured** et **referral** rapportent le plus **par joueur**.
- Leçon : **le volume n'est pas la valeur**, comparer les canaux au CA brut est trompeur ; il faut un ARPU par canal (et idéalement le **ROAS**, un revenu ne se jugeant jamais sans son coût).

**Engagement**
- **Rétention J1 = 57,6 %**, qui chute à **20,4 % à J7** : l'attrition frappe **tôt** (la première semaine).
- **Stickiness (DAU/MAU) ≈ 0,13**, soit **~3,6 jours de jeu par mois** pour un joueur moyen → un jeu qu'on **relance de temps en temps**, pas encore une habitude quotidienne.

**Monétisation**
- **Taux de conversion = 7,4 %** (donc **92,6 % des joueurs ne paient jamais** : le modèle F2P).
- **ARPU = 2,36 €** · **ARPPU = 31,81 €**, reliés par l'identité **ARPU = conversion × ARPPU**.
- **Les whales représentent 0,7 % de *tous* les joueurs mais 35,5 % du revenu.** Ce sont toutefois les **dolphins** qui pèsent le plus gros bloc de CA (**49 %**), le volume l'emportant sur le panier.
- **Pareto : le top 20 % des payeurs = 55 % du CA** → concentration réelle mais **modérée**, donc un revenu plutôt **résilient** (pas dépendant d'une poignée de baleines).

---

## Contenu du dépôt

| Fichier | Description |
|---|---|
| `database_setup.sql` | Script de **création et d'alimentation** de la base SQLite (schéma + données). |
| `analyse_nova_clash.sql` | **Requêtes d'analyse** : KPI, rétention (exacte / rolling), stickiness, ARPU/ARPPU, revenu par canal, segmentation whales/dolphins/minnows, Pareto. |
| `dashboard.pbix` | Rapport **Power BI** source (éditable). |
| `dashboard.png` | Aperçu du tableau de bord. |

---

## Outils utilisés

- **SQL** : DB Browser for SQLite (extraction et agrégation des données)
- **Power BI** : modélisation légère et tableau de bord décisionnel

---

## Compétences mises en œuvre

**SQL**
- Agrégations, `GROUP BY`, `ORDER BY` / `LIMIT`
- Jointures et distinction **`JOIN` vs `LEFT JOIN`** (le piège du dénominateur)
- Fonctions de dates (`date`, `strftime`, `julianday`, `+N day`)
- **Sous-requêtes / tables dérivées** (un `SUM` d'un `SUM`)
- `CASE WHEN` pour la segmentation
- Fonctions fenêtre (`SUM(...) OVER ()`, `NTILE`)

**Analyse produit (gaming)**
- DAU / MAU, **stickiness**, rétention (exacte / rolling), attrition
- Conversion, **ARPU / ARPPU**, segmentation payeurs, **Pareto** / concentration

**Data visualisation / BI**
- Conception d'un tableau de bord décisionnel (choix des visuels, mise en récit, lisibilité)

---

## Reproduire l'analyse

1. Ouvrir `database_setup.sql` dans **DB Browser for SQLite** pour créer et remplir la base `game_analytics.db`.
2. Exécuter les requêtes de `analyse_nova_clash.sql` pour retrouver les indicateurs.
3. Ouvrir `dashboard.pbix` dans **Power BI Desktop** pour explorer le tableau de bord.

---

*Projet personnel de data analyse : jeu de données simulé à but pédagogique.*
