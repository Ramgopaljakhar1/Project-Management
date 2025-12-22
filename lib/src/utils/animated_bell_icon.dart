import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedBellIcon extends StatefulWidget {
  final VoidCallback? onBellTap;

  const AnimatedBellIcon({Key? key, this.onBellTap}) : super(key: key);

  @override
  State<AnimatedBellIcon> createState() => _AnimatedBellIconState();
}

class _AnimatedBellIconState extends State<AnimatedBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    await _audioPlayer.play(AssetSource('audio/mixkit-kids-cartoon-close-bells-2256.wav'));
  }


  void _onTap() {
    _controller.forward(from: 0);
    _playNotificationSound().catchError((e) {
      debugPrint('Audio error: $e');
    });
    widget.onBellTap?.call();
  }


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[100],
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              double offsetX = _shakeAnimation.value.clamp(-10.0, 10.0);
              return Transform.translate(
                offset: Offset(offsetX, 0),
                child: child,
              );
            },
            child: const Icon(
              Icons.notifications_active,
              color: Colors.black87,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
