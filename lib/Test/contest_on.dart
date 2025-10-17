// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:quthon/Contest/contest_model.dart';
// import 'package:quthon/Contest/contest_notifier.dart';
// import 'package:quthon/Models/option_model.dart';
// import 'package:quthon/Service/brightness_service.dart';
// import 'package:quthon/Test/submit_page.dart';
// import 'package:quthon/Test/contest_on_notifier.dart';
// import '../animated_loading.dart';
// import 'countdown_notifier.dart';

// class ThemeWrapper extends StatefulWidget {
//   final Widget Function(BuildContext context, void Function() toggleTheme)
//   builder;

//   const ThemeWrapper({super.key, required this.builder});

//   @override
//   State<ThemeWrapper> createState() => _ThemeWrapperState();
// }

// class _ThemeWrapperState extends State<ThemeWrapper> {
//   late bool _isDark;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final brightness = MediaQuery.platformBrightnessOf(context);
//     _isDark = brightness == Brightness.dark;
//   }

//   void _toggleTheme() {
//     setState(() {
//       _isDark = !_isDark;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data:
//           _isDark
//               ? ThemeData.dark(useMaterial3: true)
//               : ThemeData.light(useMaterial3: true),
//       child: Builder(
//         builder: (context) => widget.builder(context, _toggleTheme),
//       ),
//     );
//   }
// }

// class ContestOn extends ConsumerStatefulWidget {
//   const ContestOn({super.key, required this.contest, required this.toggleMode});
//   final ContestListModel contest;
//   final VoidCallback toggleMode;

//   /// theme toggle mode:

//   @override
//   ConsumerState<ContestOn> createState() => _TestOnState();
// }

// class _TestOnState extends ConsumerState<ContestOn>
//     with WidgetsBindingObserver {
//   final Map<String, Map<String, dynamic>> answerMetadata = {};

//   void saveAnswer({
//     required String questionId,
//     required String selectedOptionId,
//     required int timeToAnswer,
//   }) {
//     answerMetadata[questionId] = {
//       'pid': selectedOptionId,
//       'timeToAnswer': timeToAnswer,
//     };

//     debugPrint(
//       'Answer saved for $questionId → pid: $selectedOptionId, time: ${timeToAnswer}s\n',
//     );
//     debugPrint('Current answerMetadata: $answerMetadata');
//   }

//   late final PageController _pageController;
//   int? _currentIndex;

//   /// question timer counter to auto submit and move to next question:

//   final ValueNotifier<int> _remainingSeconds = ValueNotifier(0);
//   Timer? _timer;
//   DateTime? dateTime;
//   void _startCountdown() {
//     _timer?.cancel();
//     dateTime = DateTime.now();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_remainingSeconds.value != 0) {
//         _remainingSeconds.value--;
//       }
//       if (_remainingSeconds.value == 0) {
//         final time = DateTime.now();
//         final quesList = ref.read(contestOnProvider).questions;

//         ///save the question
//         saveAnswer(
//           questionId: quesList[_currentIndex!].id,
//           selectedOptionId: selectedOption.value ?? "",
//           timeToAnswer: time.difference(dateTime!).inMilliseconds,
//         );

//         ///move to next page
//         if (quesList.length - 1 == _currentIndex) {
//           //submit calls
//           /// navigator to submit screen:
//           submitContest();
//           // _timer?.cancel();
//           // Navigator.of(
//           //   context,
//           // ).pushReplacement(MaterialPageRoute(builder: (context) => SubmitPage()));

//           return;
//         }

//         /// when the total timer of contest expires
//         if (widget.contest.endAt.difference(time).inSeconds <= 0) {
//           _timer?.cancel();
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => SubmitPage()),
//           );

//           /// navigator to submit screen:
//           return;
//         }
//         _pageController.nextPage(
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );

//         ///update variable will be handle by the OnPageChange
//       }
//     });
//   }

//   String _formatTime(int totalSeconds) {
//     final minutes = totalSeconds ~/ 60;
//     final seconds = totalSeconds % 60;
//     return '$minutes:${seconds.toString().padLeft(2, '0')}';
//   }

//   late final DateTime? initialTime;

//   /// submit contest and forward to new page:
//   void submitContest() async {
//     ///cancel timer if running, obviously it is running
//     _timer?.cancel();
//     // move to another page
//     Navigator.of(
//       context,
//     ).pushReplacement(MaterialPageRoute(builder: (context) => SubmitPage()));
//   }

//   @override
//   void initState() {
//     debugPrint('initState called');
//     WidgetsBinding.instance.addObserver(this);
//     ref.read(contestOnProvider.notifier).startClock();
//     initialTime = DateTime.now();
//     debugPrint(" this is starting time: $initialTime");
//     _pageController = PageController();

//     /// lock orientation as it will cause the focus change of app which may lead to test cancellation instead user want to rotate he/she we provided button
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.initState();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     ///sync the time when user exit app which is not allowed in test when user uses as non- contest environment then it help:
//     if (state == AppLifecycleState.resumed) {
//       ref.read(contestOnProvider.notifier).startClock(); // Resync clock
//     }
//   }

//   @override
//   void dispose() {
//     // restore brightness setting:
//     BrightnessService.restore();
//     debugPrint(
//       "this is dispose widget calling : ${initialTime?.difference(DateTime.now()).inSeconds}",
//     );
//     _timer?.cancel();
//     _remainingSeconds.dispose();
//     selectedOption.dispose();
//     WidgetsBinding.instance.removeObserver(this);

//     /// to let user decide there preferred orientation for device not in test only the app toggle are allow to monitor the
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//     super.dispose();
//   }

//   /// option toggle
//   final ValueNotifier<String?> selectedOption = ValueNotifier(null);
//   void toggleOnSelect(String index) {
//     if (selectedOption.value == index) {
//       selectedOption.value = null;
//       return;
//     }
//     selectedOption.value = index;
//   }

//   @override
//   Widget build(BuildContext context) {
//     ///testOn state
//     final showBrightnessSlider = ref.watch(
//       contestOnProvider.select((b) => b.showBrightnessSlider),
//     );

//     /// to sync the per question timer with available time
//     final currentTime = ref.watch(
//       contestOnProvider.select((s) => s.currentTime),
//     );

//     /// widget.contest can be remove by the contestProvider selectedQuestion
//     final remaining = widget.contest.endAt.difference(currentTime);

//     final notifier = ref.read(contestOnProvider.notifier);
//     // final colorScheme = Theme.of(context).colorScheme;
//     final screenWidth = MediaQuery.sizeOf(context).width;

//     /// question fetching
//     final questionsAsync = ref.watch(questionsProvider);
//     final questionsNotifier = ref.read(questionsProvider.notifier);

//     return Scaffold(
//       extendBody: true,
//       appBar: AppBar(
//         title: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Contest Id',
//               overflow: TextOverflow.ellipsis,
//               maxLines: 2,
//             ),
//             Consumer(
//               builder: (context, ref, child) {
//                 final currentTime = ref.watch(
//                   contestOnProvider.select((s) => s.currentTime),
//                 );
//                 return Text(
//                   DateFormat('h:mm a').format(currentTime),
//                   style: TextTheme.of(context).labelSmall,
//                 );
//               },
//             ),
//           ],
//         ),
//         leading: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: BatteryIcon(colorScheme: Theme.of(context).colorScheme),
//         ),
//         actions: [
//           TextButton(onPressed: widget.toggleMode, child: Text("theme")),
//           IconButton(
//             icon: Icon(
//               showBrightnessSlider
//                   ? Icons.brightness_5_rounded
//                   : Icons.brightness_5_outlined,
//               color:
//                   showBrightnessSlider
//                       ? Theme.of(context).colorScheme.primary
//                       : null,
//             ),
//             onPressed: () {
//               notifier.toggleBrightnessSlider();
//             },
//           ),
//         ],
//         bottom:
//             showBrightnessSlider
//                 ? PreferredSize(
//                   preferredSize: Size(screenWidth, 50),
//                   child: BrightnessWidget(),
//                 )
//                 : PreferredSize(
//                   preferredSize: Size(screenWidth, 0),
//                   child: Divider(thickness: 0, height: 0),
//                 ),
//       ),
//       body: questionsAsync.when(
//         loading: () {
//           return const Center(
//             child: RepaintBoundary(child: QuestionLoaderAnimation()),
//           );
//         },
//         error:
//             (error, stack) => Center(
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Center(
//                       child: Image.asset(
//                         "assets/error_page.png",
//                         fit: BoxFit.contain,
//                         height: 250,
//                       ),
//                     ),
//                     Text("Something Went Wrong Try again!!"),
//                     FilledButton.tonal(
//                       onPressed: () {
//                         questionsNotifier.refreshQuestions();
//                       },
//                       child: Text("Retry"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         data: (questions) {
//           /// Start timer only once rest is timer reassigning value will be handle by the onPageChange
//           if (_timer == null || !_timer!.isActive) {
//             setState(() {
//               _currentIndex = 0;
//             });

//             /// to determine the question time based on the available time

//             _remainingSeconds.value =
//                 remaining.inSeconds > questions.first.timeAllocated.inSeconds
//                     ? questions.first.timeAllocated.inSeconds
//                     : remaining.inSeconds;
//             _startCountdown();
//           }

//           return Stack(
//             children: [
//               PageView.builder(
//                 controller: _pageController,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: questions.length,
//                 onPageChanged: (pageIndex) {
//                   /// when widget got disposed but page change calls:
//                   if (!mounted) return;

//                   ///after changing the page pageIndex is new page's index:
//                   selectedOption.value = null;

//                   /// take the current index for global access
//                   setState(() {
//                     _currentIndex = pageIndex;
//                   });
//                   dateTime = DateTime.now();
//                   _timer?.cancel();
//                   _remainingSeconds.value =
//                       widget.contest.endAt
//                                   .difference(dateTime!)
//                                   .inSeconds >
//                               questions[pageIndex].timeAllocated.inSeconds
//                           ? questions[pageIndex].timeAllocated.inSeconds
//                           : widget.contest.endAt
//                               .difference(dateTime!)
//                               .inSeconds;
//                   _startCountdown();
//                 },

//                 itemBuilder: (BuildContext context, int qIndex) {
//                   return _buildQuestionDetails(context: context);
//                 },
//               ),

//               ///timer and control button (skip and next)
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _ContestTimer(key: ValueKey(questions[_currentIndex!].id)),
//                     _buildQuestionSubmit(
//                       context: context,
//                       colorScheme: Theme.of(context).colorScheme,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildQuestionDetails({required BuildContext context}) {
//     final questions = ref.read(contestOnProvider).questions;
//     if (questions.isEmpty) {
//       debugPrint(
//         "Error: _buildQuestionDetails found empty list, Contest Can't have Empty list or mounted Error happens",
//       );
//       return SizedBox.shrink();
//     }

//     final index = _currentIndex!;
//     final question = questions[index];
//     final textTheme = TextTheme.of(context);
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             ///question no.
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Card(
//                   elevation: 0,
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text("Question: ${index + 1}/${questions.length}"),
//                   ),
//                 ),
//               ],
//             ),

//             /// question description
//             Card(
//               elevation: 0,

//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 12,
//                 ),
//                 child: Column(
//                   children: [Text(question.text, style: textTheme.bodyLarge)],
//                 ),
//               ),
//             ),

//             Text("Options"),

//             /// option widget to get the option form the given one:
//             ValueListenableBuilder<String?>(
//               valueListenable: selectedOption,
//               builder: (context, selected, _) {
//                 return Column(
//                   children: List.generate(question.options.length, (index) {
//                     final option = question.options[index];
//                     final isSelected = selected == option.id;

//                     return Card(
//                       clipBehavior: Clip.antiAliasWithSaveLayer,
//                       elevation: 0,
//                       color:
//                           isSelected
//                               ? Colors.green.withAlpha(20)
//                               : Colors.transparent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(24),
//                         side: BorderSide(
//                           color:
//                               isSelected
//                                   ? Colors.green.withAlpha(130)
//                                   : Theme.of(
//                                     context,
//                                   ).colorScheme.surfaceContainerHigh,
//                           width: 1,
//                         ),
//                       ),
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 6,
//                       ),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(10),
//                         onTap: () => toggleOnSelect(option.id),
//                         child: ListTile(
//                           leading: Text(
//                             option.id,
//                             style: Theme.of(
//                               context,
//                             ).textTheme.bodyLarge?.copyWith(
//                               color:
//                                   isSelected
//                                       ? Colors.green.withAlpha(230)
//                                       : null,
//                             ),
//                           ),
//                           trailing:
//                               isSelected
//                                   ? const Icon(Icons.check, color: Colors.green)
//                                   : null,
//                           title: Text(
//                             option.text,
//                             style: TextStyle(
//                               color:
//                                   isSelected
//                                       ? Colors.green.withAlpha(230)
//                                       : null,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }),
//                 );
//               },
//             ),
//             SizedBox(height: 120),
//           ],
//         ),
//       ),
//     );
//   }

//   SafeArea _buildQuestionSubmit({
//     required BuildContext context,
//     required ColorScheme colorScheme,
//   }) {
//     final questions = ref.read(contestOnProvider).questions;

//     /// after getting data there is no case where _current index is nullable
//     final question = questions[_currentIndex!];
//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: AnimatedSize(
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeInSine,
//           child: Card(
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(36),
//             ),
//             color: colorScheme.surfaceContainer.withAlpha(200),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 spacing: 8,
//                 children: [
//                   /// conditional timer or prev button for based on contest and user practise mode:
//                   // TextButton(
//                   //   onPressed: () {
//                   //     if(_currentIndex ==0)return;
//                   //       _pageController.previousPage(
//                   //         duration: Duration(milliseconds: 300),
//                   //         curve: Curves.easeInOut,
//                   //       );
//                   //   },
//                   //   child: Text("skip"),
//                   // ),
//                   _buildQuestionTimer(context: context),
//                   FilledButton(
//                     style: FilledButton.styleFrom(
//                       elevation: 1,
//                       // tapTargetSize: MaterialTapTargetSize.shrinkWrap, // disables extra tap space
//                     ),
//                     onPressed: () {
//                       final time = DateTime.now();
//                       final diff = time.difference(dateTime!);

//                       ///save the answer
//                       saveAnswer(
//                         questionId: question.id,
//                         selectedOptionId: selectedOption.value ?? "",
//                         timeToAnswer: diff.inMilliseconds,
//                       );
//                       dateTime = time;

//                       /// move to next page

//                       if (questions.length - 1 == _currentIndex) {
//                         /// move to submit page
//                         submitContest();

//                         /// take the current index for global access
//                         return;
//                       }
//                       _pageController.nextPage(
//                         duration: Duration(milliseconds: 300),

//                         curve: Curves.easeInOut,
//                       );
//                     },
//                     child: ValueListenableBuilder(
//                       valueListenable: selectedOption,
//                       builder:
//                           (__, value, _) =>
//                               Text(value != null ? "submit" : "Next"),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   ValueListenableBuilder<int> _buildQuestionTimer({
//     required BuildContext context,
//   }) {
//     final colorScheme = Theme.of(context).colorScheme;
//     return ValueListenableBuilder<int>(
//       valueListenable: _remainingSeconds,
//       builder: (context, value, _) {
//         final Color? textColor = value <= 10 ? colorScheme.error : null;

//         return Card(
//           elevation: 0,
//           color: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Text(
//               _formatTime(value),
//               style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _ContestTimer extends ConsumerWidget {
//   const _ContestTimer({super.key});

//   ///remaining total contest timing formatter
//   String formatDuration(Duration duration) {
//     // final days = duration.inDays;
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);

//     /// for all previous contest only shows the minutes:

//     if (hours != 0) {
//       return '$hours hr${hours > 1 ? 's' : ''} $minutes min';
//     } else {
//       return '$minutes min';
//     }
//   }

//   /// total time showing reverse counter or not
//   bool shouldUseCountdown(Duration remaining) {
//     return remaining.inMinutes <= 2 && remaining > Duration.zero;
//   }

//   Widget _buildTimeCard(String text, {bool isUrgent = false}) {
//     return Card(
//       elevation: 0,
//       margin: EdgeInsets.all(12),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(20),
//           bottomLeft: Radius.circular(20),
//           topRight: Radius.circular(10),
//           bottomRight: Radius.circular(10),
//         ),
//       ),
//       child: Padding(padding: const EdgeInsets.all(12.0), child: Text(text)),
//     );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final contest = ref.watch(contestProvider).selectedContest!;
//     final currentTime = ref.watch(
//       contestOnProvider.select((s) => s.currentTime),
//     );
//     final remaining = contest.endAt.difference(currentTime);

//     // Use precise countdown when remaining time is <= 120s
//     if (shouldUseCountdown(remaining)) {
//       final countdown = ref.watch(countdownProvider(contest.endAt));
//       return _buildTimeCard(countdown.displayText, isUrgent: true);
//     }

//     // Fallback to regular display
//     final displayText = formatDuration(remaining);
//     return _buildTimeCard(displayText);
//   }
// }

// class SelectionCard extends StatefulWidget {
//   final List<Option> options;
//   final ValueChanged<String> onSelected;

//   const SelectionCard({
//     super.key,
//     required this.options,
//     required this.onSelected,
//   });

//   @override
//   State<SelectionCard> createState() => _SelectionCardState();
// }

// class _SelectionCardState extends State<SelectionCard> {
//   String? selectedOptionId;

//   void _onSelect(String id) {
//     setState(() {
//       selectedOptionId = id;
//     });
//     widget.onSelected(id);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Column(
//       children:
//           widget.options.map((option) {
//             final isSelected = selectedOptionId == option.id;

//             return Card(
//               key: ValueKey(option.id),
//               clipBehavior: Clip.antiAliasWithSaveLayer,
//               elevation: 0,
//               color:
//                   isSelected ? Colors.green.withAlpha(20) : Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(24),
//                 side: BorderSide(
//                   color:
//                       isSelected
//                           ? Colors.green.withAlpha(130)
//                           : colorScheme.surfaceContainerHigh,
//                   width: 1,
//                 ),
//               ),
//               margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(10),
//                 onTap: () => _onSelect(option.id),
//                 child: ListTile(
//                   leading: Text(
//                     option.id,
//                     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                       color: isSelected ? Colors.green.withAlpha(230) : null,
//                     ),
//                   ),
//                   trailing:
//                       isSelected
//                           ? const Icon(Icons.check, color: Colors.green)
//                           : null,
//                   title: Text(
//                     option.text,
//                     style: TextStyle(
//                       color: isSelected ? Colors.green.withAlpha(230) : null,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//     );
//   }
// }

// class BrightnessWidget extends ConsumerWidget {
//   const BrightnessWidget({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final brightness = ref.watch(contestOnProvider).brightness;
//     final notifier = ref.read(contestOnProvider.notifier);
//     final colorScheme = Theme.of(context).colorScheme;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: 500),
//         child: SliderTheme(
//           data: SliderTheme.of(context).copyWith(
//             trackHeight: 25.0,
//             overlayShape: const RoundSliderOverlayShape(overlayRadius: 15.0),
//             trackShape: const RoundedRectSliderTrackShape(),
//             activeTrackColor: colorScheme.tertiaryContainer,
//             inactiveTrackColor: colorScheme.surfaceContainerHigh,
//             thumbColor: colorScheme.surface,
//             showValueIndicator: ShowValueIndicator.never,
//           ),
//           child: Slider(
//             value: brightness,
//             min: 0,
//             max: 1,
//             // divisions: 100,
//             onChanged: notifier.updateBrightness,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class BatteryIcon extends ConsumerWidget {
//   final ColorScheme colorScheme;

//   const BatteryIcon({super.key, required this.colorScheme});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final batteryLevel = ref.watch(
//       contestOnProvider.select((b) => b.batteryLevel),
//     );

//     final chargingState = ref.watch(
//       contestOnProvider.select((c) => c.isCharging),
//     );
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       child: CustomPaint(
//         painter: _BatteryPainter(
//           level: batteryLevel,
//           charging: chargingState,
//           colorScheme: colorScheme,
//         ),
//         child: SizedBox(
//           width: 40,
//           height: 40,
//           child: Center(
//             child:
//                 chargingState
//                     ? const Icon(Icons.electric_bolt, size: 12)
//                     : Text(
//                       '$batteryLevel',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,

//                         color:
//                             batteryLevel < 10
//                                 ? colorScheme.error
//                                 : colorScheme.primary,
//                       ),
//                     ), // Render actual content
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TimerAvatar extends StatelessWidget {
//   final int timeLeftInSeconds;
//   final int totalTimeInSeconds;
//   final double radius;
//   final double strokeWidth;
//   final Color normalColor;
//   final Color warningColor;
//   final Color backgroundColor;

//   const TimerAvatar({
//     super.key,
//     required this.timeLeftInSeconds,
//     required this.totalTimeInSeconds,
//     this.radius = 15,
//     this.strokeWidth = 6,
//     this.normalColor = Colors.green,
//     this.warningColor = Colors.red,
//     this.backgroundColor = Colors.grey,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final progress = timeLeftInSeconds / totalTimeInSeconds;
//     final isWarning = timeLeftInSeconds <= 5;

//     final fillColor = isWarning ? warningColor : normalColor;

//     final size = (radius + strokeWidth) * 2;

//     return SizedBox(
//       width: size,
//       height: size,
//       child: CustomPaint(
//         painter: TimerCirclePainter(
//           progress: progress,
//           strokeWidth: strokeWidth,
//           fillColor: fillColor,
//           backgroundColor: backgroundColor,
//           radius: radius,
//         ),
//         child: Center(
//           child: Text(
//             "$timeLeftInSeconds",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: isWarning ? warningColor : Colors.black,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class TimerCirclePainter extends CustomPainter {
//   final double progress;
//   final double strokeWidth;
//   final Color fillColor;
//   final Color backgroundColor;
//   final double radius;

//   TimerCirclePainter({
//     required this.progress,
//     required this.strokeWidth,
//     required this.fillColor,
//     required this.backgroundColor,
//     required this.radius,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);

//     final Paint backgroundPaint =
//         Paint()
//           ..strokeWidth = strokeWidth
//           ..color = backgroundColor
//           ..style = PaintingStyle.stroke;

//     final Paint fillPaint =
//         Paint()
//           ..strokeWidth = strokeWidth
//           ..color = fillColor
//           ..style = PaintingStyle.stroke
//           ..strokeCap = StrokeCap.round;

//     canvas.drawCircle(center, radius, backgroundPaint);

//     final angle = 2 * pi * progress;
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -pi / 2,
//       angle,
//       false,
//       fillPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// class _BatteryPainter extends CustomPainter {
//   final int? level;
//   final bool charging;
//   final ColorScheme colorScheme;

//   _BatteryPainter({
//     required this.level,
//     required this.charging,
//     required this.colorScheme,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     /// this is actually shape on canvas to show the circle only draw with stoke :
//     final Paint base =
//         Paint()
//           ..strokeWidth = 6
//           ..color = colorScheme.surfaceContainer
//           ..style = PaintingStyle.stroke;

//     final Offset center = Offset(size.width / 2, size.height / 2);
//     final double radius = (size.width / 2) - 4;

//     canvas.drawCircle(center, radius, base);

//     if (level == null) return;

//     /// shows the battery in
//     final Paint fill =
//         Paint()
//           ..strokeWidth = 6
//           ..color =
//               charging
//                   ? Colors.green
//                   : (level! < 10
//                       ? colorScheme.error
//                       : colorScheme.primaryFixedDim)
//           ..style = PaintingStyle.stroke
//           ..strokeCap = StrokeCap.round;

//     /// just to let start the value from right to left:
//     final double angle = -2 * pi * (level! / 100);

//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -pi / 2,
//       angle,
//       false,
//       fill,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
