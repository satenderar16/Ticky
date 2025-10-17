import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Add this
import 'package:quthon/Contest/contest_entry_notifier.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/Models/answer_model.dart';
import 'package:quthon/Models/question_model.dart';
import 'package:quthon/Service/dnd_service.dart';
import 'package:quthon/Service/pinn_service.dart';
import 'package:quthon/Test/contest_page.dart';
import 'package:quthon/Widgets/utils.dart';
import 'package:quthon/Widgets/widgets.dart';

class SubmitPage extends ConsumerStatefulWidget {
  const SubmitPage({
    super.key,
    required this.answerMap,

    required this.startAt,
    required this.endAt,
    required this.submissionTag,
    required this.contest,
    required this.questions,
  });

  final Map<String, Answer> answerMap;

  final DateTime startAt;
  final DateTime endAt;
  final ContestSubmission submissionTag;
  final ContestDetailModel contest;
  final List<Question> questions;

  @override
  ConsumerState<SubmitPage> createState() => _SubmitPageState();
}

class _SubmitPageState extends ConsumerState<SubmitPage> {
  late final List<Answer> sortedAnswers;

  @override
  void initState() {
    detailsExpanded = false;
    Future.microtask(() async {
      await PinService.setMonitorState(false);
      // must persist current answers with contest id as primary keys:
      await ref.read(contestEntryProvider.notifier).persistAnswers();
    });
    // enough for about more than 1000 question:

    sortedAnswers =
        widget.answerMap.values.toList()
          ..sort((a, b) => a.questionIN.compareTo(b.questionIN));
    super.initState();
  }

  late bool detailsExpanded;
  void toggleDetails() {
    setState(() {
      detailsExpanded = !detailsExpanded;
    });
  }

  String getSubmissionTag() {
    switch (widget.submissionTag) {
      case ContestSubmission.none:
        return "No submission";
      case ContestSubmission.submit:
        return 'Submit';
      case ContestSubmission.timeOutSumit:
        return "Time out Submit";
      case ContestSubmission.interrupted:
        return "Contest Window Interrupted";
    }
  }

  @override
  Widget build(BuildContext context) {
    // final mediaPadding = MediaQuery.paddingOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: 16,
        ).add(MediaQuery.of(context).padding.copyWith(top: 0)),
        children: [
          StyledContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Text("DETAILS"),
                Divider(color: colorScheme.surfaceContainer),
                SizedBox(height: 10),
                Wrap(
                  runSpacing: 10,
                  spacing: 10,
                  children: [
                    DataHorizontalCard(
                      label: 'Started Time',
                      time: _formatTime(widget.startAt),
                    ),
                    DataHorizontalCard(
                      label: 'End Time',
                      time: _formatTime(widget.endAt),
                    ),

                    DataHorizontalCard(
                      label: 'Submission Tag',
                      time: getSubmissionTag(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10),

          StyledContainer(
            child: Column(
              children: [
                Text('SUMMARY'),
                Divider(color: colorScheme.surfaceContainer),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    // final total = widget.questions.length;

                    int answered = 0;
                    int skipped = 0;
                    int notVisited = 0;

                    for (final q in widget.questions) {
                      final ans =
                          widget.answerMap[q.id]; // if ansMap output is null:
                      if (ans == null) {
                        notVisited++;
                      } else if (ans.optionIN == null) {
                        skipped++; // not answered:
                      } else {
                        answered++;
                      }
                    }

                    // // avoid divide by zero
                    // double answeredFrac = total > 0 ? answered / total : 0;
                    // double skippedFrac = total > 0 ? skipped / total : 0;
                    // double notVisitedFrac = total > 0 ? notVisited / total : 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Legend
                        Wrap(
                          spacing: 12,
                          runAlignment: WrapAlignment.center,

                          children: [
                            _buildLegendItem(
                              color: colorScheme.primary,
                              label: "Answers ($answered)",
                            ),
                            _buildLegendItem(
                              color: colorScheme.primary.withAlpha(150),
                              label: "Skip ($skipped)",
                            ),
                            _buildLegendItem(
                              color: colorScheme.primary.withAlpha(100),
                              label: "Not Visited ($notVisited)",
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // linear indicator
                        ClipRRect(
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            spacing: 4,
                            children: [
                              if (answered > 0)
                                Expanded(
                                  flex: answered,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              if (skipped > 0)
                                Expanded(
                                  flex: skipped,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(150),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              if (notVisited > 0)
                                Expanded(
                                  flex: notVisited,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(100),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.answerMap.isNotEmpty)
                          AnimatedSize(
                            duration: Duration(milliseconds: 300),
                            child:
                                detailsExpanded
                                    ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 16),
                                        QuestionSummary(
                                          answerMap: widget.answerMap,
                                          questions: widget.questions,
                                          timeDistribution:
                                              widget.contest.timeDistribution,
                                        ),
                                      ],
                                    )
                                    : SizedBox.shrink(),
                          ),
                        const SizedBox(height: 12),
                        Divider(color: colorScheme.surfaceContainer, height: 0),
                        const SizedBox(height: 12),
                        _toggleButton(context, detailsExpanded),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Card _toggleButton(BuildContext context, bool isExpanded) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: StadiumBorder(),
      elevation: 0,
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: toggleDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Text(
            isExpanded ? 'View less' : 'View more',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Small helper widget for the legend
  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,

          // style: TextTheme.of(context).displayLarge
        ),
      ],
    );
  }

  // Format time in hh:mm AM/PM
  String _formatTime(DateTime dt) {
    return DateFormat("hh:mm:ss a").format(dt);
    // Example: 02:34:06 PM
  }
}

class BottomSubmitNavbar extends StatefulWidget {
  final Future<void> Function() onSubmit; // async callback

  const BottomSubmitNavbar({super.key, required this.onSubmit});

  @override
  State<BottomSubmitNavbar> createState() => _BottomSubmitNavbarState();
}

class _BottomSubmitNavbarState extends State<BottomSubmitNavbar> {
  @override
  void dispose() {
    super.dispose();
  }

  // multiple failure occured:
  int mFailed = 1;

  Future<bool?> _showMltpFail(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaPadding = MediaQuery.of(context).padding;

    return showModalBottomSheet<bool>(
      barrierColor: colorScheme.surfaceContainerLowest.withAlpha(0),
      backgroundColor: colorScheme.surfaceContainerLowest.withAlpha(0),
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: mediaPadding.bottom + 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: StyledContainer(
              boxShadow: const [],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Flexible(
                    child: Text('Submission Failed. Try again after sometime'),
                  ),
                  CupertinoButton(
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text(
                      'Exit',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExit() async {
    await PinService.stopPin();
    await DndService.disableDnd();
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.of(context).padding;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: AsyncActionBottomBar(
            onSubmit: () async {
              // multple fails:

              if (mFailed == 0 && context.mounted) {
                final exit = await _showMltpFail(context);

                if (exit == true) {
                  await _handleExit();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => ContestPage()),
                    );
                  }
                }
              }
              mFailed = (mFailed + 1) % 3;

              await widget.onSubmit();
              // await Future.error('eror');
            },
            onSuccess: () async {
              await _handleExit();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ContestPage()),
                );
              }
            },
            builder: (context, state) {
              switch (state) {
                case "idle":
                  return Text(
                    "Submit Contest",
                    style: TextTheme.of(
                      context,
                    ).labelLarge?.copyWith(color: colorScheme.primary),
                  );
                case "loading":
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      Text(
                        "Submitting...",
                        style: TextTheme.of(
                          context,
                        ).labelLarge?.copyWith(color: colorScheme.outline),
                      ),
                    ],
                  );
                case "retry":
                  return Text(
                    "Try Again",
                    style: TextTheme.of(
                      context,
                    ).labelLarge?.copyWith(color: colorScheme.primary),
                  );
                case "complete":
                  return Text(
                    "Exit",
                    style: TextTheme.of(
                      context,
                    ).labelLarge?.copyWith(color: colorScheme.primary),
                  );
                default:
                  return Text(
                    "Submit",
                    style: TextTheme.of(
                      context,
                    ).labelLarge?.copyWith(color: colorScheme.primary),
                  );
              }
            },
          ),
        ),
      ],
    );
  }

  // intial banner for submission:
  Widget _buildBanner({
    required bool active,
    required Color color,
    required IconData icon,
    required String text,
    required Color textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: Offset(0, active ? 0 : 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: active ? 1 : 0,
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surfaceContainerLowest,
          shape: StadiumBorder(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(color: color),
            child: Row(
              spacing: 6,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: textColor),
                Flexible(child: Text(text, style: TextStyle(color: textColor))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionSummary extends StatelessWidget {
  final List<dynamic> questions;
  final Map<String, Answer> answerMap;
  final TimeDistribution timeDistribution;
  const QuestionSummary({
    super.key,
    required this.questions,
    required this.answerMap,
    required this.timeDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final optionLetters = ["A", "B", "C", "D", "E", "F"];
    final colorScheme = Theme.of(context).colorScheme;
    final isTimeFree = timeDistribution == TimeDistribution.free;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, colorScheme, isTimeFree),
        Divider(color: colorScheme.surfaceContainer),

        ..._buildDataRows(optionLetters, isTimeFree),
      ],
    );
  }

  // Header
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool timeFree,
  ) {
    return Card(
      color: colorScheme.surfaceContainerLow.withAlpha(0),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildHeaderCell(context, "Q.No", flex: 1),
            _buildHeaderCell(context, "Option", flex: timeFree ? 1 : 2),
            if (!timeFree) _buildHeaderCell(context, "Time (s)", flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    String text, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Data Rows
  List<Widget> _buildDataRows(List<String> optionLetters, bool timeFree) {
    return List.generate(questions.length, (index) {
      final question = questions[index];
      final answer = answerMap[question.id];

      if (answer == null) return const SizedBox.shrink();

      final optionChosen = _getOptionChosen(answer, optionLetters);
      final timeTaken = _getTimeTaken(answer);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildCell("${index + 1}", flex: 1),
            _buildCell(optionChosen, flex: timeFree ? 1 : 2),
            if (!timeFree) _buildCell(timeTaken, flex: 2),
          ],
        ),
      );
    });
  }

  Widget _buildCell(String text, {required int flex}) {
    return Expanded(flex: flex, child: Text(text, textAlign: TextAlign.center));
  }

  String _getOptionChosen(Answer ans, List<String> optionLetters) {
    if (ans.optionIN != null &&
        ans.optionIN! >= 0 &&
        ans.optionIN! < optionLetters.length) {
      return optionLetters[ans.optionIN!];
    }
    return "-";
  }

  String _getTimeTaken(Answer ans) {
    if (ans.startAt != null && ans.endAt != null) {
      final duration = ans.endAt!.difference(ans.startAt!);
      return _formatDuration(duration);
    }
    return "-";
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inMilliseconds / 1000.0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final roundedSeconds = double.parse(seconds.toStringAsFixed(3));

    if (minutes > 0) {
      return "$minutes : $roundedSeconds";
    }

    if (roundedSeconds == roundedSeconds.roundToDouble()) {
      return "${roundedSeconds.toInt()}";
    }

    return "$roundedSeconds";
  }
}
