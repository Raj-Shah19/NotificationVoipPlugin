import 'dart:ui';

/// Styling for the in-app banner notification.
///
/// Any field left `null` falls back to the platform default, which adapts
/// to the device's light/dark appearance:
/// - light mode: white background, black text
/// - dark mode: dark gray (#2C2C2E) background, white text
class NvpInAppNotificationStyle {
  /// Banner background color. `null` = platform light/dark default.
  final Color? backgroundColor;

  /// Title text color. The body, avatar placeholder, and close button are
  /// derived from this with reduced opacity. `null` = platform light/dark
  /// default.
  final Color? textColor;

  const NvpInAppNotificationStyle({
    this.backgroundColor,
    this.textColor,
  });

  Map<String, dynamic> toMap() => {
        if (backgroundColor != null)
          // ignore: deprecated_member_use
          'backgroundColor': backgroundColor!.value,
        if (textColor != null)
          // ignore: deprecated_member_use
          'textColor': textColor!.value,
      };
}
