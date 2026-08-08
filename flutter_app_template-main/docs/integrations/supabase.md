# Supabase integration

## Setup

### 1. Create the project

[supabase.com](https://supabase.com) → new project. From **Settings → API**
copy the **Project URL** and the **anon / publishable** key.

The anon key is designed to be public — it ships in your app binary. What
protects your data is row-level security, not the key.

### 2. Configure the build

`env/dev.json`:

```json
{
  "ENV": "dev",
  "SUPABASE_URL": "https://xxxxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGciOi..."
}
```

```bash
flutter run --dart-define-from-file=env/dev.json
```

`env/*.json` is gitignored. Commit only `env/dev.json.example`.

Without these values the app still runs: `SupabaseInitializer` logs a warning
and the locator registers `UnavailableAuthRepository`, so auth fails with a
clear message rather than crashing.

### 3. Enable auth

**Authentication → Providers → Email**. For development, turn *off* "Confirm
email" — otherwise `signUp` returns a user with no session, and the data source
surfaces that as "Confirm your email address to sign in."

## Row-level security — do not skip this

Every table needs RLS. Without it, the public anon key reads your whole
database.

```sql
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "update own profile"
  on public.profiles for update
  using (auth.uid() = id);
```

Verify with the anon key, signed out — you should get zero rows, not an error.

## Using the database

Through a repository, always:

```dart
class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  const ProfileRepositoryImpl({
    required SupabaseDatabaseService database,
    required super.logger,
    super.cache,
  }) : _database = database;

  final SupabaseDatabaseService _database;

  @override
  AsyncResult<Profile> fetchProfile(String userId) => guard(() async {
        final row = await _database.findById('profiles', userId);
        if (row == null) throw const NotFoundException(message: 'No profile.');
        return Profile.fromJson(row);
      }, context: 'fetchProfile');
}
```

## Realtime

```dart
listenTo(
  _database.watch('orders', primaryKey: ['id'], orderBy: 'created_at'),
  (rows) => _orders = rows.map(Order.fromJson).toList(),
);
```

Realtime must be enabled per table (**Database → Replication**). Always cancel
the subscription — `SubscriptionMixin` does it for you.

## Edge Functions

Anything requiring the service-role key belongs in a function, never in the app:

- account deletion,
- Stripe payment-intent creation,
- any write the client must not be trusted to compute.

```ts
// supabase/functions/delete-account/index.ts
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,   // server only
);
```

Call it from the app with `SupabaseDatabaseService.callFunction`.

## Error mapping

`ExceptionMapper` already translates Supabase errors:

| Supabase | App |
| --- | --- |
| `AuthException` 401/403 | `UnauthorizedException` |
| `AuthException` other | `AuthException` |
| `PostgrestException` `PGRST116` | `NotFoundException` |
| `PostgrestException` other | `ServerException` |
| `StorageException` | `StorageException` |

## Production checklist

- [ ] RLS enabled on **every** table, policies tested signed-out
- [ ] Email confirmation ON in staging and production
- [ ] Redirect URLs allow-listed (**Authentication → URL Configuration**)
- [ ] Service-role key never in the app, never in `env/*.json` used by Flutter
- [ ] Separate Supabase projects for dev/staging/prod
- [ ] Database backups enabled
- [ ] Rate limits reviewed under **Auth → Rate Limits**
