import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:liga_country_sur/data/models.dart';
import 'package:liga_country_sur/data/parser.dart';

String _fixture(String nombre) =>
    File('test/fixtures/$nombre').readAsStringSync();

void main() {
  group('catálogo de torneos', () {
    final cat = LigaParser.catalogo(_fixture('futbol.html'));

    test('lee torneos y marca el actual', () {
      expect(cat.torneos.first.id, 329);
      expect(cat.actual.nombre, 'Clausura 2026');
      expect(cat.torneos.last.nombre, 'Apertura 2026');
    });

    test('lista las categorías con las Primeras primero', () {
      final camps = cat.de(329);
      expect(camps.take(3).map((c) => c.id), [4313, 4314, 4315]);
      expect(camps.take(3).map((c) => c.letraPrimera), ['A', 'B', 'C']);
      expect(camps.first.nombreCorto, 'Primera A');
      expect(camps.last.deporte, 'Futbol Menores');
    });

    test('se puede guardar y recuperar como JSON', () {
      final copia = Catalogo.fromJson(cat.toJson());
      expect(copia.de(329).length, cat.de(329).length);
      expect(copia.actual.id, 329);
    });
  });

  group('campeonato Primera C', () {
    final d = LigaParser.campeonato(
      _fixture('campeonato_4315.html'),
      anio: 2026,
    );

    test('tabla de posiciones', () {
      expect(d.posiciones, hasLength(1));
      final filas = d.posiciones.first.filas;
      expect(filas.length, greaterThan(5));
      expect(filas.first.posicion, 1);
      expect(filas.first.equipo, isNotEmpty);
      expect(filas.first.iniciales.length, lessThanOrEqualTo(3));
      expect(filas.first.puntos, greaterThanOrEqualTo(filas.last.puntos));
      expect(filas.first.golesFavor, isNotNull);
      expect(d.descripcion, contains('Primera'));
    });

    test('fixture por fechas', () {
      expect(d.jornadas, hasLength(11));
      final f1 = d.jornadas.first;
      expect(f1.nombre, 'Fecha 1');
      expect(f1.dia, DateTime(2026, 8, 15));
      expect(f1.partidos.first.jugado, isTrue);
      expect(
        d.jornadas.expand((j) => j.partidos).any((p) => p.esLibre),
        isTrue,
      );
    });

    test('próximos partidos: sólo sin jugar y desde hoy', () {
      final prox = d.proximas(DateTime(2026, 9, 24));
      expect(prox, isNotEmpty);
      expect(
        prox.every((j) => !j.dia!.isBefore(DateTime(2026, 9, 24))),
        isTrue,
      );
      expect(prox.expand((j) => j.partidos).every((p) => !p.jugado), isTrue);
    });

    test('goleadores y sancionados', () {
      expect(d.goleadores, isNotEmpty);
      expect(d.goleadores.first.goles, greaterThan(0));
      expect(
        d.goleadores.first.jugador,
        isNot(equals(d.goleadores.first.jugador.toUpperCase())),
      );
      expect(d.sanciones, isNotEmpty);
      expect(d.sanciones.first.tarjeta, isNotEmpty);
      expect(d.sanciones.first.colorTarjeta, isNotNull);
    });
  });

  test('noticias del blog', () {
    final base = Uri.parse('https://ligacountrysur.com.ar/blog');
    final n = LigaParser.noticias(_fixture('blog.html'), base);
    expect(n, hasLength(4));
    expect(n.first.titulo, 'COPA DE LIGA PINAMAR');
    expect(n.first.imagen, startsWith('https://'));
    expect(n.first.resumen, isNot(contains('Leer más')));
  });

  test('utilidades', () {
    expect(
      LigaParser.fechaDesdeTexto('sábado 3 de octubre', 2026),
      DateTime(2026, 10, 3),
    );
    expect(LigaParser.nombrePropio('GONZáLEZ, LEANDRO'), 'González, Leandro');
    expect(
      LigaParser.nombrePropio('FINCAS DE IRAOLA II'),
      'Fincas de Iraola II',
    );
    expect(LigaParser.iniciales('Village del Parque Verde'), 'VD');
  });
}
