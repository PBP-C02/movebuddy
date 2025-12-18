class EventConfig {
  // Base domain only (no app prefix), so Event endpoints resolve correctly.
  static const String baseUrl = String.fromEnvironment(
    'MOVE_BUDDY_BASE_URL',
    defaultValue: 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id',
  );

  static String resolve(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(normalizedBase).resolve(normalizedPath).toString();
  }
}

