// import 'package:flutter/material.dart';

// class CircularSegmentedBar extends StatelessWidget {
//   final int totalSegments;
//   final int currentSegment;
//   final double height;
//   final double gap;
//   final Color completedColor;
//   final Color remainingColor;

//   const CircularSegmentedBar({
//     super.key,
//     required this.totalSegments,
//     required this.currentSegment,
//     this.height = 10,
//     this.gap = 4,
//     this.completedColor = Colors.green,
//     this.remainingColor = Colors.grey,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: height,
//       child: CustomPaint(
//         painter: _CircularSegmentedBarPainter(
//           totalSegments: totalSegments,
//           currentSegment: currentSegment,
//           height: height,
//           gap: gap,
//           completedColor: completedColor,
//           remainingColor: remainingColor,
//         ),
//       ),
//     );
//   }
// }

// class _CircularSegmentedBarPainter extends CustomPainter {
//   final int totalSegments;
//   final int currentSegment;
//   final double height;
//   final double gap;
//   final Color completedColor;
//   final Color remainingColor;

//   _CircularSegmentedBarPainter({
//     required this.totalSegments,
//     required this.currentSegment,
//     required this.height,
//     required this.gap,
//     required this.completedColor,
//     required this.remainingColor,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..style = PaintingStyle.fill;

//     final totalGapWidth = gap * (totalSegments - 1);
//     final segmentWidth = (size.width - totalGapWidth) / totalSegments;

//     for (int i = 0; i < totalSegments; i++) {
//       final left = i * (segmentWidth + gap);
//       final rect = Rect.fromLTWH(left, 0, segmentWidth, height);
//       paint.color = i < currentSegment ? completedColor : remainingColor;
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(rect, Radius.circular(height / 2)),
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
// // import 'package:flutter/material.dart';

// class StopWatchWidget extends StatelessWidget {
//   final double size;
//   final String text;
//   final Color color;

//   const StopWatchWidget({
//     Key? key,
//     required this.size,
//     required this.text,
//     this.color = const Color.fromARGB(255, 52, 226, 209),
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size(size, size), // add extra space for knob
//       painter: _StopWatchPainter(color),
//       child: SizedBox(
//         width: size,
//         height: size,
//         child: Align(
//           alignment: Alignment.bottomCenter,
//           child: Container(
//             width: size,
//             height: size,
//             alignment: Alignment.center,
//             child: Text(
//               text,
//               style: TextTheme.of(
//                 context,
//               ).labelMedium?.copyWith(color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StopWatchPainter extends CustomPainter {
//   final Color color;

//   _StopWatchPainter(this.color);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()..color = color;

//     final double bodySize = size.width;
//     final Offset circleCenter = Offset(
//       bodySize / 2,
//       size.height - bodySize / 2,
//     );

//     // Circle path (main body)
//     Path circlePath =
//         Path()..addOval(
//           Rect.fromCircle(center: circleCenter, radius: bodySize / 2),
//         );
//     canvas.drawPath(circlePath, paint);

//     // Knob path (independent from circle)
//     double knobWidth = bodySize * 0.45;
//     double knobHeight = bodySize * 0.16;
//     double knobY = size.height - bodySize - 4; // gap of 4 px

//     Path knobPath =
//         Path()..addRRect(
//           RRect.fromRectAndRadius(
//             Rect.fromCenter(
//               center: Offset(bodySize / 2, knobY),
//               width: knobWidth,
//               height: knobHeight,
//             ),
//             Radius.circular(knobHeight / 2),
//           ),
//         );
//     canvas.drawPath(knobPath, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
