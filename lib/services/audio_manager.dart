import 'package:audioplayers/audioplayers.dart';

/// 音频管理器
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _volume = 0.5;

  /// 初始化
  Future<void> init() async {
    if (_isInitialized) return;
    
    // 设置循环播放
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(_volume);
    
    _isInitialized = true;
  }

  /// 播放射手村背景音乐
  Future<void> playHenesysBGM() async {
    if (!_isInitialized) await init();
    
    if (_isPlaying) return;
    
    try {
      await _bgmPlayer.play(AssetSource('audio/射手村8bit.mp3'));
      _isPlaying = true;
    } catch (e) {
      print('播放背景音乐失败: $e');
    }
  }

  /// 停止播放
  Future<void> stop() async {
    await _bgmPlayer.stop();
    _isPlaying = false;
  }

  /// 暂停
  Future<void> pause() async {
    await _bgmPlayer.pause();
    _isPlaying = false;
  }

  /// 恢复播放
  Future<void> resume() async {
    await _bgmPlayer.resume();
    _isPlaying = true;
  }

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_volume);
  }

  /// 获取当前音量
  double get volume => _volume;

  /// 是否正在播放
  bool get isPlaying => _isPlaying;

  /// 释放资源
  Future<void> dispose() async {
    await _bgmPlayer.dispose();
  }
}