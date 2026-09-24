import 'package:flutter/material.dart';

import '../data/repository.dart';
import 'proximos.dart';
import 'widgets.dart';

/// Solo los próximos partidos de Primera A, B y C, agrupados por día.
class FixturePage extends StatefulWidget {
  const FixturePage({super.key, required this.repo});
  final LigaRepository repo;

  @override
  State<FixturePage> createState() => _FixturePageState();
}

class _FixturePageState extends State<FixturePage> {
  late Future<Respuesta<List<PartidoProximo>>> _futuro = cargarProximos(
    widget.repo,
  );
  String? _filtro; // null = todas; si no, "A", "B" o "C".

  Future<void> _refrescar() async {
    setState(() => _futuro = cargarProximos(widget.repo, refrescar: true));
    await _futuro.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Próximos partidos')),
      body: FutureBuilder<Respuesta<List<PartidoProximo>>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Cargando();
          }
          if (snap.hasError) {
            return Center(
              child: MensajeError(error: snap.error, onReintentar: _refrescar),
            );
          }
          final todos = snap.data!.datos;
          final lista = _filtro == null
              ? todos
              : todos
                    .where((p) => p.campeonato.letraPrimera == _filtro)
                    .toList();

          // Agrupar por día.
          final grupos = <String, List<PartidoProximo>>{};
          for (final p in lista) {
            grupos.putIfAbsent(p.jornada.textoDia, () => []).add(p);
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AvisoActualizacion(
                  fecha: snap.data!.actualizado,
                  desdeCache: snap.data!.desdeCache,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      for (final f in [null, 'A', 'B', 'C'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f == null ? 'Todas' : 'Primera $f'),
                            selected: _filtro == f,
                            onSelected: (_) => setState(() => _filtro = f),
                          ),
                        ),
                    ],
                  ),
                ),
                if (lista.isEmpty)
                  const Vacio('No hay partidos programados por ahora.')
                else
                  for (final e in grupos.entries) ...[
                    Seccion(capitalizar(e.key.isEmpty ? 'Sin fecha' : e.key)),
                    for (final g in _porCategoria(e.value).entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Etiqueta(g.key),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: ListaPartidos(
                          partidos: [for (final p in g.value) p.partido],
                          mostrarEstado: false,
                        ),
                      ),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// "Primera A · Fecha 7" -> partidos.
  static Map<String, List<PartidoProximo>> _porCategoria(
    List<PartidoProximo> l,
  ) {
    final res = <String, List<PartidoProximo>>{};
    for (final p in l) {
      res
          .putIfAbsent(
            '${p.campeonato.nombreCorto} · ${p.jornada.nombre}',
            () => [],
          )
          .add(p);
    }
    return res;
  }
}
