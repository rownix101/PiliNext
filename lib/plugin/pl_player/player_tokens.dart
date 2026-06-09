import 'package:flutter/material.dart';

/// Player overlay glass style preference.
enum PlayerGlassStyle {
  /// No blur — plain translucent background.
  transparent,

  /// Standard Frosted Glass — BackdropFilter with Gaussian blur.
  frostedGlass,

  /// Enhanced Liquid Glass — deeper blur + color processing
  /// (mimics UIVisualEffectView on Apple platforms).
  liquidGlass,
}

/// PiliNext player overlay design tokens.
///
/// Single source of truth for all player UI sizing, typography,
/// colors, and layout constants. Replaces scattered magic numbers
/// across view.dart, widgets.dart, settings_panel.dart, and
/// live/video control pages.
///
/// YouTube benchmark: 48dp tap targets, 4dp progress bar,
/// limited 12/14/16/20 type scale, single foreground=white color.
abstract final class PlayerTokens {
  PlayerTokens._();

  // ── Control sizing ────────────────────────────────────────────

  /// Tap target for player buttons. YouTube uses 48dp;
  /// we use 44 to stay comfortable on Chinese UI with smaller glyphs.
  static const double buttonSize = 44;

  /// Default icon size inside player buttons.
  static const double iconSize = 20;

  /// Large icon (fullscreen, play/pause center, seek arrows).
  static const double iconSizeLg = 24;

  /// Small icon (lock, back-arrow, pin, settings checkmark).
  static const double iconSizeSm = 16;

  /// Extra small (single-digit indicators).
  static const double iconSizeXs = 14;

  /// Control bar height (vertical footprint for a row of controls).
  static const double controlBarHeight = 44;

  /// Horizontal padding around grouped controls (PlayerControlSurface).
  static const EdgeInsets controlSurfacePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  /// Horizontal padding for popup trigger text (speed, fit, qa labels).
  static const EdgeInsets popupTriggerPadding = EdgeInsets.symmetric(
    horizontal: 8,
  );

  // ── Progress bar ──────────────────────────────────────────────

  /// Resting bar height.
  static const double progressBarHeight = 3.5;

  /// Hover-expanded bar height (desktop only).
  static const double progressBarHoverHeight = 4.5;

  /// Drag-expanded bar height.
  static const double progressBarExpandedHeight = 5.5;

  /// Resting thumb radius.
  static const double thumbRadius = 7.0;

  /// Hover thumb radius (desktop only).
  static const double thumbHoverRadius = 8.0;

  /// Drag-expanded thumb radius.
  static const double thumbExpandedRadius = 10.0;

  /// Glow halo radius on drag.
  static const double thumbGlowRadius = 25.0;

  /// Standalone overlay progress bar thumb (no hover/drag animation).
  static const double overlayThumbRadius = 5.0;

  /// Segment bar vertical offset below progress bar.
  static const double segmentBarBottom = 0.75;

  /// View-point segment bar vertical offset.
  static const double viewPointBarBottom = 4.25;

  /// Seek preview bottom offset (accounts for expanded thumb).
  static const double seekPreviewOffset = 18.0;

  // ── Panel / overlay ───────────────────────────────────────────

  /// Settings panel width clamp.
  static const double settingsPanelMinWidth = 200;
  static const double settingsPanelMaxWidth = 320;

  /// Popup menu item height.
  static const double popupMenuItemHeight = 40;

  /// Popup menu item horizontal padding.
  static const EdgeInsets popupMenuItemPadding = EdgeInsets.only(left: 24);

  /// Popup menu background opacity over surfaceContainerHigh.
  static const double popupMenuOpacity = 0.95;

  /// Speed popup width.
  static const double speedPopupWidth = 288;

  /// Center lock / screenshot pill background opacity.
  static const double centerPillOpacity = 0.45;

  /// Toast / loading / error container background opacity.
  static const double containerOpacity = 0.75;

  /// Dim overlay opacity (settings panel backdrop).
  static const double dimOverlayOpacity = 0.45;

  // ── Glass overrides (player is always dark-overlay) ───────────

  /// Player control surface background — darker than app glass.
  static const Color surfaceFill = Color(0x57000000);

  /// Player settings panel background.
  static const Color panelFill = Color(0xB8000000);

  /// Toast / speed-popup fill.
  static const Color toastFill = Color(0x88000000);

  /// Popup menu fill (for hardcoded speed popup; prefer surfaceContainerHigh).
  static const Color popupFill = Color(0xF21B1C20);

  // ── Typography ────────────────────────────────────────────────

  /// Time display (position / duration).
  static const TextStyle timeText = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );

  /// Progress toast text.
  static const TextStyle toastText = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );

  /// Popup menu item label.
  static const TextStyle popupLabel = TextStyle(
    color: Colors.white,
    fontSize: 13,
  );

  /// Popup menu disabled item label.
  static TextStyle popupLabelDisabled(BuildContext context) => TextStyle(
    color: Colors.white.withValues(alpha: 0.38),
    fontSize: 13,
  );

  /// Active popup trigger text (e.g. speed "1.5x", fit "填充").
  static const TextStyle popupTrigger = TextStyle(
    color: Colors.white,
    fontSize: 13,
  );

  /// Bold popup trigger (e.g. speed when using custom value).
  static const TextStyle popupTriggerBold = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Volume / brightness percentage text.
  static const TextStyle indicatorText = TextStyle(
    fontSize: 13,
    color: Colors.white,
    fontWeight: FontWeight.w500,
    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
  );

  /// Seek feedback duration text ("+10s", "-5s").
  static const TextStyle seekFeedbackText = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
  );

  /// Seek preview time text.
  static const TextStyle seekPreviewTime = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
  );

  /// Settings panel title.
  static const TextStyle settingsTitle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// Settings panel tile label.
  static const TextStyle settingsTileLabel = TextStyle(
    color: Colors.white,
    fontSize: 14,
  );

  /// Settings panel tile trailing value.
  static const TextStyle settingsTileTrailing = TextStyle(
    color: Color(0x8CFFFFFF),
    fontSize: 13,
  );

  /// Settings panel subtitle.
  static const TextStyle settingsSubtitle = TextStyle(
    color: Color(0x8CFFFFFF),
    fontSize: 12,
  );

  /// Speed panel heading.
  static const TextStyle speedHeading = TextStyle(
    color: Color(0xB3FFFFFF),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Speed panel current value.
  static const TextStyle speedValueText = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// Speed preset button label.
  static TextStyle speedPresetLabel(bool isSelected) => TextStyle(
    color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.78),
    fontSize: 12,
    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
  );

  /// Long-press speed toast.
  static const TextStyle longPressSpeedToast = TextStyle(
    color: Colors.white,
    fontSize: 13,
  );

  /// Loading / error text.
  static TextStyle statusText(BuildContext context) => TextStyle(
    color: ColorScheme.of(context).onSurface,
    fontSize: 12,
  );

  // ── Radii ─────────────────────────────────────────────────────

  /// Toast bubble radius.
  static const Radius toastRadius = Radius.circular(16);

  /// Long-press speed toast.
  static const BorderRadius toastBorderRadius = BorderRadius.all(toastRadius);

  /// Time progress pill radius.
  static const BorderRadius timeProgressRadius = BorderRadius.all(
    Radius.circular(32),
  );

  /// Center lock / screenshot pill radius.
  static const BorderRadius centerPillRadius = BorderRadius.all(
    Radius.circular(8),
  );

  /// Loading / error container radius.
  static const BorderRadius statusContainerRadius = BorderRadius.all(
    Radius.circular(24),
  );

  /// Control surface radius.
  static const BorderRadius controlSurfaceRadius = BorderRadius.all(
    Radius.circular(20),
  );

  // ── Shadows ───────────────────────────────────────────────────

  /// Loading / error container shadow.
  static const BoxShadow statusContainerShadow = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  /// Seek preview thumbnail shadow.
  static const BoxShadow seekPreviewShadow = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  // ── Overlay indicator ─────────────────────────────────────────

  static const double indicatorSidePadding = 12;
  static const double indicatorIconSize = 22;
  static const double indicatorSpacing = 4;

  // ── Toast positions ────────────────────────────────────────────

  /// Fullscreen toast vertical translation.
  static const Offset toastTranslationFullscreen = Offset(0.0, 1.2);

  /// Embedded (non-fullscreen) toast vertical translation.
  static const Offset toastTranslationEmbedded = Offset(0.0, 0.8);

  // ── Seek indicators ───────────────────────────────────────────

  /// Cancel seek toast padding.
  static const EdgeInsets cancelSeekPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  /// Long-press speed toast padding.
  static const EdgeInsets longPressSpeedPadding = EdgeInsets.all(6);

  /// Time progress toast padding.
  static const EdgeInsets timeProgressPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 8,
  );

  /// Status container padding.
  static const EdgeInsets statusContainerPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  );

  /// Error container padding.
  static const EdgeInsets errorContainerPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  /// Speed panel internal padding.
  static const EdgeInsets speedPanelPadding = EdgeInsets.fromLTRB(
    12,
    8,
    12,
    12,
  );

  /// Restore scale button padding.
  static const EdgeInsets restoreScalePadding = EdgeInsets.all(15);

  /// Restore scale button bottom offset.
  static const double restoreScaleBottom = 95;

  // ── Overlay colors (ad-hoc, outside ColorScheme) ──────────────

  /// Indicator shadow color.
  static const Color indicatorShadow = Colors.black54;

  /// Volume / brightness icon colors.
  static const Color indicatorIcon = Colors.white;

  /// Seek feedback burst circle color.
  static const Color seekBurst = Colors.white;

  /// Seek icon shadow.
  static const Color seekIconShadow = Colors.black45;
}
