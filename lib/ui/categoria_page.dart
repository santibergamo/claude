import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'tabla_view.dart';

/// Pestañas de secciones (posiciones, fixture, etc.) de una categoría.
class CategoriaPage extends StatefulWidget {
  const CategoriaPage({super.key, required this.categoria, required this.repo});

  final Categoria categoria;
  final LigaRepository repo;

  static const secciones = [
    Seccion.posiciones,
    Seccion.fixture,
    Seccion.goleadores,
    Seccion.sanciones,
  ];

  @override
  State<CategoriaPage> createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage>
    with AutomaticKeepAliveClientMixin {
  late Future<DatosCategoria> _futuro = widget.repo.datos(widget.categoria);

  @override
  bool get wantKeepAlive => true;

  Future<void> _recargar() async {
    final f = widget.repo.datos(widget.categoria);
    setState(() => _futuro = f);
    try {
      await f;
    } catch (_) {
      // El FutureBuilder muestra el error.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<DatosCategoria>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _Error(mensaje: '${snap.error}', onReintentar: _recargar);
        }
        final datos = snap.data!;
        return TabBarView(
          children: [
            for (final s in CategoriaPage.secciones)
              _SeccionView(seccion: s, datos: datos, onRecargar: _recargar),
          ],
        );
      },
    );
  }
}

class _SeccionView extends StatefulWidget {
  const _SeccionView({
    required this.seccion,
    required this.datos,
    required this.onRecargar,
  });

  final Seccion seccion;
  final DatosCategoria datos;
  final Future<void> Function() onRecargar;

  @override
  State<_SeccionView> createState() => _SeccionViewState();
}

class _SeccionViewState extends State<_SeccionView> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final datos = widget.datos;
    var tablas = datos.de(widget.seccion);
    // Si la web tiene tablas que no supimos clasificar, se muestran en
    // Posiciones para no perder información.
    if (widget.seccion == Seccion.posiciones) {
      tablas = [...tablas, ...datos.de(Seccion.otros)];
    }
    final buscable = widget.seccion != Seccion.posiciones;

    return RefreshIndicator(
      onRefresh: widget.onRecargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Estado(datos: datos),
          if (buscable && tablas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar equipo o jugador',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _filtro = v),
              ),
            ),
          if (tablas.isEmpty)
            _Vacio(seccion: widget.seccion, url: datos.url)
          else
            for (final t in tablas) TablaView(tabla: t, filtro: _filtro),
        ],
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.datos});
  final DatosCategoria datos;

  @override
  Widget build(BuildContext context) {
    final a = datos.actualizado;
    String dos(int n) => n.toString().padLeft(2, '0');
    final fecha =
        '${dos(a.day)}/${dos(a.month)} ${dos(a.hour)}:${dos(a.minute)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(
            datos.desdeCache ? Icons.cloud_off : Icons.update,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              datos.desdeCache
                  ? 'Sin conexión · datos guardados del $fecha'
                  : 'Actualizado $fecha · deslizá para refrescar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.seccion, required this.url});
  final Seccion seccion;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.sports_soccer,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no hay ${seccion.titulo.toLowerCase()} publicados '
            'para esta categoría.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Ver en la web de la liga'),
            onPressed: () =>
                launchUrl(url, mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: onReintentar,
            ),
            TextButton(
              onPressed: () => launchUrl(
                LigaConfig.urlCampeonato(LigaConfig.campeonatoSemilla),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Abrir la web de la liga'),
            ),
          ],
        ),
      ),
    );
  }
}
