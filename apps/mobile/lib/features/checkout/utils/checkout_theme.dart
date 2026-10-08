import 'package:flutter/material.dart';

abstract final class CheckoutPalette {
  static const background = Color(0xFFFAF8F2);
  static const surface = Color(0xFFFFFDF8);
  static const field = Color(0xFFF7F5EF);
  static const forest = Color(0xFF173F2B);
  static const forestPressed = Color(0xFF0F2F20);
  static const sage = Color(0xFFE8F0E8);
  static const sageStrong = Color(0xFFD7E5D8);
  static const border = Color(0xFFE5E1D7);
  static const text = Color(0xFF1D2B22);
  static const mutedText = Color(0xFF6E756F);
  static const error = Color(0xFFB5473F);
  static const errorSurface = Color(0xFFFFEFEC);
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
        appBarTheme: baseTheme.appBarTheme.copyWith(
          backgroundColor: CheckoutPalette.background,
          foregroundColor: CheckoutPalette.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
            color: CheckoutPalette.text,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
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
          border: _inputBorder(CheckoutPalette.border),
          enabledBorder: _inputBorder(CheckoutPalette.border),
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
              borderRadius: BorderRadius.circular(16),
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
