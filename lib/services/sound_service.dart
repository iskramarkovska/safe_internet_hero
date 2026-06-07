import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool _muted = false;

  bool get isMuted => _muted;
  set muted(bool value) => _muted = value;

  Future<void> _play(String asset) async {
    if (_muted) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(asset));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {}
  }

  Future<void> playCorrect() => _play('sounds/correct.mp3');
  Future<void> playWrong() => _play('sounds/wrong.mp3');
  Future<void> playComplete(int stars) =>
      _play(stars == 3 ? 'sounds/complete_3star.mp3' : 'sounds/complete.mp3');
  Future<void> playCoin() => _play('sounds/coin.mp3');
  Future<void> playPurchase() => _play('sounds/purchase.mp3');
}
