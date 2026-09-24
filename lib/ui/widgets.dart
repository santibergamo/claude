import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/parser.dart';
import '../data/repository.dart';
import 'theme.dart';

/// Círculo con las iniciales del equipo.
class TeamAvatar extends StatelessWidget {
  const TeamAvatar(this.equipo, {super.key, this.iniciales, this.size = 28});

  final String equipo;
  final String? iniciales;
  final double size;

  @override
  Widget build(BuildContext context) {
    final texto = iniciales ?? LigaParser.iniciales(equipo);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _color(equipo), shape: BoxShape.circle),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * .36,
          letterSpacing: -.3,
        ),
      ),
    );
  }

  /// Un tono de verde/azul estable por equipo, para distinguirlos.
  static Color _color(String equipo) {
    const paleta = [
      LigaColors.verde,
      Color(0xFF0E7490),
      Color(0xFF1D4ED8),
      Color(0xFF7C3AED),
      Color(0xFFB45309),
      Color(0xFF0F766E),
      Color(0xFFBE123C),
      Color(0xFF4D7C0F),
    ];
    final h = equipo.toLowerCase().codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    return paleta[h.abs() % paleta.length];
  }
}

/// Posición con medalla para los 3 primeros.
class RankPill extends StatelessWidget {
  const RankPill(this.posicion, {super.key});
  final int posicion;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = switch (posicion) {
      1 => (LigaColors.oro, const Color(0xFF7A5200)),
      2 => (LigaColors.plata, const Color(0xFF3A4A56)),
      3 => (LigaColors.bronce, const Color(0xFF5C3200)),
      _ => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$posicion',
        style: TextStyle(
          color: texto,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Tarjeta de un partido: local, resultado u hora, visitante.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.partido,
    this.etiqueta,
    this.mostrarEstado = true,
  });

  final Partido partido;
  final String? etiqueta;
  final bool mostrarEstado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = partido;
    final estilo = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    Widget equipo(String nombre, {required bool local}) {
      final ganador =
          p.jugado &&
          (local
              ? p.golesLocal! > p.golesVisitante!
              : p.golesVisitante! > p.golesLocal!);
      final libre = nombre.toLowerCase() == 'libre';
      final children = [
        if (!libre) TeamAvatar(nombre, size: 30),
        const SizedBox(height: 6),
        Text(
          libre ? 'Libre' : nombre,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: estilo?.copyWith(
            fontWeight: ganador ? FontWeight.w800 : FontWeight.w600,
            color: libre ? scheme.outline : null,
            fontStyle: libre ? FontStyle.italic : null,
          ),
        ),
      ];
      return Expanded(child: Column(children: children));
    }

    final centro = p.jugado
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: LigaColors.verde,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${p.golesLocal}  –  ${p.golesVisitante}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          )
        : Column(
            children: [
              Text(
                p.hora.isEmpty ? 'vs' : p.hora.replaceAll('hs', ' hs'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
              if (p.hora.isNotEmpty)
                Text(
                  'vs',
                  style: TextStyle(color: scheme.outline, fontSize: 12),
                ),
            ],
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            if (etiqueta != null || (mostrarEstado && p.jugado))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (etiqueta != null) Etiqueta(etiqueta!),
                    const Spacer(),
                    if (mostrarEstado) EstadoChip(p),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                equipo(p.local, local: true),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: centro,
                ),
                equipo(p.visitante, local: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LigaColors.verde.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: LigaColors.verde,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .6,
        ),
      ),
    );
  }
}

/// Fila compacta de partido para listas: local · hora/resultado · visitante.
class MatchRow extends StatelessWidget {
  const MatchRow({super.key, required this.partido, this.mostrarEstado = true});

  final Partido partido;
  final bool mostrarEstado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = partido;

    Widget equipo(String nombre, {required bool local}) {
      final libre = nombre.toLowerCase() == 'libre';
      final ganador =
          p.jugado &&
          (local
              ? p.golesLocal! > p.golesVisitante!
              : p.golesVisitante! > p.golesLocal!);
      final texto = Flexible(
        child: Text(
          libre ? 'Libre' : nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: local ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 14,
            fontWeight: ganador ? FontWeight.w800 : FontWeight.w600,
            color: libre ? scheme.outline : null,
            fontStyle: libre ? FontStyle.italic : null,
          ),
        ),
      );
      final avatar = libre
          ? const SizedBox(width: 26)
          : TeamAvatar(nombre, size: 26);
      return Expanded(
        child: Row(
          mainAxisAlignment: local
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: local
              ? [texto, const SizedBox(width: 8), avatar]
              : [avatar, const SizedBox(width: 8), texto],
        ),
      );
    }

    final centro = p.jugado
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: LigaColors.verde,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${p.golesLocal} – ${p.golesVisitante}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          )
        : Text(
            p.hora.isEmpty ? 'vs' : p.hora.replaceAll('hs', ''),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          equipo(p.local, local: true),
          SizedBox(
            width: 78,
            child: Column(
              children: [
                centro,
                if (mostrarEstado && p.jugado) ...[
                  const SizedBox(height: 3),
                  EstadoChip(p),
                ],
              ],
            ),
          ),
          equipo(p.visitante, local: false),
        ],
      ),
    );
  }
}

/// Lista de partidos dentro de una tarjeta, con separadores.
class ListaPartidos extends StatelessWidget {
  const ListaPartidos({
    super.key,
    required this.partidos,
    this.mostrarEstado = true,
  });
  final List<Partido> partidos;
  final bool mostrarEstado;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < partidos.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            MatchRow(partido: partidos[i], mostrarEstado: mostrarEstado),
          ],
        ],
      ),
    );
  }
}

class EstadoChip extends StatelessWidget {
  const EstadoChip(this.partido, {super.key});
  final Partido partido;

  @override
  Widget build(BuildContext context) {
    if (!partido.jugado) return const SizedBox.shrink();
    final (texto, color) = switch (partido.estado) {
      EstadoPartido.finalizado => ('Final', LigaColors.verde),
      EstadoPartido.aConfirmar => ('A confirmar', LigaColors.naranja),
      EstadoPartido.pendiente => ('Pendiente', Colors.grey),
    };
    return Text(
      texto,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
    );
  }
}

/// Título de sección.
class Seccion extends StatelessWidget {
  const Seccion(this.titulo, {super.key, this.accion, this.subtitulo});
  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: t.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}

class Cargando extends StatelessWidget {
  const Cargando({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(child: CircularProgressIndicator()),
  );
}

class MensajeError extends StatelessWidget {
  const MensajeError({
    super.key,
    required this.error,
    required this.onReintentar,
  });
  final Object? error;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            error is LigaException
                ? '$error'
                : 'Algo salió mal al cargar los datos.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class Vacio extends StatelessWidget {
  const Vacio(this.texto, {super.key, this.icono = Icons.sports_soccer});
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(icono, size: 44, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// "Actualizado 24/09 18:30" o aviso de datos sin conexión.
class AvisoActualizacion extends StatelessWidget {
  const AvisoActualizacion({
    super.key,
    required this.fecha,
    required this.desdeCache,
  });
  final DateTime fecha;
  final bool desdeCache;

  @override
  Widget build(BuildContext context) {
    String dos(int n) => n.toString().padLeft(2, '0');
    final f =
        '${dos(fecha.day)}/${dos(fecha.month)} ${dos(fecha.hour)}:${dos(fecha.minute)}';
    final color = desdeCache
        ? LigaColors.naranja
        : Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Icon(
            desdeCache ? Icons.cloud_off : Icons.update,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            desdeCache ? 'Sin conexión · datos del $f' : 'Actualizado $f',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

String capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Futbol Mayores" -> "Fútbol Mayores".
String conTildes(String s) => s.replaceAll(RegExp(r'\bFutbol\b'), 'Fútbol');
