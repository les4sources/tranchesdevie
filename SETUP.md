# Configuration de l'environnement - Tranches de Vie

## Variables d'environnement

Ce projet utilise des variables d'environnement pour les configurations sensibles.

### Installation

1. Copier le fichier d'exemple :
```bash
cp .env.example .env
```

2. Remplir les valeurs dans `.env` avec vos vraies clés API

### Variables requises

#### Stripe (Paiements)
- `STRIPE_PUBLISHABLE_KEY` - Clé publique Stripe (commence par `pk_`)
- `STRIPE_SECRET_KEY` - Clé secrète Stripe (commence par `sk_`)
- `STRIPE_WEBHOOK_SECRET` - Secret pour les webhooks Stripe (commence par `whsec_`)

#### Telerivet (SMS)
- `TELERIVET_API_KEY` - Clé API Telerivet
- `TELERIVET_PROJECT_ID` - ID du projet Telerivet
- `TELERIVET_PHONE_ID` - ID du numéro de téléphone Telerivet

#### Sentry (Monitoring d'erreurs)
- `SENTRY_DSN` - Data Source Name pour Sentry

#### Configuration générale
- `TIME_ZONE` - Fuseau horaire (défaut: `Europe/Brussels`)

### Développement local

Le fichier `.env` est automatiquement chargé en développement et en test grâce au gem `dotenv-rails`.

**Important** : Ne jamais committer le fichier `.env` dans git ! Il est ignoré par `.gitignore`.

### Production

En production, configurez ces variables via votre plateforme d'hébergement (Heroku, Render, etc.) ou votre système de gestion de configuration.
