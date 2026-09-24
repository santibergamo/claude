import 'package:flutter/material.dart';

import 'data/repository.dart';
import 'ui/fixture_page.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';
import 'ui/torneos_page.dart';

void main() => runApp(LigaApp(repo: LigaRepository()));

class LigaApp extends StatelessWidget {
  const LigaApp({super.key, required this.repo});

  final LigaRepository repo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liga Country Sur',
      debugShowCheckedModeBanner: false,
      theme: ligaTheme(Brightness.light),
      darkTheme: ligaTheme(Brightness.dark),
      home: AppShell(repo: repo),
    );
  }
}

/// Navegación principal: Inicio · Fixture · Torneos.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repo});
  final LigaRepository repo;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  void _ir(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          HomePage(repo: widget.repo, onVerFixture: () => _ir(1)),
          FixturePage(repo: widget.repo),
          TorneosPage(repo: widget.repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _ir,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Fixture',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Torneos',
          ),
        ],
      ),
    );
  }
}
