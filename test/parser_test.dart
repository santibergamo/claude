import 'package:flutter_test/flutter_test.dart';
import 'package:liga_country_sur/data/models.dart';
import 'package:liga_country_sur/data/parser.dart';

const _html = '''
<html><body>
<select name="campeonato">
  <option value="4312">PRIMERA "A"</option>
  <option value="4314" selected>Primera B</option>
  <option value="4315">1ra C</option>
  <option value="4316">Primera Categoría Veteranos</option>
</select>
<a href="/futbol?torneo=329&campeonato=4314&seccion=goleadores">Goleadores</a>
<div class="box">
  <h3>Tabla de Posiciones</h3>
  <table>
    <thead><tr><th>#</th><th>Equipo</th><th>PJ</th><th>PTS</th></tr></thead>
    <tbody>
      <tr><td>1</td><td>San Eliseo</td><td>5</td><td>13</td></tr>
      <tr><td>2</td><td><img alt="Abril"></td><td>5</td><td>10</td></tr>
    </tbody>
  </table>
</div>
<h4>Fecha 5</h4>
<table>
  <tr><td>Abril</td><td>2 - 1</td><td>Saint Thomas</td></tr>
  <tr><td>Greenville</td><td>0 - 0</td><td>Nordelta</td></tr>
</table>
<table>
  <tr><th>Jugador</th><th>Equipo</th><th>Fechas</th></tr>
  <tr><td>Pérez</td><td>Abril</td><td>2</td></tr>
</table>
</body></html>
''';

void main() {
  test('descubre los campeonatos de Primera A, B y C', () {
    expect(LigaParser.descubrirCampeonatos(_html), {
      'A': 4312,
      'B': 4314,
      'C': 4315,
    });
  });

  test('extrae y clasifica tablas', () {
    final tablas = LigaParser.extraerTablas(_html);
    expect(tablas.map((t) => t.seccion), [
      Seccion.posiciones,
      Seccion.fixture,
      Seccion.sanciones,
    ]);
    final pos = tablas.first;
    expect(pos.titulo, 'Tabla de Posiciones');
    expect(pos.encabezados, ['#', 'Equipo', 'PJ', 'PTS']);
    expect(pos.filas[1][1], 'Abril');
    expect(tablas[1].titulo, 'Fecha 5');
  });

  test('encuentra subpáginas de secciones', () {
    final base = Uri.parse(
      'https://ligacountrysur.com.ar/futbol?torneo=329&campeonato=4314',
    );
    final enlaces = LigaParser.enlacesSecciones(_html, base, 4314);
    expect(
      enlaces[Seccion.goleadores]?.queryParameters['seccion'],
      'goleadores',
    );
  });

  test('clasifica goleadores', () {
    expect(
      LigaParser.clasificar(
        '',
        ['Jugador', 'Equipo', 'Goles'],
        const [
          ['Gómez', 'Abril', '7'],
        ],
      ),
      Seccion.goleadores,
    );
  });
}
