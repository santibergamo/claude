# Liga Country Sur – Fútbol Clausura 2026

App móvil en Flutter (Android e iOS) para seguir **Primera A**, **Primera B** y **Primera C**
del Clausura 2026 de la [Liga Country Sur](https://ligacountrysur.com.ar/futbol?torneo=329&campeonato=4314).

## Qué muestra

Cada categoría (barra inferior: A · B · C) tiene 4 pestañas:

- **Posiciones**: la tabla del torneo.
- **Fixture**: partidos y resultados.
- **Goleadores**: ranking de goleadores, con buscador.
- **Sanciones**: tarjetas y suspendidos, con buscador.

Además:

- Para actualizar, deslizá hacia abajo.
- Guarda los últimos datos para verlos **sin conexión**.
- Tiene modo oscuro automático.
- Si una sección está vacía, tiene un botón para abrirla en la web de la liga.

## Cómo funciona

La liga no tiene una API pública, así que la app descarga la página de la liga y lee su HTML
(`lib/data/parser.dart`):

1. Desde el campeonato `4314` del torneo `329` busca en los selectores o links los
   IDs de campeonato de "Primera A/B/C".
2. Lee todas las `<table>` de la página y las clasifica por encabezados y títulos
   (`PTS` → posiciones, `Goles` → goleadores, `Fechas`/`Tarjetas` → sanciones,
   `Local`/`Visitante` o resultados `2 - 1` → fixture).
3. Si hay links a subpáginas ("Goleadores", "Sanciones", etc.) del mismo campeonato,
   también los descarga.

Si la búsqueda automática no encuentra una categoría, fijá su ID en `lib/config.dart`:

```dart
Categoria(letra: 'A', nombre: 'Primera A', campeonato: 4312),
```

## Correr la app

```bash
flutter pub get
flutter run            # con un celular conectado o un emulador
flutter test           # tests del parser y de la UI
flutter build apk      # APK para instalar en Android
```

## Estructura

```
lib/
  config.dart            # URL, torneo, categorías
  main.dart              # App, navegación A/B/C y pestañas
  data/
    models.dart          # Tabla, Seccion, DatosCategoria
    parser.dart          # Lectura y clasificación del HTML de la liga
    repository.dart      # Descarga, caché offline y descubrimiento de categorías
  ui/
    categoria_page.dart  # Pestañas de secciones de una categoría
    tabla_view.dart      # Tabla con scroll horizontal y búsqueda
```
