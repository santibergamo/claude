enum Seccion {
  posiciones('Posiciones'),
  fixture('Fixture'),
  goleadores('Goleadores'),
  sanciones('Sanciones'),
  otros('Otros');

  const Seccion(this.titulo);
  final String titulo;
}

/// Una tabla extraída de la web de la liga.
class Tabla {
  const Tabla({
    required this.titulo,
    required this.encabezados,
    required this.filas,
    required this.seccion,
  });

  final String titulo;
  final List<String> encabezados;
  final List<List<String>> filas;
  final Seccion seccion;
}

/// Todo lo que la app muestra de una categoría.
class DatosCategoria {
  const DatosCategoria({
    required this.tablas,
    required this.url,
    required this.actualizado,
    this.desdeCache = false,
  });

  final List<Tabla> tablas;
  final Uri url;
  final DateTime actualizado;
  final bool desdeCache;

  List<Tabla> de(Seccion s) => tablas.where((t) => t.seccion == s).toList();
}
