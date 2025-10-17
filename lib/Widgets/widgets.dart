import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StyledContainer extends StatelessWidget {
  final Widget child;
  final BoxBorder? border;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double blurRadius;
  final Offset offset;
  final List<BoxShadow>? boxShadow;
  final Color? color;
  const StyledContainer({
    super.key,
    required this.child,
    this.border,
    this.margin = const EdgeInsets.symmetric(horizontal: 10),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.blurRadius = 10,
    this.offset = const Offset(0, 0),
    this.boxShadow,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: margin, // vertical will be handle in scroll child
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color ?? colorScheme.surfaceContainerLowest,
        border:
            border ??
            Border.fromBorderSide(
              BorderSide(
                color: colorScheme.surfaceContainer,
              ), // slight border difference
            ),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: colorScheme.scrim.withAlpha(30),
                blurRadius: blurRadius,
                offset: offset,
              ),
            ],
      ),
      child: child,
    );
  }
}

class DataLabelCard extends StatelessWidget {
  final String label;
  final String data;

  /// Border color of the outer card.
  final Color? borderColor;

  /// Background color of the outer card.
  final Color? outerColor;

  /// Background color of the inner (label) card.
  final Color? innerColor;

  final TextStyle? labelStyle;
  final TextStyle? dataStyle;

  const DataLabelCard({
    super.key,
    required this.label,
    required this.data,
    this.borderColor,
    this.outerColor,
    this.innerColor,
    this.labelStyle,
    this.dataStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DataWidgetCard(
      label: label,
      child: Text(
        data,
        style:
            labelStyle ??
            Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class DataWidgetCard extends StatelessWidget {
  final String label;
  final Widget child;

  /// Border color of the outer card.
  final Color? borderColor;

  /// Background color of the outer card.
  final Color? outerColor;

  /// Background color of the inner (label) card.
  final Color? innerColor;

  final TextStyle? labelStyle;
  final TextStyle? dataStyle;

  const DataWidgetCard({
    super.key,
    required this.label,
    required this.child,
    this.borderColor,
    this.outerColor,
    this.innerColor,
    this.labelStyle,
    this.dataStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveBorderColor = borderColor ?? colorScheme.surfaceContainerLow;
    final effectiveOuterColor =
        outerColor ?? colorScheme.surfaceContainerLowest;
    final effectiveInnerColor = innerColor ?? colorScheme.surfaceContainerLow;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 70),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: effectiveBorderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        color: effectiveOuterColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Data text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
              child: child,
            ),

            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: effectiveInnerColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  label,
                  style:
                      labelStyle ??
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataHorizontalCard extends StatelessWidget {
  final String label;
  final String time;

  /// Border color of the outer card.
  final Color? borderColor;

  /// Background color of the outer card.
  final Color? outerColor;

  /// Background color of the inner (label) card.
  final Color? innerColor;

  final TextStyle? labelStyle;
  final TextStyle? timeStyle;

  const DataHorizontalCard({
    super.key,
    required this.label,
    required this.time,
    this.borderColor,
    this.outerColor,
    this.innerColor,
    this.labelStyle,
    this.timeStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final effectiveBorderColor = borderColor ?? colorScheme.surfaceContainerLow;
    final effectiveOuterColor =
        outerColor ?? colorScheme.surfaceContainerLowest;
    final effectiveInnerColor = innerColor;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: StadiumBorder(side: BorderSide(color: effectiveBorderColor)),
      color: effectiveOuterColor,
      child: IntrinsicHeight(
        child: Row(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Inner label card
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: effectiveInnerColor,
              shape: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                child: Center(
                  child: Text(
                    label,
                    style:
                        labelStyle ??
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),

            // Time text
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  time,
                  style:
                      timeStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionStateButton extends StatefulWidget {
  final IconData icon;
  final bool initialActive;
  final ValueChanged<bool>? onStateChanged; // external callback

  const ActionStateButton({
    super.key,
    required this.icon,
    this.initialActive = false,
    this.onStateChanged,
  });

  @override
  State<ActionStateButton> createState() => _ActionStateButtonState();
}

class _ActionStateButtonState extends State<ActionStateButton> {
  late bool isActive;

  @override
  void initState() {
    super.initState();
    isActive = widget.initialActive;
  }

  void _toggle() {
    setState(() {
      isActive = !isActive;
    });

    // Call external callback if provided
    widget.onStateChanged?.call(isActive);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: colorScheme.surfaceContainerLow,
        // side: BorderSide(
        //   color: colorScheme.surfaceContainer,
        //   // width: ÷,
        // ),
      ),
      // color: colorScheme.surfaceCosntainerLow,
      padding: EdgeInsets.zero,
      onPressed: _toggle,
      icon: Icon(
        isActive ? Icons.bookmark : Icons.bookmark_add_outlined,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class AsyncActionBottomBar extends StatefulWidget {
  /// Called when the user triggers the main async action.
  final Future<String?> Function()? onSubmit;

  /// Called when the async action succeeds (optional).
  /// Useful for navigation, validation, or cleanup.
  final Future<void> Function()? onSuccess;

  /// Builds the button child depending on the current state.
  final Widget Function(BuildContext context, String state) builder;

  final String intialState;

  /// Optional custom success message.
  final String successMessage;

  /// Optional padding for the bottom area.
  final EdgeInsetsGeometry? padding;

  /// Optional max width for the button container.
  final double maxWidth;

  // reuse onsucess :
  final bool reuseSuccess;

  const AsyncActionBottomBar({
    super.key,
    required this.onSubmit,
    required this.builder,
    this.intialState = 'idle',
    this.onSuccess,
    this.successMessage = "Successful",
    this.padding,
    this.maxWidth = 350,
    this.reuseSuccess = false,
  });

  @override
  State<AsyncActionBottomBar> createState() => AsyncActionBottomBarState();
}

class AsyncActionBottomBarState extends State<AsyncActionBottomBar>
    with TickerProviderStateMixin {
  late String _state = "idle"; // idle, loading, retry, complete
  String? _submissionError;
  late String _successMessage;
  @override
  void initState() {
    _state = widget.intialState;
    _successMessage = widget.successMessage;
    super.initState();
  }

  Future<void> handleSubmit() async {
    // success call :
    if (widget.onSuccess != null && _state == 'complete') {
      try {
        await widget.onSuccess!(); // don't need delay
      } catch (e) {
        setState(() {
          _state == 'complete';
          _submissionError = e.toString();
        });
        return;
      }
      if (!widget.reuseSuccess && context.mounted) {
        setState(() {
          _state = 'idle';
          _submissionError = null;
        });
      }

      return;
    }
    // null function after completion:
    if (_state == 'complete') {
      return;
    }

    // calling:

    if (context.mounted) {
      setState(() => _state = "loading");
    }

    try {
      // Perform the submission
      final msg = await Future.wait([
        widget.onSubmit!(),
        Future.delayed(Duration(milliseconds: 200)),
      ]);
      // debugPrint(msg[0].toString());

      if (context.mounted) {
        setState(() {
          _state = "complete";
          _submissionError = null;
          if (msg[0] != null) {
            _successMessage = msg[0].toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = "retry";
          _submissionError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          widget.padding ??
          EdgeInsets.only(
            bottom: mediaPadding.bottom + 16,
            left: 16,
            right: 16,
            top: 10,
          ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            // Animated banners for success/error
            Stack(
              alignment: Alignment.center,
              children: [
                _AnimatedBanner(
                  active: _state == "complete",
                  color: Colors.green.withAlpha(30),
                  icon: Icons.check_circle_outline,
                  text: _successMessage,
                  textColor: Colors.green,
                ),
                _AnimatedBanner(
                  active: _state == "retry",
                  color: Colors.red.withAlpha(40),
                  icon: Icons.error_outline,
                  text: _submissionError ?? "Something went wrong",
                  textColor: Colors.red,
                ),
              ],
            ),

            // Action button
            CupertinoButton(
              sizeStyle: CupertinoButtonSize.medium,
              onPressed:
                  _state == 'loading' ||
                          (widget.onSuccess == null && _state == 'complete') ||
                          widget.onSubmit == null
                      ? null
                      : handleSubmit,
              child: SizedBox(
                width: double.infinity,
                child: StyledContainer(
                  margin: EdgeInsetsGeometry.zero,
                  // padding: EdgeInsetsGeometry.zero,
                  offset: const Offset(0, 12),
                  child: Center(child: widget.builder(context, _state)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBanner extends StatefulWidget {
  final bool active;
  final Color color;
  final IconData icon;
  final String text;
  final Color textColor;
  final Duration? autoHideDuration;
  final VoidCallback? onHidden; // optional callback after hide

  const _AnimatedBanner({
    required this.active,
    required this.color,
    required this.icon,
    required this.text,
    required this.textColor,
    this.autoHideDuration = const Duration(seconds: 3),
    this.onHidden,
  });

  @override
  State<_AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<_AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _offstage = true;
  bool _hasAutoHidden = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _offstage = true);
        widget.onHidden?.call(); // fire callback if provided
      } else if (status == AnimationStatus.forward) {
        setState(() => _offstage = false);
      }
    });

    if (widget.active) _show();
  }

  @override
  void didUpdateWidget(covariant _AnimatedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only show if newly active
    if (widget.active && !oldWidget.active) {
      _hasAutoHidden = false;
      _show();
    }
    // Hide if parent deactivates
    else if (!widget.active && oldWidget.active) {
      _hide();
    }
  }

  void _show() {
    _controller.forward();
    _offstage = false;
    _hideTimer?.cancel();

    if (widget.autoHideDuration != null) {
      _hideTimer = Timer(widget.autoHideDuration!, () {
        if (mounted && _controller.isCompleted) {
          _hide();
          _hasAutoHidden = true;
        }
      });
    }
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted && !_controller.isAnimating) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // TODO ensure the maximum height :
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Offstage(
      offstage: _offstage,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Card(
            margin: EdgeInsets.zero,
            shape: StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            color: colorScheme.surfaceContainerLowest,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 6,
                right: 8,
                top: 6,
                bottom: 6,
              ),
              color: widget.color,
              child: Row(
                spacing: 6,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: AlignmentGeometry.topLeft,
                    child: Icon(widget.icon, color: widget.textColor),
                  ),
                  Flexible(
                    child: Text(
                      widget.text,
                      style: TextStyle(color: widget.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// question review

class QuestionStatusBox extends StatelessWidget {
  const QuestionStatusBox({
    super.key,
    required this.label,
    this.isAnswered = false,
    this.isReviewed = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.isCurrent = false,
  });

  final String label;
  final bool isAnswered;
  final bool isReviewed;
  final BorderRadius borderRadius;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // final borderRadius = BorderRadius.circular(isAnswered ? 100 : 16);

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color:
                  isAnswered
                      ? Colors.green.withAlpha(20)
                      : colorScheme.surfaceContainerLow,
              borderRadius:
                  isAnswered
                      ? BorderRadius.circular(100) // fully rounded
                      : BorderRadius.circular(16), // less rounded,
              border:
                  isCurrent
                      ? Border.all(
                        width: 2,
                        color:
                            isAnswered
                                ? Colors.green.withAlpha(60)
                                : colorScheme.secondaryContainer,
                      )
                      : null,
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isAnswered ? Colors.green : colorScheme.primary,
                ),
              ),
            ),
          ),

          if (isReviewed)
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.bookmark, color: colorScheme.primary, size: 18),
            ),
        ],
      ),
    );
  }
}
