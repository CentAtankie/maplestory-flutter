import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 音频管理器
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer? _bgmPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _volume = 0.5;
  bool _isWeb = false;

  /// 初始化
  Future<void> init() async {
    if (_isInitialized) return;
    
    // 检测是否在 Web 平台
    _isWeb = kIsWeb;
    
    if (!_isWeb) {
      // 非 Web 平台才初始化音频
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(_volume);
    }
    
    _isInitialized = true;
  }

  /// 播放射手村背景音乐
  Future<void> playHenesysBGM() async {
    if (!_isInitialized) await init();
    
    // Web 平台暂不支持本地音频
    if (_isWeb) {
      print('Web 平台暂不支持本地音频播放');
      return;
    }
    
    if (_isPlaying || _bgmPlayer == null) return;
    
    try {
      await _bgmPlayer!.play(AssetSource('audio/射手村8bit.mp3'));
      _isPlaying = true;
    } catch (e) {
      print('播放背景音乐失败: $e');
      // 不抛出异常，避免崩溃
    }
  }

  /// 停止播放
  Future<void> stop() async {
    if (_bgmPlayer == null) return;
    await _bgmPlayer!.stop();
    _isPlaying = false;
  }

  /// 暂停
  Future<void> pause() async {
    if (_bgmPlayer == null) return;
    await _bgmPlayer!.pause();
    _isPlaying = false;
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_bgmPlayer == null) return;
    await _bgmPlayer!.resume();
    _isPlaying = true;
  }

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_bgmPlayer != null) {
      await _bgmPlayer!.setVolume(_volume);
    }
  }

  /// 获取当前音量
  double get volume => _volume;

  /// 是否正在播放 (Web 平台始终返回 false)
  bool get isPlaying => _isWeb ? false : _isPlaying;

  /// 是否在 Web 平台
  bool get isWeb => _isWeb;

  /// 释放资源
  Future<void> dispose() async {
    if (_bgmPlayer != null) {
      await _bgmPlayer!.dispose();
    }
  }
}