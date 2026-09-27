# App environment

The Flutter client reads compile-time values through `--dart-define`. These
values are embedded in the built application; they are configuration, not a
place to store server secrets.

## Variables read by the app

| Variable | Purpose | Required for configured mode |
| --- | --- | --- |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | Supabase client anon/publishable key | Yes |

Both reads are defined in `lib/core/config/app_environment.dart`. If either
value is empty, the app uses its unconfigured repository implementations and
does not initialize Supabase.

Generated Riverpod files also read the SDK-provided `dart.vm.product` boolean.
It is not application configuration and must not be added to the defines file.

Stripe is outside the canonical product scope. The Flutter client has no
Stripe environment variable, initialization, or payment flow. Do not add
Stripe keys to client configuration.

## Local setup

Create the ignored local configuration file from the tracked template:

```sh
cp dart_defines.example.json dart_defines.json
```

Fill in the two values:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-or-publishable-key"
}
```

Run the app with:

```sh
make run
```

The target runs:

```sh
flutter run --dart-define-from-file=dart_defines.json
```

To select a device explicitly, run the Flutter command directly and append
`-d <device-id>`.

## Client key security

The Supabase anon/publishable key is designed to be embedded in public clients.
It identifies the project and does not bypass Row Level Security. Repository
migrations create 43 `public` tables and enable RLS on all 43; access is then
granted by the table policies. This confirms the checked-in schema, but the
deployed project must still be kept in sync with these migrations.

The Supabase `service_role` key bypasses RLS and must never be shipped. No
`service_role` key or environment variable is referenced anywhere under
`lib/`. The SQL migrations do mention the database role for server-only grants
and privileged functions; that is expected and does not embed a key in the
client.
