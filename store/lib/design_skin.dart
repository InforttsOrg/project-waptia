// GENERATED FILE — DO NOT EDIT BY HAND.
// Regenerate: python3 tools/design-pipeline/generate.py
// Source skill: ~/.config/opencode/skills/bento/DESIGN.md
//
//   Design : Bento
//   Mode   : dark
//   Skill  : bento
//
// Audit at generation time (WCAG on the generated panel surface):
//   body contrast  15.31:1   subtext contrast 6.38:1   accent 10.27:1
//
// The Infortts 3D emblem, logo and shell chrome are NOT affected by this file —
// they stay canonical Rocky Vision. Only the product surface is restyled, which
// is how each app ends up visually distinct while remaining on-brand.
//
// Prefer composing `shared` primitives (AcousticSurface, AcousticButton,
// AcousticText, AcousticSection…) over hand-rolled decoration; they read these
// values automatically.

import 'package:flutter/material.dart';

import 'package:infortts_shared/infortts_shared.dart';

/// Design skin for **waptia/store**.
class AppDesignSkin {
  const AppDesignSkin._();

  static const String appName = 'waptia/store';
  static const String skill = 'bento';
  static const String designName = 'Bento';
  static const bool isDark = true;

  /// Apply before `runApp`.
  static void boot({Brightness brightness = Brightness.dark}) {
    InforttsDesign.boot(skin, initialBrightness: brightness);
  }

  static const AcousticDynamicThemeConfig skin = AcousticDynamicThemeConfig(
    // accents
    primaryColor: Color(0xFFF4ACB7),
    secondaryColor: Color(0xFF6898C6),
    primaryDimColor: Color(0xFF573F44),
    successColor: Color(0xFF16A34A),
    dangerColor: Color(0xFFDC2626),
    warnColor: Color(0xFFD97706),

    // surfaces
    darkBg: Color(0xFF090A0E),
    darkPanelBg: Color(0xFF141012),
    lightBg: Color(0xFFFFF5E6),
    lightPanelBg: Color(0xFFFFF5E6),
    obsidianColor: Color(0xFF1C171C),
    activeCardColor: Color(0xFF4A484C),

    // text (dark palette)
    titaniumColor: Color(0xFFE2E8F0),
    steelColor: Color(0xFF94969C),
    midGrayColor: Color(0xFF4A484C),
    // Drives AcousticColors.lightOnBackground/lightOnSurface, so it must be
    // the LIGHT palette's ink — the dark titanium would be invisible on a light
    // panel. Light-mode subtext reuses steelColor via lightOnSurfaceVariant.
    textOnSurface: Color(0xFF111827),
    lightSubTextColor: Color(0xFF7C7B7D),
    outlineColor: Color(0xFF4A484C),

    // type
    fontFamily: 'Inter',
    monoFamily: 'JetBrains Mono',
    displayFamily: 'Inter',
    bodyTextSize: 16,
    headingTextSize: 32,

    // geometry
    cardBorderRadius: 8,
    radiusSm: 4,
  );
}

