import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'models.dart';
import 'parser.dart';

class LigaException implements Exception {
  LigaException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

/// Descarga las páginas de la liga, las parsea y guarda una copia local para
/// poder mostrar los últimos datos sin conexión.
class LigaRepository {
  LigaRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  Future<Map<String, int>>? _campeonatos;

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/128.0 Mobile Safari/537.36',
    'Accept-Language': 'es-AR,es;q=0.9',
  };

  Future<String> _descargar(Uri url) async {
    final prefs = await SharedPreferences.getInstance();
    final clave = 'html:$url';
    try {
      final r = await _client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) {
        throw LigaException('La web respondió ${r.statusCode}');
      }
      final html = _decodificar(r.bodyBytes);
      await prefs.setString(clave, html);
      await prefs.setString('fecha:$url', DateTime.now().toIso8601String());
      return html;
    } catch (e) {
      final cache = prefs.getString(clave);
      if (cache != null) throw _SinConexion(cache, e);
      throw LigaException('No se pudo conectar con la liga ($e)');
    }
  }

  static String _decodificar(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// IDs de campeonato de cada categoría (A, B, C).
  Future<Map<String, int>> campeonatos() =>
      _campeonatos ??= _descubrirCampeonatos();

  Future<Map<String, int>> _descubrirCampeonatos() async {
    final res = <String, int>{
      for (final c in LigaConfig.categorias)
        if (c.campeonato != null) c.letra: c.campeonato!,
    };
    if (res.length < LigaConfig.categorias.length) {
      final url = LigaConfig.urlCampeonato(LigaConfig.campeonatoSemilla);
      String html;
      try {
        html = await _descargar(url);
      } on _SinConexion catch (s) {
        html = s.html;
      }
      LigaParser.descubrirCampeonatos(html)
          .forEach((letra, id) => res.putIfAbsent(letra, () => id));
    }
    return res;
  }

  Future<DatosCategoria> datos(Categoria categoria) async {
    Map<String, int> ids;
    try {
      ids = await campeonatos();
    } catch (_) {
      _campeonatos = null;
      rethrow;
    }
    final id = ids[categoria.letra];
    if (id == null) {
      _campeonatos = null; // Reintentar el descubrimiento la próxima vez.
      throw LigaException(
        'No se encontró ${categoria.nombre} en el ${LigaConfig.tituloTorneo}.',
      );
    }
    final url = LigaConfig.urlCampeonato(id);
    var desdeCache = false;
    String html;
    try {
      html = await _descargar(url);
    } on _SinConexion catch (s) {
      html = s.html;
      desdeCache = true;
    }

    final tablas = LigaParser.extraerTablas(html);
    // Si alguna sección vive en otra página, se descarga también.
    final enlaces = LigaParser.enlacesSecciones(html, url, id);
    for (final entry in enlaces.entries) {
      if (tablas.any((t) => t.seccion == entry.key)) continue;
      try {
        String sub;
        try {
          sub = await _descargar(entry.value);
        } on _SinConexion catch (s) {
          sub = s.html;
        }
        for (final t in LigaParser.extraerTablas(sub)) {
          final seccion = t.seccion == Seccion.otros ? entry.key : t.seccion;
          if (seccion != entry.key) continue;
          tablas.add(
            Tabla(
              titulo: t.titulo,
              encabezados: t.encabezados,
              filas: t.filas,
              seccion: seccion,
            ),
          );
        }
      } catch (_) {
        // Una subpágina caída no debe impedir mostrar el resto.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final fecha = DateTime.tryParse(prefs.getString('fecha:$url') ?? '');
    return DatosCategoria(
      tablas: tablas,
      url: url,
      actualizado: fecha ?? DateTime.now(),
      desdeCache: desdeCache,
    );
  }
}

class _SinConexion implements Exception {
  _SinConexion(this.html, this.causa);
  final String html;
  final Object causa;
}
