# F.I LOGS

F.I LOGS is a digital marketplace and services platform built with TanStack Start, React, and Supabase.

## Brand palette

- **Royal Blue:** `#014BAA` — primary brand colour, actions, navigation, and highlights.
- **Light Cream:** `#F8F3F0` — light page backgrounds and surfaces.

## Supabase

The active Supabase project is `iqnpmmezuznwznwqhbau`. Its application schema, row-level security, wallet functions, credential-delivery RPC, notification triggers, and storage buckets have been provisioned.

Copy `.env.example` to `.env`. Use the publishable key in browser variables. Add the service-role key and provider secrets only to the server/deployment secret manager; never expose them through `VITE_*`.

After signing up to F.I LOGS, replace the placeholder email in `supabase/bootstrap-admin.sql` and run it to grant your own account `super_admin`.

## Development

Install dependencies with `bun install`, then run `bun run dev`.

Checks:
- `bun run build`
- `bun run test`
- `bun run lint`

Do not commit `.env`, provider credentials, service-role keys, or database passwords.
