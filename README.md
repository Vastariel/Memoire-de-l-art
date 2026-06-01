# Mémoire de l'art

Une couleur par jour, une œuvre par mois. Application mobile Flutter + backend Node.js.

## Développement mobile

```bash
cd mobile

# Déployer sur Android (Pixel 9)
LC_ALL=en_US.UTF-8 flutter run -d 46080DLAQ001LM

# Build APK debug
LC_ALL=en_US.UTF-8 flutter build apk --debug
```

> Le préfixe `LC_ALL=en_US.UTF-8` est nécessaire car le chemin du projet contient `é` (Mémoire).

## Backend

```bash
cd backend
npm install
npm run db:setup   # Crée le schéma PostgreSQL (nécessite DATABASE_URL)
npm run dev        # Serveur de développement (port 3000)
```

## Infrastructure

```bash
cp .env.example .env   # Remplir les variables
docker compose up -d   # Lance API + Admin + PostgreSQL + MinIO
```
