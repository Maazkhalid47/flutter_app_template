# supabase/

## Why it exists

Every line of Supabase SDK code in the app lives here. Outside this folder,
nothing imports `supabase_flutter` — which is what allows Supabase to be
replaced, or absent, without breaking the build.

(The one deliberate exception is `exceptions/exception_mapper.dart`, which must
recognise Supabase's error types in order to translate them.)

## What belongs here

| File | Purpose |
| --- | --- |
| `supabase_initializer.dart` | Startup, plus the "not configured" path |
| `supabase_auth_data_source.dart` | GoTrue adapter: SDK types in, app types out |
| `supabase_database_service.dart` | Generic Postgrest CRUD, RPC and realtime |

## What does NOT belong here

- Error handling — these classes throw; repositories map.
- Business logic. This is a translation layer only.
- Model definitions (→ `models/`).

## Naming conventions

- `SupabaseXDataSource` for adapters over an SDK client.
- `SupabaseXService` for query surfaces.
- Import the SDK aliased (`import 'package:supabase_flutter/supabase_flutter.dart' as sb;`)
  so it is obvious in the code which types are foreign.

## Example usage

```dart
final rows = await databaseService.select(
  'orders',
  filters: {'user_id': userId},
  orderBy: 'created_at',
  limit: 20,
);
final orders = rows.map(Order.fromJson).toList();
```

Realtime, from a view model with `SubscriptionMixin`:

```dart
listenTo(
  databaseService.watch('orders', primaryKey: ['id']),
  (rows) => _orders = rows.map(Order.fromJson).toList(),
);
```

## Best practices

- Return raw `Json` from this layer; let the repository decode. Only the
  repository knows which model a table maps to.
- Enable **row-level security** on every table. The anon key is public by
  design — it is in the app binary, and RLS is the only thing protecting data.
- Never put the service-role key in the app. Privileged work (account deletion,
  Stripe intents) belongs in an Edge Function.
- Always cancel realtime subscriptions; `SubscriptionMixin` does it for you.
- `PGRST116` means "no rows from `.single()`" and is mapped to
  `NotFoundException`, not a server error.

Setup: `docs/integrations/supabase.md`.
