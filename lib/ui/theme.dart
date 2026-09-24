import 'package:flutter/material.dart';

/// Colores de la web de la Liga Country Sur.
class LigaColors {
  static const verde = Color(0xFF1A7F37);
  static const verdeOscuro = Color(0xFF0F5A25);
  static const oro = Color(0xFFF5B800);
  static const plata = Color(0xFFC0CCD6);
  static const bronce = Color(0xFFD08A4E);
  static const naranja = Color(0xFFE65100);
}

ThemeData ligaTheme(Brightness brillo) {
  final scheme = ColorScheme.fromSeed(
    seedColor: LigaColors.verde,
    brightness: brillo,
  ).copyWith(primary: brillo == Brightness.light ? LigaColors.verde : null);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final oscuro = brillo == Brightness.dark;
  return base.copyWith(
    scaffoldBackgroundColor: oscuro ? scheme.surface : const Color(0xFFF6F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: oscuro ? scheme.surfaceContainer : LigaColors.verde,
      foregroundColor: oscuro ? scheme.onSurface : Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: oscuro ? scheme.onSurface : Colors.white,
        fontWeight: FontWeight.w800,
        letterSpacing: .3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: oscuro ? scheme.surfaceContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: oscuro ? scheme.primary : Colors.white,
      unselectedLabelColor: oscuro
          ? scheme.onSurfaceVariant
          : Colors.white.withValues(alpha: .7),
      indicatorColor: oscuro ? scheme.primary : Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      dividerColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
