import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:quthon/Contest/Page/contest_body.dart';
import 'package:quthon/Contest/Page/contest_page.dart';
import 'package:quthon/Contest/Page/entry_body.dart';
import 'package:quthon/Contest/contest_entry_notifier.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/DashBoard/RegistrationPage/participates_screen.dart';
import 'package:quthon/Service/battery_service.dart';
import 'package:quthon/Service/brightness_service.dart';
import 'package:quthon/Service/dnd_service.dart';
import 'package:quthon/Service/pin_service.dart';
import 'package:quthon/Service/wake_class.dart';
import 'package:quthon/Utilies/current_contest_provider.dart';
import 'package:quthon/Widgets/overlay.dart';
import 'package:quthon/Widgets/widgets.dart';
import 'package:screen_capture_event/screen_capture_event.dart';

class SecureWidget extends ConsumerStatefulWidget {
  final bool? pin;
  final bool? dnd;
  final bool? autoRotation;
  final int unknownFallbackCount;
  const SecureWidget({
    super.key,
    this.pin,
    this.dnd,
    this.autoRotation,
    this.unknownFallbackCount = 2,
  });
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SecureWidget();
}

class _SecureWidget extends ConsumerState<SecureWidget>
    with WidgetsBindingObserver {
  bool isSubmit = false;
  //globalkey for dismissing the fallback dialog if user unpinned during the fallback case:
  final _fallbackKey = GlobalKey<_FallbackOverlayState>();

  // pin mode
  late bool _pin;
  bool pinFlag = false;

  // dnd mode:
  late bool _dnd;

  // orientation:
  late NativeDeviceOrientation _lastOrientation;
  late NativeDeviceOrientation _currentOrientation;
  late bool autoRotation;
  StreamSubscription<NativeDeviceOrientation>? _orientationSub;

  // screen shot:
  final _screenCaptureEvent = ScreenCaptureEvent(true);
  String? ssPath;
  bool ssDialogActive = false;

  // fallback case with n limit count

  late int fallbackCount;
  bool fallbackDialogActive = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pin = widget.pin ?? false;
    _dnd = widget.dnd ?? false;
    fallbackCount = widget.unknownFallbackCount;
    autoRotation = widget.autoRotation ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _lockCurrentOrientation(initial: true);
      final pin = await PinService.getStatus() == 2;
      final dnd = await DndService.getCurrentFilter() == DndFilter.none;

      _startListening();
      setState(() {
        _pin = pin;
        _dnd = dnd;
      });
      await WakeClass.enable();
    });

    super.initState();
  }

  @override
  void dispose() {
    debugPrint('secure widget is being disposed:');
    WidgetsBinding.instance.removeObserver(this);
    WakeClass.disable();
    BrightnessService.restore();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _screenCaptureEvent.preventAndroidScreenShot(false);
    _screenCaptureEvent.dispose();
    super.dispose();
  }

  // screen shots ----------------------->
  void _startListening() {
    _screenCaptureEvent.preventAndroidScreenShot(true);
    _screenCaptureEvent.addScreenShotListener((filePath) {
      if (ssPath == filePath) return;
      setState(() {
        ssPath = filePath;
      });
    });

    _screenCaptureEvent.watch();
  }

  void _showScreenShotDialog() {
    if (!mounted || ssDialogActive) return;
    ssDialogActive = true;
    showModalBottomSheet(
      context: context,
      // isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            width: double.maxFinite,
            child: StyledContainer(
              boxShadow: [],
              margin: EdgeInsetsGeometry.only(bottom: 20, left: 16, right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Screenshots are not allowed',
                style: TextTheme.of(context).bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    ).then((value) {
      ssDialogActive = false;
      ssPath = null;
    });
  }

  // rotation ---------------------------------->
  Future<void> _lockCurrentOrientation({bool initial = false}) async {
    final orientation = await NativeDeviceOrientationCommunicator().orientation(
      useSensor: !initial,
    ); // not use sensor to get current orientation:
    final List<DeviceOrientation> locked;
    switch (orientation) {
      case NativeDeviceOrientation.portraitUp:
        locked = [DeviceOrientation.portraitUp];

        break;
      case NativeDeviceOrientation.portraitDown:
        locked = [DeviceOrientation.portraitDown];

        break;
      case NativeDeviceOrientation.landscapeLeft:
        locked = [DeviceOrientation.landscapeLeft];

        break;
      case NativeDeviceOrientation.landscapeRight:
        locked = [DeviceOrientation.landscapeRight];

        break;
      default:
        locked = [DeviceOrientation.portraitUp];
    }
    _orientationSub?.cancel();
    _orientationSub = null;

    await SystemChrome.setPreferredOrientations(locked);

    if (initial) {
      _lastOrientation = orientation;
      _currentOrientation = orientation;
    }
    if (!initial && mounted) {
      setState(() {
        autoRotation = false;
      });
    }
  }

  // Future<void> _enableAutoRotation() async {
  //   await SystemChrome.setPreferredOrientations([
  //     DeviceOrientation.portraitUp,
  //     DeviceOrientation.portraitDown,
  //     DeviceOrientation.landscapeLeft,
  //     DeviceOrientation.landscapeRight,
  //   ]);

  //   // Listen for rotation changes
  //   _orientationSub = NativeDeviceOrientationCommunicator()
  //       .onOrientationChanged(useSensor: true)
  //       .listen((newOrientation) {
  //         if (newOrientation == _currentOrientation) return;

  //         _lastOrientation = _currentOrientation;
  //         _currentOrientation = newOrientation;
  //       });
  //   setState(() {
  //     autoRotation = true;
  //   });
  // }

  // void _toggleAutoRotation() async {
  //   if (autoRotation) {
  //     // await AutoRotate.followSystemRotation();
  //     await _lockCurrentOrientation();
  //   } else {
  //     // await AutoRotate.ignoreSystemRotation();
  //     await _enableAutoRotation();
  //   }
  // }

  // pinning ------------------------------------->
  void togglePin() async {
    if (!_pin) {
      await PinService.startPin();
      if (mounted) {
        setState(() {
          _pin = true;
        });
      }
    } else {
      await PinService.stopPin();
      if (!mounted) return;
      setState(() {
        _pin = false;
      });
    }
  }

  void _showPinDialog() {
    if (!mounted || pinFlag) return; // either of dialog is available at a time:
    pinFlag = true;
    if (fallbackDialogActive) {
      _fallbackKey.currentState?.confirmDismissed(callConfim: false);
    }

    late final CustomOverlay overlay;

    overlay = CustomOverlay(
      child: PinViolationOverlay(
        onDismiss: () async {
          if (!mounted) return; //quit update:
          //save data
          final contestType =
              ref.read(contestEntryProvider).contest.timeDistribution;
          final notifier = ref.read(contestEntryProvider.notifier);
          // debugPrint('Pin saving data \n');

          //even if user dismissed the dialog we persist again if have to: also handle the fallback case to perist answers:
          await notifier.persistAnswers(contestType: contestType);

          debugPrint('Pin  moving to submissionPage:');
          if (contestType == TimeDistribution.free) {
            notifier.contestSubmission(ContestSubmission.interrupted);
          } else {
            notifier.unifromContestSubmission(ContestSubmission.interrupted);
          }

          overlay.remove();
        },
      ),
    );

    overlay.show(context);
  }

  //dnd ------------------------------------>

  void toggleDND() async {
    if (!_dnd) {
      await DndService.enableDnd();
      if (mounted) {
        setState(() {
          _dnd = true;
        });
      }
    } else {
      await DndService.disableDnd();
      if (!mounted) return;
      setState(() {
        _dnd = false;
      });
    }
  }

  //fallback------------------------------>

  void _showUnknownInterruptDialog() {
    if (!mounted || fallbackDialogActive || pinFlag) return;
    fallbackDialogActive = true;
    fallbackCount = fallbackCount - 1;

    Future<void> persistAndSubmit() async {
      //save data
      final contestType =
          ref.read(contestEntryProvider).contest.timeDistribution;
      final notifier = ref.read(contestEntryProvider.notifier);
      debugPrint('fallback saving data \n');
      await notifier.persistAnswers(contestType: contestType);

      debugPrint('fallaback  moving to submissionPage:');
      if (contestType == TimeDistribution.free) {
        notifier.contestSubmission(ContestSubmission.interrupted);
      } else {
        notifier.unifromContestSubmission(ContestSubmission.interrupted);
      }
    }

    late final CustomOverlay overlay;

    overlay = CustomOverlay(
      child: FallbackOverlay(
        key: _fallbackKey,
        initialSeconds: 5,
        onConfirm: () async {
          fallbackDialogActive = false;
          debugPrint('confirmed and attempted is: $fallbackCount');
          if (fallbackCount.isNegative) {
            debugPrint('fallback multiple: fails');
            await persistAndSubmit();
          }
          overlay.remove();
        },
        onDismiss: () async {
          await persistAndSubmit();
          overlay.remove();
        },
      ),
    );

    overlay.show(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_pin == false || isSubmit) {
      return;
    }
    debugPrint('applifestate is : $state \n');
    final pin = await PinService.getStatus();
    //state changes and not pinned save the data:
    if (pin != 2) {
      // save data
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        debugPrint('saving data '); //persistant answers:
        // detect the unpinned directly persist answers:
        final contestType =
            ref.read(contestEntryProvider).contest.timeDistribution;
        final notifier = ref.read(contestEntryProvider.notifier);
        debugPrint('Pin saving data \n');

        await notifier.persistAnswers(contestType: contestType);
      }

      // not pinned and onResume show dialog
      if (state == AppLifecycleState.resumed) {
        // check if saved data is as in memory:

        _showPinDialog();

        //set pinned to false :avoid calling function multiple times:
        setState(() {
          _pin = false;
        });
      }
      return;
    }

    // state is pause or inactive:
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // look for the s.s.
      if (ssPath != null) {
        _showScreenShotDialog();
        return;
      }

      // look for orientation
      if (_lastOrientation != _currentOrientation) {
        _lastOrientation =
            _currentOrientation; // implies noted. not fallback case:focus loses due to orientation:
        // _showUnknownInterrupt();
        return;
      }

      // fallback case when user loses focus due to unknown reason in pinned mode:
      if (!fallbackCount.isNegative && !fallbackDialogActive) {
        _showUnknownInterruptDialog();
      }
    }

    // //state is resume:
    // if (state == AppLifecycleState.resumed) {
    //   // look for dnd:
    // if (_dnd) {
    //   final getdnd = await DndService.getCurrentFilter() == DndFilter.none;
    //   if (!getdnd) {
    //     debugPrint('hey don\'t you dare to touch dnd again');
    //     await DndService.enableDnd();
    //   }
    // }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaPadding = MediaQuery.paddingOf(context);
    final submitted = ref.watch(
      contestEntryProvider.select((s) => s.submit != ContestSubmission.none),
    );
    isSubmit = submitted;

    final isStarted = ref.watch(contestStartProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {},
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  final questionIndex = ref.watch(
                    contestEntryProvider.select((c) => c.currentIndex),
                  );

                  final dndFilter = ref.watch(dndProvider);
                  // less  priority:
                  if (dndFilter.hasValue) {
                    if (!_dnd || submitted) {
                    } else {
                      // immediated
                      Future.microtask(() async {
                        final getdnd = dndFilter.value == DndFilter.none;
                        if (!getdnd) {
                          // show snackbar:

                          await DndService.enableDnd();
                        }
                      });
                    }
                  }

                  ///TODO thitiis here:
                  Future.delayed(Duration.zero, () async {
                    if (!_pin || submitted) return;
                    final pin = await PinService.getStatus() == 2;

                    if (pin || !mounted) return;
                    _showPinDialog();

                    //set pinned to false :avoid calling function multiple times:
                    // if(!mounted)return;
                    // setState(() {
                    //   _pin = false;
                    // }); after this user redirect to submit page: and even user close the app we just gonna persist the answers again. we can simply avoid multiple save by check is there is entry or not:
                  });

                  return SizedBox.shrink();
                },
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(
                top: mediaPadding.top + kToolbarHeight,
              ),

              child:
                  isStarted
                      ? const ContestBody(key: ValueKey('contestBodyKey'))
                      : const EntryBody(key: ValueKey('contestEntryBodyKey')),
            ),

            LogoAppBar(),
          ],
        ),
      ),
    );
  }
}

class FallbackOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback? onConfirm; // new: callback when user confirms
  final int initialSeconds; // allow custom initial time

  const FallbackOverlay({
    super.key,
    required this.onDismiss,
    this.onConfirm,
    this.initialSeconds = 5,
  });

  @override
  State<FallbackOverlay> createState() => _FallbackOverlayState();
}

class _FallbackOverlayState extends State<FallbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _fade;

  late int _remainingSeconds;
  Timer? _autoDismissTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _remainingSeconds = widget.initialSeconds;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _position = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _autoDismissTimer = Timer(Duration(seconds: _remainingSeconds), _dismiss);

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

  Future<void> confirmDismissed({bool callConfim = true}) async {
    if (_remainingSeconds < 1) return;

    _autoDismissTimer?.cancel();
    _countdownTimer?.cancel();
    await _controller.reverse();
    if (widget.onConfirm != null && callConfim) {
      widget.onConfirm?.call();
    }
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
            child: Container(color: Colors.transparent),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Contest Interrupted',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        Divider(color: colorScheme.surfaceContainer),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Are you alive? Please Confirm\t',
                              ),
                              TextSpan(
                                text: _remainingSeconds.toString(),
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
                            onPressed: confirmDismissed,
                            child: const Text("yes"),
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
        // Positioned.fill(
        //   child: FadeTransition(
        //     opacity: _fade,
        //     child: GestureDetector(
        //       onTap: _dismiss,
        //       child: Container(color: Colors.transparent),
        //     ),
        //   ),
        // ),
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

class LogoAppBar extends ConsumerStatefulWidget {
  const LogoAppBar({super.key, this.currentOrientation});

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
          // ref.invalidate(dndProvider);
          final pagearrived = ref.read(currentContestProvider).source;
          if (pagearrived == ContestSource.live) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ContestPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ParticipatedPage()),
            );
          }

          // await PinService.stopPin();
          // await DndService.disableDnd();
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
          final contestType =
              ref.read(contestEntryProvider).contest.timeDistribution;
          final notifier = ref.read(contestEntryProvider.notifier);
          await notifier.persistAnswers(contestType: contestType);
          if (contestType == TimeDistribution.free) {
            notifier.contestSubmission(ContestSubmission.submit);
          } else {
            notifier.unifromContestSubmission(ContestSubmission.submit);
          }
        }

        break;

      default:
        // Optional: handle unknown values
        break;
    }
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
                // Material(
                //   color: colorScheme.surfaceContainerLowest,
                //   child: Image.asset(
                //     'assets/ic_launcher192.png',
                //     fit: BoxFit.contain,
                //   ),
                // ),
                // const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tikcy',
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                CustomMenu(
                  items:
                      isSubmit
                          ? const ['Battery & Time', 'Brightness']
                          : [
                            'Battery & Time',
                            'Brightness',

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
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<bool>(
      context: context,
      barrierColor: colorScheme.scrim.withAlpha(40),
      backgroundColor: colorScheme.primary.withAlpha(0),
      //Update with matching UI hope suits :
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final mediaPadding = MediaQuery.paddingOf(context);
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: mediaPadding.bottom + 12,
              left: 20,
              right: 20,
            ),
            child: StyledContainer(
              border: Border.fromBorderSide(
                BorderSide(
                  // TODO make sure to update this so we only as we are only using th styled container property:
                  color: colorScheme.surfaceContainer,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              padding: EdgeInsets.all(12),
              color: colorScheme.surfaceContainerLowest,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value Contest?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: ButtonStyle(
                            side: WidgetStatePropertyAll(
                              BorderSide(color: colorScheme.surfaceContainer),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(value),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Cancel"),
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
}

class CustomMenu extends StatelessWidget {
  final List<String> items;
  final Function(String) onSelected;

  const CustomMenu({super.key, required this.items, required this.onSelected});

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

// statusBar we can move this in appbar bar but as when the appbar rebuild the entire batterystatusbar changes it state:
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
