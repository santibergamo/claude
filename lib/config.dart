/// Configuración de la liga.
class LigaConfig {
  /// Se puede cambiar con --dart-define=BASE_URL=... (útil para pruebas).
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://ligacountrysur.com.ar',
  );

  /// Torneo que se usa si la web no marca ninguno como actual (Clausura 2026).
  static const int torneoActual = 329;

  /// IDs de Primera A, B y C del Clausura 2026, por si la web no los lista.
  static const Map<String, int> primerasPorDefecto = {
    'A': 4313,
    'B': 4314,
    'C': 4315,
  };

  static Uri get urlFutbol => Uri.parse('$baseUrl/futbol');
  static Uri get urlNoticias => Uri.parse('$baseUrl/blog');

  static Uri urlCampeonato(int campeonato, int torneo) =>
      Uri.parse('$baseUrl/liga/tabla-resultados-alt/$campeonato/$torneo');

  static Uri urlWeb(int campeonato, int torneo) =>
      Uri.parse('$baseUrl/futbol?torneo=$torneo&campeonato=$campeonato');
}
