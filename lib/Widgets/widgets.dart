import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quthon/Service/dnd_service.dart';
import 'package:quthon/Service/pin_service.dart';
import 'package:quthon/Widgets/animations.dart';

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

class CustomShapeDataCard extends StatelessWidget {
  final String label;
  final String data;
  final Color? textColor;
  final Color? backgroundColor;
  final double amplitude;
  final double frequency;

  const CustomShapeDataCard({
    super.key,
    required this.label,
    required this.data,
    this.textColor,
    this.backgroundColor,
    this.amplitude = 2.5,
    this.frequency = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: ClipPath(
            clipper: WavyCircleClipper(
              amplitude: amplitude,
              frequency: frequency,
            ),
            child: Material(
              color:
                  backgroundColor ??
                  Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Text(
                    data,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          textColor ??
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
            Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Data text
            Align(
              alignment: AlignmentGeometry.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 4,
                ),
                child: child,
              ),
            ),

            Card(
              margin: EdgeInsets.symmetric(horizontal: 10),
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
                      Theme.of(context).textTheme.labelSmall?.copyWith(
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
    final effectiveInnerColor = innerColor ?? colorScheme.surface;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: StadiumBorder(side: BorderSide(color: effectiveBorderColor)),
      color: effectiveOuterColor,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Inner label card
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(),
                child: Card(
                  shape: StadiumBorder(
                    side: BorderSide(color: effectiveBorderColor),
                  ),
                  color: effectiveInnerColor,
                  margin: EdgeInsets.all(0),
                  // decoration: BoxDecoration(color: colorScheme.surface),
                  // alignment: Alignment.center,
                  // padding: const EdgeInsets.symmetric(
                  //   vertical: 10,
                  //   horizontal: 10,
                  // ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style:
                            labelStyle ??
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
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
                child: Align(
                  alignment: AlignmentGeometry.centerRight,
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
            ),
          ],
        ),
      ),
    );
  }
}

// used in question review state:
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

class AsyncButton extends StatefulWidget {
  final Future<String?> Function()? onPressedAsync;
  final VoidCallback? onSuccess;
  final void Function(String? result)? onResult;
  final ButtonStyle? buttonStyle;
  final Offset? offset;
  final List<BoxShadow>? boxShadow;

  // Text labels for each state
  final String childText; // initial child text
  final String
  loadingText; // label or design the loading child but only text is allowed
  final String retryText; // lable error child
  final String continueText; // lable continue child
  final String errorMessage; // input any fallback msg
  final String successMessage; // input any succuess msg

  /// Show or hide internal response messages above the button
  final bool showResponse; // get response in text just above the button:
  final bool needContinue; // if required to show continue button:

  final bool
  callContinue; // when only wants to show the continue button initially:

  const AsyncButton({
    super.key,
    required this.onPressedAsync,
    this.onSuccess,
    this.onResult,
    this.buttonStyle,
    this.offset,
    this.boxShadow,
    this.childText = "Press Me",
    this.loadingText = "Loading...",
    this.retryText = "Retry",
    this.continueText = "Continue",
    this.successMessage = 'SuccessFull',
    this.errorMessage = '',
    this.showResponse = true,
    this.needContinue =
        true, // first pressed is async after that do you need continue:
    this.callContinue = false, //first pressed as continue:
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showContinue = false;
  @override
  initState() {
    super.initState();
    _showContinue = widget.callContinue;
  }

  // NOTE : make sure to add some time onPressedAsync.call to have atleast some minimum time whenuser call it :
  Future<void> _handlePress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _showContinue = false;
    });

    try {
      // you can add future.wait to show loading or repose with atlease some delay:
      final resultObject = await Future.wait([
        widget.onPressedAsync?.call() ??
            Future.delayed(Duration(milliseconds: 200)),
        Future.delayed(Duration(milliseconds: 200)),
      ]);
      final result = resultObject[0];
      if (!mounted) return;

      setState(() {
        _successMessage = result ?? widget.successMessage;
        if (widget.needContinue) _showContinue = true;
      });

      widget.onResult?.call(result); // send success result externally
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });

      widget.onResult?.call(e.toString()); // send error externally
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleContinue() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    widget.onSuccess?.call();
  }

  /// Builds the button child based on internal state
  Widget _buildButtonChild() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          ThreeDotWave(dotSize: 4, amplitude: .5),

          Flexible(
            child: Text(
              widget.loadingText,
              style: TextStyle(color: colorScheme.outline),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Text(widget.retryText);
    }

    if (widget.needContinue && _showContinue) {
      return Text(widget.continueText);
    }

    // child state
    return Text(widget.childText);
  }

  /// Returns correct callback depending on state
  VoidCallback? _currentCallback() {
    if (_isLoading) return null;
    if (_showContinue && widget.needContinue) return _handleContinue;
    return _handlePress;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: SingleChildScrollView(
        // edit for hero widget
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 350),
              child: Stack(
                alignment: AlignmentGeometry.topCenter,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showResponse) ...[
                    AnimatedUpDown(
                      active: _errorMessage != null,
                      // enableFade: true,
                      autoHideDuration: const Duration(seconds: 3),

                      child: Text(
                        _errorMessage ?? '',
                        maxLines: 4,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    AnimatedUpDown(
                      active: _successMessage != null,
                      autoHideDuration: const Duration(seconds: 3),

                      child: Text(
                        _successMessage ?? widget.successMessage,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            CustomBottomButton(
              offset: widget.offset,
              boxShadow: widget.boxShadow,
              buttonStyle: widget.buttonStyle,
              onPressed:
                  widget.onPressedAsync == null ? null : _currentCallback(),
              child: _buildButtonChild(),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Color? foregroundColor;
  final Color? disabledForegroundColor;
  final ButtonStyle? buttonStyle;
  final List<BoxShadow>? boxShadow;
  final Offset? offset;

  const CustomBottomButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.foregroundColor,
    this.disabledForegroundColor,
    this.buttonStyle,
    this.boxShadow,
    this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return StyledContainer(
      // TODO use simple container to remove any couping with maincontianer with button:
      margin: EdgeInsetsGeometry.all(0),
      padding: EdgeInsetsGeometry.all(0),
      color: colorScheme.surfaceContainerLowest.withAlpha(0),
      boxShadow: onPressed == null ? [] : boxShadow,
      border: Border.fromBorderSide(
        BorderSide(
          color: colorScheme.scrim.withAlpha(0),
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      offset: offset ?? Offset(0, 12),
      child: Card(
        margin: EdgeInsets.all(0),
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: StadiumBorder(),
        child: FilledButton(
          // this could be anything instead of filledbutton
          style:
              (buttonStyle == null || onPressed == null)
                  ? ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return disabledBackgroundColor ??
                            colorScheme.surfaceContainerHigh;
                      }
                      return backgroundColor ?? colorScheme.primary;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return disabledForegroundColor ??
                            colorScheme.onSurfaceVariant;
                      }
                      return foregroundColor ?? colorScheme.onPrimary;
                    }),
                  )
                  : buttonStyle,
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

class CustomCheckTile extends StatelessWidget {
  const CustomCheckTile({
    super.key,
    required this.toggleBool,
    required this.onChanged,
    required this.title,
  });

  final bool toggleBool;
  final String title;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Checkbox(
          activeColor: colorScheme.primaryContainer,
          value: toggleBool,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // for softer corners
          ),
          side: BorderSide(
            strokeAlign: BorderSide.strokeAlignInside,
            width: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
          checkColor:
              Theme.of(context).colorScheme.primary, // color of the checkmark
          fillColor: WidgetStatePropertyAll(Colors.transparent),
        ),

        Flexible(child: Text(title)),
      ],
    );
  }
}

//TODO move this to contestPage for joining the contest :
class ContestJoiningSheet extends StatefulWidget {
  final Future<String?> Function() onPressedAsync;
  final VoidCallback onSuccess;
  final VoidCallback? onToggle;
  final ColorScheme? colorScheme;
  final EdgeInsets? mediaPadding;

  const ContestJoiningSheet({
    super.key,
    required this.onPressedAsync,
    required this.onSuccess,
    this.onToggle,
    this.colorScheme,
    this.mediaPadding,
  });

  @override
  State<ContestJoiningSheet> createState() => _ContestJoiningSheetState();
}

class _ContestJoiningSheetState extends State<ContestJoiningSheet> {
  late bool _dnd = false;
  late bool _pin = false;
  bool confirmPin = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await DndService.isPermissionGranted();
      bool newDnd = false;
      if (granted) {
        final filter = await DndService.getCurrentFilter();
        newDnd = filter == DndFilter.none; // all notifications off
      }

      final pinned = await PinService.getStatus();
      bool newPin = pinned == 2; // 2 -> PinState.pinned

      if (mounted) {
        setState(() {
          _dnd = newDnd;
          _pin = newPin;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme ?? Theme.of(context).colorScheme;
    final mediaPadding = widget.mediaPadding ?? MediaQuery.of(context).padding;
    final mediaSize = MediaQuery.sizeOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close Button
        IconButton(
          onPressed: widget.onToggle,
          icon: Icon(Icons.close_rounded, color: colorScheme.outline),
        ),

        // Main Container
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: colorScheme.surfaceContainer),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(blurRadius: 10, color: colorScheme.scrim.withAlpha(30)),
            ],
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            bottom: mediaPadding.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  mediaSize.height * .8 < 300 ? mediaSize.height * .8 : 300,
            ),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StyledContainer(
                    padding: EdgeInsetsGeometry.all(0),
                    margin: EdgeInsetsGeometry.all(0),
                    boxShadow: [],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [
                        RotatedBox(
                          quarterTurns: 3, // 1 = 90°, 2 = 180°, 3 = 270°
                          child: Card(
                            margin: EdgeInsets.all(0),
                            shape: RoundedRectangleBorder(),
                            elevation: 0,
                            child: Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                vertical: 4,
                                horizontal: 12,
                              ),
                              child: Text(
                                'NOTE',
                                style: TextStyle(color: colorScheme.secondary),
                              ),
                            ),
                          ),
                        ),

                        Flexible(
                          child: Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: Text(
                              'You can only join the contest once and after joining don\'t press back button or exit the app',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // DND Toggle
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomCheckTile(
                      toggleBool: _dnd,
                      title: 'DND mode',
                      onChanged: (ch) async {
                        if (ch == null) return;
                        if (_dnd) {
                          setState(() => _dnd = !_dnd);
                          await DndService.disableDnd();
                          return;
                        }

                        final granted = await DndService.isPermissionGranted();
                        if (!granted && context.mounted) {
                          showDndPermissionSheet(context);
                          return;
                        }

                        setState(() => _dnd = !_dnd);
                        await DndService.enableDnd();
                      },
                    ),
                  ),

                  // PIN Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomCheckTile(
                        toggleBool: _pin,
                        title: 'PIN mode',
                        onChanged: (ch) async {
                          if (ch == null) return;
                          if (_pin) {
                            setState(() => _pin = !_pin);
                            await PinService.stopPin();
                            return;
                          } else {
                            setState(() {
                              confirmPin = true;
                            });
                            await PinService.startPin();
                          }
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed:
                            !confirmPin
                                ? null
                                : () async {
                                  final isPinned = await PinService.getStatus();
                                  setState(() {
                                    confirmPin = false;
                                  });
                                  if (isPinned == 2 && !_pin) {
                                    setState(() {
                                      _pin = true;
                                    });
                                  }
                                },
                        child: Text(
                          'Confirm Pin',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            color:
                                !confirmPin
                                    ? colorScheme.outlineVariant
                                    : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // NOTE
                  SizedBox(height: 8),
                  AsyncButton(
                    // // this make sure when contestpage builds it rebuilds:
                    // key: UniqueKey(),
                    showResponse: true,

                    childText: 'Join',
                    loadingText: 'joining',
                    retryText: 'Try again',

                    onPressedAsync:
                        (_dnd && _pin) ? widget.onPressedAsync : null,
                    onSuccess:
                        (_dnd && _pin)
                            ? () async {
                              final dnd =
                                  await DndService.isDndCurrentlyEnabled();
                              final pin = 2 == await PinService.getStatus();
                              setState(() {
                                _dnd = dnd;
                                _pin = pin;
                              });
                              if (_dnd && _pin) {
                                widget.onSuccess.call();
                              }
                            }
                            : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> showDndPermissionSheet(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaPadding = MediaQuery.of(context).padding;

    await showModalBottomSheet(
      // barrierColor: colorScheme.surfaceContainerLowest.withAlpha(0),
      backgroundColor: colorScheme.surfaceContainerLowest.withAlpha(0),
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: mediaPadding.bottom + 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: StyledContainer(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                spacing: 10,
                children: [
                  const Text('DND mode permission required'),
                  const Spacer(),
                  CupertinoButton(
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Open settings',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    onPressed: () async {
                      await DndService.requestPermission();
                      if (context.mounted) {
                        Navigator.maybePop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            // left: 16,
            // right: 16,
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

//GENERAL ERROR BUILDER:

class ErrorBuilder extends StatelessWidget {
  final String errorText;
  final String imageAsset;
  final VoidCallback onPressed;
  final String buttonText;
  final ButtonStyle? buttonStyle;

  const ErrorBuilder({
    super.key,
    required this.errorText,
    this.imageAsset = 'assets/error_page.png',
    required this.onPressed,
    this.buttonText = 'Retry',
    this.buttonStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final defaultButtonStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: colorScheme.surfaceContainer),
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.fromBorderSide(
              BorderSide(color: colorScheme.surfaceContainer),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 250),
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              OutlinedButton(
                style: buttonStyle ?? defaultButtonStyle,
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Measurement of widget:
typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  const MeasureSize({super.key, required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  Size? oldSize;
  final OnWidgetSizeChange onChange;

  _RenderMeasureSize(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final size = this.size;
    if (oldSize == size) return;
    oldSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(size);
    });
  }
}

// review and quetion answer styled:

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
