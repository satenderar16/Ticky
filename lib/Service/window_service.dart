// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum WindowFlag {
  FLAG_SECURE,
  FLAG_KEEP_SCREEN_ON,
  FLAG_LAYOUT_NO_LIMITS,
  FLAG_FULLSCREEN,
  FLAG_FORCE_NOT_FULLSCREEN,
  FLAG_TRANSLUCENT_STATUS,
  FLAG_TRANSLUCENT_NAVIGATION,
  FLAG_NOT_FOCUSABLE,
  FLAG_NOT_TOUCH_MODAL,
  FLAG_WATCH_OUTSIDE_TOUCH,
  FLAG_DIM_BEHIND,
  FLAG_SHOW_WHEN_LOCKED,
  FLAG_DISMISS_KEYGUARD,
  FLAG_TURN_SCREEN_ON,
  FLAG_ALT_FOCUSABLE_IM,
  FLAG_SPLIT_TOUCH,
  FLAG_LAYOUT_IN_SCREEN,
  FLAG_LAYOUT_INSET_DECOR,
  FLAG_LAYOUT_ATTACHED_IN_DECOR,
  FLAG_LAYOUT_IN_OVERSCAN,
  FLAG_WALLPAPER,
}

extension WindowFlagExtension on WindowFlag {
  int get value {
    switch (this) {
      case WindowFlag.FLAG_SECURE:
        return 0x80000000;
      case WindowFlag.FLAG_KEEP_SCREEN_ON:
        return 0x00000080;
      case WindowFlag.FLAG_LAYOUT_NO_LIMITS:
        return 0x00000400;
      case WindowFlag.FLAG_FULLSCREEN:
        return 0x00000400;
      case WindowFlag.FLAG_FORCE_NOT_FULLSCREEN:
        return 0x00000800;
      case WindowFlag.FLAG_TRANSLUCENT_STATUS:
        return 0x04000000;
      case WindowFlag.FLAG_TRANSLUCENT_NAVIGATION:
        return 0x08000000;
      case WindowFlag.FLAG_NOT_FOCUSABLE:
        return 0x00000008;
      case WindowFlag.FLAG_NOT_TOUCH_MODAL:
        return 0x00000020;
      case WindowFlag.FLAG_WATCH_OUTSIDE_TOUCH:
        return 0x00000040;
      case WindowFlag.FLAG_DIM_BEHIND:
        return 0x00000002;
      case WindowFlag.FLAG_SHOW_WHEN_LOCKED:
        return 0x00080000;
      case WindowFlag.FLAG_DISMISS_KEYGUARD:
        return 0x00400000;
      case WindowFlag.FLAG_TURN_SCREEN_ON:
        return 0x00200000;
      case WindowFlag.FLAG_ALT_FOCUSABLE_IM:
        return 0x00020000;
      case WindowFlag.FLAG_SPLIT_TOUCH:
        return 0x00010000;
      case WindowFlag.FLAG_LAYOUT_IN_SCREEN:
        return 0x00000100;
      case WindowFlag.FLAG_LAYOUT_INSET_DECOR:
        return 0x00000200;
      case WindowFlag.FLAG_LAYOUT_ATTACHED_IN_DECOR:
        return 0x00001000;
      case WindowFlag.FLAG_LAYOUT_IN_OVERSCAN:
        return 0x00002000;
      case WindowFlag.FLAG_WALLPAPER:
        return 0x00000800;
    }
  }
}

class WindowFlagsController extends StatefulWidget {
  final List<WindowFlag> flags;
  final bool enable;
  final Color? statusBarColor;
  final Color? navigationBarColor;
  final bool transparentBars;
  final Color? windowBackgroundColor; // NEW: background for notch/status bar
  final Widget child;

  const WindowFlagsController({
    required this.flags,
    this.enable = true,
    this.statusBarColor,
    this.navigationBarColor,
    this.transparentBars = false,
    this.windowBackgroundColor,
    required this.child,
    super.key,
  });

  @override
  State<WindowFlagsController> createState() => _WindowFlagsControllerState();
}

class _WindowFlagsControllerState extends State<WindowFlagsController> {
  static const _channel = MethodChannel('window_flags');

  @override
  void initState() {
    super.initState();
    _applyFlags();
  }

  @override
  void didUpdateWidget(covariant WindowFlagsController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flags != oldWidget.flags ||
        widget.statusBarColor != oldWidget.statusBarColor ||
        widget.navigationBarColor != oldWidget.navigationBarColor ||
        widget.transparentBars != oldWidget.transparentBars ||
        widget.enable != oldWidget.enable ||
        widget.windowBackgroundColor != oldWidget.windowBackgroundColor) {
      _applyFlags();
    }
  }

  Future<void> _applyFlags() async {
    final intFlags = widget.flags.map((e) => e.value).toList();
    try {
      await _channel.invokeMethod('setFlags', {
        'flags': intFlags,
        'enable': widget.enable,
        'statusBarColor': widget.statusBarColor?.toARGB32(),
        'navigationBarColor': widget.navigationBarColor?.toARGB32(),
        'transparentBars': widget.transparentBars,
        'windowBackgroundColor': widget.windowBackgroundColor?.toARGB32(),
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to set window flags: ${e.message}');
    }
  }

  @override
  void dispose() {
    _channel.invokeMethod('setFlags', {
      'flags': widget.flags.map((e) => e.value).toList(),
      'enable': false,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
