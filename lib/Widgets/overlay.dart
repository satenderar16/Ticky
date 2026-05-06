import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_entry_notifier.dart';

class CustomOverlay {
  OverlayEntry? _entry;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  CustomOverlay({
    required this.child,
    this.padding = const EdgeInsets.all(0),
    this.alignment = Alignment.center,
  });

  /// Show the overlay
  void show(BuildContext context) {
    if (_entry != null) return; // prevent duplicates

    _entry = OverlayEntry(
      builder: (context) {
        return Transform.translate(
          offset: Offset(0.5, 0.5),
          child: Padding(padding: padding, child: child),
        );
      },
    );

    Overlay.of(context)?.insert(_entry!);
  }

  /// Remove the overlay
  void remove() {
    _entry?.remove();
    _entry = null;
  }

  /// Dispose overlay when no longer needed
  void dispose() {
    remove();
  }
}

class AutoDismissOverlay {
  OverlayEntry? _entry;
  Timer? _timer;

  final Widget child;
  final Duration? duration;
  final void Function()? onDestroy;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  AutoDismissOverlay({
    required this.child,
    this.duration,
    this.onDestroy,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
  });

  /// Show the overlay, but only if not already displayed
  void show(BuildContext context) {
    if (_entry != null) return; // prevent duplicate overlay

    _entry = OverlayEntry(
      builder: (context) {
        return Align(
          alignment: alignment,
          child: Padding(padding: padding, child: child),
        );
      },
    );

    Overlay.of(context)?.insert(_entry!);

    // Auto-remove after duration
    if (duration != null) {
      _timer = Timer(duration!, () {
        dispose();
      });
    }
  }

  /// Remove the overlay manually
  void remove() {
    if (_entry == null) return; // already removed

    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    onDestroy?.call();
  }

  /// Dispose overlay (alias for remove)
  void dispose() => remove();

  /// Whether the overlay is currently visible
  bool get isVisible => _entry != null;
}

// custom slider verticle version:

class CustomVerticalSlider extends StatefulWidget {
  final VoidCallback onHide;
  final double value;

  const CustomVerticalSlider({
    super.key,
    required this.onHide,
    required this.value,
  });

  @override
  State<CustomVerticalSlider> createState() => _CustomVerticalSliderState();
}

class _CustomVerticalSliderState extends State<CustomVerticalSlider> {
  late double _value;
  Timer? _hideTimer;
  late bool visible;
  late bool active;

  double _horizontalOffset = 0.0;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    // debugPrint('hey _value is here -> $_value');
    visible = true;
    active = false;

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onHide();
      });
    });
  }

  void _onInteractionStart() {
    // debugPrint('on InstrationStart');
    _hideTimer?.cancel();
    setState(() {
      active = true;
      visible = true;
    });
  }

  void _onInteractionEnd() {
    // debugPrint('on InstrationEnd');
    setState(() {
      active = false;
    });
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _cancelOverlay() {
    setState(() {
      // active = false;
      visible = false;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onHide();
    });
    _hideTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    _screenWidth = MediaQuery.of(context).size.width;

    return Consumer(
      builder: (context, ref, child) {
        return AnimatedSlide(
          offset: Offset(visible ? 0.0 : 1.0, 0),
          duration: const Duration(milliseconds: 400),
          child: AnimatedScale(
            duration: Duration(milliseconds: 300),
            scale: visible ? 1 : 0.5,
            child: Transform.translate(
              offset: Offset(_horizontalOffset, 0),
              child: GestureDetector(
                onVerticalDragStart: (_) => _onInteractionStart(),
                onVerticalDragUpdate: (details) {
                  _onInteractionStart();
                  setState(() {
                    _value -= details.primaryDelta! / 200;
                    _value = _value.clamp(0.0, 1.0);
                  });
                  ref
                      .read(contestEntryProvider.notifier)
                      .applyBrightness(_value);
                },
                onVerticalDragEnd: (_) {
                  // debugPrint('drag end vertical :$_value')`  ;
                  _onInteractionEnd();
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _horizontalOffset += details.primaryDelta!;

                    // Optional: clamp the overlay so it doesn't go too far right
                    _horizontalOffset = _horizontalOffset.clamp(
                      -_screenWidth * .3,
                      _screenWidth,
                    );
                  });
                },

                onHorizontalDragEnd: (details) {
                  if (_horizontalOffset > 0) {
                    // Dragged to the right → dismiss overlay
                    _cancelOverlay();
                  } else {
                    // debugPrint('drag end horizontal :');
                    _onInteractionEnd();
                    // Dragged left or stayed at center → animate back to original position
                    setState(() {
                      active = false;
                      _horizontalOffset = 0.0;
                    });
                  }
                },
                onTapDown: (_) {
                  // debugPrint('tap Down :');
                  _onInteractionStart();
                },
                onTapUp: (_) {
                  // debugPrint('tap up :');
                  _onInteractionEnd();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.fromBorderSide(
                            BorderSide(color: colorScheme.surfaceContainer),
                          ),
                        ),
                        padding: EdgeInsets.all(4),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final mediaSize = MediaQuery.sizeOf(context);
                            final mediaPadding = MediaQuery.paddingOf(context);
                            final maxHeight =
                                mediaSize.height -
                                40 -
                                mediaPadding.bottom -
                                mediaPadding.top -
                                50;

                            return Stack(
                              // alignment: AlignmentGeometry.bottomCenter,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: active ? 40 : 30,
                                  height:
                                      maxHeight > 200
                                          ? active
                                              ? 200
                                              : 150
                                          : active
                                          ? maxHeight + 50
                                          : maxHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: CustomPaint(
                                      painter: _VerticalSliderPainter(
                                        borderRadius: BorderRadius.circular(20),
                                        value: _value,
                                        filledColor:
                                            colorScheme.secondaryContainer,
                                        unfilledColor: colorScheme
                                            .surfaceContainer
                                            .withAlpha(0),
                                      ),
                                    ),
                                  ),
                                ),

                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  alignment: Alignment.center,
                                  width: active ? 40 : 30,
                                  height: active ? 40 : 30,

                                  child: Icon(
                                    Icons.light_mode_outlined,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VerticalSliderPainter extends CustomPainter {
  final double value;
  final Color filledColor;
  final Color unfilledColor;
  final BorderRadius borderRadius;

  _VerticalSliderPainter({
    required this.value,
    required this.filledColor,
    required this.unfilledColor,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint unfilledPaint =
        Paint()
          ..color = unfilledColor
          ..style = PaintingStyle.fill;

    final Paint filledPaint =
        Paint()
          ..color = filledColor
          ..style = PaintingStyle.fill;

    // Background (unfilled)
    final RRect background = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );
    canvas.drawRRect(background, unfilledPaint);

    // Filled part (from bottom to top)
    final double filledHeight = size.height * value;
    if (filledHeight > 0) {
      final Rect filledRect = Rect.fromLTWH(
        0,
        size.height - filledHeight,
        size.width,
        filledHeight,
      );

      // Clip the rounded rect to keep corners consistent
      final RRect filledRRect = RRect.fromRectAndCorners(
        filledRect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      );

      canvas.drawRRect(filledRRect, filledPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalSliderPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.filledColor != filledColor ||
      oldDelegate.unfilledColor != unfilledColor ||
      oldDelegate.borderRadius != borderRadius;
}

class SliderOverlay {
  OverlayEntry? _entry;

  void show(BuildContext context) {
    if (_entry != null) return; // prevent duplicates

    _entry = OverlayEntry(
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            // final colorScheme = Theme.of(context).colorScheme;
            ref.read(contestEntryProvider.notifier).getBrightness();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: CustomVerticalSlider(
                  value: ref.read(contestEntryProvider.notifier).brightness,
                  onHide: remove,
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  void remove() {
    _entry?.remove();
    _entry = null;
  }

  void dispose() {
    remove(); // cleanup when page is popped
  }
}
