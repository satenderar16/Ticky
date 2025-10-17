import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quthon/Contest/contest_entry.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/Contest/contest_notifier.dart';
import 'package:quthon/Service/dnd_service.dart';
import 'package:quthon/Test/dnd_checkbox.dart';
import 'package:quthon/Service/pinn_service.dart';
import 'package:quthon/Widgets/animated_loading.dart';
import 'package:quthon/Widgets/widgets.dart';
import 'contest_page_notifier.dart';

class ContestPage extends ConsumerStatefulWidget {
  const ContestPage({super.key});

  @override
  ConsumerState<ContestPage> createState() => _ContestPageState();
}

class _ContestPageState extends ConsumerState<ContestPage> {
  final actionKey =
      GlobalKey<_AnimatedActionButtonState>(); // bottom animated button:
  // final _screenCaptureEvent = ScreenCaptureEvent(true);
  @override
  void initState() {
    super.initState();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _startListening();
    Future.microtask(() async {
      await ref.read(contestPageProvider.notifier).getContestDetail();
    });
  }

  void _startListening() {
    // _screenCaptureEvent.preventAndroidScreenShot(true);
    // _screenCaptureEvent.addScreenShotListener((filePath) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text("Screenshot detected!")));
    // });

    // _screenCaptureEvent.watch();
  }

  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // _screenCaptureEvent.preventAndroidScreenShot(false);
    // _screenCaptureEvent.dispose();
    super.dispose();
  }

  String formatDateTime(DateTime dateTime) {
    final datePart = DateFormat('d MMM').format(dateTime);

    /// e.g. 4 Aug
    final timePart = DateFormat('h:mm a').format(dateTime);

    /// e.g. 3:00 PM
    return '$timePart\n$datePart';
  }

  Widget buildInstructionList(String? instruction) {
    if (instruction == null || instruction.isEmpty) {
      return const Text("No rules");
    }

    // Split instructions by "||" and trim spaces
    final rules = instruction.split("||").map((e) => e.trim()).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          rules.map((rule) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [Text('•'), Flexible(child: Text(rule))],
              ),
            );
          }).toList(),
    );
  }

  bool bottombool = false;
  void toggleBottom() {
    setState(() {
      bottombool = !bottombool;
    });
  }

  bool offStage = true;
  void toggleoffStage(bool value) {
    setState(() {
      offStage = value;
    });
  }

  // // dnd toggle
  // bool _dnd = false;
  // bool _pin = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contest = ref.watch(contestProvider).selectedContest!;

    final pageState = ref.watch(contestPageProvider);
    final pageNotifier = ref.watch(contestPageProvider.notifier);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        clipBehavior: Clip.antiAlias,
        // scrolledUnderElevation: 5,
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 1, color: colorScheme.surfaceContainer),
        ),
        // floating: true,
        surfaceTintColor: colorScheme.surfaceContainer,

        backgroundColor: colorScheme.surfaceContainerLowest,

        centerTitle: true,
        elevation: 4,
        shadowColor: colorScheme.scrim.withAlpha(40),

        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ContestEntry()),
              );
            },
            child: Text("byPass"),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: Builder(
          builder: (context) {
            if (pageState.isLoading) {
              return _loadingWidget(context);
            } else if (pageState.hasError) {
              return _errorWidget(context, error: pageState.errorMessage);
            } else {
              return Center(child: ContestPageBody());
            }
          },
        ),
      ),
      bottomNavigationBar: ContestPageNavBar(
        isLoading: pageState.isLoading,
        hasError: pageState.hasError,
        pageNotifier: pageNotifier,
        pageState: pageState,
        contest: contest,
      ),
    );
  }

  Widget _loadingWidget(BuildContext context) {
    return const Center(child: QuestionLoaderAnimation());
  }

  Widget _errorWidget(BuildContext context, {required String? error}) {
    final colorScheme = Theme.of(context).colorScheme;
    final contestPageNotifier = ref.read(contestPageProvider.notifier);
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Center(
              child: Image.asset(
                "assets/error_page.png",
                fit: BoxFit.contain,
                height: 250,
              ),
            ),
            Text(error ?? 'Something Went wrong'),
            TextButton(
              style: ButtonStyle(
                side: WidgetStatePropertyAll(
                  BorderSide(color: colorScheme.surfaceContainer),
                ),
              ),

              onPressed: contestPageNotifier.refreshContestDetail,
              child: Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Material closeIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: StadiumBorder(
        // side: BorderSide(color: colorScheme.surfaceContainer),
      ),
      color: colorScheme.scrim.withAlpha(130),
      child: InkWell(
        onTap: () {
          toggleBottom();
          actionKey.currentState?.toggle();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.close, color: Colors.white),
        ),
      ),
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

class ContestPageBody extends ConsumerStatefulWidget {
  const ContestPageBody({super.key});

  @override
  ConsumerState<ContestPageBody> createState() => _ContestPageBodyState();
}

class _ContestPageBodyState extends ConsumerState<ContestPageBody> {
  @override
  Widget build(BuildContext context) {
    // final padding = MediaQuery.of(context).padding;
    final contest = ref.watch(contestProvider).selectedContest!;
    final contestPageNotifier = ref.read(contestPageProvider.notifier);
    // final contestPageState = ref.watch(contestPageProvider);
    // final textTheme = TextTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final day = DateFormat('EEE').format(contest.schedulateAt);
    final date = DateFormat('d MMM').format(contest.schedulateAt);

    final entryTime = DateFormat('h:mm a').format(contest.schedulateAt);

    // ensurig the minimum time to have fetching the question and entry window:
    final startTime = DateFormat(
      'h:mm a',
    ).format(contest.startAt.subtract(Duration(seconds: 30)));

    final endTime = DateFormat('h:mm a').format(contest.endAt);
    final submissionTime = DateFormat(
      'h:mm a',
    ).format(contest.endAt.add(Duration(minutes: 10)));
    return RefreshIndicator(
      onRefresh: contestPageNotifier.refreshContestDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          SizedBox(height: 12),
          StyledContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          contest.name,
                          style: TextTheme.of(context).titleMedium,
                        ),
                      ),

                      VerticalDivider(
                        width: 0,
                        color: colorScheme.surfaceContainer,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Text(day, style: TextTheme.of(context).bodyLarge),
                          Text(date),
                        ],
                      ),
                    ],
                  ),
                ),

                Text(
                  contest.description!,
                  style: TextTheme.of(context).bodyMedium,
                ),
                Wrap(
                  spacing: 10,
                  runAlignment: WrapAlignment.center,
                  alignment: WrapAlignment.center,
                  runSpacing: 10,
                  children: [
                    DataHorizontalCard(label: 'Entry Start', time: entryTime),
                    DataHorizontalCard(label: 'Contest Begin', time: startTime),
                    DataHorizontalCard(label: 'Contest End', time: endTime),
                    DataHorizontalCard(
                      label: 'Sumission Before',
                      time: submissionTime,
                    ),
                  ],
                ),
                Divider(color: colorScheme.surfaceContainer, height: 0),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  runAlignment: WrapAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    DataLabelCard(
                      label: 'Questions',
                      data: contest.numberOfQuestions.toString(),
                    ),
                    DataLabelCard(
                      label: 'Duration',
                      data: contest.timeDuration.inMinutes.toString(),
                    ),
                    DataLabelCard(
                      label: 'status',
                      data: contest.status?.name.toString() ?? '',
                    ),
                    DataLabelCard(
                      label: 'Mode',
                      data: contest.timeDistribution.name,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),

          StyledContainer(
            child: Column(
              spacing: 10,
              children: [
                Text("Rules".toUpperCase()),
                Divider(height: 0, color: colorScheme.surfaceContainer),

                buildInstructionList(contest.instruction),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInstructionList(String? instruction) {
    if (instruction == null || instruction.isEmpty) {
      return const Text("No rules");
    }

    // Split instructions by "||" and trim spaces
    final rules = instruction.split("||").map((e) => e.trim()).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          rules.map((rule) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [Text('•'), Flexible(child: Text(rule))],
              ),
            );
          }).toList(),
    );
  }
}

class ContestPageNavBar extends StatefulWidget {
  final bool isLoading;
  final bool hasError;
  final ContestPageNotifier pageNotifier;
  final ContestPageState pageState;
  final ContestDetailModel contest;

  const ContestPageNavBar({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.pageNotifier,
    required this.pageState,
    required this.contest,
  });

  @override
  State<ContestPageNavBar> createState() => _ContestPageNavBarState();
}

class _ContestPageNavBarState extends State<ContestPageNavBar> {
  bool bottomOpen = false;
  bool offStage = true;

  late bool _dnd = false;
  late bool _pin = false;

  @override
  void initState() {
    Future.microtask(() async {
      final granted = await DndService.isPermissionGranted();
      if (granted) {
        final filter = await DndService.getCurrentFilter();
        _dnd = filter == DndFilter.none; // all notification off
      }
      final pinned = await PinService.getStatus();
      _pin = pinned == 2; // 2 ->PinState.pinned:
    });

    super.initState();
  }

  final btmAmtionBtm = GlobalKey<_AnimatedActionButtonState>();

  void toggleBottom() {
    setState(() {
      bottomOpen = !bottomOpen;
    });
  }

  void toggleOffStage(bool value) {
    setState(() {
      offStage = value;
    });
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
          padding: EdgeInsets.only(bottom: mediaPadding.bottom + 40),
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

  String formatDateTime(DateTime dateTime) {
    final datePart = DateFormat('d MMM').format(dateTime);

    /// e.g. 4 Aug
    final timePart = DateFormat('h:mm a').format(dateTime);

    /// e.g. 3:00 PM
    return '$timePart\n$datePart';
  }

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);

    if (widget.isLoading || widget.hasError) return const SizedBox.shrink();
    final mediaPadding = MediaQuery.paddingOf(context);
    final partici = widget.contest.participate != null;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnimatedActionButton(
        key: btmAmtionBtm,
        firstChild: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: mediaPadding.bottom + 24,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(0),
                      sizeStyle: CupertinoButtonSize.medium,
                      onPressed:
                          partici
                              ? () {
                                btmAmtionBtm.currentState?.toggle();
                              }
                              : () async {
                                if (!mounted) return;
                                setState(() {
                                  _loading = !_loading;
                                });
                                try {
                                  final msg =
                                      await widget.pageNotifier
                                          .participateContest();
                                  if (context.mounted) {
                                    showStyledSnackBar(
                                      context,
                                      message: msg.toString(),
                                      color: Colors.green,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showStyledSnackBar(
                                      context,
                                      message: e.toString(),
                                      color: Colors.red,
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() {
                                      _loading = !_loading;
                                    });
                                  }
                                }
                              },
                      child: StyledContainer(
                        margin: EdgeInsetsGeometry.zero,
                        offset: const Offset(0, 12),
                        child:
                            partici
                                ? Center(
                                  child: Text(
                                    'Accept and Continue',
                                    style: TextTheme.of(context).labelLarge
                                        ?.copyWith(color: colorScheme.primary),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                : Row(
                                  spacing: 6,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_loading) ...[
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      Text(
                                        'Waiting...',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                    ],

                                    if (!_loading)
                                      Text(
                                        'Participate',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        secondChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildCloseIcon(context), _buildBottomSheet(context)],
        ),
      ),
    );
  }

  void showStyledSnackBar(
    BuildContext context, {
    required String message,
    Color? color,
    Duration duration = const Duration(seconds: 1),
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        elevation: 0,
        dismissDirection: DismissDirection.horizontal,
        backgroundColor: colorScheme.surface.withAlpha(0),
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350, maxHeight: 100),
              child: StyledContainer(
                boxShadow: const [],
                margin:
                    EdgeInsetsGeometry.lerp(
                      EdgeInsets.zero,
                      EdgeInsets.zero,
                      0,
                    )!,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color ?? Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: () {
        toggleBottom();
        btmAmtionBtm.currentState?.toggle();
      },
      icon: Icon(Icons.close_rounded, color: colorScheme.outline),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colorScheme.surfaceContainer)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: colorScheme.scrim.withAlpha(30)),
        ],
      ),
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // DND toggle
          CustomCheckTile(
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

          // PIN toggle
          Row(
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
                    await PinService.startPin();
                  }
                },
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed:
                    _pin
                        ? null
                        : () async {
                          final isPinned = await PinService.getStatus();
                          if (isPinned == 2 && !_pin) {
                            setState(() => _pin = true);
                          }
                        },
                child: Text(
                  'Confirm Pin',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        _pin ? colorScheme.outlineVariant : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          // Participate button
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: AsyncActionBottomBar(
                onSubmit:
                    (!_dnd && !_pin)
                        ? null
                        : () async {
                          // //
                          // final pin = await PinService.getStatus();
                          // final dnd = await DndService.isDndCurrentlyEnabled();

                          // if (pin != 2 || !dnd) {
                          //   setState(() {
                          //     _pin = pin == 2;
                          //     _dnd = dnd;
                          //   });
                          //   throw 'Please Enable Dnd and Pin Mode';
                          // }
                          // await Future.delayed(
                          //   const Duration(milliseconds: 200),
                          // );
                          // final now = DateTime.now();
                          // final contest = widget.contest;

                          // if (!now.isAfter(contest.schedulateAt)) {
                          //   throw 'Contest is scheduled at ${formatDateTime(contest.schedulateAt)}';
                          // }
                          // if (!now.isBefore(
                          //   contest.startAt.subtract(
                          //     const Duration(seconds: 30),
                          //   ),
                          // )) {
                          //   throw 'Contest already began';
                          // }
                          // if (now.isAfter(contest.endAt)) {
                          //   throw 'Contest Ended';
                          // }

                          await widget.pageNotifier.joinContest();
                        },
                onSuccess:
                    (!_dnd && !_pin)
                        ? null
                        : () async {
                          final pin = await PinService.getStatus();
                          final dnd = await DndService.isDndCurrentlyEnabled();

                          if (pin != 2 || !dnd) {
                            setState(() {
                              _pin = pin == 2;
                              _dnd = dnd;
                            });
                            throw 'Please Enable Dnd and Pin Mode';
                          }
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,

                              MaterialPageRoute(
                                builder: (_) => const ContestEntry(),
                              ),
                            );
                          }
                        },
                builder: (context, state) {
                  final colorScheme = Theme.of(context).colorScheme;
                  final style = Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colorScheme.primary);

                  switch (state) {
                    case "loading":
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Joining...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      );
                    case "retry":
                      return Text('Try Again', style: style);
                    case "complete":
                      return Text(
                        'Continue',
                        style: style?.copyWith(
                          color:
                              (_dnd && _pin)
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                        ),
                      );
                    default:
                      return Text(
                        'Participate',
                        style: style?.copyWith(
                          color:
                              (_dnd && _pin)
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                        ),
                      );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedActionButton extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final bool initiallySecond;

  const AnimatedActionButton({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.initiallySecond = false,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _firstSlide; //ignore:
  late final Animation<Offset> _secondSlide;
  late final Animation<double> _firstFade;
  late final Animation<double> _secondFade;

  late bool _showSecond;

  @override
  void initState() {
    super.initState();

    _showSecond = widget.initiallySecond;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _firstSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _secondSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _firstFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _secondFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_showSecond) _controller.value = 1;
  }

  void toggle() {
    setState(() {
      _showSecond = !_showSecond;
      _showSecond ? _controller.forward() : _controller.reverse();
    });
  }

  bool get _isFirstOffstage => _controller.value > 0.99;
  bool get _isSecondOffstage => _controller.value < 0.01;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // First child — fades out, slides up, then offstage
            Offstage(
              offstage: _isFirstOffstage,
              child: FadeTransition(
                opacity: _firstFade,
                child: widget.firstChild,
              ),
            ),

            // Second child — fades in, slides up, then visible
            Offstage(
              offstage: _isSecondOffstage,
              child: FadeTransition(
                opacity: _secondFade,
                child: SlideTransition(
                  position: _secondSlide,
                  child: widget.secondChild,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
