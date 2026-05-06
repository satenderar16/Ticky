import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:quthon/Auth/auth_notifier.dart';
import 'package:quthon/Auth/user_model.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/DashBoard/RegistrationPage/participated_notifier.dart';
import 'package:quthon/Models/leaderboard_model.dart';
import 'package:quthon/Models/option_model.dart';
import 'package:quthon/Models/participate_model.dart';
import 'package:quthon/Models/register_models.dart';
import 'package:quthon/Repository/contest_repository.dart';
import 'package:quthon/Utilies/current_contest_provider.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/widgets.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  late PagingState<int, LeaderboardModel> _pageState;
  late final User user;

  @override
  void initState() {
    super.initState();
    user = ref.read(authNotifierProvider).user!;
    final partic = ref.read(participateProvider).selectedParticipated!;
    final intialList = partic.leaderboard;
    final hasNext = partic.leaderboardHasNext;
    if (intialList == null) {
      _pageState = PagingState();
      return;
    }
    _pageState = PagingState(
      pages: [intialList],
      keys: [intialList.length],
      hasNextPage: hasNext,
    );
    // user must be login to have this info:
  }

  Future<void> _fetchNextPage() async {
    if (_pageState.isLoading || _pageState.hasNextPage == false) return;
    if (!mounted) return;
    setState(() {
      _pageState = _pageState.copyWith(isLoading: true, error: null);
    });

    try {
      final currentOffset = (_pageState.keys?.last ?? 0);
      final (leaderboard: newItems, hasNext: hasNext) = await ref
          .read(participateProvider.notifier)
          .getLeaderboardList(offset: currentOffset);

      final newOffset = currentOffset + newItems.length;
      if (!mounted) return;
      setState(() {
        _pageState = _pageState.copyWith(
          pages: [...?_pageState.pages, newItems],
          keys: [...?_pageState.keys, newOffset],
          hasNextPage: hasNext,
          isLoading: false,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pageState = _pageState.copyWith(error: error, isLoading: false);
      });
    }
  }

  /// on Refresh page:
  Future<void> _onRefresh() async {
    if (_pageState.isLoading) return;

    try {
      final (leaderboard: newItems, :hasNext) = await ref
          .read(participateProvider.notifier)
          .getLeaderboardList(offset: 0, refresh: true);

      if (!mounted) return;
      setState(() {
        setState(() {
          _pageState = _pageState.copyWith(
            pages: [newItems],
            keys: [newItems.length],
            hasNextPage: hasNext,
            isLoading: false,
          );
        });
      });
    } catch (e) {
      if (!mounted) return;
      if (_pageState.keys?.isNotEmpty ?? false) {
        //TODO style it to let it match with ui component:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint(e.toString());
      setState(() {
        _pageState = _pageState.copyWith(error: e, isLoading: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    // final registerNotifier = ref.read(registerProvider.notifier);
    // making suring that selected couldn't be null here:
    final contest = ref.watch(
      participateProvider.select((p) => p.selectedParticipated!.contest),
    );
    final bool hasItems = _pageState.pages?.isNotEmpty ?? false;

    final bool isFirstPageLoading = _pageState.isLoading && !hasItems;

    final bool isFirstPageError = _pageState.error != null && !hasItems;
    final bool hasData = (!isFirstPageError && !isFirstPageLoading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 5,
        shadowColor: colorScheme.scrim.withAlpha(40),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SafeArea(
          bottom: false,
          top: false,
          child: CustomScrollView(
            physics:
                !isFirstPageLoading
                    ? const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    )
                    : const NeverScrollableScrollPhysics(),
            slivers: [
              if (hasData)
                SliverPadding(
                  padding: EdgeInsetsGeometry.only(top: 12, bottom: 10),
                  sliver: SliverToBoxAdapter(
                    child: StyledContainer(
                      child: Column(
                        children: [
                          Text('Summary', style: textTheme.labelMedium),
                          Divider(color: colorScheme.surfaceContainer),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              bottom: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        contest.participantCount.toString(),
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'participant',
                                        style: textTheme.labelSmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        contest.joinedCount.toString(),
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'join',
                                        style: textTheme.labelSmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        contest.submissionCount.toString(),
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'submission',
                                        style: textTheme.labelSmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // as once this widget builds it can't reflect the new update value here it don't matter as it viewable page only but needed to update the page state as soon as the riverpod update the state:
              SliverPadding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
                sliver: PagedSliverMasonryGrid<int, LeaderboardModel>(
                  state: _pageState,
                  fetchNextPage: _fetchNextPage,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  showNewPageErrorIndicatorAsGridChild: false,
                  showNewPageProgressIndicatorAsGridChild: false,
                  showNoMoreItemsIndicatorAsGridChild: false,

                  builderDelegate: PagedChildBuilderDelegate<LeaderboardModel>(
                    firstPageErrorIndicatorBuilder: (context) {
                      return Center(
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
                                _pageState.error.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    },

                    firstPageProgressIndicatorBuilder:
                        (context) => Center(child: ThreeDotWave(amplitude: 0)),
                    newPageProgressIndicatorBuilder:
                        (context) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 20,
                          ),
                          child: Center(
                            child: ThreeDotWave(
                              phaseDifference: pi / 3,
                              amplitude: 0.6,
                              minScale: 0.8,
                              dotSize: 10,
                              maxScale: 1.2,
                            ),
                          ),
                        ),

                    noItemsFoundIndicatorBuilder:
                        (context) => Column(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No items found', style: textTheme.titleLarge),
                            Text('The list is currently empty.'),
                          ],
                        ),
                    animateTransitions: true,
                    itemBuilder: (context, item, index) {
                      final isSubmitted =
                          item.contestStage == ContestStage.submitted;

                      return GestureDetector(
                        onTap: () {
                          if (!isSubmitted) {
                            return;
                          }
                          Navigator.of(context).push(
                            // also use Pageroute BUilder:
                            MaterialPageRoute(
                              builder:
                                  (context) => ParticipantScorePage(
                                    leaderboardModel: item,
                                  ),
                            ),
                          );
                        },
                        child: StyledContainer(
                          border: Border.fromBorderSide(
                            BorderSide(
                              color: colorScheme.surfaceContainer,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          ),
                          margin: EdgeInsetsGeometry.all(0),
                          boxShadow: isSubmitted ? null : [],

                          child: Row(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              Container(
                                clipBehavior: Clip.antiAlias,
                                constraints: BoxConstraints(
                                  minHeight: 40,
                                  minWidth: 40,
                                ),
                                decoration: BoxDecoration(
                                  // color: colorScheme.secondaryContainer,
                                  border: Border.fromBorderSide(
                                    BorderSide(
                                      color: colorScheme.surfaceContainer,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  '#${item.rank}',
                                  style: textTheme.labelSmall,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item.firstName} ${item.lastName} ${item.id == user.id ? '(You)' : ''}',

                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.contestStage ==
                                        ContestStage.submitted)
                                      Text.rich(
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        TextSpan(
                                          children: [
                                            //first:
                                            TextSpan(
                                              text: item.contestStage.name,
                                            ),
                                          ],
                                        ),
                                      ),

                                    if (item.contestStage !=
                                        ContestStage.submitted)
                                      Text(
                                        'Not submitted',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

              if (_pageState
                  .hasNextPage) // we can update this with the listviewin last to have botttomnav padding as well dynamically:
                SliverPadding(
                  padding: EdgeInsetsGeometry.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              if (!_pageState.hasNextPage)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: AlignmentGeometry.bottomCenter,
                    child: AppBottomLogoTile(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

//participants result fetching:-------------------------------------------------------------------------------------------->

class ParticipantScorePage extends ConsumerStatefulWidget {
  final LeaderboardModel leaderboardModel;
  const ParticipantScorePage({super.key, required this.leaderboardModel});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ParticipantScorePage();
}

class _ParticipantScorePage extends ConsumerState<ParticipantScorePage> {
  late AsyncValue<ResultModel> _asyncResult;
  int? expandIndex;

  @override
  void initState() {
    // make sure to have intial loading:
    _asyncResult = AsyncLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _onRefresh();
    });
    super.initState();
  }

  //loading data and refresh is same only intial loading is required while first fetch:
  Future<void> _onRefresh() async {
    try {
      // instead of this we have to fetch this directly from the repo as single fetch instead of updating state:
      // since leaderboard is specific to contest so :
      final contestId =
          ref.read(participateProvider).selectedParticipated?.contest.id;
      if (contestId == null) {
        throw Exception('CotestId null Excpetion');
      }
      final responseBody = await ContestRepository.getContestResult(
        id: contestId,
        userId: widget.leaderboardModel.id,
      );
      final response = await jsonDecode(responseBody);
      // parse the result, update state and return :
      final result = ResultModel.fromJson(response as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _asyncResult = AsyncData(result);
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _asyncResult = AsyncError(e, st);
      });
    }
  }

  int? getSelectedIndex({
    required String? selectedOptionId,
    required List<Option> options,
  }) {
    if (selectedOptionId == null) return null;
    for (int i = 0; i < options.length; i++) {
      if (options[i].id == selectedOptionId) {
        return i;
      }
    }
    return null;
  }

  ({String? correctID, int? correctIn}) getCorrectOption({
    required List<Option> options,
  }) {
    Option? correctOption;
    for (final o in options) {
      if (o.correct == true) {
        correctOption = o;
        break;
      }
    }

    if (correctOption == null) {
      return (correctID: null, correctIn: null);
    }

    final index = options.indexOf(correctOption);

    return (correctID: correctOption.id, correctIn: index);
  }

  List<String> optionSymList = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final contest = ref.read(participateProvider).selectedParticipated!.contest;
    final freeTime = contest.timeDistribution == TimeDistribution.free;

    return Scaffold(
      appBar: AppBar(
        // animateColor: true,
        centerTitle: true,
        title: const Text('Detail'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 5,
        shadowColor: colorScheme.scrim.withAlpha(40),
      ),

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _asyncResult.when(
              data:
                  (res) => SliverPadding(
                    padding: EdgeInsetsGeometry.only(top: 10),
                    sliver: SliverToBoxAdapter(
                      child: StyledContainer(
                        child: Column(
                          children: [
                            // user details
                            Column(
                              spacing: 12,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: 100,
                                    maxHeight: 100,
                                  ),
                                  child: ClipPath(
                                    clipper: WavyCircleClipper(
                                      amplitude: 1.4,
                                      frequency: 10,
                                    ),
                                    child: Container(
                                      color: colorScheme.surfaceContainerLow,
                                      width: double.maxFinite,
                                      height: double.maxFinite,
                                      child: Icon(
                                        Icons.person_2_rounded,
                                        size: 50,
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.leaderboardModel.userName,
                                  style: TextTheme.of(context).titleMedium
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Row(
                                spacing: 24,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      spacing: 8,
                                      children: [
                                        Text(
                                          res.score.toString(),
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          'score',
                                          style: textTheme.labelSmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.leaderboardModel.rank !=
                                      -1) // skiping the default case:
                                    Flexible(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            widget.leaderboardModel.rank
                                                .toString(),
                                            style: textTheme.bodyLarge
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                ),
                                          ),
                                          Text(
                                            'rank',
                                            style: textTheme.labelSmall,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
              error: (e, st) => SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            SliverPadding(
              padding: EdgeInsetsGeometry.only(top: 12, left: 12, right: 12),
              sliver: _asyncResult.when(
                data: (res) {
                  return SliverMasonryGrid(
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final question = res.questions[index];
                      final (:correctID, :correctIn) = getCorrectOption(
                        options: question.options,
                      );

                      if (correctID == null || correctIn == null) {
                        return SizedBox.shrink();
                      }
                      //null means not attemted:
                      final isCorrect =
                          question.selectedOptionId == null
                              ? null
                              : correctID == question.selectedOptionId!;

                      final selectedIn = getSelectedIndex(
                        selectedOptionId: question.selectedOptionId,
                        options: question.options,
                      );

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false, // let see the previous page
                              barrierDismissible: true,
                              barrierColor: Colors.black38,
                              pageBuilder: (context, _, __) {
                                return ResultQuestionPreview(
                                  key: ValueKey(contest.id),
                                  questions: res.questions,
                                  index: index,
                                  contest: contest,
                                );
                              },
                              // Simple fade in for the background barrier
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                return child;
                              },
                            ),
                          );
                        },
                        child: Hero(
                          tag: question.id,
                          child: StyledContainer(
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: colorScheme.surfaceContainer,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                            margin: EdgeInsetsGeometry.all(0),
                            padding: EdgeInsetsGeometry.all(0),
                            // decoration: BoxDecoration(
                            //   borderRadius: BorderRadius.circular(24),
                            //   border: Border.fromBorderSide(
                            //     BorderSide(
                            //       color: colorScheme.surfaceContainer,
                            //       strokeAlign: BorderSide.strokeAlignOutside,
                            //     ),
                            //   ),
                            //   color: colorScheme.surfaceContainerLowest,
                            // ),
                            child: Material(
                              color: colorScheme.surfaceContainerLowest,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 12,
                                  children: [
                                    Stack(
                                      alignment: AlignmentGeometry.bottomLeft,
                                      children: [
                                        Container(
                                          constraints: BoxConstraints(
                                            maxWidth: 40,
                                            maxHeight: 40,
                                          ),
                                          decoration: BoxDecoration(
                                            // color: colorScheme.secondaryContainer,
                                            border: Border.fromBorderSide(
                                              BorderSide(
                                                color:
                                                    colorScheme
                                                        .surfaceContainer,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          padding: EdgeInsets.all(8),
                                          child: Text((index + 1).toString()),
                                        ),
                                        if (isCorrect != null)
                                          Icon(
                                            isCorrect
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel,
                                            size:
                                                textTheme.titleMedium?.fontSize,
                                            color:
                                                isCorrect
                                                    ? Colors.green.withAlpha(
                                                      150,
                                                    )
                                                    : Colors.red.withAlpha(150),
                                          ),
                                      ],
                                    ),

                                    Flexible(
                                      child: SingleChildScrollView(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 4,
                                          children: [
                                            Text(
                                              question.text,
                                              // style: textTheme.bo,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                            ),

                                            /// for free contet:
                                            if (selectedIn != null &&
                                                isCorrect != null) ...[
                                              SingleChildScrollView(
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    Text.rich(
                                                      style: textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color:
                                                                colorScheme
                                                                    .outline,
                                                          ),
                                                      TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text:
                                                                optionSymList[selectedIn],
                                                          ),
                                                          if (!freeTime) ...[
                                                            TextSpan(
                                                              text: ' • ',
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  question.timeTaken ==
                                                                          null
                                                                      ? "0.00"
                                                                      : "${question.timeTaken!.toStringAsFixed(2)}s",
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            if (selectedIn == null)
                                              Text(
                                                'Not answered',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.outline,
                                                    ),
                                              ),
                                            //need to divide this in contestTimeDistribution:
                                          ],
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
                    }, childCount: res.questions.length),

                    gridDelegate:
                        SliverSimpleGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500,
                        ),
                  );
                },
                error: (e, st) {
                  return SliverFillRemaining(
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
                  );
                },
                loading: () {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: ThreeDotWave(amplitude: 0)),
                  );
                },
              ),
            ),

            if (!_asyncResult.isLoading && !_asyncResult.hasError)
              SliverToBoxAdapter(
                // hasScrollBody:
                //     false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AppBottomLogoTile(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// components:

class _ReviewOptionCard extends StatelessWidget {
  final List<Option> options;
  final String? selectedOptionId;
  final String? correctOptionId;

  const _ReviewOptionCard({
    super.key,
    required this.options,
    required this.selectedOptionId,
    required this.correctOptionId,
  });

  final List<String> _leadingChars = const [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
  ];

  int _calculateCrossAxisCount(double width) {
    int count = (width ~/ 350).clamp(1, 8);
    final allowed = [1, 2, 4, 8];
    for (int i = allowed.length - 1; i >= 0; i--) {
      if (count >= allowed[i]) return allowed[i];
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final rows = <List<Option>>[];

        for (var i = 0; i < options.length; i += crossAxisCount) {
          rows.add(options.skip(i).take(crossAxisCount).toList());
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in rows)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final option in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: _buildOption(option, colorScheme),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOption(Option option, ColorScheme colorScheme) {
    final optionIndex = options.indexOf(option);

    final isCorrect = option.id == correctOptionId;
    final isSelected = option.id == selectedOptionId;

    Color? bgColor;
    Color borderColor = colorScheme.surfaceContainer;

    // Logic: show visual states based on correct/selected
    if (isCorrect) {
      bgColor = Colors.green.withAlpha(40);
      borderColor = Colors.green.withAlpha(150);
    } else if (isSelected && !isCorrect) {
      bgColor = colorScheme.surfaceContainer;
      borderColor = colorScheme.surfaceContainer;
    }

    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentGeometry.topCenter,
          child: CustomShapeDataOnlyCard(
            backgroundColor:
                isCorrect
                    ? Colors.green.withAlpha(40)
                    : colorScheme.surfaceContainer,
            textColor: colorScheme.onSurface,
            frequency:
                ((optionIndex % _leadingChars.length) + 1 as num).toDouble(),
            data: _leadingChars[optionIndex % _leadingChars.length],
          ),
        ),

        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              border: isCorrect ? null : Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              option.text,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomShapeDataOnlyCard extends StatelessWidget {
  final String data;
  final Color? textColor;
  final Color? backgroundColor;
  final double amplitude;
  final double frequency;

  const CustomShapeDataOnlyCard({
    super.key,
    required this.data,
    this.textColor,
    this.backgroundColor,
    this.amplitude = 2.5,
    this.frequency = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipBehavior: Clip.antiAlias,
      clipper: WavyCircleClipper(amplitude: amplitude, frequency: frequency),
      child: Container(
        color:
            backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            data,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color:
                  textColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class ResultQuestionPreview extends StatefulWidget {
  final List<ResultQuestionModel> questions;
  final int index;
  final ContestDetailModel contest;
  const ResultQuestionPreview({
    super.key,
    required this.questions,
    required this.index,
    required this.contest,
  });

  @override
  State<ResultQuestionPreview> createState() => _ResultQuestionPreviewState();
}

class _ResultQuestionPreviewState extends State<ResultQuestionPreview> {
  late int _currentIndex;

  @override
  void initState() {
    _currentIndex = widget.index;

    super.initState();
  }

  /// get correctId , correctIn, selecedOptionIndex:
  ///

  int? getSelectedIndex({
    required String? selectedOptionId,
    required List<Option> options,
  }) {
    if (selectedOptionId == null) return null;
    for (int i = 0; i < options.length; i++) {
      if (options[i].id == selectedOptionId) {
        return i;
      }
    }
    return null;
  }

  ({String? correctID, int? correctIn}) getCorrectOption({
    required List<Option> options,
  }) {
    Option? correctOption;
    for (final o in options) {
      if (o.correct == true) {
        correctOption = o;
        break;
      }
    }

    if (correctOption == null) {
      return (correctID: null, correctIn: null);
    }

    final index = options.indexOf(correctOption);

    return (correctID: correctOption.id, correctIn: index);
  }

  static const optionSymList = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    final question = widget.questions[_currentIndex];
    final freeTime = widget.contest.timeDistribution == TimeDistribution.free;

    final (:correctID, :correctIn) = getCorrectOption(
      options: question.options,
    );

    if (correctID == null || correctIn == null) {
      return SizedBox.shrink();
    }
    //null means not attemted:
    final isCorrect =
        question.selectedOptionId == null
            ? null
            : correctID == question.selectedOptionId!;

    // final selectedIn = getSelectedIndex(
    //   selectedOptionId: question.selectedOptionId,
    //   options: question.options,
    // );
    return SafeArea(
      child: Stack(
        alignment: AlignmentGeometry.center,
        children: [
          Hero(
            tag: question.id,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: StyledContainer(
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: colorScheme.surfaceContainer,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      margin: EdgeInsetsGeometry.all(0),
                      child: Material(
                        color: colorScheme.surfaceContainerLowest,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,

                                  children: [
                                    Text('Question ${_currentIndex + 1}'),
                                    if (isCorrect != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          isCorrect
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel,
                                          size: textTheme.labelLarge?.fontSize,
                                          color:
                                              isCorrect
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                  ],
                                ),

                                if (isCorrect == null)
                                  Text(
                                    'Not answered',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outlineVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (!freeTime && isCorrect != null)
                                  Text(
                                    question.timeTaken?.toStringAsFixed(2) ??
                                        '0.00',

                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outlineVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            Divider(color: colorScheme.surfaceContainer),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 20,
                              ),
                              child: Text(question.text),
                            ),

                            _ReviewOptionCard(
                              options: question.options,
                              selectedOptionId: question.selectedOptionId,
                              correctOptionId: correctID,
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                children: [
                                  Text(
                                    'Correct:${optionSymList[correctIn]}',
                                    style: TextTheme.of(context).labelLarge,
                                  ),
                                ],
                              ),
                            ),
                            Divider(color: colorScheme.surfaceContainer),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                top: 8,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    question.options[correctIn].explanation ??
                                        '',
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}
