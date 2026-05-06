import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:quthon/Auth/auth_notifier.dart';
import 'package:quthon/Auth/user_model.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/DashBoard/RegistrationPage/participated_notifier.dart';
import 'package:quthon/DashBoard/RegistrationPage/registered_notifier.dart';
import 'package:quthon/Models/option_model.dart';
import 'package:quthon/Models/participate_model.dart';
import 'package:quthon/Models/register_models.dart';
import 'package:quthon/Utilies/current_contest_provider.dart';
import 'package:quthon/Widgets/animations.dart';
import 'package:quthon/Widgets/widgets.dart';

//TODO refactor lot of scope available:

class PersonalScorePage extends ConsumerStatefulWidget {
  const PersonalScorePage({super.key});
  @override
  ConsumerState<PersonalScorePage> createState() =>
      _PersonalScorePageAlternativeState();
}

class _PersonalScorePageAlternativeState
    extends ConsumerState<PersonalScorePage> {
  late AsyncValue<ResultModel> _asyncResult;
  late final User user;

  int? currentIndex;
  bool expand = true;

  @override
  void initState() {
    //check if is already there. this page is only auth user to no need to check user:
    user = ref.read(authNotifierProvider).user!; //
    _asyncResult = AsyncLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // check the result state
      final result =
          ref.read(participateProvider).selectedParticipated!.resultModel;
      if (result == null) {
        try {
          final result = await ref
              .read(participateProvider.notifier)
              .getResult(userId: user.id);

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
        return;
      }
      if (!mounted) return;
      setState(() {
        _asyncResult = AsyncData(result);
      });
    });

    super.initState();
  }

  Future<void> _onRefresh() async {
    try {
      final result = await ref
          .read(participateProvider.notifier)
          .getResult(userId: user.id, refresh: true);
      if (!mounted) return;
      setState(() {
        _asyncResult = AsyncData<ResultModel>(result);
      });
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _asyncResult = AsyncError(e, st);
        });
      }
    }
  }

  void setCurrentIndex(int? value) {
    if (currentIndex == value) {
      setState(() {
        currentIndex = null;
      });
      return;
    }
    setState(() {
      currentIndex = value;
    });
  }

  ({int? selectedIndex, String? correctId}) getOptionInfo(
    ResultQuestionModel question,
  ) {
    // Find index of user's chosen option
    final selectedIndex = question.options.indexWhere(
      (o) => o.id == question.selectedOptionId,
    );

    // Find the correct option's id
    final correctOption = question.options.firstWhere(
      (o) => o.correct ?? false,
      orElse:
          () =>
              throw Exception(
                'No correct option found for question ${question.id}',
              ),
    );

    return (
      selectedIndex: selectedIndex == -1 ? null : selectedIndex,
      correctId: correctOption.id,
    );
  }

  final optionSymList = ['A', 'B', 'C', 'D'];
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    final participateNotifier = ref.read(participateProvider.notifier);
    final hasAsyncData = (!_asyncResult.isLoading && !_asyncResult.hasError);
    final contest = ref.read(participateProvider).selectedParticipated!.contest;
    final freeTime = contest.timeDistribution == TimeDistribution.free;
    final result = ref.watch(
      participateProvider.select(
        (s) =>
            s
                .participates[participateNotifier.getSelectParticipateIndex()]
                .resultModel,
      ),
    );

    if (hasAsyncData) {
      _asyncResult = _asyncResult.copyWithPrevious(AsyncData(result!));
    }
    if (result != null &&
        currentIndex != null &&
        currentIndex! >= result.questions.length) {
      currentIndex = null; // questions length changes:
    }

    return Scaffold(
      // backgroundColor: colorScheme.surface,
      appBar: _appbar(colorScheme),
      body: SafeArea(
        bottom: false,
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics:
                _asyncResult.isLoading
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
            slivers: [
              if (hasAsyncData)
                SliverPadding(
                  padding: EdgeInsetsGeometry.only(top: 12),
                  sliver: SliverToBoxAdapter(
                    child:
                        _asyncResult.value == null
                            ? SizedBox.shrink()
                            : _buildUser(
                              colorScheme,
                              context,
                              _asyncResult.value!,
                            ),
                  ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 12,
                                    children: [
                                      Stack(
                                        alignment: AlignmentGeometry.bottomLeft,
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
                                                  color:
                                                      colorScheme
                                                          .surfaceContainer,
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            alignment: Alignment.center,
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              (index + 1).toString(),
                                              style: textTheme.labelSmall,
                                            ),
                                          ),
                                          if (isCorrect != null)
                                            Icon(
                                              isCorrect
                                                  ? Icons.check_circle_rounded
                                                  : Icons.cancel,
                                              size:
                                                  textTheme
                                                      .titleMedium
                                                      ?.fontSize,
                                              color:
                                                  isCorrect
                                                      ? Colors.green.withAlpha(
                                                        150,
                                                      )
                                                      : Colors.red.withAlpha(
                                                        150,
                                                      ),
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
              if (hasAsyncData) SliverToBoxAdapter(child: AppBottomLogoTile()),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appbar(ColorScheme colorScheme) {
    return AppBar(
      title: Text('Score card'),
      centerTitle: true,
      scrolledUnderElevation: 4,
      shadowColor: colorScheme.scrim.withAlpha(40),
      surfaceTintColor: colorScheme.surfaceContainerLowest,
      backgroundColor: colorScheme.surfaceContainerLowest,
    );
  }

  StyledContainer _buildUser(
    ColorScheme colorScheme,
    BuildContext context,
    ResultModel res,
  ) {
    final textTheme = TextTheme.of(context);

    return StyledContainer(
      // margin: EdgeInsetsGeometry.all(0),
      child: Column(
        children: [
          // user details
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Column(
              spacing: 12,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 100, maxHeight: 100),
                  child: ClipPath(
                    clipper: WavyCircleClipper(amplitude: 1.4, frequency: 10),
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
                Text(user.username, style: TextTheme.of(context).titleMedium),
              ],
            ),
          ),
          // score and rank:
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  spacing: 8,
                  children: [
                    Text(
                      res.score.toString(),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Score', style: textTheme.labelSmall),
                  ],
                ),
                if (!res.rank.isNegative)
                  Column(
                    spacing: 8,
                    children: [
                      Text(
                        res.rank.toString(),
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Rank', style: textTheme.labelSmall),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AnimatedSwitcher _questionContainer({
    required BuildContext context,
    required bool timeDistribution,
    required ResultQuestionModel question,
  }) {
    final correctIndex = question.options.indexOf(
      (question.options.firstWhere(
        (o) => o.id == getOptionInfo(question).correctId,
      )),
    );
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child:
          currentIndex == null
              ? SizedBox.shrink()
              : StyledContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Question ${currentIndex! + 1}'),
                        if (question.selectedOptionId == null)
                          Text(
                            'N/A',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: colorScheme.outlineVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (question.selectedOptionId != null &&
                            !timeDistribution)
                          Text(
                            question.timeTaken?.toStringAsFixed(2) ?? 'N/A',

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
                      padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                      child: Text(question.text),
                    ),

                    _ReviewOptionCard(
                      options: question.options,
                      selectedOptionId: question.selectedOptionId,
                      correctOptionId: getOptionInfo(question).correctId,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Text(
                            'Correct:${optionSymList[correctIndex]}',
                            style: TextTheme.of(context).labelLarge,
                          ),
                        ],
                      ),
                    ),
                    Divider(color: colorScheme.surfaceContainer),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 8),
                      child: Column(
                        children: [
                          Text(
                            question.options[correctIndex].explanation ?? '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  _builQuestionGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaSize = MediaQuery.of(context).size;
    // final participateNotifier = ref.read(participateProvider.notifier);
    final freeTime =
        ref
            .read(participateProvider)
            .selectedParticipated!
            .contest
            .timeDistribution ==
        TimeDistribution.free;
    final result = _asyncResult.value;

    // final result = register.resultModel.value;
    if (result == null) {
      return SizedBox.shrink();
    }

    return StyledContainer(
      padding: EdgeInsetsGeometry.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header button
          Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 12,
              top: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                ),
                Material(
                  shape: CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => expand = !expand),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        expand
                            ? Icons.keyboard_arrow_down_outlined
                            : Icons.keyboard_arrow_up_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animated expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                expand
                    ? const SizedBox(
                      width: double.maxFinite,
                    ) // when collapsed, hide content
                    : Column(
                      children: [
                        Divider(height: 0, color: colorScheme.surfaceContainer),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                mediaSize.height * 0.5 > 300
                                    ? 300
                                    : mediaSize.height * 0.6,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                            ),
                            child: CustomScrollView(
                              physics: BouncingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsetsGeometry.only(top: 10),
                                ),
                                SliverMasonryGrid(
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  delegate: SliverChildBuilderDelegate(childCount: result.questions.length, (
                                    context,
                                    i,
                                  ) {
                                    final question = result.questions[i];
                                    final isAnswered =
                                        question.selectedOptionId != null;

                                    final (
                                      :selectedIndex,
                                      :correctId,
                                    ) = getOptionInfo(question);

                                    return Material(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      color:
                                          currentIndex != i
                                              ? colorScheme.surfaceContainer
                                                  .withAlpha(0)
                                              : colorScheme.surface,
                                      shape: StadiumBorder(
                                        side: BorderSide(
                                          color:
                                              currentIndex == i
                                                  ? colorScheme.outlineVariant
                                                  : colorScheme
                                                      .surfaceContainerLow,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setCurrentIndex(i);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${i + 1}.',
                                                  maxLines: 1,

                                                  style: TextStyle(
                                                    color: colorScheme.outline,
                                                  ),
                                                ),
                                              ),
                                              if (freeTime) ...[
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        AlignmentGeometry
                                                            .centerRight,
                                                    child:
                                                        isAnswered
                                                            ? Text(
                                                              optionSymList[selectedIndex!], // if answered implies nn:
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.bodyMedium?.copyWith(
                                                                color:
                                                                    correctId ==
                                                                            question.selectedOptionId
                                                                        ? Colors
                                                                            .green
                                                                            .withAlpha(
                                                                              150,
                                                                            )
                                                                        : Colors
                                                                            .red
                                                                            .withAlpha(
                                                                              150,
                                                                            ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            )
                                                            : SizedBox.shrink(),
                                                  ),
                                                ),
                                              ],

                                              if (isAnswered && !freeTime)
                                                Expanded(
                                                  child: Center(
                                                    child: Text(
                                                      optionSymList[selectedIndex!], // if answered implies nn:
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodyMedium?.copyWith(
                                                        color:
                                                            correctId ==
                                                                    question
                                                                        .selectedOptionId
                                                                ? Colors.green
                                                                    .withAlpha(
                                                                      150,
                                                                    )
                                                                : Colors.red
                                                                    .withAlpha(
                                                                      150,
                                                                    ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      AlignmentGeometry
                                                          .centerRight,
                                                  child: Text(
                                                    question.timeTaken
                                                            ?.toStringAsFixed(
                                                              2,
                                                            ) ??
                                                        'N/A',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color:
                                                              colorScheme
                                                                  .outlineVariant,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),

                                  gridDelegate:
                                      const SliverSimpleGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 200,
                                      ),
                                ),

                                SliverPadding(
                                  padding: EdgeInsetsGeometry.only(top: 10),
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

  // // result null Exception:
  // Center resultNullException(
  //   BuildContext context,
  //   RegisterNotifier registerNotifier,
  // ) {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   return Center(
  //     child: SingleChildScrollView(
  //       child: Column(
  //         spacing: 10,
  //         // mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [Text('Score is not Available\nPlease refresh page')],
  //       ),
  //     ),
  //   );
  // }
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

// get the reviewOptionCard
// not optimized for larger list use only for limit child: it is the best scenior:

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
