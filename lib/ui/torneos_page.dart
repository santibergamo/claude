import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/parser.dart';
import '../data/repository.dart';
import 'campeonato_page.dart';
import 'theme.dart';
import 'widgets.dart';

/// Navegación entre torneos y sus categorías.
class TorneosPage extends StatefulWidget {
  const TorneosPage({super.key, required this.repo});
  final LigaRepository repo;

  @override
  State<TorneosPage> createState() => _TorneosPageState();
}

class _TorneosPageState extends State<TorneosPage> {
  late Future<Respuesta<Catalogo>> _futuro = widget.repo.catalogo();
  Torneo? _torneo;

  Future<void> _refrescar() async {
    setState(() => _futuro = widget.repo.catalogo(refrescar: true));
    await _futuro.then((_) {}, onError: (_) {});
  }

  Future<void> _elegirTorneo(Catalogo cat) async {
    final elegido = await showModalBottomSheet<Torneo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _SelectorTorneo(catalogo: cat, actual: _torneo ?? cat.actual),
    );
    if (elegido != null) setState(() => _torneo = elegido);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Torneos')),
      body: FutureBuilder<Respuesta<Catalogo>>(
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
          final cat = snap.data!.datos;
          if (cat.torneos.isEmpty) {
            return const Vacio('No se encontraron torneos.');
          }
          final torneo = _torneo ?? cat.actual;
          final campeonatos = cat.de(torneo.id);

          final grupos = <String, List<Campeonato>>{};
          for (final c in campeonatos) {
            final grupo = c.letraPrimera != null
                ? 'Primera división'
                : conTildes(c.deporte);
            grupos.putIfAbsent(grupo, () => []).add(c);
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _elegirTorneo(cat),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: LigaColors.verde.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.emoji_events_outlined,
                                color: LigaColors.verde,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Torneo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                  Text(
                                    torneo.nombre,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            if (torneo.actual) const Etiqueta('En curso'),
                            const SizedBox(width: 4),
                            const Icon(Icons.unfold_more),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (campeonatos.isEmpty)
                  const Vacio('Este torneo no tiene categorías.')
                else
                  for (final e in grupos.entries) ...[
                    Seccion(e.key),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (var i = 0; i < e.value.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 64),
                              _CampeonatoTile(
                                campeonato: e.value[i],
                                torneo: torneo,
                                repo: widget.repo,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CampeonatoTile extends StatelessWidget {
  const _CampeonatoTile({
    required this.campeonato,
    required this.torneo,
    required this.repo,
  });

  final Campeonato campeonato;
  final Torneo torneo;
  final LigaRepository repo;

  @override
  Widget build(BuildContext context) {
    final letra = campeonato.letraPrimera;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: letra != null
            ? LigaColors.verde
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: letra != null ? Colors.white : null,
        child: Text(
          letra ?? LigaParser.iniciales(campeonato.nombreCorto),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(
        campeonato.nombreCorto,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CampeonatoPage(
            campeonato: campeonato,
            torneo: torneo,
            repo: repo,
          ),
        ),
      ),
    );
  }
}

class _SelectorTorneo extends StatefulWidget {
  const _SelectorTorneo({required this.catalogo, required this.actual});
  final Catalogo catalogo;
  final Torneo actual;

  @override
  State<_SelectorTorneo> createState() => _SelectorTorneoState();
}

class _SelectorTorneoState extends State<_SelectorTorneo> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.toLowerCase().trim();
    final torneos = widget.catalogo.torneos
        .where((t) => q.isEmpty || t.nombre.toLowerCase().contains(q))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar torneo (ej: Apertura 2025)',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: torneos.length,
              itemBuilder: (_, i) {
                final t = torneos[i];
                final seleccionado = t.id == widget.actual.id;
                return ListTile(
                  title: Text(
                    t.nombre,
                    style: TextStyle(
                      fontWeight: seleccionado
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(_categorias(widget.catalogo.de(t.id).length)),
                  trailing: seleccionado
                      ? const Icon(Icons.check_circle, color: LigaColors.verde)
                      : t.actual
                      ? const Etiqueta('En curso')
                      : null,
                  onTap: () => Navigator.of(context).pop(t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _categorias(int n) => n == 1 ? '1 categoría' : '$n categorías';
