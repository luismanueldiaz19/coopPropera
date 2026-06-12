import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  // Colores extraídos del logo de CoopPropera
  static const Color primaryDarkTeal = Color(0xFF00594C); // Outer triangle and 'Coop' text
  static const Color primaryVibrantGreen = Color(0xFF008960); // Inner tree and 'prospera' text
  static const Color accentGrey = Color(0xFF808080); // Tagline text

  // Definición del AccentColor en Fluent UI
  // Fluent UI requiere un AccentColor que soporta múltiples tonos (light, normal, dark)
  static final AccentColor accentColor = AccentColor.swatch({
    'darkest': primaryDarkTeal.withValues(alpha: 0.8),
    'darker': primaryDarkTeal.withValues(alpha: 0.9),
    'dark': primaryDarkTeal,
    'normal': primaryVibrantGreen, // Principal
    'light': primaryVibrantGreen.withValues(alpha: 0.9),
    'lighter': primaryVibrantGreen.withValues(alpha: 0.8),
    'lightest': primaryVibrantGreen.withValues(alpha: 0.7),
  });

  static FluentThemeData lightTheme() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: accentColor,
      activeColor: primaryVibrantGreen,
      visualDensity: VisualDensity.standard,
      focusTheme: const FocusThemeData(
        glowFactor: 0.0,
      ),
    );
  }

  static FluentThemeData darkTheme() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: accentColor,
      activeColor: primaryVibrantGreen,
      visualDensity: VisualDensity.standard,
      focusTheme: const FocusThemeData(
        glowFactor: 0.0,
      ),
    );
  }
}
