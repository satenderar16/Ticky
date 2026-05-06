import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class QuestionLoaderAnimation extends StatefulWidget {
  const QuestionLoaderAnimation({super.key});

  @override
  State<QuestionLoaderAnimation> createState() =>
      _QuestionLoaderAnimationState();
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
        tween: Tween<double>(
          begin: 0,
          end: _maxJumpHeight,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _maxJumpHeight,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller)..addListener(_onAnimate);

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

class AnimatedUpDown extends StatefulWidget {
  final bool active;
  final Widget child;
  final Duration duration;
  final Duration? autoHideDuration;
  final VoidCallback? onHidden;

  final bool enableFade;

  const AnimatedUpDown({
    required this.active,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.autoHideDuration,
    this.onHidden,
    this.enableFade = true,
    super.key,
  });

  @override
  State<AnimatedUpDown> createState() => _AnimatedUpDownState();
}

class _AnimatedUpDownState extends State<AnimatedUpDown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _offstage = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _offstage = true);
        widget.onHidden?.call();
      } else if (status == AnimationStatus.forward) {
        setState(() => _offstage = false);
      }
    });

    if (widget.active) _show();
  }

  @override
  void didUpdateWidget(covariant AnimatedUpDown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active && !oldWidget.active) {
      _show();
    } else if (!widget.active && oldWidget.active) {
      _hide();
    }
  }

  void _show() {
    _controller.forward();
    _offstage = false;

    _hideTimer?.cancel();
    if (widget.autoHideDuration != null) {
      _hideTimer = Timer(widget.autoHideDuration!, () {
        if (mounted && _controller.isCompleted) _hide();
      });
    }
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted && !_controller.isAnimating) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animatedChild =
        widget.enableFade
            ? FadeTransition(opacity: _opacity, child: widget.child)
            : widget.child;

    return Offstage(
      offstage: _offstage,
      child: SlideTransition(position: _slide, child: animatedChild),
    );
  }
}

// custom paint for getting the wavyshape border: can be used for loading as well:
class WavyCirclePainter extends CustomPainter {
  final double amplitude; // height of each wave
  final double frequency; // number of waves around the circle
  final Color color;
  final double strokeWidth;

  WavyCirclePainter({
    this.amplitude = 10,
    this.frequency = 8,
    this.color = Colors.blueAccent,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;

    final Path path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double baseRadius = min(cx, cy) - strokeWidth;

    for (double angle = 0; angle <= 2 * pi; angle += 0.02) {
      final double radius = baseRadius + sin(angle * frequency) * amplitude;
      final double x = cx + radius * cos(angle);
      final double y = cy + radius * sin(angle);

      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavyCirclePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.frequency != frequency ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// get custom shape with no. of spikes and it curve shape: with frequency and amplitude:
class WavyCircleClipper extends CustomClipper<Path> {
  final double amplitude; // how "splashy" the edge is
  final double frequency; // number of waves around the circle

  WavyCircleClipper({this.amplitude = 10, this.frequency = 10});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double baseRadius = min(centerX, centerY) - amplitude;

    // Create a rippled circular path using polar coordinates
    for (double angle = 0; angle <= 2 * pi; angle += 0.02) {
      final double radius =
          baseRadius + sin(angle * frequency) * amplitude; // wave distortion
      final double x = centerX + radius * cos(angle);
      final double y = centerY + radius * sin(angle);

      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WavyCircleClipper oldClipper) =>
      amplitude != oldClipper.amplitude || frequency != oldClipper.frequency;
}

/// three dot loading
///

typedef WaveFunction = double Function(double x);

class ThreeDotWave extends StatefulWidget {
  final double dotSize;
  final double spacing;
  final Color? color;
  final int durationMs;
  final double amplitude;
  final double maxScale;
  final double minScale;
  final double phaseDifference; // in radians
  final WaveFunction? waveFunc; // sine or cosine

  const ThreeDotWave({
    super.key,
    this.dotSize = 12,
    this.spacing = 8,
    this.color,
    this.durationMs = 1000,
    this.amplitude = 6.0,
    this.maxScale = 1.2,
    this.minScale = 0.6,
    this.phaseDifference = pi / 3, // 60 degrees default
    this.waveFunc,
  });

  @override
  State createState() => _ThreeDotWaveState();
}

class _ThreeDotWaveState extends State<ThreeDotWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late WaveFunction _waveFunc;

  @override
  void initState() {
    super.initState();

    _waveFunc = widget.waveFunc ?? sin; // default sine wave

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(); // continuous repeat
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.dotSize + widget.amplitude * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final phase = index * widget.phaseDifference;
              final waveValue = _waveFunc(2 * pi * _controller.value + phase);

              final dy = -waveValue * widget.amplitude;

              final scale =
                  widget.minScale +
                  (waveValue + 1) / 2 * (widget.maxScale - widget.minScale);

              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.dotSize,
                    height: widget.dotSize,
                    margin: EdgeInsets.symmetric(
                      horizontal: widget.spacing / 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color ?? colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
