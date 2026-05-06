import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/Page/submit_page.dart';
import 'package:quthon/Contest/contest_entry_notifier.dart';
import 'package:quthon/Contest/contest_model.dart';
// import 'package:quthon/Contest/Page/submit_page.dart';
import 'package:quthon/Models/option_model.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/widgets.dart';

class ContestBody extends ConsumerStatefulWidget {
  const ContestBody({super.key});

  @override
  ConsumerState<ContestBody> createState() => __ContestBodyState();
}

class __ContestBodyState extends ConsumerState<ContestBody> {
  // review container state:
  bool reviewContainerOpen = false;

  void toggleReviewContainer(bool value) {
    setState(() {
      reviewContainerOpen = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    // final mediaPadding = MediaQuery.paddingOf(context);
    // final colorScheme = Theme.of(context).colorScheme;
    final loading = ref.watch(contestEntryProvider.select((l) => l.loading));
    final isError = ref.watch(contestEntryProvider.select((e) => e.error));
    final submitText = ref.watch(contestEntryProvider.select((s) => s.submit));
    final emptyQuestion = ref.watch(
      contestEntryProvider.select((s) => s.questions.isEmpty),
    );

    final entryNotifier = ref.read(contestEntryProvider.notifier);
    final bodyState =
        !loading &&
        !isError &&
        (submitText == ContestSubmission.none) &&
        !emptyQuestion;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Builder(
        builder: (context) {
          if (bodyState) {
            return BottomNavBar(
              reviewContainerOpen: reviewContainerOpen,
              toggleReviewContainer: toggleReviewContainer,
            );
          }
          if (submitText != ContestSubmission.none) {
            return BottomSubmitNavbar(
              onSubmit: () async {
                // sumission

                return await entryNotifier.submitAnwsers();
              },
            );
          }
          return SizedBox.shrink();
        },
      ),

      body: Builder(
        builder: (context) {
          if (loading) {
            return _loading();
          }

          if (isError) {
            return _errorState(entryNotifier);
          }

          return submitText != ContestSubmission.none
              ? SubmitPage(
                answerMap: entryNotifier.answerMap,

                startAt: ref.read(contestEntryProvider).contest.startAt,
                endAt: DateTime.now(),
                submissionTag: submitText!,
                questions: ref.read(contestEntryProvider).questions,
                contest: ref.read(contestEntryProvider).contest,
                submitBefore: ref
                    .read(contestEntryProvider)
                    .contest
                    .endAt
                    .add(Duration(minutes: 10)),
              )
              : emptyQuestion
              ? _emptyList()
              : Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Flexible(flex: 3, child: QuestionFullView()),

                  if (mediaSize.width >= 900 && reviewContainerOpen)
                    Flexible(flex: 1, child: ReviewContainer()),
                ],
              );
        },
      ),
    );
  }

  Widget submitBottomNavBar(EdgeInsets mediaPadding) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        // mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StyledContainer(
            margin: EdgeInsetsGeometry.only(
              left: 16,
              right: 16,
              bottom: 16 + mediaPadding.bottom,
            ),
            padding: EdgeInsetsGeometry.zero,
            // blurRadius: 10,
            offset: Offset(0, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 350),
              child: SizedBox(
                width: double.maxFinite,
                child: TextButton(
                  onPressed: () {},

                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),

                  child: Text('Submit Contest', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Center _errorState(ContestEntryNotifier entryNotifier) {
    return Center(
      child: SingleChildScrollView(
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
            Text("Something Went Wrong Try again!!"),
            FilledButton.tonal(
              onPressed: () {
                entryNotifier.fetchQuestions();
              },
              child: Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyList() {
    return Center(
      child: SingleChildScrollView(child: Text('No question Found')),
    );
  }

  Center _loading() {
    return const Center(
      child: RepaintBoundary(child: QuestionLoaderAnimation()),
    );
  }
}

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({
    super.key,
    this.reviewContainerOpen = false,
    required this.toggleReviewContainer,
  });
  final bool reviewContainerOpen;
  final ValueChanged<bool> toggleReviewContainer;
  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  late bool reviewContainer = false;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    reviewContainer = widget.reviewContainerOpen;

    super.initState();
  }

  bool test = true;
  void toggleReview() {
    setState(() {
      reviewContainer = !reviewContainer;
      widget.toggleReviewContainer(reviewContainer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaSize = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // debugPrint("bottom navbar build: called");
    final contest = ref.read(contestEntryProvider).contest;

    final entryFree = ref.watch(
      contestEntryProvider.select(
        (s) => s.contest.timeDistribution == TimeDistribution.free,
      ),
    );

    final entryNotifier = ref.read(contestEntryProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding + 16,
        right: 16,
        left: 16,
        top: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        // alignment: Alignment.bottomCenter,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaSize.height * .35,
              maxWidth: 350,
            ),
            child: AnimatedContainer(
              // reverseDuration: Duration(milliseconds: 300),
              duration: Duration(milliseconds: 300),
              child:
                  (mediaSize.width <= 900 && entryFree && reviewContainer)
                      ? StyledContainer(
                        padding: EdgeInsetsGeometry.zero,
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 12,
                              ),
                              child: ReviewList(),
                            ),
                          ],
                        ),
                      )
                      : SizedBox(width: double.infinity),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 10,
              children: [
                IntrinsicHeight(
                  child: StyledContainer(
                    padding: EdgeInsetsGeometry.zero,
                    margin: EdgeInsetsGeometry.zero,
                    offset: const Offset(0, 12),
                    // blurRadius: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ContestTimer(endAt: contest.endAt),
                        ),
                        if (entryFree) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: VerticalDivider(
                              width: 0,
                              color: colorScheme.surfaceContainer,
                            ),
                          ),
                          bottomCupertinoButton(
                            colorScheme: colorScheme,
                            onPressed: toggleReview,
                            child: Row(
                              spacing: 4,
                              children: [
                                Icon(
                                  reviewContainer
                                      ? Icons.bookmark_added
                                      : Icons.bookmark_added_outlined,
                                ),
                                Text('Review', textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IntrinsicHeight(
                  child: StyledContainer(
                    padding: EdgeInsetsGeometry.zero,
                    margin: EdgeInsetsGeometry.zero,
                    offset: const Offset(0, 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        bottomCupertinoButton(
                          colorScheme: colorScheme,
                          onPressed: entryNotifier.movetoPrevQuestion,
                          enable: entryFree,
                          child: Row(
                            spacing: 4,
                            children: [
                              Icon(Icons.arrow_back_ios_new_rounded),
                              Text('Prev', textAlign: TextAlign.center),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: VerticalDivider(
                            width: 0,
                            color: colorScheme.surfaceContainer,
                          ),
                        ),
                        bottomCupertinoButton(
                          colorScheme: colorScheme,

                          child: Row(
                            spacing: 4,
                            children: [
                              Text('Next'),
                              Icon(Icons.arrow_forward_ios_rounded),
                            ],
                          ),
                          onPressed:
                              entryFree
                                  ? entryNotifier.movetoNextQuestion
                                  : ref
                                      .watch(questionTimerProvider.notifier)
                                      .moveToNextQuestion,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CupertinoButton bottomCupertinoButton({
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
    bool enable = true,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 16,
      horizontal: 12,
    ),
  }) {
    return CupertinoButton(
      onPressed: enable ? onPressed : null,
      sizeStyle: CupertinoButtonSize.small,
      foregroundColor: enable ? colorScheme.onSurface : null,
      padding: padding,
      child: child,
    );
  }
}

class ContestTimer extends StatelessWidget {
  final DateTime? endAt;
  const ContestTimer({super.key, required this.endAt});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final clock = ref.watch(globalClockProvider);

        final remaining = endAt!.difference(
          clock.subtract(Duration(seconds: 1)),
        ); // padding time by a second:
        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        // debugPrint(remaining.inSeconds.toString());
        // maintaining the timer:

        // When time is over
        if (remaining.isNegative) {
          // this ensures the call:
          // need to replace other method:
          Future.microtask(() async {
            final contestType =
                ref.read(contestEntryProvider).contest.timeDistribution;
            final notifier = ref.read(contestEntryProvider.notifier);
            await notifier.persistAnswers(contestType: contestType);
            if (contestType == TimeDistribution.free) {
              notifier.contestSubmission(ContestSubmission.timeOutSumit);
            } else {
              notifier.unifromContestSubmission(ContestSubmission.timeOutSumit);
            }
          });
          return Text(
            "--:--",
            style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
          );
        }

        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;

        final formatted =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        return Stack(
          alignment: Alignment.center,
          children: [
            // Invisible widest text to lock width
            // this make sure max width required is there:
            Opacity(
              opacity: 0,
              child: Text(
                '88:88',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // The actual countdown text
            Text(
              formatted,
              style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
            ),
          ],
        );
      },
    );
  }
}

class QuestionFullView extends ConsumerStatefulWidget {
  const QuestionFullView({super.key});

  @override
  ConsumerState<QuestionFullView> createState() => _QuestionFullViewState();
}

class _QuestionFullViewState extends ConsumerState<QuestionFullView> {
  @override
  void initState() {
    super.initState();
    // ensuring the timer start when first question frame builds: cause this function update the state can't directly call in build/init:
    if (ref.read(contestEntryProvider).contest.timeDistribution ==
        TimeDistribution.free) {
      return;
    }
    Future.microtask(() async {
      ref
          .read(questionTimerProvider.notifier)
          .startQuestion(ref.read(contestEntryProvider).currentIndex);
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) {

    //   // return;
    // });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    final entryNotifier = ref.read(contestEntryProvider.notifier);

    final textTheme = TextTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final (index, questions, review, contest) = ref.watch(
      contestEntryProvider.select(
        (q) => (q.currentIndex, q.questions, q.review, q.contest),
      ),
    );

    final question = questions[index];
    final free = contest.timeDistribution != TimeDistribution.free;

    // for review and details
    return ListView(
      // shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.only(bottom: mediaPadding.bottom, top: 16),
      children: [
        // question container
        StyledContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              Row(
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(child: Text("Question ${index + 1}")),

                  if (free) ...[QuestionTimerText()],
                  if (!free)
                    ActionStateButton(
                      icon: Icons.bookmark_outline_outlined,
                      initialActive:
                          entryNotifier.currentAnswer()?.review ?? false,
                      key: ValueKey(question.id),
                      onStateChanged: (b) {
                        entryNotifier.reviewToggle();
                      },
                    ),
                ],
              ),

              Divider(height: 0, color: colorScheme.surfaceContainer),
              Text(question.text, style: textTheme.bodyLarge),

              ///question no.
              SizedBox(height: 12),

              SelectionCard(
                key: ValueKey(question.id),
                options: question.options,
                onSelected: (id) {
                  entryNotifier.selectedOptionId = id;
                  entryNotifier.updateAnswers();
                },
                initialOptionId: entryNotifier.selectedOptionId,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuestionTimerText extends ConsumerWidget {
  const QuestionTimerText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(
      questionTimerProvider.select((s) => s.questionRemaining),
    );

    final formattedTime =
        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Invisible widest text to lock width
          // this make sure max width required is there:
          Opacity(
            opacity: 0,
            child: Text('88:88', style: TextStyle(fontFamily: 'monospace')),
          ),
          // The actual countdown text
          Text(formattedTime),
        ],
      ), //TODO change with maxsized getter:
    );
  }
}

class ReviewContainer extends StatelessWidget {
  const ReviewContainer({super.key});
  // cause list tile need padding from bottom dynamically:
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      physics: const BouncingScrollPhysics(),
      children: const [
        StyledContainer(
          padding: EdgeInsetsGeometry.all(12),
          child: ReviewList(),
        ),
      ],
    );
  }
}

class ReviewList extends ConsumerStatefulWidget {
  const ReviewList({super.key});

  @override
  ConsumerState<ReviewList> createState() => ReviewListState();
}

class ReviewListState extends ConsumerState<ReviewList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(contestEntryProvider);
    final entryNotifier = ref.watch(contestEntryProvider.notifier);
    final questions = entry.questions;
    final answerMap = entry.answerMap;
    final currentIndex = entry.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    // 1. UPDATED: Calculate statistics for all 4 states
    final totalCount = questions.length;
    final answeredCount =
        answerMap.values.where((a) => a.optionID != null && !a.review).length;
    final answeredAndReviewedCount =
        answerMap.values.where((a) => a.optionID != null && a.review).length;
    final unansweredButReviewedCount =
        answerMap.values.where((a) => a.optionID == null && a.review).length;

    // Total answered is the sum of answered-only and answered-and-reviewed
    final totalAnswered = answeredCount + answeredAndReviewedCount;
    // The final unanswered count
    final unansweredCount =
        totalCount - totalAnswered - unansweredButReviewedCount;

    Widget getQuestionWidget(int index) {
      final question = questions[index];
      final answer = answerMap[question.id];
      final answerNotVisited = answer == null;
      final isReviewed = answer?.review ?? false;
      final isAnswered = answer?.optionID != null;
      final isCurrent = index == currentIndex;
      final boderRadius =
          isAnswered
              ? BorderRadius.circular(100) // fully rounded
              : BorderRadius.circular(16);
      // Shape: circular if answered, rounded rectangle otherwise

      return Stack(
        alignment: Alignment.center,
        children: [
          InkWell(
            borderRadius: boderRadius,
            onTap: () => entryNotifier.updateIndex(index),
            child: QuestionStatusBox(
              isCurrent: isCurrent,
              label: '${index + 1}',
              isAnswered: isAnswered,
              isReviewed: isReviewed,
            ),
          ),
          if (answerNotVisited)
            Positioned(
              bottom: 4,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SizedBox(height: 12),
        // header
        Text('Review'.toUpperCase(), textAlign: TextAlign.center),
        Divider(color: colorScheme.surfaceContainer),
        // 2. Statistics Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              _buildStatItem('Answered', answeredCount, Colors.green.shade400),
              _buildStatItem(
                'Ans & Review',
                answeredAndReviewedCount,
                Colors.green.shade400,
              ),
              _buildStatItem(
                'Review',
                unansweredButReviewedCount,
                Colors.deepOrange.shade400,
              ),
              _buildStatItem(
                'Not Answered',
                unansweredCount,
                Colors.deepPurple.shade400,
              ),
            ],
          ),
        ),
        Divider(color: colorScheme.surfaceContainer),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            runSpacing: 6,
            spacing: 6,
            children:
                questions
                    .map((e) => getQuestionWidget(questions.indexOf(e)))
                    .toList(),
          ),
        ),

        // 4. Divider and Legend - UPDATED for 4 states
        Divider(color: colorScheme.surfaceContainer),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: Column(
            spacing: 8,
            children: [
              infoTile(
                colorScheme: colorScheme,
                lable: 'Answer',
                isAnswered: true,
              ),
              infoTile(
                colorScheme: colorScheme,
                lable: 'Not Answered',
                // isAnswered: falses,
              ),
              infoTile(
                colorScheme: colorScheme,
                lable: 'Answered & Reviewed',
                isAnswered: true,
                isReviewed: true,
                // isAnswered: falses,
              ),
              infoTile(
                colorScheme: colorScheme,
                lable: 'Not Answered & Reviewed',
                isAnswered: false,
                isReviewed: true,
                // isAnswered: falses,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for stats section
  Widget _buildStatItem(String label, int count, Color color) {
    return SizedBox(
      width: 80,

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextTheme.of(context).titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget infoTile({
    bool isAnswered = false,
    required ColorScheme colorScheme,
    BorderRadiusGeometry? borderRadius,
    bool isReviewed = false,
    required String lable,
  }) {
    final borderRadius = BorderRadius.circular(isAnswered ? 100 : 16);
    return Row(
      spacing: 6,
      children: [
        QuestionStatusBox(
          label: 'X',
          isAnswered: isAnswered,
          isReviewed: isReviewed,
          borderRadius: borderRadius,
        ),
        Flexible(child: Text(lable)),
      ],
    );
  }
}

class SelectionCard extends StatefulWidget {
  final List<Option> options;
  final ValueChanged<String?> onSelected;
  final String? initialOptionId;

  const SelectionCard({
    super.key,
    required this.options,
    required this.onSelected,
    required this.initialOptionId,
  });

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard>
    with TickerProviderStateMixin {
  String? selectedOptionId;
  final List<String> _leadingChars = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    selectedOptionId = widget.initialOptionId;
  }

  void _onSelect(String? id) {
    setState(() {
      selectedOptionId = selectedOptionId == id ? null : id;
    });
    widget.onSelected(selectedOptionId);
  }

  int _calculateCrossAxisCount(double width) {
    // How many 350 -wide items could fit
    int count = (width ~/ 350).clamp(1, 8);

    // Allowed values
    final allowed = [1, 2, 4, 8];

    // Pick the nearest allowed value <= count
    for (int i = allowed.length - 1; i >= 0; i--) {
      if (count >= allowed[i]) return allowed[i];
    }

    return 1; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

        // Break options into rows of [crossAxisCount]
        final rows = <List<Option>>[];

        for (var i = 0; i < widget.options.length; i += crossAxisCount) {
          rows.add(widget.options.skip(i).take(crossAxisCount).toList());
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
                          padding: const EdgeInsets.all(4.0),
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
    final isSelected = selectedOptionId == option.id;
    final selectNull = selectedOptionId == null;
    final optionIndex = widget.options.indexOf(option);

    return Opacity(
      opacity: selectNull ? 1 : (isSelected ? 1 : 0.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.surfaceContainer : null,
              border: Border.all(color: colorScheme.surfaceContainer),
              borderRadius: BorderRadius.circular(isSelected ? 20 : 12),
            ),
            child: Text(_leadingChars[optionIndex % _leadingChars.length]),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: () => _onSelect(option.id),
              child: AnimatedContainer(
                height: double.infinity,
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surfaceContainer : null,
                  border: Border.all(color: colorScheme.surfaceContainer),
                  borderRadius: BorderRadius.circular(isSelected ? 20 : 12),
                ),
                child: Text(
                  option.text,
                  // style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
