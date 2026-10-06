// GENERATED FILE — DO NOT EDIT BY HAND.
// Regenerate: python3 tools/design-pipeline/generate.py
// Source skill: ~/.config/opencode/skills/levels/DESIGN.md
//
//   Design : Levels
//   Mode   : dark
//   Skill  : levels
//
// Audit at generation time (WCAG on the generated panel surface):
//   body contrast  15.35:1   subtext contrast 6.39:1   accent 5.53:1
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

/// Design skin for **waptia/admin**.
class AppDesignSkin {
  const AppDesignSkin._();

  static const String appName = 'waptia/admin';
  static const String skill = 'levels';
  static const String designName = 'Levels';
  static const bool isDark = true;

  /// Apply before `runApp`.
  static void boot({Brightness brightness = Brightness.dark}) {
    InforttsDesign.boot(skin, initialBrightness: brightness);
  }

  static const AcousticDynamicThemeConfig skin = AcousticDynamicThemeConfig(
    // accents
    primaryColor: Color(0xFF828D8B),
    secondaryColor: Color(0xFF53DBEB),
    primaryDimColor: Color(0xFF2F3736),
    successColor: Color(0xFF16A34A),
    dangerColor: Color(0xFFDC2626),
    warnColor: Color(0xFFD97706),

    // surfaces
    darkBg: Color(0xFF070A0E),
    darkPanelBg: Color(0xFF0B1212),
    lightBg: Color(0xFFFFFFFF),
    lightPanelBg: Color(0xFFFFFFFF),
    obsidianColor: Color(0xFF111418),
    activeCardColor: Color(0xFF434A4C),

    // text (dark palette)
    titaniumColor: Color(0xFFE2E8F0),
    steelColor: Color(0xFF90979C),
    midGrayColor: Color(0xFF434A4C),
    // Drives AcousticColors.lightOnBackground/lightOnSurface, so it must be
    // the LIGHT palette's ink — the dark titanium would be invisible on a light
    // panel. Light-mode subtext reuses steelColor via lightOnSurfaceVariant.
    textOnSurface: Color(0xFF111827),
    lightSubTextColor: Color(0xFF7C8088),
    outlineColor: Color(0xFF434A4C),

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

