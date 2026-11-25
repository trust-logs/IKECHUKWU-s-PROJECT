# F.I LOGS

F.I LOGS is a digital marketplace for social media accounts and related digital services, with wallet, order management, virtual numbers, SMS, social boosting and bill-payment workflows.

## Brand system
- **Royal Blue:** `#014BAA` — primary brand colour, navigation, actions and accents.
- **Light Cream:** `#F8F3F0` — primary light surface and page background.
- Dark mode uses deep navy surfaces with accessible blue accents.

The theme is centralized in `src/styles.css`. Legacy `gold` utility names are retained for compatibility and now resolve to the Royal Blue palette.

## Development
Requires Node.js 22+ and npm (or Bun).

```sh
npm install
npm run dev
```

Useful scripts: `npm run build`, `npm run test`, and `npm run lint`.

## Environment and Supabase
Copy `.env.example` to `.env` and fill in the public Supabase URL and publishable key. Configure server-only integration secrets in the deployment provider's secret manager. Never commit `.env`, service-role keys, webhook secrets, or provider API keys.

Database migrations are in `supabase/migrations/`. Apply and validate them against the target Supabase project before enabling production traffic. Live project credentials and provider secrets are intentionally excluded from this repository.

## Deployment readiness
The application uses TanStack Start, Vite, Cloudflare tooling, PWA assets and server-side API routes. Complete deployment configuration, Supabase connection, authentication redirect URLs, database migrations, webhook URLs and provider credentials after connecting the target Supabase project.
