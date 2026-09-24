import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'theme.dart';
import 'widgets.dart';

/// Posiciones, fixture, goleadores y sanciones de una categoría.
class CampeonatoPage extends StatefulWidget {
  const CampeonatoPage({
    super.key,
    required this.campeonato,
    required this.torneo,
    required this.repo,
  });

  final Campeonato campeonato;
  final Torneo torneo;
  final LigaRepository repo;

  @override
  State<CampeonatoPage> createState() => _CampeonatoPageState();
}

class _CampeonatoPageState extends State<CampeonatoPage> {
  late Future<Respuesta<DatosCampeonato>> _futuro = _cargar();

  Future<Respuesta<DatosCampeonato>> _cargar({bool refrescar = false}) =>
      widget.repo.campeonato(
        widget.campeonato,
        nombreTorneo: widget.torneo.nombre,
        refrescar: refrescar,
      );

  Future<void> _refrescar() async {
    setState(() => _futuro = _cargar(refrescar: true));
    await _futuro.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.campeonato.nombreCorto),
              Text(
                widget.torneo.nombre,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Ver en la web',
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => launchUrl(
                LigaConfig.urlWeb(widget.campeonato.id, widget.torneo.id),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Posiciones'),
              Tab(text: 'Fixture'),
              Tab(text: 'Goleadores'),
              Tab(text: 'Sanciones'),
            ],
          ),
        ),
        body: FutureBuilder<Respuesta<DatosCampeonato>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Cargando();
            }
            if (snap.hasError) {
              return Center(
                child: MensajeError(
                  error: snap.error,
                  onReintentar: _refrescar,
                ),
              );
            }
            final r = snap.data!;
            Widget pestania(List<Widget> hijos) => RefreshIndicator(
              onRefresh: _refrescar,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  AvisoActualizacion(
                    fecha: r.actualizado,
                    desdeCache: r.desdeCache,
                  ),
                  ...hijos,
                ],
              ),
            );
            return TabBarView(
              children: [
                pestania(_posiciones(r.datos)),
                _FixtureCompleto(datos: r.datos, onRefrescar: _refrescar),
                pestania(_goleadores(r.datos)),
                pestania(_sanciones(r.datos)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _posiciones(DatosCampeonato d) {
    if (d.posiciones.every((t) => t.filas.isEmpty)) {
      return const [
        Vacio(
          'Todavía no hay tabla de posiciones.',
          icono: Icons.leaderboard_outlined,
        ),
      ];
    }
    return [
      for (final t in d.posiciones)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TablaPosicionesView(tabla: t),
        ),
    ];
  }

  List<Widget> _goleadores(DatosCampeonato d) {
    if (d.goleadores.isEmpty) {
      return const [Vacio('Todavía no hay goleadores.')];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < d.goleadores.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _GoleadorTile(d.goleadores[i]),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _sanciones(DatosCampeonato d) {
    if (d.sanciones.isEmpty) {
      return const [
        Vacio('No hay sancionados.', icono: Icons.gpp_good_outlined),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < d.sanciones.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16),
                _SancionTile(d.sanciones[i]),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}

/// Tabla de posiciones pensada para el ancho de un celular.
class TablaPosicionesView extends StatelessWidget {
  const TablaPosicionesView({super.key, required this.tabla});
  final TablaPosiciones tabla;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final conEmpates = tabla.filas.any((f) => f.empatados != null);
    final conGoles = tabla.filas.any((f) => f.diferencia != null);
    final columnas = ['J', 'G', if (conEmpates) 'E', 'P', if (conGoles) 'DG'];

    Widget num(String t, {bool fuerte = false, Color? color}) => SizedBox(
      width: fuerte ? 34 : 26,
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: fuerte ? FontWeight.w900 : FontWeight.w500,
          fontSize: fuerte ? 15 : 13,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: LigaColors.verde,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: .5,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 26,
                    child: Text('#', textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('EQUIPO')),
                  for (final c in columnas) num(c, color: Colors.white),
                  num('PTS', fuerte: true, color: Colors.white),
                ],
              ),
            ),
          ),
          for (var i = 0; i < tabla.filas.length; i++)
            Builder(
              builder: (context) {
                final f = tabla.filas[i];
                final dg = f.diferencia;
                return Container(
                  color: i.isOdd ? scheme.surfaceContainerLow : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      RankPill(f.posicion),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f.equipo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.15,
                          ),
                        ),
                      ),
                      num('${f.jugados ?? '-'}'),
                      num('${f.ganados ?? '-'}'),
                      if (conEmpates) num('${f.empatados ?? '-'}'),
                      num('${f.perdidos ?? '-'}'),
                      if (conGoles)
                        num(
                          dg == null ? '-' : (dg > 0 ? '+$dg' : '$dg'),
                          color: dg == null || dg == 0
                              ? null
                              : dg > 0
                              ? LigaColors.verde
                              : Colors.red.shade700,
                        ),
                      num('${f.puntos}', fuerte: true),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FixtureCompleto extends StatefulWidget {
  const _FixtureCompleto({required this.datos, required this.onRefrescar});
  final DatosCampeonato datos;
  final Future<void> Function() onRefrescar;

  @override
  State<_FixtureCompleto> createState() => _FixtureCompletoState();
}

class _FixtureCompletoState extends State<_FixtureCompleto> {
  late int _indice = widget.datos.indiceJornadaActual;

  @override
  Widget build(BuildContext context) {
    final jornadas = widget.datos.jornadas;
    if (jornadas.isEmpty) {
      return const Vacio(
        'Todavía no hay fixture publicado.',
        icono: Icons.calendar_month_outlined,
      );
    }
    final j = jornadas[_indice.clamp(0, jornadas.length - 1)];
    return RefreshIndicator(
      onRefresh: widget.onRefrescar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              itemCount: jornadas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(jornadas[i].nombre.replaceFirst('Fecha ', 'F')),
                selected: i == _indice,
                onSelected: (_) => setState(() => _indice = i),
              ),
            ),
          ),
          Seccion(j.nombre, subtitulo: capitalizar(j.textoDia)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListaPartidos(partidos: j.partidos),
          ),
        ],
      ),
    );
  }
}

class _GoleadorTile extends StatelessWidget {
  const _GoleadorTile(this.g);
  final Goleador g;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: RankPill(g.posicion),
      title: Text(
        g.jugador,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(g.equipo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${g.goles}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.sports_soccer, size: 16, color: LigaColors.verde),
        ],
      ),
    );
  }
}

class _SancionTile extends StatelessWidget {
  const _SancionTile(this.s);
  final Sancion s;

  @override
  Widget build(BuildContext context) {
    final color = s.colorTarjeta != null
        ? Color(s.colorTarjeta!)
        : s.tarjeta.toLowerCase().contains('roja')
        ? Colors.red
        : Colors.amber.shade700;
    final detalles = [
      if (s.fechas.isNotEmpty) 'Fechas: ${s.fechas}',
      if (s.articulo.isNotEmpty) s.articulo,
      if (s.fecha.isNotEmpty) s.fecha,
    ].join(' · ');
    return ListTile(
      leading: Container(
        width: 18,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      title: Text(
        s.jugador,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text([s.equipo, if (detalles.isNotEmpty) detalles].join('\n')),
      isThreeLine: detalles.isNotEmpty,
      trailing: Text(
        s.tarjeta,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
