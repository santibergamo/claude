import '../config.dart';

class Torneo {
  const Torneo({required this.id, required this.nombre, this.actual = false});

  final int id;
  final String nombre;
  final bool actual;

  Map<String, Object?> toJson() => {
    'id': id,
    'nombre': nombre,
    'actual': actual,
  };
  factory Torneo.fromJson(Map<String, dynamic> j) => Torneo(
    id: j['id'] as int,
    nombre: j['nombre'] as String,
    actual: j['actual'] as bool? ?? false,
  );
}

/// Una categoría dentro de un torneo (p. ej. Primera "B" del Clausura 2026).
class Campeonato {
  const Campeonato({
    required this.id,
    required this.torneoId,
    required this.nombre,
    required this.deporte,
  });

  final int id;
  final int torneoId;
  final String nombre;
  final String deporte;

  /// "A", "B" o "C" si es una Primera; null si no.
  String? get letraPrimera {
    final m = RegExp(
      r'''^primera\s*["'“]?\s*([abc])\b''',
      caseSensitive: false,
    ).firstMatch(nombre.trim());
    return m?.group(1)?.toUpperCase();
  }

  /// Nombre sin comillas: Primera "B" -> Primera B.
  String get nombreCorto => nombre.replaceAll(RegExp(r'''["“”]'''), '').trim();

  Map<String, Object?> toJson() => {
    'id': id,
    't': torneoId,
    'n': nombre,
    'd': deporte,
  };
  factory Campeonato.fromJson(Map<String, dynamic> j) => Campeonato(
    id: j['id'] as int,
    torneoId: j['t'] as int,
    nombre: j['n'] as String,
    deporte: j['d'] as String,
  );
}

class Catalogo {
  const Catalogo({required this.torneos, required this.campeonatos});

  /// Ordenados del más nuevo al más viejo.
  final List<Torneo> torneos;
  final Map<int, List<Campeonato>> campeonatos;

  Torneo get actual =>
      torneos.where((t) => t.actual).firstOrNull ??
      torneos.where((t) => t.id == LigaConfig.torneoActual).firstOrNull ??
      torneos.first;

  List<Campeonato> de(int torneoId) => campeonatos[torneoId] ?? const [];

  Map<String, Object?> toJson() => {
    'torneos': [for (final t in torneos) t.toJson()],
    'campeonatos': [
      for (final l in campeonatos.values)
        for (final c in l) c.toJson(),
    ],
  };

  factory Catalogo.fromJson(Map<String, dynamic> j) {
    final camps = <int, List<Campeonato>>{};
    for (final c in (j['campeonatos'] as List)) {
      final camp = Campeonato.fromJson(c as Map<String, dynamic>);
      camps.putIfAbsent(camp.torneoId, () => []).add(camp);
    }
    return Catalogo(
      torneos: [
        for (final t in (j['torneos'] as List))
          Torneo.fromJson(t as Map<String, dynamic>),
      ],
      campeonatos: camps,
    );
  }
}

class FilaPosicion {
  const FilaPosicion({
    required this.posicion,
    required this.equipo,
    required this.iniciales,
    required this.jugados,
    required this.ganados,
    required this.empatados,
    required this.perdidos,
    required this.golesFavor,
    required this.golesContra,
    required this.puntos,
  });

  final int posicion;
  final String equipo;
  final String iniciales;
  final int? jugados, ganados, empatados, perdidos, golesFavor, golesContra;
  final int puntos;

  int? get diferencia => golesFavor != null && golesContra != null
      ? golesFavor! - golesContra!
      : null;
}

class TablaPosiciones {
  const TablaPosiciones({required this.titulo, required this.filas});
  final String titulo;
  final List<FilaPosicion> filas;
}

enum EstadoPartido { pendiente, aConfirmar, finalizado }

class Partido {
  const Partido({
    required this.local,
    required this.visitante,
    required this.hora,
    required this.estado,
    this.golesLocal,
    this.golesVisitante,
    this.detalleUrl,
  });

  final String local;
  final String visitante;
  final String hora;
  final EstadoPartido estado;
  final int? golesLocal;
  final int? golesVisitante;
  final String? detalleUrl;

  bool get jugado => golesLocal != null && golesVisitante != null;
  bool get esLibre =>
      local.toLowerCase() == 'libre' || visitante.toLowerCase() == 'libre';
}

/// Una fecha (jornada) del fixture.
class Jornada {
  const Jornada({
    required this.nombre,
    required this.textoDia,
    required this.dia,
    required this.partidos,
  });

  final String nombre; // "Fecha 6"
  final String textoDia; // "sábado 26 de septiembre"
  final DateTime? dia;
  final List<Partido> partidos;

  bool get completa => partidos.every((p) => p.jugado || p.esLibre);
}

class Goleador {
  const Goleador({
    required this.posicion,
    required this.jugador,
    required this.equipo,
    required this.goles,
  });

  final int posicion;
  final String jugador;
  final String equipo;
  final int goles;
}

class Sancion {
  const Sancion({
    required this.jugador,
    required this.equipo,
    required this.tarjeta,
    required this.colorTarjeta,
    required this.fechas,
    required this.articulo,
    required this.fecha,
  });

  final String jugador;
  final String equipo;
  final String tarjeta;
  final int? colorTarjeta; // ARGB
  final String fechas;
  final String articulo;
  final String fecha;
}

class DatosCampeonato {
  const DatosCampeonato({
    required this.descripcion,
    required this.posiciones,
    required this.jornadas,
    required this.goleadores,
    required this.sanciones,
  });

  final String descripcion;
  final List<TablaPosiciones> posiciones;
  final List<Jornada> jornadas;
  final List<Goleador> goleadores;
  final List<Sancion> sanciones;

  /// Jornadas desde [hoy] en adelante, sólo con los partidos por jugar.
  List<Jornada> proximas(DateTime hoy) {
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    return [
      for (final j in jornadas)
        if (j.dia == null ? !j.completa : !j.dia!.isBefore(dia))
          Jornada(
            nombre: j.nombre,
            textoDia: j.textoDia,
            dia: j.dia,
            partidos: j.partidos.where((p) => !p.jugado).toList(),
          ),
    ].where((j) => j.partidos.isNotEmpty).toList();
  }

  /// Primera jornada que todavía tiene partidos por jugar.
  int get indiceJornadaActual {
    final i = jornadas.indexWhere((j) => !j.completa);
    return i < 0 ? (jornadas.isEmpty ? 0 : jornadas.length - 1) : i;
  }
}

class Noticia {
  const Noticia({
    required this.titulo,
    required this.resumen,
    required this.url,
    this.imagen,
  });

  final String titulo;
  final String resumen;
  final String url;
  final String? imagen;
}
