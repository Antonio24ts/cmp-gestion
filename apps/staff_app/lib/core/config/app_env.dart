abstract final class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'Falta la variable SUPABASE_URL. '
        'Ejecuta Flutter utilizando --dart-define.',
      );
    }

    if (supabasePublishableKey.isEmpty) {
      throw StateError(
        'Falta la variable SUPABASE_PUBLISHABLE_KEY. '
        'Ejecuta Flutter utilizando --dart-define.',
      );
    }
  }
}