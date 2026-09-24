# Liga Country Sur – App de Fútbol

App móvil en Flutter (Android e iOS) con los datos de la
[Liga Country Sur](https://ligacountrysur.com.ar/futbol?torneo=329&campeonato=4314).

## Secciones

| Pestaña | Qué muestra |
|---|---|
| **Inicio** | Próximos partidos de Primera A, B y C (carrusel) y las noticias de la liga. |
| **Fixture** | Sólo los partidos que faltan jugar de Primera A, B y C, agrupados por día y categoría, con filtro por categoría. |
| **Torneos** | Todos los torneos de la liga (Clausura 2026 primero). Elegís un torneo y una categoría y ves **Posiciones**, **Fixture** por fecha con resultados, **Goleadores** y **Sanciones**. |

Además:

- Para actualizar, deslizá hacia abajo.
- Guarda los últimos datos para verlos sin conexión.
- Tiene modo oscuro automático.

## De dónde salen los datos

La liga no tiene una API pública, así que la app lee las mismas páginas que usa la web
(`lib/data/parser.dart`):

| Dato | URL |
|---|---|
| Torneos y categorías | `/futbol`: el selector de torneos y la variable `campeonatosXTorneo` |
| Posiciones, fixture, goleadores, sanciones | `/liga/tabla-resultados-alt/{campeonato}/{torneo}` |
| Noticias | `/blog` |

En el Clausura 2026 (torneo `329`), Primera A, B y C son los campeonatos `4313`, `4314` y `4315`.
La app los detecta sola a partir del torneo marcado como actual.

## Correr la app (macOS)

```bash
# Una vez: Xcode desde el App Store, y después
brew install --cask flutter
brew install cocoapods

flutter pub get
open -a Simulator
flutter run          # abre la app en el simulador de iPhone
flutter test         # tests del parser (con páginas reales guardadas) y de la app
```

## Estructura

```
lib/
  main.dart                # Navegación: Inicio · Fixture · Torneos
  config.dart              # URL base, torneo actual e IDs por defecto
  data/
    models.dart            # Torneo, Campeonato, Partido, Jornada, Goleador, ...
    parser.dart            # Lectura del HTML de la liga
    repository.dart        # Descarga, caché offline
  ui/
    home_page.dart         # Inicio
    fixture_page.dart      # Próximos partidos
    torneos_page.dart      # Selector de torneo y categorías
    campeonato_page.dart   # Posiciones / Fixture / Goleadores / Sanciones
    proximos.dart          # Arma la lista de próximos partidos
    widgets.dart, theme.dart
test/
  fixtures/                # Páginas reales de la liga para los tests
```
