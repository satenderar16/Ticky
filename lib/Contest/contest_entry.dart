import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quthon/Contest/Entry/entry_body.dart';
import 'package:quthon/Contest/ContestBody/contest_body.dart';
// import 'package:quthon/Contest/widgets.dart';
import 'package:quthon/Service/Battery/battery_provider.dart';
import 'package:quthon/Service/brightness_service.dart';
import 'package:quthon/Service/dnd_service.dart';
import 'package:quthon/Service/pinn_service.dart';
import 'package:quthon/Service/wake_class.dart';
import 'package:quthon/Test/contest_page.dart';
import 'package:quthon/Widgets/overlay.dart';
import 'package:quthon/Widgets/utils.dart';
import 'package:quthon/Widgets/widgets.dart';
import 'contest_entry_notifier.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class ContestEntry extends ConsumerStatefulWidget {
  const ContestEntry({super.key});

  @override
  ConsumerState<ContestEntry> createState() => _ContestEntryState();
}

class _ContestEntryState extends ConsumerState<ContestEntry> {
  String _currentOrientation = 'Portrait Up';

  @override
  void initState() {
    super.initState();

    // Lock to current device orientation on start
    Future.microtask(() async {
      await _lockCurrentOrientation();
    });

    WakeClass.enable();
  }

  Future<void> _lockCurrentOrientation() async {
    final orientation =
        await NativeDeviceOrientationCommunicator().orientation();

    String label;
    List<DeviceOrientation> locked = [];

    switch (orientation) {
      case NativeDeviceOrientation.portraitUp:
        locked = [DeviceOrientation.portraitUp];
        label = 'Portrait Up';
        break;
      case NativeDeviceOrientation.portraitDown:
        locked = [DeviceOrientation.portraitDown];
        label = 'Portrait Down';
        break;
      case NativeDeviceOrientation.landscapeLeft:
        locked = [DeviceOrientation.landscapeLeft];
        label = 'Landscape Left';
        break;
      case NativeDeviceOrientation.landscapeRight:
        locked = [DeviceOrientation.landscapeRight];
        label = 'Landscape Right';
        break;
      default:
        locked = [DeviceOrientation.portraitUp];
        label = 'Portrait Up';
    }

    await SystemChrome.setPreferredOrientations(locked);

    setState(() {
      _currentOrientation = label; // Update state
    });
  }

  Future<void> _handleOrientationSelection(String? selected) async {
    if (selected == null) return;

    setState(() => _currentOrientation = selected);
    await PinService.setMonitorState(false);
    switch (selected) {
      case 'Portrait Up':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        break;
      case 'Portrait Down':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitDown,
        ]);
        break;
      case 'Landscape Left':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
        break;
      case 'Landscape Right':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }

    await Future.delayed(Duration(milliseconds: 400));
    await PinService.setMonitorState(true);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    BrightnessService.restore();
    PinService.setMonitorState(false);
    WakeClass.disable();
    // should remove in practice mode:
    DndService.disableDnd(); // assuming entry allowed only when dnd is enabled:
    super.dispose();
  }

  //flag for dnd and pin
  bool pinFlag = false;

  void _showPinViolationOverlay(
    BuildContext context, {
    required bool isStarted,
  }) {
    if (pinFlag) return;
    pinFlag = true;

    late final CustomOverlay overlay;

    overlay = CustomOverlay(
      child: PinViolationOverlay(
        onDismiss: () async {
          overlay.remove();
          await PinService.setMonitorState(false);
          // pinFlag = false; single time overlay condition

          // handle logic after overlay dismissed
          if (!context.mounted) return;
          if (!isStarted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ContestPage()),
            );
            return;
          }

          ref
              .read(contestEntryProvider.notifier)
              .contestSubmission(ContestSubmission.interrupted);
        },
      ),
    );

    overlay.show(context);
  }

  // bool started = false;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaPadding = MediaQuery.paddingOf(context);
    final isStarted = ref.watch(contestStartProvider);
    final isSumit = ref.watch(
      contestEntryProvider.select((s) => s.submit != ContestSubmission.none),
    );
    final dnd = ref.watch(dndProvider);
    final pin = ref.watch(pinProvider);
    if (!isSumit && isStarted) {
      dnd.whenData((filter) {
        if (filter != DndFilter.none) {
          DndService.enableDnd();
          ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              elevation: 0,
              backgroundColor: colorScheme.surface.withAlpha(0),
              // clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.all(0),
              padding: const EdgeInsets.all(0),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 350),
                    child: StyledContainer(
                      boxShadow: const [],
                      margin: const EdgeInsetsGeometry.all(0),
                      child: Text(
                        'Dnd Mode is required',
                        style: TextTheme.of(context).bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
      // pin dialog
      if (!pinFlag) {
        pin.whenData((state) {
          if (state != PinState.pinned) {
            Future.microtask(() async {
              // assuming current answer cheated:

              if (isStarted) {
                await ref.read(contestEntryProvider.notifier).persistAnswers();
              }
              // show the dialog
              if (context.mounted) {
                _showPinViolationOverlay(context, isStarted: isStarted);
              }
            });
          }
        });
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {},
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsetsGeometry.only(
                top: mediaPadding.top + kToolbarHeight,
              ),

              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final inFromRight = Tween<Offset>(
                    begin: const Offset(
                      1.0,
                      0.0,
                    ), // start just outside the right edge
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return SlideTransition(position: inFromRight, child: child);
                },
                //TODO chagne the keys:
                child:
                    isStarted
                        ? const ContestBody(key: ValueKey('contest'))
                        : const EntryBody(key: ValueKey('entry')),
              ),
            ),

            LogoAppBar(
              key: logoAppBarKey,
              currentOrientation: _currentOrientation,
              onOrientationSelected: _handleOrientationSelection,
            ),
            // Align(
            //   alignment: AlignmentGeometry.bottomCenter,
            //   child: FloatingActionButton(
            //     onPressed: () {
            //       setState(() {
            //         started = !started;
            //       });
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class PinViolationOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const PinViolationOverlay({super.key, required this.onDismiss});

  @override
  State<PinViolationOverlay> createState() => _PinViolationOverlayState();
}

class _PinViolationOverlayState extends State<PinViolationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _fade;

  static const int _initialSeconds = 30;
  int _remainingSeconds = _initialSeconds;
  Timer? _autoDismissTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _position = Tween<Offset>(
      begin: const Offset(0, 1.2), // start from bottom
      end: Offset.zero, // center
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _autoDismissTimer = Timer(
      const Duration(seconds: _initialSeconds),
      _dismiss,
    );

    // countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _dismiss() async {
    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        Align(
          alignment: Alignment.center,
          child: SlideTransition(
            position: _position,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: StyledContainer(
                  margin: EdgeInsetsGeometry.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Pin Mode Alert !!",
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Divider(color: colorScheme.surfaceContainer),

                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    "• Pin mode was disabled during the contest.\n"
                                    "• Redirecting to submission page ",
                              ),
                              TextSpan(
                                text: '[$_remainingSeconds]',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: _dismiss,
                            child: const Text("Ok"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final logoAppBarKey = GlobalKey<_LogoAppBarState>();

class LogoAppBar extends ConsumerStatefulWidget {
  const LogoAppBar({
    super.key,
    this.onOrientationSelected,
    this.currentOrientation,
  });

  /// Parent provides this handler to control orientation logic externally.
  final Future<void> Function(String? selected)? onOrientationSelected;
  final String? currentOrientation;

  @override
  ConsumerState<LogoAppBar> createState() => _LogoAppBarState();
}

class _LogoAppBarState extends ConsumerState<LogoAppBar> {
  /// this will update when contest support  question switch for large test. with sections.
  final SliderOverlay _sliderOverlay = SliderOverlay();

  @override
  void dispose() {
    _sliderOverlay.dispose(); //
    super.dispose();
  }

  void _handleMenuSelection(BuildContext context, String value) async {
    // final colorScheme = Theme.of(context).colorScheme;
    if (!context.mounted) return;

    switch (value) {
      case 'Quit':
        final shouldQuit = await showCfm(context, value: 'Quit');

        if (shouldQuit == true && context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ContestPage()),
          );
          await PinService.stopPin();
          await DndService.disableDnd();
        }
        break;

      case 'Orientation':
        final selected = await showOrientationMenu(context);
        if (widget.onOrientationSelected != null) {
          await widget.onOrientationSelected!(selected);
        }
        break;

      case 'Brightness':
        _sliderOverlay.show(context);
        break;

      case 'Battery & Time':
        batteryStatusBarKey.currentState?.toggleAlignment();
        break;

      case 'Submit':
        final shouldQuit = await showCfm(context, value: 'Submit');

        if (shouldQuit == true && context.mounted) {
          ref
              .read(contestEntryProvider.notifier)
              .contestSubmission(ContestSubmission.submit);
        }

        break;

      default:
        // Optional: handle unknown values
        break;
    }
  }

  Future<void> handleOrientationSelection(String? selected) async {
    if (selected == null) return;

    switch (selected) {
      case 'Portrait Up':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        break;

      case 'Portrait Down':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitDown,
        ]);
        break;

      case 'Landscape Left':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
        break;

      case 'Landscape Right':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
        ]);
        break;

      default:
        // Reset to all orientations if something unexpected happens
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }

    debugPrint(' Orientation changed to: $selected');
  }

  Future<String?> showOrientationMenu(BuildContext context) async {
    final current = widget.currentOrientation;
    return await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: StyledContainer(
              child: Column(
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: buildMobileOutline(
                          label: 'Portrait Up',
                          context: context,
                          borderColor:
                              current == 'Portrait Up'
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                        ),
                      ),
                      Expanded(
                        child: buildMobileOutline(
                          label: 'Portrait Down',
                          context: context,
                          angle: pi,
                          borderColor:
                              current == 'Portrait Down'
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: buildMobileOutline(
                          label: 'Landscape Left',
                          context: context,
                          angle: -pi / 2,
                          borderColor:
                              current == 'Landscape Left'
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                        ),
                      ),
                      Expanded(
                        child: buildMobileOutline(
                          label: 'Landscape Right',
                          context: context,
                          angle: pi / 2,
                          borderColor:
                              current == 'Landscape Right'
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contestStarted = ref.watch(contestStartProvider);
    final isSubmit = ref.watch(
      contestEntryProvider.select((c) => c.submit != ContestSubmission.none),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: colorScheme.surfaceContainer)),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.scrim.withAlpha(30),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          BatteryStatusBar(key: batteryStatusBarKey),
          Container(
            padding: const EdgeInsets.only(left: 12),
            height: kToolbarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: colorScheme.surfaceContainerLowest,
                  child: Image.asset(
                    'assets/ic_launcher192.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tiixs',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                CustomMenu(
                  items:
                      isSubmit
                          ? const [
                            'Battery & Time',
                            'Brightness',
                            'Orientation',
                          ]
                          : [
                            'Battery & Time',
                            'Brightness',
                            'Orientation',
                            contestStarted ? 'Submit' : 'Quit',
                          ],
                  onSelected: (val) => _handleMenuSelection(context, val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileOutline({
    required BuildContext context,
    required String label,

    double width = 30,
    double height = 50,
    Color borderColor = Colors.black,
    double borderWidth = 3,
    double scale = 0.7,
    double angle = 0,
    double borderRadius = 6,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.all(0),
      onPressed: () => Navigator.pop(context, label),
      child: DataWidgetCard(
        label: label,
        child: Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Notch
                  Positioned(
                    top: 0,
                    child: Container(
                      width: width * 0.18,
                      height: height * 0.23,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderColor,
                      ),
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

  Future<bool?> showCfm(BuildContext context, {required String value}) {
    return showModalBottomSheet<bool>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withAlpha(40),
      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(0),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: colorScheme.scrim.withAlpha(30),
                  blurRadius: 10,
                  offset: const Offset(0, 12),
                ),
              ],
              borderRadius: BorderRadius.circular(30),
              border: Border.fromBorderSide(
                BorderSide(color: colorScheme.surfaceContainer),
              ),
              color: colorScheme.surfaceContainerLowest,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 30,
              children: [
                Flexible(child: Text('$value contest?')),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Expanded(
                      flex: 1,
                      child: FilledButton.tonal(
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(StadiumBorder()),

                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStatePropertyAll(
                            colorScheme.surfaceContainerLow,
                          ),
                        ),
                        onPressed: () {
                          Navigator.maybeOf(context)?.maybePop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: FilledButton(
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(StadiumBorder()),
                          overlayColor: WidgetStatePropertyAll(
                            Colors.red.withAlpha(20),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.red.withAlpha(20),
                          ),
                          foregroundColor: WidgetStatePropertyAll(Colors.red),
                        ),
                        onPressed: () {
                          Navigator.maybeOf(context)?.maybePop(true);
                        },
                        child: Text(value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomMenu extends StatelessWidget {
  final List<String> items;
  final Function(String) onSelected;

  const CustomMenu({Key? key, required this.items, required this.onSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      popUpAnimationStyle: AnimationStyle(
        curve: Curves.easeIn,
        duration: Duration(milliseconds: 300),
        reverseCurve: Curves.easeInOut,
        reverseDuration: Duration(milliseconds: 300),
      ),
      shadowColor: theme.colorScheme.scrim.withAlpha(50),
      position: PopupMenuPosition.under,
      // padding: EdgeInsets.symmetric(horizontal: 8),
      tooltip: 'Menu',
      elevation: 5,
      clipBehavior: Clip.antiAlias,

      // splashRadius: 20,
      color: theme.colorScheme.surfaceContainerLowest,

      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.surfaceContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) => onSelected(value),
      itemBuilder: (BuildContext context) {
        return List.generate(items.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Divider between custom items
            return PopupMenuDivider(
              color: theme.colorScheme.surfaceContainer,
              // thickness: 0,
              height: 0,
            );
          }
          final item = items[index ~/ 2];
          return PopupMenuItem<String>(
            onTap: null,
            value: item,

            padding: EdgeInsets.zero, // remove default padding
            height: 0,
            child: Builder(
              builder: (context) {
                return Container(
                  width: double.infinity,
                  // margin: EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item, style: theme.textTheme.bodyMedium),
                );
              },
            ),
          );
        });
      },
    );
  }
}

// statusBar
final batteryStatusBarKey = GlobalKey<_BatteryStatusBarState>();

class BatteryStatusBar extends StatefulWidget {
  const BatteryStatusBar({super.key, this.toggleAlignment});
  final VoidCallback? toggleAlignment;

  // final BuildContext context;

  @override
  State<BatteryStatusBar> createState() => _BatteryStatusBarState();
}

class _BatteryStatusBarState extends State<BatteryStatusBar> {
  MainAxisAlignment _alignment = MainAxisAlignment.spaceBetween;

  void toggleAlignment() {
    final values = MainAxisAlignment.values;
    final currentIndex = values.indexOf(_alignment);
    final nextIndex = (currentIndex + 1) % values.length;

    setState(() {
      _alignment = values[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final clock = ref.watch(globalClockProvider);
        final colorScheme = Theme.of(context).colorScheme;
        final mediaPadding = MediaQuery.paddingOf(context);
        final battery = ref.watch(batteryProvider);

        return SizedBox(
          height: mediaPadding.top,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: _alignment,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 6,
              children: [
                // Time
                Text(
                  DateFormat('h:mm a').format(clock).toString(),
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colorScheme.outline),
                ),
                // Battery
                battery.when(
                  data: (state) {
                    final lowColor = Colors.red;
                    final charginColor = Colors.green;
                    final level = state.level;
                    final isLow = level <= 15;
                    final charging = state.isCharging;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Battery body
                            Container(
                              width: 20,
                              height: 10,
                              // alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: colorScheme.outline),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: level,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                isLow
                                                    ? lowColor
                                                    : colorScheme
                                                        .primaryContainer,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(2),
                                                  bottomLeft: Radius.circular(
                                                    2,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 100 - level,
                                        child: SizedBox(),
                                      ),
                                    ],
                                  ),
                                  charging
                                      ? Transform.rotate(
                                        angle: -pi / 2,
                                        child: Icon(
                                          Icons.electric_bolt,
                                          size: 10,

                                          color: charginColor,
                                        ),
                                      )
                                      : SizedBox.shrink(),
                                ],
                              ),
                            ),
                            // Battery cap
                            Container(
                              width: 2,
                              height: 4,
                              margin: const EdgeInsets.only(left: .5),
                              decoration: BoxDecoration(
                                color: isLow ? lowColor : colorScheme.outline,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$level',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: isLow ? lowColor : colorScheme.outline,
                          ),
                        ),
                      ],
                    );
                  },
                  loading:
                      () => Text(
                        '...',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                  error:
                      (_, __) => Text(
                        '...',
                        style: TextStyle(color: colorScheme.outline),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
