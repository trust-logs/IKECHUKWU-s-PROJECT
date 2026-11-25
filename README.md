# F.I LOGS

F.I LOGS is a Nigerian digital marketplace for social account listings, logs, SMS/virtual numbers, SMM services, wallet funding, and bill payments.

## Brand palette
- Royal Blue: `#014BAA` — primary brand colour, actions, navigation, and highlights.
- Light Cream: `#F8F3F0` — light surfaces and page backgrounds.

## Supabase project
The application is configured for the active Supabase project `iqnpmmezuznwznwqhbau` (`successuchendu90@gmail.com's Project`).

Copy `.env.example` to `.env` and fill in the project's publishable key. Add `SUPABASE_SERVICE_ROLE_KEY` only to the server deployment's secret store; never expose it to browser code or commit it.

## Development
```sh
npm install
npm run dev
```

Build and test:
```sh
npm run build
npm test
npm run lint
```

Provider credentials (PocketFi, Gramlsocial, and SMS provider keys) are intentionally left blank. Add them through server-side deployment secrets or the admin configuration flow after obtaining valid credentials.

The original SQL migration history contains multiple historical full-schema snapshots. Review and reconcile the chain before applying it to a new database.
