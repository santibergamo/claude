import '../data/models.dart';
import '../data/repository.dart';

class PartidoProximo {
  const PartidoProximo({
    required this.campeonato,
    required this.jornada,
    required this.partido,
  });

  final Campeonato campeonato;
  final Jornada jornada;
  final Partido partido;
}

/// Próximos partidos (sin jugar) de Primera A, B y C, ordenados por día.
Future<Respuesta<List<PartidoProximo>>> cargarProximos(
  LigaRepository repo, {
  bool refrescar = false,
  DateTime? hoy,
}) async {
  final primeras = await repo.primeras(refrescar: refrescar);
  Catalogo? catalogo;
  try {
    catalogo = (await repo.catalogo()).datos;
  } catch (_) {
    // Sin catálogo se asume el año actual para las fechas.
  }
  final nombreTorneo = catalogo?.actual.nombre;
  final respuestas = await Future.wait([
    for (final c in primeras)
      repo.campeonato(c, nombreTorneo: nombreTorneo, refrescar: refrescar),
  ]);

  final lista = <PartidoProximo>[];
  for (var i = 0; i < primeras.length; i++) {
    for (final j in respuestas[i].datos.proximas(hoy ?? DateTime.now())) {
      for (final p in j.partidos) {
        if (p.esLibre) continue;
        lista.add(
          PartidoProximo(campeonato: primeras[i], jornada: j, partido: p),
        );
      }
    }
  }
  final lejano = DateTime(9999);
  lista.sort((a, b) {
    final d = (a.jornada.dia ?? lejano).compareTo(b.jornada.dia ?? lejano);
    if (d != 0) return d;
    final c = a.campeonato.nombre.compareTo(b.campeonato.nombre);
    if (c != 0) return c;
    return a.partido.hora.compareTo(b.partido.hora);
  });

  return Respuesta(
    lista,
    actualizado: respuestas
        .map((r) => r.actualizado)
        .reduce((a, b) => a.isBefore(b) ? a : b),
    desdeCache: respuestas.any((r) => r.desdeCache),
  );
}
