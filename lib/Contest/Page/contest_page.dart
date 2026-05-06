import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/Contest/contest_notifier.dart';
// import 'package:quthon/Service/rotation_service.dart';
import 'package:quthon/Utilies/current_contest_provider.dart';
import 'package:quthon/Utilies/secure_widget.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/custom_grid.dart';
import 'package:quthon/Widgets/widgets.dart';

class ContestPage extends ConsumerStatefulWidget {
  const ContestPage({super.key});

  @override
  ConsumerState<ContestPage> createState() =>
      _ContestPageAlternativStateState();
}

class _ContestPageAlternativStateState extends ConsumerState<ContestPage> {
  late AsyncValue<ContestDetailModel> _asyncContest;

  ///Nav bar -------------------------------------------->
  bool showNavBar = false;
  void toggleShowNavbar() {
    setState(() {
      showNavBar = !showNavBar;
    });
  }

  @override
  void initState() {
    _asyncContest = AsyncLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initial =
            await ref.read(contestProvider.notifier).getContestDetail();
        if (!mounted) return;
        setState(() {
          _asyncContest = AsyncData(initial);
        });
      } catch (e, st) {
        if (!mounted) return;
        setState(() {
          _asyncContest = AsyncError(e, st);
        });
      }
    });
    super.initState();
  }

  Future<void> _onRefresh() async {
    try {
      if (_asyncContest.isLoading) return;

      final contest = await ref
          .read(contestProvider.notifier)
          .getContestDetail(refresh: true);

      if (!mounted) return;
      // the dual safty update the state which cause the janks if we receive fast retrivals
      setState(() {
        _asyncContest = AsyncData(contest);
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _asyncContest = AsyncError(e, st);
      });
    }
  }

  List<({String label, String time})> timeTile() {
    final contest = ref.read(contestProvider).selectedContest!;

    final entryTime = DateFormat('h:mm a').format(contest.scheduleAt);
    final startTime = DateFormat('h:mm a').format(contest.startAt);
    final endTime = DateFormat('h:mm a').format(contest.endAt);
    // final submissionTime = DateFormat(
    //   'h:mm a',
    // ).format(contest.endAt.add(const Duration(minutes: 10)));

    return [
      (label: 'Join', time: entryTime),
      (label: 'Join End', time: startTime),
      (label: 'Start', time: startTime),
      (label: 'End', time: endTime),
      // (label: 'End', time: endTime),
    ];
  }

  // Widget buildInstructionList(String? instruction) {
  //   if (instruction == null || instruction.isEmpty) {
  //     return const Text("No rules");
  //   }

  //   // Split instructions by "||" and trim spaces
  //   final rules = instruction.split("||").map((e) => e.trim()).toList();

  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children:
  //         rules.map((rule) {
  //           return Padding(
  //             padding: const EdgeInsets.symmetric(vertical: 4),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               spacing: 6,
  //               children: [Text('•'), Flexible(child: Text(rule))],
  //             ),
  //           );
  //         }).toList(),
  //   );
  // }

  // contest participation and joining:

  Future<String?> _participateCallBack() async {
    final contest = ref.read(contestProvider).selectedContest!;

    if (contest.scheduleAt.isBefore(DateTime.now())) {
      throw 'Participation closed';
    }
    return await ref.read(contestProvider.notifier).postContestParticipate();
  }

  String formatDuration(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);
    int seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '0m ${seconds}s';
    }
  }

  // server
  Future<String?> _joinedContest() async {
    // call server if timing is in between the  start and end_at:
    final contest = ref.read(contestProvider).selectedContest!;
    final now = DateTime.now();
    // before joined allowed:
    if (contest.scheduleAt.isAfter(now)) {
      final String timein = formatDuration(contest.scheduleAt.difference(now));
      throw 'Contest will start in $timein';
    }

    // after contest started try to take entry :
    if (contest.startAt.isBefore(now)) {
      throw 'Joining closed.';
    }

    // request server also update the contestDetail:
    return await ref.read(contestProvider.notifier).joinContest();
  }

  void _successjoined() {
    // navigate to contestEntry: with currentCOntest Provider to update it:
    ref
        .read(currentContestProvider.notifier)
        .update(
          (state) => state.copyWith(
            contest: ref.read(contestProvider).selectedContest!,
            source: ContestSource.live,
          ),
        );

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(builder: (_) => const SecureWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    // final notifier = ref.watch(contestProvider.notifier);
    final contest = ref.watch(contestProvider).selectedContest!;
    final hasAsyncData = (!_asyncContest.isLoading && !_asyncContest.hasError);
    if (hasAsyncData) {
      _asyncContest = _asyncContest.copyWithPrevious(AsyncData(contest));
    }

    final day = DateFormat('EEE').format(contest.scheduleAt);
    final date = DateFormat('d MMM').format(contest.scheduleAt);
    final entryTime = DateFormat(
      'h:mm a',
    ).format(contest.scheduleAt); // using for participation note:
    final List<({String label, String time})> timeTiles = timeTile();

    final participated = contest.participatedAt != null;

    return Scaffold(
      extendBody: true,
      appBar: _appbar(context),
      body: RefreshIndicator(
        onRefresh: _onRefresh,

        child: CustomScrollView(
          physics:
              _asyncContest.isLoading
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
          slivers: [
            _asyncContest.when(
              data: (contest) {
                return SliverPadding(
                  padding: EdgeInsetsGeometry.symmetric(vertical: 12),
                  sliver: SliverToBoxAdapter(
                    child: ListView(
                      // spacing: 10,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap:
                          true, //COULD be dangerous for the larger list rendering:
                      children: [
                        //title container:
                        StyledContainer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                        style: TextTheme.of(
                                          context,
                                        ).titleMedium?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),

                                    VerticalDivider(
                                      width: 0,
                                      color: colorScheme.surfaceContainer,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,

                                      children: [
                                        Text(
                                          day,
                                          style:
                                              TextTheme.of(context).bodyLarge,
                                        ),
                                        Text(date),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                contest.description,
                                style: TextTheme.of(context).bodyMedium,
                              ),

                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 600),
                                  child: CustomGrid(
                                    childWidth: 120,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,

                                    children:
                                        timeTiles.map((t) {
                                          final (:label, :time) = t;
                                          return DataHorizontalCard(
                                            label: label,
                                            time: time,
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                              Divider(
                                color: colorScheme.surfaceContainer,
                                height: 0,
                              ),

                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 600),
                                  child: CustomGrid(
                                    mainAxisSpacing: 10,

                                    // ), // crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    childWidth: 100,
                                    children: [
                                      DataLabelCard(
                                        label: 'Questions',
                                        data: contest.questionCount.toString(),
                                      ),
                                      DataLabelCard(
                                        label: 'Duration',
                                        data:
                                            contest.timeDuration.inMinutes
                                                .toString(),
                                      ),
                                      DataLabelCard(
                                        label: 'status',
                                        data: contest.status.name.toString(),
                                      ),
                                      DataLabelCard(
                                        label: 'Mode',
                                        data: contest.timeDistribution.name,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(
                                color: colorScheme.surfaceContainer,
                                height: 0,
                              ),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NOTE',
                                      style: TextStyle(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    VerticalDivider(
                                      color: colorScheme.surfaceContainer,
                                      // width: 0,
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Participation only allowed before $entryTime',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),

                        // instruction container:
                        StyledContainer(
                          child: Column(
                            spacing: 10,
                            children: [
                              Text('Instruction', style: textTheme.titleSmall),
                              Divider(
                                height: 0,
                                color: colorScheme.surfaceContainer,
                              ),

                              Text(
                                contest.instruction ?? 'No instruction',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },

              error:
                  (e, st) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 250),
                              child: Image.asset(
                                'assets/error_page.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              loading:
                  () => SliverFillRemaining(
                    hasScrollBody: false,
                    // hasScrollBody: false,
                    // padding: EdgeInsetsGeometry.all(0),
                    child: Center(child: ThreeDotWave(amplitude: 0)),
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          hasAsyncData
              ? Stack(
                alignment: AlignmentGeometry.bottomCenter,
                children: [
                  //participation button :
                  AnimatedSlide(
                    duration: Duration(milliseconds: 300),
                    offset: Offset(0, showNavBar ? 1 : 0),
                    // offstage: showNavBar,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 350),
                      child: SizedBox(
                        width: double.maxFinite,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: mediaPadding.bottom + 24,
                            left: 16.0,
                            right: 16.0,
                          ),
                          child: Column(
                            spacing: 4,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AsyncButton(
                                onPressedAsync:
                                    contest.scheduleAt.isBefore(
                                              DateTime.now(),
                                            ) &&
                                            !participated
                                        ? null
                                        : _participateCallBack,
                                callContinue: participated,
                                onSuccess: toggleShowNavbar,
                                // loadingText: ,
                                continueText: 'Accept & Continue',
                                childText: 'Participate',
                                buttonStyle:
                                    !participated
                                        ? null
                                        : ButtonStyle(
                                          side: WidgetStatePropertyAll(
                                            BorderSide(
                                              color:
                                                  colorScheme.surfaceContainer,
                                            ),
                                          ),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                colorScheme
                                                    .surfaceContainerLowest,
                                              ),
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                                colorScheme.primary,
                                              ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                retryText: 'Try again',
                              ),
                              // if (contest.scheduleAt.isBefore(DateTime.now()) &&
                              //     contest.participatedAt == null)
                              //   Container(
                              //     padding: EdgeInsets.symmetric(
                              //       horizontal: 12,
                              //       vertical: 6,
                              //     ),
                              //     decoration: ShapeDecoration(
                              //       shape: StadiumBorder(),
                              //       color: colorScheme.secondaryContainer,
                              //     ),
                              //     child: Text(
                              //       'Participation closed',
                              //       style: TextTheme.of(
                              //         context,
                              //       ).labelSmall?.copyWith(
                              //         color: colorScheme.onSurfaceVariant,
                              //       ),
                              //     ),
                              //   ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // joining button :
                  AnimatedUpDown(
                    duration: Duration(milliseconds: 300),
                    active: showNavBar,

                    autoHideDuration: null,
                    enableFade: false,
                    child: ContestJoiningSheet(
                      onPressedAsync: _joinedContest,
                      onSuccess: _successjoined,
                      onToggle: toggleShowNavbar,
                    ),
                  ),
                ],
              )
              : null,
    );
  }

  AppBar _appbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      clipBehavior: Clip.antiAlias,
      scrolledUnderElevation: 4,
      surfaceTintColor: colorScheme.surfaceContainer,

      backgroundColor: colorScheme.surfaceContainerLowest,

      centerTitle: true,

      shadowColor: colorScheme.scrim.withAlpha(40),

      // actions: [TextButton(onPressed: () async {}, child: Text("byPass"))],
    );
  }
}

// class CountdownTimerWidget extends StatefulWidget {
//   final TextStyle? textStyle;

//   const CountdownTimerWidget({super.key, this.textStyle});

//   @override
//   State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
// }

// class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
//   late Duration remaining;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     remaining = const Duration(minutes: 2); // Start at 2:00
//     _startTimer();
//   }

//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (remaining.inSeconds == 0) {
//         timer.cancel();
//       } else {
//         setState(() {
//           remaining -= const Duration(seconds: 1);
//         });
//       }
//     });
//   }

//   String _formatTime(Duration d) {
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final timeText = _formatTime(remaining);

//     return Row(
//       children: [
//         Text('testing the dynamic '),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//           decoration: ShapeDecoration(
//             shape: StadiumBorder(
//               side: BorderSide(color: Colors.blue, width: 2),
//             ),
//             color: Colors.yellow,
//           ),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // Invisible widest text to lock width
//               Opacity(
//                 opacity: 0,
//                 child: Text(
//                   '88:88',
//                   style: widget.textStyle?.copyWith(fontFamily: 'monospace'),
//                 ),
//               ),
//               // The actual countdown text
//               Text(timeText, style: widget.textStyle),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
