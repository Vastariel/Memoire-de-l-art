# Mémoire de l'art — Backend (v2)

API Fastify + PostgreSQL + MinIO pour le modèle **hebdomadaire** v2 (œuvre/semaine,
7 familles de couleur, variantes, claims, photos, contributions, tampons, paris,
scores/streaks). Le backend garde son **auth JWT maison** : le client échange le
jeton d'un fournisseur (Google/Apple via Firebase, ou `dev`) contre un JWT.

## Démarrer

```bash
cp .env.example .env          # à la racine du repo — renseigner les secrets
# Pour tester l'app sans OAuth : ALLOW_DEV_LOGIN=true
docker compose up -d --build
# Le schéma db/schema.sql est appliqué au 1er démarrage (volume vide).
# Seed de la semaine courante (« Le Semeur ») :
docker compose exec api npm run db:seed
```

En local (sans Docker) : `npm install && npm run build` (vérifie les types) puis
`npm run dev`. Base : `npm run db:setup` puis `npm run db:seed`.

> Validation : ce code n'a pas pu être compilé dans l'environnement de dev
> (Node absent). **Lancer `npm run build`** pour le typecheck avant déploiement.

## Cycle hebdomadaire (UTC)
- Lundi 00:00 — l'œuvre `planned` de la semaine ISO passe `active` (cron).
- Chaque jour 00:00 — la famille du jour découle de la date (jour 1=lundi…7=dimanche).
- Dimanche 23:59 — reveal : résolution des paris, points du barème, statut `revealed`.

## Endpoints (`/api/v1`)
| Méthode · chemin | Auth | Rôle |
|---|---|---|
| `POST /auth/:provider` (`google`\|`apple`\|`dev`) | — | vérifie le jeton, upsert user, renvoie `{token, user}` |
| `GET /weeks/current` | — | œuvre active (métadonnées cachées avant reveal) + familles/variantes |
| `GET /weeks/current/bundle` | — | idem + payload reveal obfusqué (offline solo) |
| `GET /days/today` | JWT | famille du jour + variantes (+ blocs) + claims des instances de l'user |
| `POST /instances` · `/instances/join` | JWT | créer / rejoindre (import auto des photos partagées de la semaine) |
| `GET /instances/mine` | JWT | mes instances (membres, rang hebdo) |
| `GET /instances/:id/artwork` | JWT | état des cellules (vitrail) |
| `GET /instances/:id/leaderboard` | JWT | classement hebdo |
| `POST /claims` | JWT | réclamer/changer sa variante (premier arrivé) |
| `POST /photos` · `/photos/catchup` | JWT | multipart : analyse ΔE+variance, stocke, propage, score+streak |
| `POST /contributions/:id/reactions` | JWT | poser/retirer un tampon |
| `POST /guesses` | JWT | pari hebdo (éditable) |
| `GET /me` · `PATCH /me` | JWT | profil + stats / maj pseudo·notif·locale |
| `GET /me/collection` | JWT | musée perso (œuvres révélées, débloquées selon la règle) |
| `GET /me/export` · `DELETE /me` | JWT | RGPD : export JSON / effacement en cascade |
| `POST /photos` body | JWT | champs : `day`, `variantKey`, `shared`, `separateInstanceId`, fichier |

Admin (`/api/admin`, header `Authorization: Bearer $ADMIN_TOKEN`) :
`GET /stats`, `GET /artworks`, `POST /artworks` (œuvre + familles + variantes + cellules),
`POST /artworks/:id/status`, `DELETE /artworks/:id`, `GET /gallery`, `DELETE /photos/:id`.

## Matching (laxiste)
Aucune photo refusée. ΔE ≤ `COLOR_DELTA_PERFECT` (25) → « parfait », ≤ `COLOR_DELTA_ACCEPT`
(55) → « correct », au-delà → accepté (« libre »), bonus nul. Bonus matching 0–15,
réduit de moitié pour les aplats (variance faible). EXIF (dont GPS) supprimé à l'upload.

## Scoring (constantes dans `services/scoring.ts`)
Photo 10 pts + bonus ΔE 0–15, × multiplicateur de streak (×1,1/jour, plafond ×1,5).
Pari : barème dégressif `[70,50,35,25,15,10,5]` (lun→dim). Collection : 7 photos/semaine
**et** ≥1 instance non-solo à 100 %.

## À faire ensuite
- Brancher l'app Flutter (couche `Repository` + client dio) sur ces endpoints — à
  faire avec le serveur en marche pour itérer écran par écran.
- Admin v2 riche (crop 3:4, pixelisation interactive, planning, modération) — Phase 3.
