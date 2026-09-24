import 'package:flutter/material.dart';

import 'config.dart';
import 'data/repository.dart';
import 'ui/categoria_page.dart';

void main() => runApp(const LigaApp());

class LigaApp extends StatelessWidget {
  const LigaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const semilla = Color(0xFF1B7F3B);
    return MaterialApp(
      title: 'Liga Country Sur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: semilla),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: semilla,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomePage(repo: LigaRepository()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repo});

  final LigaRepository repo;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indice = 1; // Primera B por defecto.

  @override
  Widget build(BuildContext context) {
    final categoria = LigaConfig.categorias[_indice];
    return DefaultTabController(
      length: CategoriaPage.secciones.length,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(categoria.nombre),
              Text(
                'Liga Country Sur · Fútbol ${LigaConfig.tituloTorneo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final s in CategoriaPage.secciones) Tab(text: s.titulo),
            ],
          ),
        ),
        body: IndexedStack(
          index: _indice,
          children: [
            for (final c in LigaConfig.categorias)
              CategoriaPage(
                key: ValueKey(c.letra),
                categoria: c,
                repo: widget.repo,
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) => setState(() => _indice = i),
          destinations: [
            for (final c in LigaConfig.categorias)
              NavigationDestination(
                icon: CircleAvatar(radius: 12, child: Text(c.letra)),
                label: c.nombre,
              ),
          ],
        ),
      ),
    );
  }
}
