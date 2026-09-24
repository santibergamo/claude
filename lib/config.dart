/// Configuración de la liga y las categorías que muestra la app.
class LigaConfig {
  static const String baseUrl = 'https://ligacountrysur.com.ar/futbol';

  /// Torneo Clausura 2026.
  static const int torneo = 329;

  /// Campeonato desde el que se descubren las demás categorías del torneo.
  static const int campeonatoSemilla = 4314;

  static const String tituloTorneo = 'Clausura 2026';

  static const List<Categoria> categorias = [
    Categoria(letra: 'A', nombre: 'Primera A'),
    Categoria(letra: 'B', nombre: 'Primera B'),
    Categoria(letra: 'C', nombre: 'Primera C'),
  ];

  static Uri urlCampeonato(int campeonato) =>
      Uri.parse('$baseUrl?torneo=$torneo&campeonato=$campeonato');
}

class Categoria {
  const Categoria({required this.letra, required this.nombre, this.campeonato});

  final String letra;
  final String nombre;

  /// ID fijo del campeonato. Si es null se busca en la web de la liga.
  final int? campeonato;
}
