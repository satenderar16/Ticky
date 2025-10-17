// import 'dart:async';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:quthon/Contest/contest_model.dart';
// import 'package:quthon/Contest/contest_notifier.dart';
// import 'package:quthon/Models/question_model.dart';
// import '../Models/option_model.dart';
// import '../Service/Battery/battery_service.dart';
// import '../Service/brightness_service.dart';
// import '../Service/dnd_service.dart';
// import '../Service/pinn_service.dart';

// /// instead of this we can simply use variable isLoading , onError in ContestON Notifier class to dynamically handle the state.
// final questionsProvider = StateNotifierProvider.autoDispose<
//   QuestionsNotifier,
//   AsyncValue<List<Question>>
// >(QuestionsNotifier.new);

// class QuestionsNotifier extends StateNotifier<AsyncValue<List<Question>>> {
//   QuestionsNotifier(this.ref) : super(const AsyncValue.loading()) {
//     _loadInitialQuestions();
//   }
//   final Ref ref;

//   Future<void> _loadInitialQuestions() async {
//     try {
//       final questions = await ref
//           .read(contestOnProvider.notifier)
//           .loadQuestions(shouldFail: false);
//       state = AsyncValue.data(questions);
//     } catch (e, st) {
//       if (mounted) state = AsyncValue.error(e, st);
//     }
//   }

//   // Optional: expose a manual refresh method
//   Future<void> refreshQuestions() async {
//     state = const AsyncValue.loading();

//     try {
//       final questions =
//           await ref.read(contestOnProvider.notifier).loadQuestions();
//       // Check if the notifier is still mounted
//       /// mounted error happens when the user tries to back when loading is on going:
//       /// need to update the mounting error happens when user retry and in loading state pop the page so notifier get unmounted and show
//       /// Bad state: Future already completed:
//       /// we update async notifier to stateNotifier with async value with custom class which help state management with additional capabilities like mounted and dispose and more customization option
//       if (mounted) {
//         state = AsyncValue.data(questions);
//       }
//     } catch (e, st) {
//       if (mounted) {
//         state = AsyncValue.error(e, st);
//       }
//     }
//   }
// }

// final contestOnProvider =
//     StateNotifierProvider.autoDispose<ContestOnNotifier, ContestOnState>(
//       ContestOnNotifier.new,
//     );

// class ContestOnState {
//   final int batteryLevel;
//   final bool isCharging;
//   final double brightness;
//   final DndFilter dndFilter;
//   final PinState pinState;
//   final bool showBrightnessSlider;
//   final DateTime currentTime;
//   final List<Question> questions;

//   /// this variable will be taken as input from the test on widget which going to get testStart starting and ending time
//   final DateTime? testStartAt;
//   final DateTime? testEndAt;
//   final ContestListModel contestModel;

//   ///answer map to store all the answer in state.
//   final Map<String, dynamic> answers;

//   ContestOnState({
//     required this.batteryLevel,
//     required this.isCharging,
//     required this.brightness,
//     required this.dndFilter,
//     required this.pinState,
//     required this.showBrightnessSlider,
//     required this.currentTime,
//     required this.questions,
//     this.testStartAt,
//     this.testEndAt,
//     required this.contestModel,
//     this.answers = const {},
//   });

//   ContestOnState copyWith({
//     int? batteryLevel,
//     bool? isCharging,
//     double? brightness,
//     DndFilter? dndFilter,
//     PinState? pinState,
//     bool? showBrightnessSlider,
//     DateTime? currentTime,
//     List<Question>? questions,
//     DateTime? testStartAt,
//     DateTime? testEndAt,
//     ContestListModel? contestModel,
//     Map<String, dynamic>? answers,
//   }) {
//     return ContestOnState(
//       batteryLevel: batteryLevel ?? this.batteryLevel,
//       isCharging: isCharging ?? this.isCharging,
//       brightness: brightness ?? this.brightness,
//       dndFilter: dndFilter ?? this.dndFilter,
//       pinState: pinState ?? this.pinState,
//       showBrightnessSlider: showBrightnessSlider ?? this.showBrightnessSlider,
//       currentTime: currentTime ?? this.currentTime,
//       questions: questions ?? this.questions,
//       testStartAt: testStartAt ?? this.testStartAt,
//       testEndAt: testEndAt ?? this.testEndAt,
//       contestModel: contestModel ?? this.contestModel,
//       answers: answers ?? this.answers,
//     );
//   }
// }

// class ContestOnNotifier extends StateNotifier<ContestOnState> {
//   late final StreamSubscription _batterySub;
//   late final StreamSubscription _dndSub;
//   late final StreamSubscription _pinSub;
//   late final ContestListModel contestModel;
//   final Ref ref;
//   Timer? _timeTicker;
//   bool _isDisposed = false;

//   ContestOnNotifier(this.ref)
//     : super(
//         ContestOnState(
//           batteryLevel: 100,
//           isCharging: false,
//           brightness: 0.5,
//           dndFilter: DndFilter.none,

//           ///assuming test user is starting test with the dnd mode enable, compulsory for contests
//           pinState: PinState.pinned,

//           /// again assuming pinned state for contests.
//           showBrightnessSlider: false,
//           currentTime: DateTime.now(),
//           questions: [],

//           /// as only user can entry to contest via entry page
//           contestModel: ref.read(contestProvider).selectedContest!,
//         ),
//       ) {
//     _batterySub = BatteryService.batteryStream.listen(_onBatteryUpdate);
//     _dndSub = DndService.dndFilterStream.listen((dnd) {
//       state = state.copyWith(dndFilter: dnd);
//     });
//     _pinSub = PinService.pinEvents.listen((pin) {
//       state = state.copyWith(pinState: pin);
//     });

//     _initBrightness();

//     ///this replace by the init state of testOn widget so when the widget is initialized it will start clock and sync with system time
//     // startClock();
//   }
//   @override
//   bool get mounted => !_isDisposed;

//   /// calling api to get the questions
//   Future<List<Question>> loadQuestions({bool shouldFail = false}) async {
//     await Future.delayed(Duration(seconds: 2));

//     /// this void the condition of notifier can't modifier the other notifier while building the widget.
//     if (!mounted) return [];

//     if (shouldFail) {
//       throw "failed to load the data";
//     }

//     final questions = buildSampleQuestions();
//     if (mounted) state = state.copyWith(questions: questions);
//     return questions;
//   }

//   ///temporary function:
//   List<Question> buildSampleQuestions() {
//     return <Question>[
//       Question(
//         id: 'q1',
//         text:
//             'A school decides to award its students for three activities: sports, academics, and discipline. The total prize money is ₹6000. If the money is divided in the ratio 5:3:2 among sports, academics, and discipline respectively, how much money does each activity get?',
//         options: [
//           Option(id: 'a', text: '₹3000, ₹1800, ₹1200'),
//           Option(id: 'b', text: '₹2500, ₹2000, ₹1500'),
//           Option(id: 'c', text: '₹3500, ₹1500, ₹1000'),
//           Option(id: 'd', text: '₹2800, ₹2000, ₹1200'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q2',
//         text:
//             'The following table shows the daily income of 50 workers of a factory:\n\nIncome (in ₹): 100–120 | 120–140 | 140–160 | 160–180 | 180–200\nNumber of workers:     5        | 10       | 15       | 10       | 10\n\nFind the mean daily income of the workers using the assumed mean method.',
//         options: [
//           Option(id: 'a', text: '₹150'),
//           Option(id: 'b', text: '₹160'),
//           Option(id: 'c', text: '₹155'),
//           Option(id: 'd', text: '₹145'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q3',
//         text:
//             'The angle of elevation of the top of a building from the foot of a tower is 30°, and the angle of elevation of the top of the tower from the foot of the building is 60°. If the tower is 50 m high, find the height of the building and the distance between them.',
//         options: [
//           Option(id: 'a', text: '86.6 m, 50 m'),
//           Option(id: 'b', text: '28.9 m, 50 m'),
//           Option(id: 'c', text: '25 m, 25 m'),
//           Option(id: 'd', text: '50 m, 86.6 m'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q4',
//         text:
//             'A card is drawn at random from a well-shuffled deck of 52 cards. Find the probability that the card drawn is:\n(a) a red king,\n(b) a card of spade or an ace,\n(c) a red card or a queen,\n(d) neither a king nor a queen.',
//         options: [
//           Option(id: 'a', text: '1/26, 4/13, 15/26, 44/52'),
//           Option(id: 'b', text: '2/52, 17/52, 15/52, 44/52'),
//           Option(id: 'c', text: '1/26, 1/13, 7/26, 11/13'),
//           Option(id: 'd', text: '2/52, 13/52, 15/52, 50/52'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q5',
//         text:
//             'From the top of a 7 m high building, the angle of elevation of the top of a tower is 60° and the angle of depression of its foot is 45°. Find the height of the tower and the distance between the building and the tower (use √3 = 1.73).',
//         options: [
//           Option(id: 'a', text: '19.11 m, 7 m'),
//           Option(id: 'b', text: '18.11 m, 7 m'),
//           Option(id: 'c', text: '20.11 m, 10 m'),
//           Option(id: 'd', text: '21.11 m, 10 m'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q6',
//         text:
//             'A metallic spherical ball of radius 4.2 cm is melted and recast into smaller spherical balls of radius 0.7 cm. Find how many such smaller balls can be made.',
//         options: [
//           Option(id: 'a', text: '512'),
//           Option(id: 'b', text: '729'),
//           Option(id: 'c', text: '343'),
//           Option(id: 'd', text: '1000'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q7',
//         text:
//             'In a circle of radius 21 cm, an arc subtends an angle of 60° at the centre. Find the length of the arc and the area of the corresponding sector.',
//         options: [
//           Option(id: 'a', text: '22 cm, 231 cm²'),
//           Option(id: 'b', text: '11 cm, 115.5 cm²'),
//           Option(id: 'c', text: '33 cm, 346.5 cm²'),
//           Option(id: 'd', text: '21 cm, 231 cm²'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q8',
//         text:
//             'A cone is cut through a plane parallel to its base and the top portion is removed. What is the name of the remaining solid? If the original cone had a height of 12 cm and the cut was made at 8 cm, what is the height of the frustum?',
//         options: [
//           Option(id: 'a', text: 'Frustum, 4 cm'),
//           Option(id: 'b', text: 'Cylinder, 12 cm'),
//           Option(id: 'c', text: 'Cone, 8 cm'),
//           Option(id: 'd', text: 'Frustum, 8 cm'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q9',
//         text:
//             'Prove that √2 is an irrational number using the method of contradiction. Give all steps clearly and justify why assuming it is rational leads to a contradiction.',
//         options: [
//           Option(id: 'a', text: 'Proof using contradiction'),
//           Option(id: 'b', text: 'Proof using geometry'),
//           Option(id: 'c', text: 'Proof by assumption of integers'),
//           Option(id: 'd', text: 'Direct proof'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//       Question(
//         id: 'q10',
//         text:
//             'The sum of the squares of three numbers is 138. If the square of the second number is 8 less than the square of the first and the third number is 2 more than the first, find the three numbers.',
//         options: [
//           Option(id: 'a', text: '5, 3, 7'),
//           Option(id: 'b', text: '6, 4, 8'),
//           Option(id: 'c', text: '7, 5, 9'),
//           Option(id: 'd', text: '8, 6, 10'),
//         ],
//         timeAllocated: Duration(seconds: 10),
//       ),
//     ]..shuffle();
//   }

//   List<Question> shuffleQuestion() {
//     ///shallow copy , if question get modified then reflect changes in our only to view and answer the question not to modify them
//     List<Question> sam = state.questions;

//     ///shuffle question to create a random order quiz. if wants to get the option shuffle we can shuffle it
//     return [...sam]..shuffle();
//   }

//   void questionSet(List<Question> q) {
//     state = state.copyWith(questions: q);
//   }

//   void questionReset() {
//     state = state.copyWith(questions: []);
//   }

//   void setTestStartTest(DateTime dateTime) {
//     ///update the test to get the value of testStartAt
//     state = state.copyWith(testStartAt: dateTime);
//   }

//   void setTestEndTest(DateTime dateTime) {
//     ///update the test to get the value of testEndAt
//     state = state.copyWith(testEndAt: dateTime);
//   }

//   /// initial battery and when stream changes the value:
//   /// this can be improve with getting map for platform channel todo
//   void _onBatteryUpdate(String data) {
//     final parts = data.split(' ');
//     final isCharging = parts.length == 2 && parts[0] == 'charging';
//     final level = int.tryParse(isCharging ? parts[1] : parts[0]) ?? 0;
//     state = state.copyWith(batteryLevel: level, isCharging: isCharging);
//   }

//   /// initial brightness
  // Future<void> _initBrightness() async {
  //   final brightness = await BrightnessService.getSystemBrightness();
  //   state = state.copyWith(brightness: brightness);
  // }

//   /// once widget builds then clock starts :
//   void startClock() {
//     _timeTicker?.cancel();

//     void updateTime() {
//       if (!mounted) return;
//       final now = DateTime.now();
//       state = state.copyWith(currentTime: now);
//     }

//     final now = DateTime.now();

//     /// sync time preciseness up to milliseconds
//     final initialDelay = Duration(
//       seconds: 60 - now.second,
//       milliseconds: -now.millisecond,
//     );

//     /// update each minutes instead of seconds
//     _timeTicker = Timer(initialDelay, () {
//       updateTime();

//       _timeTicker = Timer.periodic(const Duration(minutes: 1), (timer) {
//         if (!mounted) {
//           timer.cancel();
//           return;
//         }
//         updateTime();
//       });
//     });
//   }

//   ///update receive brightness value:
//   void updateBrightness(double newValue) {
//     BrightnessService.applyCustomBrightness(newValue);
//     state = state.copyWith(brightness: newValue);
//   }

//   void toggleBrightnessSlider() {
//     state = state.copyWith(showBrightnessSlider: !state.showBrightnessSlider);
//   }

//   Future<void> brightnessRestore() async {
//     BrightnessService.restore();
//   }

//   @override
//   void dispose() {
//     _isDisposed = true;
//     _batterySub.cancel();
//     _dndSub.cancel();
//     _pinSub.cancel();
//     _timeTicker?.cancel();
//     super.dispose();
//   }
// }
