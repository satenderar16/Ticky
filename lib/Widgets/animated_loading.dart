import 'dart:math';
import 'package:flutter/material.dart';

class QuestionLoaderAnimation extends StatefulWidget {
  const QuestionLoaderAnimation({super.key});

  @override
  State<QuestionLoaderAnimation> createState() => _QuestionLoaderAnimationState();
}

class _QuestionLoaderAnimationState extends State<QuestionLoaderAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _positionAnimation;

  static const double _maxJumpHeight = 200;
  static const double _baseSize = 60;
  static const double _squishedHeight = 5;
  static const double _squishedWidthIncrease = 20;

  final Random _random = Random();

  final List<Color> _colors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.indigoAccent,
    Colors.deepPurpleAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  double _width = _baseSize;
  double _height = _baseSize;
  Color _color = Colors.deepPurple;
  BorderRadius _borderRadius = BorderRadius.circular(16);
  bool _isSquished = false;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    // Add this line to apply a random shape at the beginning
    _randomizeShape();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _positionAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: _maxJumpHeight)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _maxJumpHeight, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller)
      ..addListener(_onAnimate);

    _startLoop();
  }


  void _onAnimate() {
    final value = _positionAnimation.value;

    if (value <= 1 && !_isSquished) {
      _isSquished = true;
      _applySquish();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isActive) _randomizeShape();
      });
    }

    if (value > 1 && _isSquished) {
      _isSquished = false;
      _resetShapeSize();
    }

    setState(() {});
  }

  void _applySquish() {
    _height = _squishedHeight;
    _width = _baseSize + _squishedWidthIncrease;
  }

  void _resetShapeSize() {
    _height = _baseSize;
    _width = _baseSize;
  }

  void _randomizeShape() {
    _color = _colors[_random.nextInt(_colors.length)];
    _borderRadius = BorderRadius.only(
      topLeft: Radius.circular(_random.nextDouble() * 40),
      topRight: Radius.circular(_random.nextDouble() * 40),
      bottomLeft: Radius.circular(_random.nextDouble() * 40),
      bottomRight: Radius.circular(_random.nextDouble() * 40),
    );
  }

  Future<void> _startLoop() async {
    while (_isActive) {
      await _controller.forward();
      if (!_isActive) break;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!_isActive) break;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _isActive = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// Ground impact bar / shadow bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSquished ? 150 : 100,
            height: 2,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _color.withAlpha(150), // Shadow color
                  blurRadius: 30, // Amount of blur
                  spreadRadius: 4,
                  offset: const Offset(0, 15), // Slightly below the bar
                ),
              ],
            ),
          ),

          /// Jumping shape
          AnimatedBuilder(
            animation: _positionAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_positionAnimation.value),
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: _color.withAlpha(150),
                borderRadius: _borderRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
