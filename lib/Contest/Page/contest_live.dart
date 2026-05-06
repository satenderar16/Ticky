import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:quthon/Auth/widgets.dart';
import 'package:quthon/Contest/contest_notifier.dart';
import 'package:quthon/Contest/Page/contest_page.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/widgets.dart';
import '../contest_model.dart';

class ContestLive extends ConsumerStatefulWidget {
  const ContestLive({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ContestLiveAlternative();
}

class _ContestLiveAlternative extends ConsumerState<ConsumerStatefulWidget> {
  late PagingState<int, ContestDetailModel> _pageState;
  List<ContestDetailModel> _cachedList = <ContestDetailModel>[];

  @override
  void initState() {
    final conState = ref.read(contestProvider);
    final initialList = conState.contests;
    final hasNext = conState.hasNext;
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
      // calling the server:
      final (contests: newContest, hasNext: hasNext) = await ref
          .read(contestProvider.notifier)
          .getContestList(offset: currentOffset);
      final newOffset = currentOffset + newContest.length;

      if (!mounted) return;
      setState(() {
        _pageState = _pageState.copyWith(
          pages: [...?_pageState.pages, newContest],
          keys: [...?_pageState.keys, newOffset],
          hasNextPage: hasNext,
          isLoading: false,
        );
      });
      _cachedList = [..._cachedList, ...newContest];
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
    ref.invalidate(contestProvider);
    try {
      if (!mounted) return;
      // get updated value:
      final (contests: newContests, hasNext: hasNext) = await ref
          .read(contestProvider.notifier)
          .getContestList(offset: 0, refresh: true);

      if (!mounted) return;
      setState(() {
        _pageState = PagingState(
          pages: [newContests],
          keys: [newContests.length],
          hasNextPage: hasNext,
          isLoading: false,
          error: null,
        );
      });
      _cachedList = newContests;
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

  void _openProfileCard(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // let see the previous page
        barrierDismissible: true,
        barrierColor: Colors.black12,
        pageBuilder: (context, _, __) {
          return UserProfile();
        },
        // Simple fade in for the background barrier
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);

    //TODO to get the data state: might get some error : need a verification:

    final bool hasItems = _pageState.pages?.isNotEmpty ?? false;

    final bool isFirstPageLoading = _pageState.isLoading && !hasItems;

    final bool isFirstPageError = _pageState.error != null && !hasItems;
    final bool hasData = (!isFirstPageError && !isFirstPageLoading);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: colorScheme.surfaceContainerLowest,
        scrolledUnderElevation: 4,
        shadowColor: colorScheme.scrim.withAlpha(40),
        // title: Image.asset('./assets/ic_launcher192.png', height: kToolbarHeight),
        actions: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 40, maxHeight: 40),
                  child: GestureDetector(
                    onTap: () => _openProfileCard(context),
                    child: Container(
                      width: double.maxFinite,
                      height: double.maxFinite,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: colorScheme.surfaceContainer),
                        ),
                      ),
                      child: Icon(
                        Icons.person_2_rounded,

                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Hero(
                  tag: 'profile-card',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 40, maxHeight: 40),
                    child: GestureDetector(
                      onTap: () => _openProfileCard(context),
                      child: Container(
                        width: double.maxFinite,
                        height: double.maxFinite,
                        decoration: BoxDecoration(
                          // borderRadius: BorderRadius.circular(20),
                          color: colorScheme.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: colorScheme.surfaceContainer),
                          ),
                        ),
                        child: Icon(
                          Icons.person_2_rounded,

                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics:
                !isFirstPageLoading
                    ? const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    )
                    : const NeverScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 12),
                sliver: PagedSliverAlignedGrid(
                  state: _pageState,
                  fetchNextPage: _fetchNextPage,
                  mainAxisSpacing: 10,
                  showNewPageErrorIndicatorAsGridChild: false,
                  showNewPageProgressIndicatorAsGridChild: false,
                  showNoMoreItemsIndicatorAsGridChild: false,
                  builderDelegate: PagedChildBuilderDelegate<
                    ContestDetailModel
                  >(
                    firstPageErrorIndicatorBuilder:
                        (context) => _firstPageError(context),
                    firstPageProgressIndicatorBuilder:
                        (context) => Center(child: ThreeDotWave(amplitude: 0)),
                    newPageProgressIndicatorBuilder:
                        (context) => _newPageProgress(),

                    noItemsFoundIndicatorBuilder:
                        (context) => _noItemFound(textTheme),
                    animateTransitions: true,
                    itemBuilder: (context, item, index) {
                      final notifier = ref.read(contestProvider.notifier);
                      final inx = notifier.contestIdsMap[item.id];

                      final contest = ref.watch(
                        contestProvider.select((e) {
                          try {
                            if (inx == null) throw '';
                            final cnt = e.contests[inx];
                            _cachedList[index] = cnt;
                            return _cachedList[index];
                          } catch (e) {
                            return _cachedList[index];
                          }
                        }),
                      );
                      return _contestCard(context: context, contest: contest);
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

  Widget _contestCard({
    required BuildContext context,
    required ContestDetailModel contest,
  }) {
    final formattedDate = DateFormat('dd MMM').format(contest.startAt);
    final formattedTime = DateFormat('h:mm a').format(contest.startAt);

    final day = DateFormat('EEE').format(contest.startAt);
    final colorScheme = Theme.of(context).colorScheme;

    void cardTap() {
      ref.read(contestProvider.notifier).setSelectedContest(id: contest.id);

      if (ref.read(contestProvider).selectedContest == null) {
        return;
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => ContestPage()));
    }

    return StyledContainer(
      padding: EdgeInsetsGeometry.all(0),
      child: InkWell(
        borderRadius: BorderRadius.circular(19), //outer -1:
        onTap: cardTap,
        child: Container(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                      Text(
                        contest.description ?? 'description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextTheme.of(context).bodySmall,
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
}
