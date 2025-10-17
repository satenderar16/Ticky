import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_entry_notifier.dart';
import 'package:quthon/Contest/contest_notifier.dart';
import 'package:quthon/Widgets/utils.dart';
import 'package:quthon/Widgets/widgets.dart';

class EntryBody extends StatelessWidget {
  const EntryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: EntryBodyList(),
      bottomNavigationBar: EntryBottomNavBar(),
    );
  }
}

class EntryBodyList extends ConsumerStatefulWidget {
  const EntryBodyList({super.key});

  @override
  ConsumerState<EntryBodyList> createState() => __EntryBodyState();
}

class __EntryBodyState extends ConsumerState<EntryBodyList> {
  static const String instructionString =
      "All questions are compulsory. || "
      "The contest will be auto-submitted once the allotted time has elapsed. || "
      "Please ensure that Contest Mode remains active throughout the contest. Disabling it will result in automatic contest submission. || "
      "Switching to other windows or apps during the contest is strictly prohibited. Any such activity will be detected and may result in immediate contest cancellation. || "
      // "If you encounter a system notice during the contest and are unable to resolve it, please contact a supervisor immediately. || "
      "Attempting to use other phone features during the contest may trigger a violation notice. Such behavior will be treated as an attempt to cheat.";

  @override
  void initState() {
    debugPrint('entry body list init');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.paddingOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: EdgeInsets.only(bottom: mediaPadding.bottom, top: 10),
          physics: const BouncingScrollPhysics(),

          children: [
            noteWidget(context),
            SizedBox(height: 10),
            contestIntruction(context),
            SizedBox(height: 10),
            genralInstruction(context),
          ],
        ),
      ),
    );
  }

  StyledContainer genralInstruction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return StyledContainer(
      child: Column(
        children: [
          Text(
            'General Instruction'.toUpperCase(),
          ), // Contest Mode instruction :
          Divider(color: colorScheme.surfaceContainer),
          buildInstructionList(instructionString),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  '•',
                ), // to do need to update with for general instruction list:

                Flexible(child: Text('Question evalutaion')),
              ],
            ),
          ),
          _buildStatusTile(
            context: context,
            title: "Answered",
            subtitle:
                "Attempted questions, Final score will be calculated for this question(s).",
            isAnswered: true,
          ),
          _buildStatusTile(
            context: context,
            title: "Unanswered",
            subtitle: "Not attempted question",
            isAnswered: false,
          ),
          _buildStatusTile(
            context: context,
            title: "Answered and mark for review",
            subtitle:
                "Attempted but review question, Final score will be calculated for this question(s).",
            isAnswered: true,
            isReviewed: true,
          ),
          _buildStatusTile(
            context: context,
            title: "Unanswered and mark for review",
            subtitle:
                "Not attempted but review will not consider score calculation.",
            isReviewed: true,
          ),
        ],
      ),
    );
  }

  StyledContainer noteWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return StyledContainer(
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text('NOTE'),
            VerticalDivider(color: colorScheme.surfaceContainer),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'you can\'t leave this page until the contest starts',
                    overflow: TextOverflow.fade,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    bool isAnswered = false,
    bool isReviewed = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        spacing: 10,
        children: [
          QuestionStatusBox(
            label: 'X',
            isAnswered: isAnswered,
            isReviewed: isReviewed,
          ),
          Flexible(
            child: Column(
              spacing: 2,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitle,
                  style: TextTheme.of(
                    context,
                  ).bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  StyledContainer contestIntruction(BuildContext context) {
    final contestDetails = ref.read(contestProvider).selectedContest!;
    final colorScheme = Theme.of(context).colorScheme;
    return StyledContainer(
      child: Column(
        children: [
          Text('Contest Instruction'.toUpperCase()), // contest instruction :
          Divider(color: colorScheme.surfaceContainer),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DataLabelCard(
                label: 'Questions',
                data: contestDetails.numberOfQuestions.toString(),
              ),
              DataLabelCard(
                label: 'Duration',
                data: '${contestDetails.timeDuration.inMinutes}m',
              ),
            ],
          ),

          buildInstructionList(contestDetails.instruction),
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
              padding: const EdgeInsets.symmetric(vertical: 6),
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

class EntryBottomNavBar extends ConsumerStatefulWidget {
  const EntryBottomNavBar({super.key});

  @override
  ConsumerState<EntryBottomNavBar> createState() => _EntryBottomNavBarState();
}

class _EntryBottomNavBarState extends ConsumerState<EntryBottomNavBar> {
  final GlobalKey<AsyncActionBottomBarState> asyncButton = GlobalKey();

  @override
  void initState() {
    Future.microtask(() {
      asyncButton.currentState?.handleSubmit();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final entryNotifier = ref.watch(contestEntryProvider.notifier);

    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AsyncActionBottomBar(
            key: asyncButton,
            onSubmit: () async {
              await entryNotifier.fetchQuestions();
            },
            onSuccess: null,

            builder: (context, state) {
              switch (state) {
                case "idle":
                  return Text('Start', style: TextTheme.of(context).bodyMedium);
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
                        'Fetching...',
                        style: TextTheme.of(context).bodyMedium,
                      ),
                    ],
                  );
                case "retry":
                  return Text('Start', style: TextTheme.of(context).bodyMedium);
                case "complete":
                  return Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Starting in ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TimerContainer(),
                    ],
                  );
                default:
                  return Text('Start', style: TextTheme.of(context).bodyMedium);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _TimerContainer extends ConsumerWidget {
  const _TimerContainer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(globalClockProvider);
    final state = ref.watch(contestEntryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final remaining = state.contest.startAt.difference(clock);
    final textTheme = TextTheme.of(context);
    return Text(
      _formatDuration(remaining),
      style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
