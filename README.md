# Powerfull DOOH - Test Technique

Mini-application de gestion de contenus DOOH (Digital Out-Of-Home) multi-tenant, réalisée dans le cadre d'un test technique.

Ce projet démontre une architecture sécurisée utilisant **Flutter** pour le frontend et **Supabase** (PostgreSQL + Edge Functions) pour le backend.

## Fonctionnalités

*   **Authentification** : Connexion/Inscription via Supabase Auth.
*   **Multi-tenant (Isolation)** : Les données sont cloisonnées par "Site" (ex: Salle de sport A ne voit pas les contenus de Salle B).
*   **Publication** : Création de contenus via une Edge Function sécurisée.
*   **Sécurité (RLS)** : Row Level Security activé sur toutes les tables.

## Architecture & Choix Techniques

### Backend (Supabase)
*   **PostgreSQL & RLS** : La sécurité est portée par la base de données. Utilisation d'une fonction helper `get_user_site_id()` pour centraliser la logique d'isolation des données.
*   **Edge Function (`publish-content`)** : L'écriture passe par une fonction server-side (Deno/TypeScript) pour valider les règles métier (dates cohérentes) et forcer l'association du `site_id` côté serveur, garantissant l'intégrité du tenant.
*   **Triggers** : Gestion automatique des dates (`updated_at`) et création du profil utilisateur à l'inscription.

### Frontend (Flutter)
*   **MVVM (Model-View-ViewModel)** : Séparation claire entre l'UI (`View`), la logique d'état (`ViewModel`) et les données (`Service`).
*   **Provider** : Gestion d'état et injection de dépendances.

## Installation & Setup

### Prérequis

*   **Flutter SDK** : `^3.9.2` ([Installation](https://docs.flutter.dev/get-started/install))
*   **Supabase CLI** : Pour lancer le backend localement ([Installation](https://supabase.com/docs/guides/cli))
*   **Docker** : Requis par Supabase CLI pour lancer les services locaux

### 1. Cloner le repository

```bash
git clone git@github.com:anthozb3x/test-technique-powerfull-dooh.git
cd test-technique-powerfull-dooh
```

### 2. Configuration du backend (Supabase)

#### 2.1 Lancer Supabase localement

```bash
cd backend
supabase start
```

Cette commande va :
*   Démarrer les services Supabase dans Docker (PostgreSQL, Auth, API, etc.)
*   Appliquer automatiquement les migrations SQL
*   Afficher les URLs et clés API nécessaires pour le frontend

**Important** : Notez les valeurs suivantes dans la sortie :
*   `API URL` : généralement `http://127.0.0.1:54321`
*   `anon key` : La clé publique (anon key)


### 3. Configuration du frontend (Flutter)

#### 3.1 Créer le fichier de configuration

Copiez le fichier `.env.template` dans le dossier `frontend/` :

```bash
cd ../frontend
cp .env.template .env
```

#### 3.2 Remplir les variables d'environnement

Éditez le fichier `.env` avec les valeurs récupérées à l'étape 2.1 :

```env
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<votre_anon_key>
```

**Remarque** : Remplacez `<votre_anon_key>` par la clé anon affichée lors du `supabase start`.

#### 3.3 Installer les dépendances

```bash
flutter pub get
```

#### 3.4 Lancer l'application

```bash
flutter run
```

L'application va démarrer sur votre plateforme par défaut (web, mobile, desktop selon votre configuration Flutter).

### 4. Création d'un utilisateur de test

L'inscription ne demande pas le site (logique simplifiée pour le test). Il faut associer manuellement un site à l'utilisateur pour tester le flux complet :

1.  **S'inscrire dans l'app** : Utilisez l'écran de Login pour créer un compte.
2.  **Récupérer un site_id** : Dans Supabase Studio (`http://127.0.0.1:54323`), consultez la table `sites` et notez un ID (ex: `11111111-1111-1111-1111-111111111111`).
3.  **Associer le site** : Dans la table `profiles`, trouvez votre utilisateur et assignez le `site_id` récupéré à l'étape précédente.

Vous pouvez aussi utiliser le SQL Editor dans Supabase Studio :

```sql
UPDATE profiles
SET site_id = '11111111-1111-1111-1111-111111111111'
WHERE email = 'votre@email.com';
```

## Hypothèses & Choix Architecturaux

### Structure Multi-tenant

**Choix** : Un utilisateur appartient à un seul site (relation 1-N entre sites et utilisateurs).

**Raisonnement** :
*   Pour un test technique, cette approche simplifie l'implémentation
*   L'isolation par RLS est plus directe avec un seul `site_id` par utilisateur
*   Facilement extensible vers un modèle multi-sites si nécessaire (table de liaison `user_sites`)

**Alternative envisagée** : Support multi-sites dès le départ (un utilisateur peut gérer plusieurs sites).

### Edge Function pour la création de contenu

**Choix** : Passage par une Edge Function (`publish-content`) plutôt qu'un INSERT direct depuis le client.

**Raisonnement** :
*   **Validation métier** : Validation des dates (endDate > startDate) côté serveur
*   **Sécurité** : Le `site_id` est forcé côté serveur à partir du profil utilisateur, impossible de créer un contenu pour un autre site
*   **Évolutivité** : Facilite l'ajout de règles métier futures (notifications, webhooks, etc.)


### Architecture Frontend : MVVM avec Provider

**Choix** : Pattern MVVM avec `ChangeNotifier` et `Provider`.

**Raisonnement** :
*   **Séparation des responsabilités** : Views (UI), ViewModels (logique d'état), Services (données)
*   **Testabilité** : ViewModels testables indépendamment de l'UI
*   **Réactivité** : `ChangeNotifier` + `Provider` offre une gestion d'état simple et efficace
*   **Standards Flutter** : Utilisation de packages standards (provider), pas de dépendance externe lourde

## Structure du Projet

```
test-technique-powerfull-dooh/
├── backend/
│   └── supabase/
│       ├── config.toml              # Configuration Supabase locale
│       ├── migrations/
│       │   └── init_dooh_schema.sql # Schéma DB + RLS + Triggers
│       ├── functions/
│       │   └── publish-content/
│       │       └── index.ts         # Edge Function TypeScript
│       └── seed.sql                 # Données de test (sites)
│
└── frontend/
    └── lib/
        ├── main.dart                # Point d'entrée
        ├── app.dart                 # Configuration MaterialApp 
        ├── data/
        │   └── models/              # Modèles de données 
        ├── services/                # Couche d'accès aux données
        │   ├── supabase_service.dart
        │   ├── auth_service.dart
        │   └── content_service.dart
        ├── viewmodels/              # Logique d'état (MVVM)
        │   ├── auth_viewmodel.dart
        │   ├── content_list_viewmodel.dart
        │   └── content_form_viewmodel.dart
        └── views/                   # Interface utilisateur
            ├── login_screen.dart
            ├── content_list_screen.dart
            └── content_form_screen.dart
```

### RLS Policies

Toutes les tables ont RLS activé avec des policies basées sur `get_user_site_id()` :
*   **SELECT** : Un utilisateur ne voit que les données de son site
*   **INSERT/UPDATE/DELETE** : Un utilisateur ne peut modifier que les données de son site

Voir `backend/supabase/migrations/init_dooh_schema.sql` pour les détails.

## Commandes Utiles

### Backend

```bash
# Démarrer Supabase
cd backend
supabase start

# Arrêter Supabase
supabase stop

# Réinitialiser la base (re-applique migrations + seed)
supabase db reset

# Voir les logs
supabase logs

# Accéder à Supabase Studio
# Ouvrir http://127.0.0.1:54323 dans votre navigateur
```

### Frontend

```bash
# Installer les dépendances
cd frontend
flutter pub get

# Lancer l'application
flutter run

```

## Limites & Améliorations

Si j'avais eu plus de temps, voici les évolutions envisagées :

### Tests
*   **Tests unitaires** : ViewModels, Services
*   **Tests d'intégration** : Test d'intégration plus complet
*   **Tests widget** : Composants UI critiques

### Fonctionnalités
*   **Upload de média** : Implémenter l'upload réel de fichiers vers Supabase Storage (actuellement un champ URL texte)
*   **Multi-sites** : Permettre à un utilisateur de gérer plusieurs sites avec sélection du site actif
*   **Édition/Suppression** : Compléter le CRUD (actuellement seule la création est implémentée)
*   **Statuts de contenu** : Interface pour gérer les statuts (draft, published, archived)

### Architecture & Qualité
*   **Architecture backend** : Structure plus modulaire pour les Edge Functions 
