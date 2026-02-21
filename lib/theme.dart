import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Color Palette ──────────────────────────────────────────────────────
  static const Color _surface = Color(0xFF0D0D12);
  static const Color _surfaceContainer = Color(0xFF16161E);
  static const Color _surfaceContainerHigh = Color(0xFF1E1E2A);
  static const Color _surfaceContainerHighest = Color(0xFF262635);
  static const Color _primary = Color(0xFFB388FF);
  static const Color _primaryContainer = Color(0xFF2D1F5E);
  static const Color _onPrimary = Color(0xFF0D0D12);
  static const Color _onPrimaryContainer = Color(0xFFD9C6FF);
  static const Color _secondary = Color(0xFF8B8FA8);
  static const Color _secondaryContainer = Color(0xFF2A2A3C);
  static const Color _onSecondary = Color(0xFF0D0D12);
  static const Color _onSecondaryContainer = Color(0xFFCCCEDA);
  static const Color _tertiary = Color(0xFF7C4DFF);
  static const Color _error = Color(0xFFCF6679);
  static const Color _onSurface = Color(0xFFE4E4ED);
  static const Color _onSurfaceVariant = Color(0xFF9696A8);
  static const Color _outline = Color(0xFF3A3A4C);
  static const Color _outlineVariant = Color(0xFF2A2A38);

  // ── Typography ─────────────────────────────────────────────────────────
  static TextTheme get _textTheme {
    final body = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);
    return body.copyWith(
      displayLarge: body.displayLarge?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: body.displayMedium?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: body.displaySmall?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: body.headlineLarge?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
      ),
      headlineMedium: body.headlineMedium?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: body.headlineSmall?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: body.titleLarge?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: body.titleSmall?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        color: _onSurface,
        letterSpacing: 0.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: _onSurface,
        letterSpacing: 0.25,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: _onSurfaceVariant,
        letterSpacing: 0.4,
      ),
      labelLarge: body.labelLarge?.copyWith(
        color: _onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.25,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: _onSurfaceVariant,
        letterSpacing: 0.5,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: _onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  // ── Playfair Display for display headings ──────────────────────────────
  static TextStyle get displayFont =>
      GoogleFonts.playfairDisplay(color: _primary, fontWeight: FontWeight.w700);

  // ── Access to palette colors for custom widgets ────────────────────────
  static const Color primary = _primary;
  static const Color surface = _surface;
  static const Color surfaceContainer = _surfaceContainer;
  static const Color onSurfaceVariant = _onSurfaceVariant;
  static const Color outline = _outline;
  static const Color tertiary = _tertiary;

  // ── Theme Data ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      surface: _surface,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      primary: _primary,
      primaryContainer: _primaryContainer,
      onPrimary: _onPrimary,
      onPrimaryContainer: _onPrimaryContainer,
      secondary: _secondary,
      secondaryContainer: _secondaryContainer,
      onSecondary: _onSecondary,
      onSecondaryContainer: _onSecondaryContainer,
      tertiary: _tertiary,
      error: _error,
      outline: _outline,
      outlineVariant: _outlineVariant,
      surfaceContainerHighest: _surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
      textTheme: _textTheme,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: _primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        iconTheme: const IconThemeData(color: _onSurface),
        actionsIconTheme: const IconThemeData(color: _onSurfaceVariant),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: _surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _primaryContainer,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primary, size: 24);
          }
          return const IconThemeData(color: _onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _textTheme.labelMedium?.copyWith(
              color: _primary,
              fontWeight: FontWeight.w600,
            );
          }
          return _textTheme.labelMedium?.copyWith(color: _onSurfaceVariant);
        }),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: _primary,
        unselectedLabelColor: _onSurfaceVariant,
        indicatorColor: _primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: _textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: _textTheme.labelMedium?.copyWith(fontSize: 13),
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        hintStyle: _textTheme.bodyMedium?.copyWith(
          color: _onSurfaceVariant.withValues(alpha: 0.6),
        ),
        labelStyle: _textTheme.bodyMedium?.copyWith(color: _onSurfaceVariant),
        errorStyle: _textTheme.bodySmall?.copyWith(color: _error),
      ),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── IconButton ──
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: _onSurfaceVariant),
      ),

      // ── Drawer ──
      drawerTheme: const DrawerThemeData(
        backgroundColor: _surfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),

      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: _onSurfaceVariant,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: _onSurface),
        contentTextStyle: _textTheme.bodyMedium?.copyWith(color: _onSurface),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _primaryContainer,
        contentTextStyle: _textTheme.bodyMedium?.copyWith(
          color: _onPrimaryContainer,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: _outlineVariant,
        thickness: 0.5,
        space: 1,
      ),

      // ── Icon ──
      iconTheme: const IconThemeData(color: _onSurfaceVariant, size: 24),

      // ── ListTile ──
      listTileTheme: ListTileThemeData(
        iconColor: _onSurfaceVariant,
        textColor: _onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
        linearTrackColor: _outlineVariant,
      ),

      // ── DropdownMenu ──
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: _textTheme.bodyMedium,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _textTheme.bodySmall?.copyWith(color: _onSurface),
      ),
    );
  }
}
