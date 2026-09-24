import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'proximos.dart';
import 'theme.dart';
import 'widgets.dart';

/// Inicio: próximos partidos destacados y noticias de la liga.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repo, required this.onVerFixture});

  final LigaRepository repo;
  final VoidCallback onVerFixture;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Respuesta<List<Noticia>>> _noticias = widget.repo.noticias();
  late Future<Respuesta<List<PartidoProximo>>> _proximos = cargarProximos(
    widget.repo,
  );

  Future<void> _refrescar() async {
    setState(() {
      _noticias = widget.repo.noticias(refrescar: true);
      _proximos = cargarProximos(widget.repo, refrescar: true);
    });
    await Future.wait([
      _noticias.then((_) {}, onError: (_) {}),
      _proximos.then((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refrescar,
      child: CustomScrollView(
        slivers: [
          const _Encabezado(),
          SliverToBoxAdapter(
            child: Seccion(
              'Próximos partidos',
              subtitulo: 'Primera A · B · C',
              accion: TextButton(
                onPressed: widget.onVerFixture,
                child: const Text('Ver todos'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Proximos(futuro: _proximos, onReintentar: _refrescar),
          ),
          const SliverToBoxAdapter(child: Seccion('Noticias')),
          FutureBuilder<Respuesta<List<Noticia>>>(
            future: _noticias,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SliverToBoxAdapter(child: Cargando());
              }
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: MensajeError(
                    error: snap.error,
                    onReintentar: _refrescar,
                  ),
                );
              }
              final noticias = snap.data!.datos;
              if (noticias.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Vacio(
                    'No hay noticias publicadas.',
                    icono: Icons.article_outlined,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: noticias.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _NoticiaCard(noticias[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, top + 20, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [LigaColors.verde, LigaColors.verdeOscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.network(
                '${LigaConfig.baseUrl}/uploads/settings/1752528050-logo_liga_chico.png',
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.sports_soccer, color: LigaColors.verde),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liga Country Sur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Fútbol · Tu deporte, tu comunidad',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Proximos extends StatelessWidget {
  const _Proximos({required this.futuro, required this.onReintentar});
  final Future<Respuesta<List<PartidoProximo>>> futuro;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Respuesta<List<PartidoProximo>>>(
      future: futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return MensajeError(error: snap.error, onReintentar: onReintentar);
        }
        final lista = snap.data!.datos.take(8).toList();
        if (lista.isEmpty) {
          return const Vacio('No hay partidos programados por ahora.');
        }
        return SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p = lista[i];
              return SizedBox(
                width: 270,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        capitalizar(p.jornada.textoDia),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    MatchCard(
                      partido: p.partido,
                      etiqueta:
                          '${p.campeonato.nombreCorto} · ${p.jornada.nombre}',
                      mostrarEstado: false,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  const _NoticiaCard(this.noticia);
  final Noticia noticia;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse(noticia.url),
          mode: LaunchMode.inAppBrowserView,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (noticia.imagen != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  noticia.imagen!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: LigaColors.verde.withValues(alpha: .1),
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.titulo,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (noticia.resumen.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      noticia.resumen,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text(
                        'Leer más',
                        style: TextStyle(
                          color: LigaColors.verde,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: LigaColors.verde,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
