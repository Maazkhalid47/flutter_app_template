# cache/

## Why it exists

Two things: making repeat reads instant, and making the app usable without a
connection. The offline story lives here — `BaseRepository.cachedFetch` serves a
*stale* entry when the network fails, so a train journey shows yesterday's data
instead of an error screen.

## What belongs here

| File | Purpose |
| --- | --- |
| `cache_entry.dart` | A value plus `storedAt` and `ttl`; JSON round-trippable |
| `cache_manager.dart` | Two-tier (memory + disk) store with TTL and prefix invalidation |

## Two tiers, on purpose

- **Memory** — survives navigation within a session; zero I/O.
- **Disk** (via `PreferencesStore`) — survives restarts; enables offline.

## Naming conventions

Cache keys are namespaced with `:` so a whole family can be invalidated at once:

```
articles:list:1:20:          // page 1, size 20, no search
articles:detail:42
orders:list:1:20:
```

`invalidatePrefix('articles')` then clears every article entry after a mutation
without needing to know each page key.

## Example usage

Through the repository (the normal path):

```dart
cachedFetch<Article>(
  cacheKey: 'articles:detail:$id',
  fetch: () async => Article.fromJson((await _service.fetchArticle(id)).data),
  decode: (cached) => Article.fromJson(Map<String, dynamic>.from(cached! as Map)),
  encode: (value) => value.toJson(),
);
```

Directly, when you need control:

```dart
await cache.write('settings:remote', json, ttl: const Duration(hours: 1));
final fresh = await cache.readJson('settings:remote');
final anything = await cache.readJson('settings:remote', allowExpired: true);
```

## Best practices

- Only cache what is safe to show slightly stale. Never cache a payment status,
  a permission check, or anything security-sensitive.
- Invalidate the namespace after every mutation, or the next read returns the
  value you just changed.
- Cache writes are best-effort: a failure is logged, never propagated. A caching
  problem must not fail a successful request.
- A corrupt entry returns `null` (a miss) rather than throwing.
- Clear the cache on sign-out — cached data belongs to a user.
- Run `evictExpired()` at startup (bootstrap already does) so the store does not
  grow without bound.
