# velcordfilm-gateway

Nginx reverse proxy – a stack egyetlen publikus belépési pontja.

## Routing

| Útvonal | Cél |
|---|---|
| `/api/blog/*` | `offerservice:3000/blog/` (nginx cache) |
| `/api/*` | `offerservice:3000` |
| `/auth/*` | `offerservice:3000/auth/` |
| `/health` | `offerservice:3000/health` |
| `/*` | `frontend:80` |

## "Staging" védelmi réteg (`ENVIRONMENT`)

Az `ENVIRONMENT` env változó vezérli (a `velcordfilm-environment/.env`-ből):

- `production` (alapértelmezett): nincs extra védelem.
- bármi más (pl. `staging`): induláskor a `staging-available/` alatti config
  darabok bekerülnek a `conf.d/`-be, ezzel:
  - **Basic auth** minden útvonalra (`02-basic-auth.conf`)
  - **`X-Robots-Tag: noindex, nofollow, noarchive`** + saját `robots.txt`
    (`Disallow: /`) – `00-noindex.conf`
  - **AI bot user-agentek elutasítása** (403) – GPTBot, ClaudeBot, CCBot,
    Google-Extended, PerplexityBot stb. (`http-extra/bot-block.conf` +
    `01-bot-block.conf`)

Ezt a `docker-entrypoint.d/40-staging-config.sh` script intézi, ami az nginx
hivatalos image indítási hookjaként fut le.

### Lokális teszt

A `docker-compose.override.yml` automatikusan bemountolja
`../velcordfilm-environment/gateway-secrets/.htpasswd`-t a gateway-be, ha
`ENVIRONMENT=staging`. Alapértelmezett lokális belépés: **velcord / velcord**
(lásd lent, hogyan generálható újra).

### Basic auth jelszó beállítása (staging/beta szerveren)

A jelszófájlt **nem** tartalmazza a repo (gitignore-olva). A
`velcordfilm-environment/gateway-secrets/.htpasswd` fájlt kell létrehozni a
szerveren, pl.:

```bash
mkdir -p gateway-secrets
# bcrypt hash generálása (apache2-utils / httpd-tools "htpasswd" csomag kell hozzá)
htpasswd -Bc gateway-secrets/.htpasswd velcord
```

Vagy `htpasswd` nélkül, `openssl`-lel (apr1 hash):

```bash
mkdir -p gateway-secrets
echo "velcord:$(openssl passwd -apr1 'ERŐS_JELSZÓ')" > gateway-secrets/.htpasswd
```

### Indítás staging módban

```bash
# velcordfilm-environment/.env-ben: ENVIRONMENT=staging
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d --build
```

### Új AI bot hozzáadása a tiltólistához

`staging-available/http-extra/bot-block.conf` – új sor:

```
~*ÚjBotNeve 1;
```

Újraindítás után (`docker compose restart gateway`) érvénybe lép.
