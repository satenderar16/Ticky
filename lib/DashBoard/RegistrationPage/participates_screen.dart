import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:quthon/DashBoard/RegistrationPage/leaderboard_page.dart';
import 'package:quthon/DashBoard/RegistrationPage/participated_notifier.dart';
import 'package:quthon/DashBoard/RegistrationPage/personal_score_page.dart';
import 'package:quthon/Models/participate_model.dart';
import 'package:quthon/Models/register_models.dart';
import 'package:quthon/Utilies/current_contest_provider.dart';
import 'package:quthon/Utilies/secure_widget.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/custom_grid.dart';
import 'package:quthon/Widgets/widgets.dart';

class ParticipatedScreen extends ConsumerStatefulWidget {
  const ParticipatedScreen({super.key});

  @override
  ConsumerState<ParticipatedScreen> createState() =>
      _ParticipatedScreenStateState();
}

class _ParticipatedScreenStateState extends ConsumerState<ParticipatedScreen> {
  late PagingState<int, ParticipateDetailModel> _pageState;
  List<ParticipateDetailModel> _cachedList = [];

  @override
  void initState() {
    final conState = ref.read(participateProvider);
    final initialList = conState.participates;
    final hasNext = conState.hasNext;
    // handle the case where list is empty and not intialized: first time fetching the list:
    if (initialList.isEmpty && !hasNext) {
      _pageState = PagingState();
      return;
    }
    if (initialList.isNotEmpty) {
      _cachedList = initialList;
      _pageState = PagingState(
        pages: [initialList],
        keys: [initialList.length],
        hasNextPage: hasNext,
      );
    } else {
      _pageState = PagingState();
    }

    super.initState();
  }

  Future<void> _fetchNextPage() async {
    if (_pageState.isLoading || _pageState.hasNextPage == false) return;
    if (!mounted) return;
    setState(() {
      _pageState = _pageState.copyWith(isLoading: true, error: null);
    });

    try {
      final currentOffset = (_pageState.keys?.last ?? 0);
      final (participates: newParticipates, hasNext: hasNext) = await ref
          .read(participateProvider.notifier)
          .getParticipateList(offset: currentOffset);

      final newOffset = currentOffset + newParticipates.length;

      if (!mounted) return;
      setState(() {
        _pageState = _pageState.copyWith(
          pages: [...?_pageState.pages, newParticipates],
          keys: [...?_pageState.keys, newOffset],
          hasNextPage: hasNext,
          isLoading: false,
        );
      });
      _cachedList = [..._cachedList, ...newParticipates];
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pageState = _pageState.copyWith(error: e, isLoading: false);
      });
    }
  }

  /// on Refresh page:
  Future<void> _onRefresh() async {
    if (_pageState.isLoading) return;
    ref.invalidate(participateProvider);
    try {
      if (!mounted) return;
      final (participates: newParticipates, hasNext: hasNext) = await ref
          .read(participateProvider.notifier)
          .getParticipateList(offset: 0, refresh: true);

      if (!mounted) return;
      setState(() {
        _pageState = PagingState(
          pages: [newParticipates],
          keys: [newParticipates.length],
          hasNextPage: hasNext,
          isLoading: false,
          error: null,
        );
      });
      _cachedList = newParticipates;
    } catch (e) {
      if (!mounted) return;
      if (_pageState.keys?.isNotEmpty ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _pageState = _pageState.copyWith(error: e, isLoading: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);

    final bool hasItems = _pageState.pages?.isNotEmpty ?? false;

    final bool isFirstPageLoading = _pageState.isLoading && !hasItems;

    // final bool isFirstPageError = _pageState.error != null && !hasItems;
    // final bool hasData = (!isFirstPageError && !isFirstPageLoading);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 4,
        shadowColor: colorScheme.scrim.withAlpha(40),

        title: const Text('Registered'),
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics:
              isFirstPageLoading
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
          slivers: [
            SliverPadding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 12),
              sliver: PagedSliverAlignedGrid(
                // crossAxisCount: 1,
                state: _pageState,
                fetchNextPage: _fetchNextPage,
                mainAxisSpacing: 10,
                showNewPageErrorIndicatorAsGridChild: false,
                showNewPageProgressIndicatorAsGridChild: false,
                showNoMoreItemsIndicatorAsGridChild: false,

                builderDelegate:
                    PagedChildBuilderDelegate<ParticipateDetailModel>(
                      firstPageErrorIndicatorBuilder:
                          (context) => _firstPageError(context),
                      firstPageProgressIndicatorBuilder:
                          (context) =>
                              Center(child: ThreeDotWave(amplitude: 0)),
                      newPageProgressIndicatorBuilder:
                          (context) => _newPageProgress(),

                      noItemsFoundIndicatorBuilder:
                          (context) => _noItemFound(textTheme),
                      animateTransitions: true,
                      itemBuilder: (context, item, index) {
                        final notifier = ref.read(participateProvider.notifier);
                        final idx = notifier.participateIdMap[item.contest.id];

                        final participate = ref.watch(
                          participateProvider.select((e) {
                            try {
                              if (idx == null) throw '';
                              final cnt = e.participates[idx];
                              _cachedList[index] = cnt;
                              return _cachedList[index];
                            } catch (e) {
                              return _cachedList[index];
                            }
                          }),
                        );

                        return _contestCard(
                          context: context,
                          participate: participate,
                        );
                      },
                    ),
                gridDelegateBuilder: (int childCount) {
                  return SliverSimpleGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                  );
                },
              ),
            ),
            // if (!_pageState.isLoading &&
            //     (_pageState.error == null) &&
            //     !_pageState.hasNextPage)
            //   SliverToBoxAdapter(child: AppBottomLogoTile()),
          ],
        ),
      ),
    );
  }

  Widget _contestCard({
    required BuildContext context,
    required ParticipateDetailModel participate,
  }) {
    final startAt = participate.contest.startAt;
    final formattedDate = DateFormat('dd MMM').format(startAt);
    final formattedTime = DateFormat('h:mm a').format(startAt);

    final day = DateFormat('EEE').format(startAt);
    final colorScheme = Theme.of(context).colorScheme;
    final contest = participate.contest;

    void cardTap() {
      ref
          .read(participateProvider.notifier)
          .setSelectedParticipate(id: participate.contest.id);
      if (ref.read(participateProvider).selectedParticipated == null) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => ParticipatedPage()));
    }

    return StyledContainer(
      padding: EdgeInsetsGeometry.all(0),
      child: InkWell(
        borderRadius: BorderRadius.circular(19), //outer -1:
        onTap: cardTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(),
          padding: EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$day\n',
                            style: TextTheme.of(context).labelSmall,
                          ),
                          TextSpan(
                            text: '$formattedTime\n',
                            style: TextTheme.of(
                              context,
                            ).bodyLarge?.copyWith(color: colorScheme.primary),
                          ),

                          TextSpan(
                            text: formattedDate,
                            style: TextTheme.of(context).labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                VerticalDivider(
                  color: colorScheme.surfaceContainer,
                  indent: 6,
                  endIndent: 6,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        contest.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                      Text(
                        contest.description,
                        style: TextTheme.of(context).bodySmall,

                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _noItemFound(TextTheme textTheme) {
    return Column(
      spacing: 12,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('No items found', style: textTheme.titleLarge),
        Text('The list is currently empty.'),
      ],
    );
  }

  Padding _newPageProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
      child: Center(
        child: ThreeDotWave(
          phaseDifference: pi / 3,
          amplitude: 0.6,
          minScale: 0.8,
          dotSize: 10,
          maxScale: 1.2,
        ),
      ),
    );
  }

  Center _firstPageError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: Image.asset('assets/error_page.png', fit: BoxFit.contain),
            ),
            Text(
              _pageState.error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipatedPage extends ConsumerStatefulWidget {
  const ParticipatedPage({super.key});

  @override
  ConsumerState<ParticipatedPage> createState() => _ParticipatedPageState();
}

class _ParticipatedPageState extends ConsumerState<ParticipatedPage> {
  late AsyncValue<ParticipateDetailModel> _asyncParticipated;

  static const submissionWindow = Duration(minutes: 10);
  bool showNavBar = false;
  void toggleShowNavbar() {
    setState(() {
      showNavBar = !showNavBar;
    });
  }

  @override
  void initState() {
    _asyncParticipated = AsyncLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initial =
            await ref.read(participateProvider.notifier).getContestDetail();
        if (!mounted) return;
        setState(() {
          _asyncParticipated = AsyncData(initial);
        });
      } catch (e, st) {
        if (!mounted) return;
        setState(() {
          _asyncParticipated = AsyncError(e, st);
        });
      }
    });
    super.initState();
  }

  Future<void> _onRefresh() async {
    try {
      if (_asyncParticipated.isLoading) return;

      final contest = await ref
          .read(participateProvider.notifier)
          .getContestDetail(refresh: true);
      if (!mounted) return;
      setState(() {
        _asyncParticipated = AsyncData(contest);
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _asyncParticipated = AsyncError(e, st);
      });
    }
  }

  List<({String label, String time})> timeTile() {
    final contest = ref.read(participateProvider).selectedParticipated!.contest;

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

  Widget buildInstructionList(String? instruction) {
    // if (instruction == null || instruction.isEmpty) {
    //   return const Text("No rules");
    // }

    // Split instructions by "||" and trim spaces
    final rules = instruction?.split("||").map((e) => e.trim()).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          rules?.map((rule) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [Text('•'), Flexible(child: Text(rule))],
              ),
            );
          }).toList() ??
          [Text('No Instruction Found')],
    );
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
    final contest = ref.read(participateProvider).selectedParticipated!.contest;
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
    return await ref.read(participateProvider.notifier).joinContest();
  }

  void _successjoined() {
    // navigate to contestEntry: with currentCOntest Provider to update it:
    final contest = ref.read(participateProvider).selectedParticipated?.contest;
    if (contest == null) {
      return;
    }
    ref
        .read(currentContestProvider.notifier)
        .update(
          (state) => state.copyWith(
            contest: contest,
            source: ContestSource.participates,
          ),
        );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SecureWidget()),
    );
  }

  Future<String> _submitContest() async {
    // button only visible till the time but still as if user didn't refrsh the page and hit the button again and again after the time expiry :
    if (!_asyncParticipated.hasValue) {
      throw 'Something went wrong'; // handling the case state is unexpected:
    }

    if (_asyncParticipated.value!.contest.endAt
        .add(submissionWindow)
        .isBefore(DateTime.now().toLocal())) {
      final time = DateFormat(
        'h:mm a',
      ).format(_asyncParticipated.value!.contest.endAt.add(submissionWindow));
      throw 'Submission window closed at $time';
    }
    final success =
        await ref.read(participateProvider.notifier).submitContest();
    return success;
  }

  @override
  Widget build(BuildContext context) {
    // get current userId
    // final user = ref.read(authNotifierProvider).user!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    // final mediaPadding = MediaQuery.paddingOf(context);
    final participate = ref.watch(participateProvider).selectedParticipated!;
    final contest = participate.contest;

    final hasAsyncData =
        (!_asyncParticipated.isLoading && !_asyncParticipated.hasError);
    if (hasAsyncData) {
      _asyncParticipated = _asyncParticipated.copyWithPrevious(
        AsyncData(participate),
      );
    }
    final scheduleAt = contest.scheduleAt;
    final startAt = contest.startAt;
    final day = DateFormat('EEE').format(scheduleAt);
    final date = DateFormat('d MMM').format(scheduleAt);
    // final startTime = DateFormat('h:mm a').format(startAt);

    final entryClose = DateFormat(
      'h:mm a',
    ).format(startAt.subtract(const Duration(seconds: 30)));

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 4,
        shadowColor: colorScheme.scrim.withAlpha(40),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics:
              _asyncParticipated.isLoading
                  ? NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsGeometry.only(top: 12, bottom: 10),
              sliver: _asyncParticipated.when(
                data: (particpate) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,

                                    children: [
                                      Text(
                                        day,
                                        style: TextTheme.of(context).bodyLarge,
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
                                      timeTile().map((t) {
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
                                constraints: BoxConstraints(maxWidth: 300),
                                child: CustomGrid(
                                  mainAxisSpacing: 10,

                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  // childWidth: 100,
                                  children: [
                                    DataLabelCard(
                                      label: 'Questions',
                                      data: '${contest.questionCount}',
                                    ),

                                    DataLabelCard(
                                      label: 'Duration',
                                      data:
                                          '${contest.timeDuration.inMinutes}m',
                                    ),
                                    DataLabelCard(
                                      label: 'Mode',
                                      data: contest.timeDistribution.name,
                                    ),
                                    DataLabelCard(
                                      label: 'Participants',
                                      data: contest.participantCount.toString(),
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
                                      'Please Join the contest before $entryClose',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      StyledContainer(
                        child: Column(
                          spacing: 10,
                          children: [
                            Text("Instruction", style: textTheme.labelMedium),
                            Divider(
                              height: 0,
                              color: colorScheme.surfaceContainer,
                            ),

                            Text(
                              contest.instruction ?? 'No Intructions',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      //TODO add submission timeOut:
                      // result section with conditional rendering:- must contest submit and ended as well :
                      // this make sure result only visible when contest  submission is closed:;
                      if (contest.endAt
                          .add(submissionWindow)
                          .isBefore(DateTime.now().toLocal())) ...[
                        SizedBox(height: 10),

                        StyledContainer(
                          child: Column(
                            children: [
                              Text('Summary', style: textTheme.labelMedium),
                              Divider(color: colorScheme.surfaceContainer),
                              if (contest.currentStage !=
                                  ContestStage.submitted)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 10,
                                  ),
                                  child: Text('Scorecard unavailable'),
                                ),
                              if (contest.currentStage ==
                                  ContestStage.submitted) ...[
                                //ScoreCard Button
                                GestureDetector(
                                  onTap:
                                      () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => PersonalScorePage(),
                                        ),
                                      ),
                                  child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.fromBorderSide(
                                        BorderSide(
                                          color: colorScheme.surfaceContainer,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),

                                      child: Row(
                                        spacing: 4,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            color: colorScheme.primary,
                                          ),
                                          Flexible(
                                            child: Text(
                                              'Score card',
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              SizedBox(height: 10),
                              GestureDetector(
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => LeaderboardPage(),
                                      ),
                                    ),
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.fromBorderSide(
                                      BorderSide(
                                        color: colorScheme.surfaceContainer,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),

                                    child: Row(
                                      spacing: 4,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.leaderboard_outlined,
                                          color: colorScheme.primary,
                                        ),
                                        Flexible(
                                          child: Text(
                                            'Leader Board',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                            ),
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
                      ],
                    ]),
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
            ),
            SliverToBoxAdapter(
              child: ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          hasAsyncData ? _buildBottomNavBar(context: context) : null,
    );
  }

  Widget? _buildBottomNavBar({required BuildContext context}) {
    final contest =
        ref.watch(participateProvider).selectedParticipated!.contest;
    final mediaPadding = MediaQuery.paddingOf(context);
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now().toLocal();

    // contest ended and submission widnow as well:->shrink box
    // padding for the submission is 10 MIN
    if (contest.endAt
        .add(submissionWindow)
        .isBefore(DateTime.now().toLocal())) {
      return null;
    }

    // // contest started and submission window is open and user joined or submitted:
    // // submit enbled and disabled based on contestsubmit stage:
    if (contest.startAt.add(Duration(minutes: 1)).isBefore(now) &&
        contest.endAt.add(submissionWindow).isAfter(now) &&
        contest.currentStage != ContestStage.participated) {
      return AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 350),
          child: SizedBox(
            width: double.maxFinite,
            child: Padding(
              padding: EdgeInsets.only(bottom: mediaPadding.bottom + 24),
              child: AsyncButton(
                needContinue: false,
                childText:
                    contest.currentStage == ContestStage.submitted
                        ? 'Submitted'
                        : 'Submit',
                onPressedAsync:
                    contest.currentStage == ContestStage.submitted
                        ? null
                        : _submitContest,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedSlide(
          duration: Duration(milliseconds: 300),
          offset: Offset(0, showNavBar ? 1 : 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 350),
            child: SizedBox(
              width: double.maxFinite,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: mediaPadding.bottom + 24,
                  left: 16,
                  right: 16,
                ),
                child: CustomBottomButton(
                  onPressed: toggleShowNavbar,
                  buttonStyle: ButtonStyle(
                    elevation: WidgetStatePropertyAll(0),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: colorScheme.surfaceContainer),
                    ),
                    backgroundColor: WidgetStatePropertyAll(
                      colorScheme.surfaceContainerLowest,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      colorScheme.primary,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Accept & Continue'),
                ),
              ),
            ),
          ),
        ),
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
    );
  }
}
