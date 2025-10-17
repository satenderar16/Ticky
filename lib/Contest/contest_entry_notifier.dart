import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/Contest/contest_notifier.dart';
import 'package:quthon/Contest/contest_repository.dart';
import 'package:quthon/Models/answer_model.dart';
import 'package:quthon/Models/question_model.dart';
import 'package:quthon/Service/brightness_service.dart';
import 'package:quthon/Service/dnd_service.dart';
import 'package:quthon/Service/pinn_service.dart';

/// ---------- 1. Global clock ----------
/// we can optimize this to have adaptive periodic timer like for duration about in multiples minutes we can only update the clock for duration of 1min for less time we use seconds.
final globalClockProvider =
    StateNotifierProvider.autoDispose<GlobalClockNotifier, DateTime>((ref) {
      return GlobalClockNotifier();
    });

class GlobalClockNotifier extends StateNotifier<DateTime> {
  Timer? _ticker;

  GlobalClockNotifier() : super(DateTime.now()) {
    startClock();
  }

  void startClock() {
    _ticker?.cancel();
    final now = DateTime.now();
    final msUntilNextSecond = 1000 - now.millisecond;

    _ticker = Timer(Duration(milliseconds: msUntilNextSecond), () {
      _update();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        return _update();
      });
    });
  }

  void _update() => state = DateTime.now();

  void triggerImmediateTick() => _update();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

enum ContestSubmission { none, submit, timeOutSumit, interrupted }

/// ---------- 2. Contest Entry State ----------
class ContestEntryState {
  final ContestDetailModel contest;
  final List<Question> questions;
  final int currentIndex;
  final bool review;
  final bool loading;
  final bool error;
  final ContestSubmission? submit;
  final Map<String, Answer> answerMap;

  const ContestEntryState({
    required this.contest,
    required this.questions,
    required this.currentIndex,
    required this.review,
    this.loading = false,
    this.error = false,
    this.submit,
    required this.answerMap,
  });

  ContestEntryState copyWith({
    ContestDetailModel? contest,
    List<Question>? questions,
    int? currentIndex,
    bool? review,
    bool? loading,
    bool? error,
    ContestSubmission? submit,
    Map<String, Answer>? answerMap,
  }) {
    return ContestEntryState(
      contest: contest ?? this.contest,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      review: review ?? this.review,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      submit:
          submit ??
          this.submit, // this enure only once the value can be assign as null:
      answerMap: answerMap ?? this.answerMap,
    );
  }
}

final contestEntryProvider =
    StateNotifierProvider.autoDispose<ContestEntryNotifier, ContestEntryState>((
      ref,
    ) {
      return ContestEntryNotifier(ref: ref);
    });

class ContestEntryNotifier extends StateNotifier<ContestEntryState> {
  final Ref ref;
  final Map<String, Answer> answerMap = {};
  DateTime? questionStartAt;
  String? selectedOptionId;
  double brightness = 0.5;

  // only needed when user update the brightness no need to update the state:
  // we update review to definew here to show only the current value instead of change the question screen:
  ContestEntryNotifier({required this.ref})
    : super(
        ContestEntryState(
          contest: ref.read(contestProvider).selectedContest!,
          questions: [],
          currentIndex: 0,
          review: false,
          answerMap: {},
          loading: false,
          // error: true,
          submit: ContestSubmission.none,
        ),
      ) {
    // updating brightness  initally value:
    getBrightness();

    // all sending time data should be in utc:
    questionStartAt = state.contest.startAt.toUtc();
    // updating value for first index: marked as visited.

    // fetching question on entryBody:
  }
  // question crud:
  Future<void> fetchQuestions() async {
    state = state.copyWith(loading: true, error: false);
    // return;
    try {
      final questions = await ContestRepository.getContestQuestions(
        id: state.contest.id,
      );

      if (questions.isEmpty) {
        throw 'No question Available';
      }

      state = state.copyWith(
        questions: questions,
        currentIndex: 0,
        loading: false,
        error: false,
      );
      // marked first question as visited:
      updateIndex(0);
    } catch (e) {
      debugPrint(e.toString());
      state = state.copyWith(loading: false, error: true);
      rethrow;
    }
  }

  void movetoNextQuestion() {
    //if current index is out of bound;

    if (state.currentIndex + 1 >= state.questions.length) {
      // change section

      // quit or submit the contest:
      // submitContest("submit"); // we don't need to submit instead we just don't update the index:
      return;
    }

    /// just need to move next index:
    updateIndex(state.currentIndex + 1);
  }

  void movetoPrevQuestion() {
    if (state.currentIndex == 0) {
      //todo move to previous section
      // last section's last question:
      return;
    }
    updateIndex(state.currentIndex - 1);
  }

  // basically jupming value of index:
  void updateIndex(int index) {
    state = state.copyWith(currentIndex: index);
    selectedOptionId = answerMap[currentQuestionId(index)]?.optionID;
    // this marked it for skipped if user didn't marked any answer:
    // skipped question will also be added to avoid non visit conflict:
    if (state.currentIndex < state.questions.length &&
        answerMap[currentQuestionId(state.currentIndex)] == null) {
      answerMap[currentQuestionId(state.currentIndex)] = Answer(
        questionID: currentQuestionId(state.currentIndex),
        questionIN: state.currentIndex,
        startAt: null,
        endAt: null,
      );

      // add answer map state to update answer:
      state = state.copyWith(answerMap: answerMap);
    }
  }

  String currentQuestionId(int index) {
    return state.questions[index].id;
  }

  // initail value:
  Answer? currentAnswer() {
    return answerMap[currentQuestionId(
      state.currentIndex,
    )]; // use state instead
  }

  void reviewToggle() {
    final index = state.currentIndex;
    final answer = answerMap[currentQuestionId(index)];

    // @deprecated as once question is display it have anwer value to marked as visited:
    if (answer == null) {
      // debugPrint("review toggle answer is null");
      answerMap[currentQuestionId(state.currentIndex)] = Answer(
        questionID: currentQuestionId(index),
        questionIN: index,
        startAt: null,
        endAt: null,
        optionID: selectedOptionId,
        // optionIN: optionIN,
        review:
            true, // if empty then it false , but we need to update answer with review values:
      );

      // update state answerMap to reflect in UI

      state = state.copyWith(review: true, answerMap: answerMap);
      // debugPrint(
      //   'state answerMap: ${state.answerMap[currentQuestionId(state.currentIndex)]?.toJson().toString()}\n',
      // );
      // debugPrint(
      //   answerMap[currentQuestionId(state.currentIndex)]?.toJson().toString(),
      // );

      return;
    }

    answerMap[currentQuestionId(state.currentIndex)] = Answer(
      questionID: answer.questionID,
      questionIN: answer.questionIN,
      startAt: answer.startAt,
      endAt: answer.endAt,
      review: !answer.review,
      optionID: answer.optionID,
      optionIN: answer.optionIN,
    );
    state = state.copyWith(review: !answer.review, answerMap: answerMap);
    // debugPrint(
    //   'state answerMap: ${state.answerMap[currentQuestionId(state.currentIndex)]?.toJson().toString()}\n',
    // );
    // debugPrint(
    //   answerMap[currentQuestionId(state.currentIndex)]?.toJson().toString(),
    // );
  }

  void updateAnswers() {
    // adding time for question:

    final index = state.currentIndex;
    final optionIN =
        selectedOptionId == null
            ? null
            : state.questions[index].options.indexWhere(
              (o) => o.id == selectedOptionId,
            );
    final answer = answerMap[currentQuestionId(index)];
    // answer is not going to be null: once question is shown to screen:
    answerMap[currentQuestionId(index)] =
        answer == null
            ? Answer(
              questionID: currentQuestionId(index),
              questionIN: index,
              startAt: null,
              endAt: null,
              optionID: null,
              optionIN: optionIN,
            )
            : answer.copyWith(
              optionID: selectedOptionId,
              optionIN: optionIN,
              review: answer.review,
            );

    // add state. AnswerMap to reflect in UI:
    state = state.copyWith(answerMap: answerMap);
    // debugPrint(
    //   'state answerMap: ${state.answerMap[currentQuestionId(state.currentIndex)]?.toJson().toString()}\n',
    // );
    debugPrint(
      'answer updated called : ${answerMap[currentQuestionId(index)]!.toJson()}',
    );
  }

  void uniformUpdateAnswers() {
    // don't need review as only sigle visit is allowed for uniform contest:
    // just to update time on uniform contest we check the exiting answer , if null we can update time

    final now = DateTime.now().toUtc();
    final index = state.currentIndex;
    if (index >= state.questions.length) {
      return; // out of bound
    }
    final optionIN =
        selectedOptionId == null
            ? null
            : state.questions[index].options.indexWhere(
              (o) => o.id == selectedOptionId,
            );
    final answer = answerMap[currentQuestionId(index)];
    answerMap[currentQuestionId(index)] =
        answer == null
            ? Answer(
              questionID: currentQuestionId(index),
              questionIN: index,
              startAt: questionStartAt!,
              endAt: now,
              optionID: selectedOptionId,
              optionIN: optionIN,
            )
            : answer.copyWith(
              optionID: selectedOptionId,
              optionIN: optionIN,
              startAt: questionStartAt!,
              endAt: now,
            );

    // update the state answerMap to update as our answerMap needed to be reflec in ui asap it updated:
    state = state.copyWith(answerMap: answerMap);
    questionStartAt = now;

    // selectedOptionId = null;
    // debugPrint(
    //   'state answerMap: ${state.answerMap[currentQuestionId(state.currentIndex)]?.toJson().toString()}\n',
    // );
    debugPrint(
      'unifrom updated called : ${answerMap[currentQuestionId(index)]!.toJson()}',
    );
  }

  // submitting answer marked lasted question time : questionPage -> submissionPage:

  //   // free contest submission
  void contestSubmission(ContestSubmission submit) {
    // take current index and update final answer time if submit is not intruppted
    if (state.questions.isEmpty) {
      state = state.copyWith(submit: ContestSubmission.submit);
      return;
    }
    if (submit == ContestSubmission.interrupted) {
      state = state.copyWith(submit: submit);
      return;
    }
    final now = DateTime.now().toUtc();
    final answer = currentAnswer();
    if (answer == null) {
      debugPrint('Exception found current answer is not while submitting');
      return;
    }
    // updating the final question
    answerMap[currentQuestionId(state.currentIndex)] = Answer(
      questionID: answer.questionID,
      questionIN: answer.questionIN,
      optionID: answer.optionID,
      optionIN: answer.optionIN,
      startAt: questionStartAt!,
      endAt: now,
    );
    debugPrint(
      'submission called: ${answerMap.map((key, value) => MapEntry(key, value.toJson().toString())).toString()}',
    );

    state = state.copyWith(answerMap: answerMap, submit: submit);
  }

  // unifrom contest submission:

  void unifromContestSubmission() {
    questionStartAt = DateTime.now().toUtc();
    // answer can't be null:
    final answer = currentAnswer();
    if (answer == null) {
      debugPrint('Submission Error: Current answer null exception');
      return;
    }
    answerMap[currentQuestionId(state.currentIndex)] = answer.copyWith(
      endAt: questionStartAt,
    );
    state = state.copyWith(
      answerMap: answerMap,
      submit: ContestSubmission.submit,
    );
  }

  // / Answers persistency:
  // persist answer in case of submit failure or violation:
  Future<void> persistAnswers() async {
    // try to persist only the anwered value:
    final jsonAnswer = jsonEncode(
      answerMap.values
          .where((a) => a.optionID != null)
          .where((a) => a.endAt != null) // keep only answers with optionID
          .map((a) => a.toJson())
          .toList(),
    );
    debugPrint(jsonAnswer);
    try {
      await ContestRepository.persistAnswers(
        answer: jsonAnswer,
        id: state.contest.id,
      );
    } catch (e) {
      debugPrint("something went while persisting the answer: $e");
    }
  }

  Future<void> removePersistAnswers() async {
    try {
      await ContestRepository.removePersistAnswers(id: state.contest.id);
    } catch (e) {
      debugPrint("something went while removing the stored answer: $e");
    }
  }

  Future<void> submitAnswers() async {
    try {
      await ContestRepository.postContestSubmit(id: state.contest.id);
    } catch (e) {
      rethrow;
    }
  }

  /// brightness
  Future<double> getBrightness() async {
    brightness = await BrightnessService.getSystemBrightness();

    return brightness;
  }

  Future<void> applyBrightness(double value) async {
    brightness = value;
    await BrightnessService.applyCustomBrightness(brightness);
  }

  Future<void> restoreBrightness() async {
    await BrightnessService.restore();
  }

  @override
  void dispose() {
    debugPrint('contest enty notifier got disposed');
    super.dispose();
  }
}

/// --------------------------------------------------contestStartProvider---------------------
final contestStartProvider = StateProvider.autoDispose<bool>((ref) {
  final clock = ref.watch(globalClockProvider);
  final contest = ref.read(contestEntryProvider).contest;

  return clock.add(Duration(seconds: 1)).difference(contest.startAt) >
      Duration.zero;
});

/// ---------- 3. Question Timer ----------
class QuestionTimerState {
  final DateTime? questionEndAt;
  final Duration questionRemaining;

  const QuestionTimerState({
    required this.questionEndAt,
    required this.questionRemaining,
  });

  QuestionTimerState copyWith({
    DateTime? questionEndAt,
    Duration? questionRemaining,
  }) {
    return QuestionTimerState(
      questionEndAt: questionEndAt ?? this.questionEndAt,
      questionRemaining: questionRemaining ?? this.questionRemaining,
    );
  }
}

final questionTimerProvider = StateNotifierProvider.autoDispose<
  QuestionTimerNotifier,
  QuestionTimerState
>((ref) {
  return QuestionTimerNotifier(ref);
});

class QuestionTimerNotifier extends StateNotifier<QuestionTimerState> {
  final Ref ref;
  Timer? _ticker;

  QuestionTimerNotifier(this.ref)
    : super(
        QuestionTimerState(
          questionEndAt: null,
          questionRemaining: Duration.zero,
        ),
      );
  void startQuestion(int index) {
    _ticker?.cancel(); // stop old timer
    if (!mounted) {
      debugPrint("start question called but it is not mounted:");
      return;
    }
    final entry = ref.read(contestEntryProvider);
    final entryNotifier = ref.read(contestEntryProvider.notifier);

    if (index >= entry.questions.length) {
      // move to next section

      // before submission we need to update persist answer:
      entryNotifier.persistAnswers();
      // quit or submit

      entryNotifier
          .unifromContestSubmission(); // in the case of quetion timer we move forward to submit so user we'll submit asap he is completed all the previous questions:
      state = state.copyWith(
        questionEndAt: null,
        questionRemaining: Duration.zero,
      );
      return;
    }

    final now = ref.read(globalClockProvider);
    // this minus one avoid start one seconds and count zero as full second.
    final durationSeconds =
        (entry.contest.timeDuration.inSeconds / entry.questions.length as num)
            .toInt() -
        1;
    final endAt = now.add(Duration(seconds: durationSeconds));

    // Update contest's question current index
    ref.read(contestEntryProvider.notifier).updateIndex(index);

    // Set initial state
    state = state.copyWith(
      questionEndAt: endAt,
      questionRemaining: Duration(seconds: durationSeconds),
    );

    Duration remaining = Duration(seconds: durationSeconds);
    // Start periodic ticker
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // final currentTime = ref.read(globalClockProvider);
      remaining = Duration(seconds: remaining.inSeconds - 1);
      if (remaining.isNegative) {
        state = state.copyWith(questionRemaining: Duration.zero);
        _ticker?.cancel();
        moveToNextQuestion();
      } else {
        state = state.copyWith(questionRemaining: remaining);
      }
    });
  }

  void moveToNextQuestion() {
    _ticker?.cancel();
    final entry = ref.read(contestEntryProvider);
    final index = entry.currentIndex;
    debugPrint("move to next manually calling");
    ref.read(contestEntryProvider.notifier).uniformUpdateAnswers();

    startQuestion(index + 1);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

// -----------------------------------------------------dnd and pin stream --------------------------------------

/// --- DND Stream Provider ---
final dndProvider = StreamProvider.autoDispose<DndFilter>((ref) {
  return DndService.dndFilterStream;
});

final pinProvider = StreamProvider.autoDispose<PinState>((ref) async* {
  await PinService.setMonitorState(true);
  await PinService.getStatus();
  yield* PinService.pinEvents;
});
