import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liga_country_sur/data/repository.dart';
import 'package:liga_country_sur/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _html = '''
<select><option value="1">Primera A</option><option value="2">Primera B</option>
<option value="3">Primera C</option></select>
<h3>Posiciones</h3>
<table><tr><th>Equipo</th><th>PJ</th><th>PTS</th></tr>
<tr><td>San Eliseo</td><td>5</td><td>13</td></tr></table>
''';

void main() {
  testWidgets('muestra la tabla de posiciones de Primera B', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient(
      (req) async => http.Response(
        _html,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(repo: LigaRepository(client: client)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('San Eliseo'), findsWidgets);
    expect(find.text('Primera B'), findsWidgets);

    await tester.tap(find.text('Goleadores'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no hay goleadores'), findsOneWidget);
  });
}
