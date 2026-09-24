import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'models.dart';

/// Lee el HTML de ligacountrysur.com.ar y extrae la información útil.
///
/// La estructura exacta de la web puede cambiar, así que el parser no depende
/// de clases CSS: busca tablas y enlaces, y las clasifica por su contenido.
class LigaParser {
  static final _reCategoria = RegExp(
    r'''(?:primera|1\s*(?:ra|era|°|º)\.?)\s*(?:division\s*)?["'«“]?\s*([abc])(?![a-z])''',
  );
  static final _reCampeonato = RegExp(r'campeonato=(\d+)');
  static final _reResultado = RegExp(r'^\d{1,2}\s*[-–:]\s*\d{1,2}$');

  /// Pasa a minúsculas y quita acentos para comparar textos.
  static String normalizar(String s) {
    const con = 'áàäâéèëêíìïîóòöôúùüûñ';
    const sin = 'aaaaeeeeiiiioooouuuun';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = con.indexOf(ch);
      b.write(i >= 0 ? sin[i] : ch);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Devuelve la letra de categoría (A, B o C) si el texto nombra una Primera.
  static String? letraCategoria(String texto) {
    final m = _reCategoria.firstMatch(normalizar(texto));
    return m?.group(1)?.toUpperCase();
  }

  /// Busca en links y selectores los IDs de campeonato de Primera A, B y C.
  static Map<String, int> descubrirCampeonatos(String html) {
    final doc = html_parser.parse(html);
    final encontrados = <String, int>{};

    void registrar(String texto, String? valor) {
      if (valor == null) return;
      final letra = letraCategoria(texto);
      if (letra == null || encontrados.containsKey(letra)) return;
      final id =
          int.tryParse(valor) ??
          int.tryParse(_reCampeonato.firstMatch(valor)?.group(1) ?? '');
      if (id != null) encontrados[letra] = id;
    }

    for (final a in doc.querySelectorAll('a[href*="campeonato="]')) {
      registrar(a.text, a.attributes['href']);
    }
    for (final opt in doc.querySelectorAll('option')) {
      registrar(opt.text, opt.attributes['value']);
    }
    return encontrados;
  }

  /// Links a subpáginas del mismo campeonato (p. ej. "Goleadores").
  static Map<Seccion, Uri> enlacesSecciones(
    String html,
    Uri base,
    int campeonato,
  ) {
    final doc = html_parser.parse(html);
    final res = <Seccion, Uri>{};
    for (final a in doc.querySelectorAll('a[href]')) {
      final href = a.attributes['href']!;
      if (href.startsWith('#') || href.startsWith('javascript')) continue;
      final seccion = _seccionPorTexto(normalizar(a.text));
      if (seccion == null || res.containsKey(seccion)) continue;
      final uri = base.resolve(href);
      if (uri.host != base.host) continue;
      final camp = uri.queryParameters['campeonato'];
      if (camp != null && camp != '$campeonato') continue;
      if (uri == base) continue;
      res[seccion] = uri;
    }
    return res;
  }

  static Seccion? _seccionPorTexto(String t) {
    if (t.length > 40) return null;
    if (RegExp(r'goleador').hasMatch(t)) return Seccion.goleadores;
    if (RegExp(r'sancion|suspendid|tarjeta|disciplin').hasMatch(t)) {
      return Seccion.sanciones;
    }
    if (RegExp(r'fixture|resultado|partidos|programacion').hasMatch(t)) {
      return Seccion.fixture;
    }
    if (RegExp(r'posiciones|tabla').hasMatch(t)) return Seccion.posiciones;
    return null;
  }

  /// Extrae y clasifica todas las tablas con datos del documento.
  static List<Tabla> extraerTablas(String html) {
    final doc = html_parser.parse(html);
    final tablas = <Tabla>[];
    for (final table in doc.querySelectorAll('table')) {
      // Las tablas anidadas se procesan por separado.
      if (table.querySelector('table') != null) continue;
      final t = _leerTabla(table);
      if (t != null) tablas.add(t);
    }
    return tablas;
  }

  static Tabla? _leerTabla(Element table) {
    final filas = <List<String>>[];
    List<String>? encabezados;
    for (final tr in table.querySelectorAll('tr')) {
      final celdas = tr.children
          .where((c) => c.localName == 'td' || c.localName == 'th')
          .toList();
      if (celdas.isEmpty) continue;
      final textos = celdas.map(_textoCelda).toList();
      final esEncabezado =
          celdas.every((c) => c.localName == 'th') ||
          tr.parent?.localName == 'thead';
      if (esEncabezado && encabezados == null && filas.isEmpty) {
        encabezados = textos;
      } else if (textos.any((t) => t.isNotEmpty)) {
        filas.add(textos);
      }
    }
    if (filas.isEmpty) return null;
    encabezados ??= const [];

    final titulo = _tituloDe(table);
    final seccion = clasificar(titulo, encabezados, filas);
    return Tabla(
      titulo: titulo,
      encabezados: encabezados,
      filas: filas,
      seccion: seccion,
    );
  }

  static String _textoCelda(Element c) {
    final texto = c.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (texto.isNotEmpty) return texto;
    final img = c.querySelector('img');
    return (img?.attributes['alt'] ?? img?.attributes['title'] ?? '').trim();
  }

  /// Busca un título cercano antes de la tabla (h1-h6, caption, etc.).
  static String _tituloDe(Element table) {
    final caption = table.querySelector('caption');
    if (caption != null && caption.text.trim().isNotEmpty) {
      return caption.text.trim();
    }
    Element? nodo = table;
    for (var nivel = 0; nivel < 4 && nodo != null; nivel++) {
      var prev = nodo.previousElementSibling;
      var saltos = 0;
      while (prev != null && saltos < 3) {
        final t = _textoTitulo(prev);
        if (t != null) return t;
        if (prev.querySelector('table') != null) break;
        prev = prev.previousElementSibling;
        saltos++;
      }
      nodo = nodo.parent;
    }
    return '';
  }

  static String? _textoTitulo(Element e) {
    const etiquetas = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};
    Element? h = etiquetas.contains(e.localName)
        ? e
        : e.querySelectorAll('h1,h2,h3,h4,h5,h6').lastOrNull;
    final clase = (e.className).toLowerCase();
    if (h == null &&
        (clase.contains('title') || clase.contains('titulo')) &&
        e.text.trim().length < 80) {
      h = e;
    }
    final t = h?.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static Seccion clasificar(
    String titulo,
    List<String> encabezados,
    List<List<String>> filas,
  ) {
    final tit = normalizar(titulo);
    final enc = normalizar(encabezados.join(' | '));
    final palabrasEnc = enc.split(RegExp(r'[^a-z0-9]+')).toSet();

    final porTitulo = _seccionPorTexto(tit);
    if (porTitulo != null) return porTitulo;

    if (RegExp(r'sancion|suspend|tarjeta|amarilla|roja|expuls').hasMatch(enc) ||
        palabrasEnc.contains('fechas')) {
      return Seccion.sanciones;
    }
    final tienePuntos =
        palabrasEnc.contains('pts') || palabrasEnc.contains('puntos');
    if (!tienePuntos && RegExp(r'goleador|goles').hasMatch(enc)) {
      return Seccion.goleadores;
    }
    if (tienePuntos) return Seccion.posiciones;
    if (RegExp(r'local|visitante|resultado|partido').hasMatch(enc)) {
      return Seccion.fixture;
    }
    final conResultado = filas
        .where((f) => f.any((c) => _reResultado.hasMatch(c)))
        .length;
    if (conResultado > 0 && conResultado >= filas.length / 2) {
      return Seccion.fixture;
    }
    return Seccion.otros;
  }
}
