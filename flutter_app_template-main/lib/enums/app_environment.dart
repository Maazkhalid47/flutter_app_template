/// The deployment environments the app can be built for.
///
/// Selected at build time through `--dart-define=ENV=<name>` and resolved by
/// [AppConfig]. Never branch on this enum inside widgets — branch inside
/// configuration or service registration instead.
enum AppEnvironment {
  dev('dev'),
  staging('staging'),
  prod('prod');

  const AppEnvironment(this.key);

  /// The literal value expected in `--dart-define=ENV=...`.
  final String key;

  bool get isDev => this == AppEnvironment.dev;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProd => this == AppEnvironment.prod;

  /// Resolves [value] to an environment, falling back to [AppEnvironment.dev]
  /// so a missing define never crashes a local run.
  static AppEnvironment fromKey(String value) {
    for (final env in AppEnvironment.values) {
      if (env.key == value) return env;
    }
    return AppEnvironment.dev;
  }
}
