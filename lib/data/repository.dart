import 'dart:convert';

import 'package:flutter/foundation.dart';
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

/// Resultado de una consulta, indicando si viene de la copia guardada.
class Respuesta<T> {
  const Respuesta(
    this.datos, {
    required this.actualizado,
    this.desdeCache = false,
  });
  final T datos;
  final DateTime actualizado;
  final bool desdeCache;
}

/// Descarga los datos de la liga, los parsea y guarda una copia local para
/// poder mostrarlos sin conexión.
class LigaRepository {
  LigaRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _memoria = <String, Future<Respuesta<Object>>>{};

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/128.0 Mobile Safari/537.36',
    'Accept-Language': 'es-AR,es;q=0.9',
    'X-Requested-With': 'XMLHttpRequest',
  };

  Future<Respuesta<Catalogo>> catalogo({bool refrescar = false}) => _consultar(
    'catalogo',
    LigaConfig.urlFutbol,
    refrescar,
    (html) => LigaParser.catalogo(html).toJson(),
    (json) => Catalogo.fromJson(json as Map<String, dynamic>),
  );

  Future<Respuesta<DatosCampeonato>> campeonato(
    Campeonato c, {
    String? nombreTorneo,
    bool refrescar = false,
  }) {
    final anio =
        int.tryParse(
          RegExp(r'\d{4}').firstMatch(nombreTorneo ?? '')?.group(0) ?? '',
        ) ??
        DateTime.now().year;
    return _consultar(
      'camp:${c.id}:${c.torneoId}',
      LigaConfig.urlCampeonato(c.id, c.torneoId),
      refrescar,
      (html) => html,
      (html) => LigaParser.campeonato(html as String, anio: anio),
    );
  }

  Future<Respuesta<List<Noticia>>> noticias({bool refrescar = false}) =>
      _consultar(
        'noticias',
        LigaConfig.urlNoticias,
        refrescar,
        (html) => html,
        (html) => LigaParser.noticias(html as String, LigaConfig.urlNoticias),
      );

  /// Primera A, B y C del torneo actual.
  Future<List<Campeonato>> primeras({bool refrescar = false}) async {
    Catalogo? cat;
    try {
      cat = (await catalogo(refrescar: refrescar)).datos;
    } catch (_) {
      // Sin catálogo se usan los IDs conocidos del Clausura 2026.
    }
    final torneo = cat?.actual;
    final lista = torneo == null
        ? <Campeonato>[]
        : cat!.de(torneo.id).where((c) => c.letraPrimera != null).toList();
    if (lista.isNotEmpty) {
      return lista..sort((a, b) => a.letraPrimera!.compareTo(b.letraPrimera!));
    }
    return [
      for (final e in LigaConfig.primerasPorDefecto.entries)
        Campeonato(
          id: e.value,
          torneoId: LigaConfig.torneoActual,
          nombre: 'Primera "${e.key}"',
          deporte: 'Futbol Mayores',
        ),
    ];
  }

  /// Descarga [url], guarda lo que devuelve [guardar] y construye el
  /// resultado con [construir]. Si falla la red usa la última copia.
  Future<Respuesta<T>> _consultar<T extends Object>(
    String clave,
    Uri url,
    bool refrescar,
    Object Function(String html) guardar,
    T Function(Object guardado) construir,
  ) {
    if (refrescar) _memoria.remove(clave);
    final f = _memoria[clave] ??= () async {
      final prefs = await SharedPreferences.getInstance();
      try {
        final r = await _client
            .get(url, headers: _headers)
            .timeout(const Duration(seconds: 25));
        if (r.statusCode != 200) {
          throw LigaException('La web de la liga respondió ${r.statusCode}.');
        }
        final html = _decodificar(r.bodyBytes);
        final guardado = await compute(_procesar, (guardar, html));
        final datos = await compute(_construir<T>, (construir, guardado));
        final ahora = DateTime.now();
        await prefs.setString('c:$clave', jsonEncode(guardado));
        await prefs.setString('f:$clave', ahora.toIso8601String());
        return Respuesta<Object>(datos, actualizado: ahora);
      } catch (e) {
        final copia = prefs.getString('c:$clave');
        if (copia == null) {
          throw e is LigaException
              ? e
              : LigaException(
                  'No se pudo conectar con la liga. '
                  'Revisá tu conexión e intentá de nuevo.',
                );
        }
        final datos = await compute(_construir<T>, (
          construir,
          jsonDecode(copia) as Object,
        ));
        return Respuesta<Object>(
          datos,
          actualizado:
              DateTime.tryParse(prefs.getString('f:$clave') ?? '') ??
              DateTime.now(),
          desdeCache: true,
        );
      }
    }();
    f.catchError((_) {
      _memoria.remove(clave);
      return Respuesta<Object>(0, actualizado: DateTime.now());
    });
    return f.then(
      (r) => Respuesta<T>(
        r.datos as T,
        actualizado: r.actualizado,
        desdeCache: r.desdeCache,
      ),
    );
  }

  static String _decodificar(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}

Object _procesar((Object Function(String), String) a) => a.$1(a.$2);
T _construir<T>((T Function(Object), Object) a) => a.$1(a.$2);
