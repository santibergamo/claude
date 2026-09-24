import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liga_country_sur/data/repository.dart';
import 'package:liga_country_sur/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _fixture(String nombre) =>
    File('test/fixtures/$nombre').readAsStringSync();

void main() {
  testWidgets('navega Inicio, Fixture y Torneos con datos reales', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = LigaRepository(client: _FixtureClient());

    await tester.runAsync(() async {
      await tester.pumpWidget(LigaApp(repo: repo));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Liga Country Sur'), findsOneWidget);
    expect(find.text('COPA DE LIGA PINAMAR'), findsOneWidget);

    await tester.tap(find.text('Torneos'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Clausura 2026'), findsOneWidget);
    expect(find.text('Primera A'), findsOneWidget);

    await tester.tap(find.text('Primera C'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PTS'), findsOneWidget);

    await tester.tap(find.text('Fixture').last);
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}

/// Responde con las páginas reales guardadas en test/fixtures.
class _FixtureClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final body = path.startsWith('/blog')
        ? _fixture('blog.html')
        : path.startsWith('/liga/')
        ? _fixture('campeonato_4315.html')
        : _fixture('futbol.html');
    return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
  }
}
