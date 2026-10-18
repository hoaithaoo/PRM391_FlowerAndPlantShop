import 'package:flutter/material.dart';

abstract final class CheckoutPalette {
  static const forest950 = Color(0xFF0D1E15);
  static const forest900 = Color(0xFF132B1E);
  static const forest800 = Color(0xFF193828);
  static const forest700 = Color(0xFF224A35);
  static const forest100 = Color(0xFFE2F0E9);
  static const forest50 = Color(0xFFF1F7F4);
  static const petal500 = Color(0xFFA84366);
  static const petal400 = Color(0xFFD982A0);
  static const petal300 = Color(0xFFEFBACB);
  static const petal200 = Color(0xFFF6D6E1);
  static const petal100 = Color(0xFFFCEAF0);
  static const petal50 = Color(0xFFFFF7FA);
  static const cream100 = Color(0xFFFFF8FA);
  static const creamPastel = Color(0xFFFFF5F7);
  static const cream200 = Color(0xFFFCEEF2);
  static const cream300 = Color(0xFFF3DDE5);
  static const charcoal900 = Color(0xFF171C19);
  static const charcoal700 = Color(0xFF36403A);
  static const charcoal500 = Color(0xFF6B7770);
  static const charcoal400 = Color(0xFF8E9993);

  static const background = cream100;
  static const surface = Color(0xFFFFFDF9);
  static const field = creamPastel;
  static const forest = forest900;
  static const forestPressed = forest800;
  static const sage = forest50;
  static const sageStrong = forest100;
  static const border = cream300;
  static const text = charcoal900;
  static const mutedText = charcoal500;
  static const error = Color(0xFFB5424A);
  static const errorSurface = Color(0xFFFFEFF1);
}

class CheckoutTheme extends StatelessWidget {
  const CheckoutTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final colorScheme = baseTheme.colorScheme.copyWith(
      primary: CheckoutPalette.forest,
      onPrimary: Colors.white,
      secondary: CheckoutPalette.sageStrong,
      onSecondary: CheckoutPalette.forest,
      surface: CheckoutPalette.surface,
      onSurface: CheckoutPalette.text,
      error: CheckoutPalette.error,
    );

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: CheckoutPalette.background,
        colorScheme: colorScheme,
        textTheme: baseTheme.textTheme.apply(
          fontFamily: 'Plus Jakarta Sans',
          bodyColor: CheckoutPalette.charcoal700,
          displayColor: CheckoutPalette.charcoal900,
        ),
        appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: CheckoutPalette.background,
          foregroundColor: CheckoutPalette.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            color: CheckoutPalette.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: CheckoutPalette.border,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CheckoutPalette.field,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(color: CheckoutPalette.mutedText),
          floatingLabelStyle: const TextStyle(
            color: CheckoutPalette.forest,
            fontWeight: FontWeight.w600,
          ),
          prefixIconColor: CheckoutPalette.mutedText,
          border: _inputBorder(CheckoutPalette.cream300),
          enabledBorder: _inputBorder(CheckoutPalette.cream300),
          focusedBorder: _inputBorder(CheckoutPalette.forest, width: 1.4),
          errorBorder: _inputBorder(CheckoutPalette.error),
          focusedErrorBorder: _inputBorder(CheckoutPalette.error, width: 1.4),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: CheckoutPalette.forest,
            foregroundColor: Colors.white,
            disabledBackgroundColor: CheckoutPalette.forest.withValues(
              alpha: 0.45,
            ),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.82),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

abstract final class CheckoutTypography {
  static const brand = TextStyle(
    fontFamily: 'Dancing Script',
    fontSize: 27,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: CheckoutPalette.forest900,
  );

  static const hero = TextStyle(
    fontFamily: 'Cormorant Garamond',
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w600,
    color: CheckoutPalette.charcoal900,
  );

  static const heading = TextStyle(
    fontFamily: 'Cormorant Garamond',
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: CheckoutPalette.charcoal900,
  );

  static const section = TextStyle(
    fontFamily: 'Cormorant Garamond',
    fontSize: 21,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: CheckoutPalette.charcoal900,
  );
}
