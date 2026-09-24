import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'models.dart';

/// Lee el HTML de ligacountrysur.com.ar.
class LigaParser {
  // ── Torneos y categorías (página /futbol) ──────────────────────────────

  static Catalogo catalogo(String html) {
    final json = _objetoJs(html, 'campeonatosXTorneo');
    final datos = json == null
        ? <String, dynamic>{}
        : jsonDecode(json) as Map<String, dynamic>;

    final campeonatos = <int, List<Campeonato>>{};
    final actuales = <int>{};
    datos.forEach((torneoId, lista) {
      final tid = int.parse(torneoId);
      for (final c in (lista as List).cast<Map<String, dynamic>>()) {
        final categoria = (c['categoria'] as Map?)?['name'] as String?;
        campeonatos
            .putIfAbsent(tid, () => [])
            .add(
              Campeonato(
                id: c['id'] as int,
                torneoId: tid,
                nombre: _limpiar(categoria ?? c['name'] as String),
                deporte: _limpiar(
                  (c['deporte'] as Map?)?['name'] as String? ?? 'Fútbol',
                ),
              ),
            );
        if ('${(c['torneo'] as Map?)?['actual']}' == '1') actuales.add(tid);
      }
    });

    // Nombres de torneos desde el selector de la página.
    final nombres = <int, String>{};
    var seleccionado = -1;
    final inicio = html.indexOf('id="la_torneo"');
    if (inicio >= 0) {
      final fin = html.indexOf('</select>', inicio);
      final select = html.substring(inicio, fin < 0 ? html.length : fin);
      for (final m in RegExp(
        r'<option\s+value="(\d+)"([^>]*)>([^<]*)',
      ).allMatches(select)) {
        final id = int.parse(m.group(1)!);
        nombres[id] = _limpiar(m.group(3)!);
        if (m.group(2)!.contains('selected')) seleccionado = id;
      }
    }

    final torneos =
        [
          for (final id in campeonatos.keys)
            Torneo(
              id: id,
              nombre: nombres[id] ?? 'Torneo $id',
              actual: actuales.isEmpty
                  ? id == seleccionado
                  : actuales.contains(id),
            ),
        ]..sort((a, b) {
          if (a.actual != b.actual) return a.actual ? -1 : 1;
          return b.id.compareTo(a.id);
        });
    for (final l in campeonatos.values) {
      l.sort(_ordenCampeonatos);
    }
    return Catalogo(torneos: torneos, campeonatos: campeonatos);
  }

  /// Primeras primero, después mayores, después menores; alfabético.
  static int _ordenCampeonatos(Campeonato a, Campeonato b) {
    int peso(Campeonato c) => c.letraPrimera != null
        ? 0
        : c.deporte.toLowerCase().contains('menores')
        ? 2
        : 1;
    final p = peso(a).compareTo(peso(b));
    return p != 0 ? p : a.nombre.compareTo(b.nombre);
  }

  /// Extrae el literal `{...}` asignado a una variable JS.
  static String? _objetoJs(String html, String variable) {
    final i = html.indexOf(variable);
    if (i < 0) return null;
    final inicio = html.indexOf('{', i);
    if (inicio < 0) return null;
    var profundidad = 0;
    var enString = false;
    for (var k = inicio; k < html.length; k++) {
      final ch = html[k];
      if (enString) {
        if (ch == r'\') {
          k++;
        } else if (ch == '"') {
          enString = false;
        }
      } else if (ch == '"') {
        enString = true;
      } else if (ch == '{') {
        profundidad++;
      } else if (ch == '}') {
        profundidad--;
        if (profundidad == 0) return html.substring(inicio, k + 1);
      }
    }
    return null;
  }

  // ── Datos de un campeonato (/liga/tabla-resultados-alt/{c}/{t}) ──────────

  static DatosCampeonato campeonato(String html, {int? anio}) {
    final doc = html_parser.parse(html);
    final posiciones = <TablaPosiciones>[];
    var goleadores = <Goleador>[];
    var sanciones = <Sancion>[];
    var descripcion = '';

    for (final card in doc.querySelectorAll('.alt-card')) {
      final head = card.querySelector('.alt-card-head');
      final titulo = _texto(head?.querySelector('span'));
      final tabla = card.querySelector('table');
      if (tabla == null) continue;
      final t = titulo.toLowerCase();
      if (t.contains('posiciones')) {
        final tag = _texto(head?.querySelector('.alt-card-tag'));
        if (descripcion.isEmpty) descripcion = tag;
        posiciones.add(
          TablaPosiciones(titulo: titulo, filas: _posiciones(tabla)),
        );
      } else if (t.contains('goleador')) {
        goleadores = _goleadores(tabla);
      } else if (t.contains('sancion')) {
        sanciones = _sanciones(tabla);
      }
    }

    return DatosCampeonato(
      descripcion: descripcion,
      posiciones: posiciones,
      jornadas: _jornadas(doc, anio ?? DateTime.now().year),
      goleadores: goleadores,
      sanciones: sanciones,
    );
  }

  /// Índice de cada columna según el encabezado (title o texto).
  static Map<String, int> _columnas(Element tabla) {
    final res = <String, int>{};
    final ths = tabla.querySelectorAll('thead th');
    for (var i = 0; i < ths.length; i++) {
      final th = ths[i];
      final clave = _normalizar(th.attributes['title'] ?? _texto(th));
      res.putIfAbsent(clave, () => i);
      res.putIfAbsent(_normalizar(_texto(th)), () => i);
    }
    return res;
  }

  static List<FilaPosicion> _posiciones(Element tabla) {
    final col = _columnas(tabla);
    final filas = <FilaPosicion>[];
    for (final tr in tabla.querySelectorAll('tbody tr')) {
      final tds = tr.querySelectorAll('td');
      int? n(String clave) {
        final i = col[clave];
        return i == null || i >= tds.length ? null : _entero(_texto(tds[i]));
      }

      final equipo = _texto(tr.querySelector('.team-nm'));
      if (equipo.isEmpty) continue;
      filas.add(
        FilaPosicion(
          posicion: n('#') ?? filas.length + 1,
          equipo: equipo,
          iniciales: _texto(tr.querySelector('.team-av')).isNotEmpty
              ? _texto(tr.querySelector('.team-av'))
              : iniciales(equipo),
          jugados: n('jugados'),
          ganados: n('ganados'),
          empatados: n('empatados'),
          perdidos: n('perdidos'),
          golesFavor: n('favor'),
          golesContra: n('contra'),
          puntos: n('puntos') ?? 0,
        ),
      );
    }
    return filas;
  }

  static List<Goleador> _goleadores(Element tabla) {
    final col = _columnas(tabla);
    final res = <Goleador>[];
    for (final tr in tabla.querySelectorAll('tbody tr')) {
      final tds = tr.querySelectorAll('td');
      String c(String clave) {
        final i = col[clave];
        return i == null || i >= tds.length ? '' : _texto(tds[i]);
      }

      final jugador = _texto(tr.querySelector('.team-nm'));
      if (jugador.isEmpty) continue;
      res.add(
        Goleador(
          posicion: _entero(c('#')) ?? res.length + 1,
          jugador: nombrePropio(jugador),
          equipo: nombrePropio(c('equipo')),
          goles: _entero(c('goles')) ?? 0,
        ),
      );
    }
    return res;
  }

  static List<Sancion> _sanciones(Element tabla) {
    final col = _columnas(tabla);
    final res = <Sancion>[];
    for (final tr in tabla.querySelectorAll('tbody tr')) {
      final tds = tr.querySelectorAll('td');
      Element? td(String clave) {
        final i = col[clave];
        return i == null || i >= tds.length ? null : tds[i];
      }

      String c(String clave) {
        final t = _texto(td(clave));
        return t == '–' || t == '-' ? '' : t;
      }

      final jugador = _texto(tr.querySelector('.team-nm'));
      if (jugador.isEmpty) continue;
      final badge = td('tarjeta')?.querySelector('.badge');
      res.add(
        Sancion(
          jugador: nombrePropio(jugador),
          equipo: nombrePropio(c('equipo')),
          tarjeta: _texto(badge).isNotEmpty ? _texto(badge) : c('tarjeta'),
          colorTarjeta: _colorDeEstilo(badge?.attributes['style']),
          fechas: c('fechas de suspension'),
          articulo: c('articulo'),
          fecha: c('fecha'),
        ),
      );
    }
    return res;
  }

  static List<Jornada> _jornadas(Document doc, int anio) {
    final res = <Jornada>[];
    for (final round in doc.querySelectorAll('.alt-round')) {
      final textoDia = _texto(round.querySelector('.alt-round-date'));
      final partidos = <Partido>[];
      for (final m in round.querySelectorAll('.alt-match')) {
        final d = m.querySelector('.alt-match-desktop') ?? m;
        final score = _texto(d.querySelector('.score-pill'));
        final goles = RegExp(r'(\d+)\s*[–-]\s*(\d+)').firstMatch(score);
        final status = d.querySelector('.amd-status');
        final EstadoPartido estado;
        if (status?.querySelector('.badge-fin') != null) {
          estado = EstadoPartido.finalizado;
        } else if ((status?.querySelector('.badge-pend')?.attributes['title'] ??
                '')
            .toLowerCase()
            .contains('confirm')) {
          estado = EstadoPartido.aConfirmar;
        } else {
          estado = EstadoPartido.pendiente;
        }
        partidos.add(
          Partido(
            local: _texto(d.querySelector('.amd-local')),
            visitante: _texto(d.querySelector('.amd-visitor')),
            hora: _texto(d.querySelector('.amd-time')),
            estado: estado,
            golesLocal: goles == null ? null : int.parse(goles.group(1)!),
            golesVisitante: goles == null ? null : int.parse(goles.group(2)!),
            detalleUrl: d
                .querySelector('a[href*="ver-resultado"]')
                ?.attributes['href'],
          ),
        );
      }
      res.add(
        Jornada(
          nombre: _texto(round.querySelector('.alt-round-badge')),
          textoDia: textoDia,
          dia: fechaDesdeTexto(textoDia, anio),
          partidos: partidos,
        ),
      );
    }
    return res;
  }

  // ── Noticias (/blog) ──────────────────────────────────────────────────────

  static List<Noticia> noticias(String html, Uri base) {
    final doc = html_parser.parse(html);
    final res = <Noticia>[];
    for (final post in doc.querySelectorAll('.blog-post')) {
      final a = post.querySelector('.post-title a');
      final href = a?.attributes['href'];
      if (a == null || href == null) continue;
      final p = post.querySelector('p');
      p?.querySelectorAll('a').forEach((e) => e.remove());
      final img = post.querySelector('img')?.attributes['src'];
      res.add(
        Noticia(
          titulo: _texto(a),
          resumen: (p?.text ?? '')
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .join('\n'),
          url: base.resolve(href).toString(),
          imagen: img == null ? null : base.resolve(img).toString(),
        ),
      );
    }
    return res;
  }

  // ── Utilidades ───────────────────────────────────────────────────────────

  static const _meses = {
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'septiembre': 9,
    'setiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
  };

  /// "sábado 26 de septiembre" -> DateTime(anio, 9, 26).
  static DateTime? fechaDesdeTexto(String texto, int anio) {
    final m = RegExp(r'(\d{1,2})\s+de\s+([a-záéíóú]+)')
        .firstMatch(texto.toLowerCase());
    if (m == null) return null;
    final mes = _meses[m.group(2)];
    if (mes == null) return null;
    return DateTime(anio, mes, int.parse(m.group(1)!));
  }

  /// "GONZáLEZ, LEANDRO" -> "González, Leandro";
  /// "FINCAS DE IRAOLA II" -> "Fincas de Iraola II".
  static String nombrePropio(String s) {
    const minusculas = {'de', 'del', 'la', 'las', 'los', 'y', 'e'};
    final romano = RegExp(r'^(i{1,3}|iv|v|vi{1,3})$');
    final palabras = s.toLowerCase().split(' ');
    return [
      for (var i = 0; i < palabras.length; i++)
        if (palabras[i].isEmpty)
          palabras[i]
        else if (romano.hasMatch(palabras[i]))
          palabras[i].toUpperCase()
        else if (i > 0 && minusculas.contains(palabras[i]))
          palabras[i]
        else
          palabras[i][0].toUpperCase() + palabras[i].substring(1),
    ].join(' ');
  }

  static String iniciales(String equipo) {
    final palabras = equipo
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (palabras.isEmpty) return '?';
    if (palabras.length == 1) {
      return palabras.first
          .substring(0, palabras.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return (palabras[0][0] + palabras[1][0]).toUpperCase();
  }

  static String _texto(Element? e) =>
      e == null ? '' : e.text.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _limpiar(String s) =>
      html_parser
          .parseFragment(s)
          .text
          ?.replaceAll(RegExp(r'\s+'), ' ')
          .trim() ??
      s.trim();

  static int? _entero(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^\d-]'), ''));

  static String _normalizar(String s) {
    const con = 'áéíóúñ';
    const sin = 'aeioun';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().trim().split('')) {
      final i = con.indexOf(ch);
      b.write(i >= 0 ? sin[i] : ch);
    }
    return b.toString().replaceAll(RegExp(r'[.\s]+'), ' ').trim();
  }

  static int? _colorDeEstilo(String? style) {
    final m = RegExp(r'background:\s*#([0-9a-fA-F]{6})')
        .firstMatch(style ?? '');
    return m == null ? null : 0xFF000000 | int.parse(m.group(1)!, radix: 16);
  }
}
