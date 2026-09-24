import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/parser.dart';

/// Muestra una tabla de la liga con scroll horizontal y filas alternadas.
class TablaView extends StatelessWidget {
  const TablaView({super.key, required this.tabla, this.filtro = ''});

  final Tabla tabla;
  final String filtro;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = LigaParser.normalizar(filtro);
    final filas = f.isEmpty
        ? tabla.filas
        : tabla.filas
              .where((r) => LigaParser.normalizar(r.join(' ')).contains(f))
              .toList();
    final columnas = [
      tabla.encabezados.length,
      ...tabla.filas.map((r) => r.length),
    ].reduce((a, b) => a > b ? a : b);

    String encabezado(int i) =>
        i < tabla.encabezados.length ? tabla.encabezados[i] : '';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tabla.titulo.isNotEmpty)
            Container(
              color: scheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                tabla.titulo,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (filas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin resultados para la búsqueda.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 56,
                horizontalMargin: 12,
                columnSpacing: 16,
                headingRowColor: WidgetStatePropertyAll(
                  scheme.surfaceContainerHighest,
                ),
                columns: [
                  for (var i = 0; i < columnas; i++)
                    DataColumn(
                      label: Text(
                        encabezado(i),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: _esNumerica(filas, i),
                    ),
                ],
                rows: [
                  for (var r = 0; r < filas.length; r++)
                    DataRow(
                      color: WidgetStatePropertyAll(
                        r.isOdd ? scheme.surfaceContainerLow : null,
                      ),
                      cells: [
                        for (var i = 0; i < columnas; i++)
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                i < filas[r].length ? filas[r][i] : '',
                                style: _esDestacada(encabezado(i))
                                    ? const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static bool _esNumerica(List<List<String>> filas, int col) {
    final valores = filas
        .where((f) => col < f.length && f[col].isNotEmpty)
        .map((f) => f[col]);
    return valores.isNotEmpty &&
        valores.every((v) => RegExp(r'^[+-]?\d+$').hasMatch(v));
  }

  static bool _esDestacada(String encabezado) {
    final e = LigaParser.normalizar(encabezado);
    return e == 'pts' || e == 'puntos' || e == 'goles' || e == 'resultado';
  }
}
