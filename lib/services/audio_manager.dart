import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 音频/触感反馈管理器
///
/// 当前未打包音频资源(pubspec.yaml 缺 assets 声明)。
/// 在添加资源前,所有音频调用会优雅失败(try/catch 兜底)。
/// HapticFeedback 在 iOS/Android 上提供真实震动反馈,Web/桌面是 no-op。
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _sfxPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  double _volume = 0.5;
  String? _currentBgm;

  /// 初始化
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _bgmPlayer = AudioPlayer();
      _sfxPlayer = AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(_volume);
      await _sfxPlayer!.setVolume(_volume);
    } catch (e) {
      debugPrint('音频初始化失败 (可忽略): $e');
    }
    _isInitialized = true;
  }

  /// 切换 BGM (没变化或资源缺失时静默)
  Future<void> playBgm(String assetPath) async {
    if (!_isInitialized) await init();
    if (_currentBgm == assetPath && _isPlaying) return;
    if (_bgmPlayer == null) return;
    try {
      await _bgmPlayer!.stop();
      await _bgmPlayer!.play(AssetSource(assetPath));
      _currentBgm = assetPath;
      _isPlaying = true;
    } catch (e) {
      debugPrint('BGM 播放失败 ($assetPath): $e');
      _isPlaying = false;
    }
  }

  /// 兼容旧调用
  Future<void> playHenesysBGM() => playBgm('audio/射手村8bit.mp3');

  /// 播放短音效 (资源缺失时静默)
  Future<void> playSfx(String assetPath) async {
    if (!_isInitialized) await init();
    if (_sfxPlayer == null) return;
    try {
      await _sfxPlayer!.play(AssetSource(assetPath));
    } catch (e) {
      // sfx 静默失败,避免日志洪水
    }
  }

  // ========== 触感反馈 (iOS/Android 原生支持) ==========

  /// 攻击: 轻震
  void hapticHit() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact();
  }

  /// 暴击/受重伤: 重震
  void hapticHeavy() {
    if (kIsWeb) return;
    HapticFeedback.heavyImpact();
  }

  /// 升级/获得奖励: 选择音
  void hapticSuccess() {
    if (kIsWeb) return;
    HapticFeedback.selectionClick();
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
    if (_sfxPlayer != null) {
      await _sfxPlayer!.setVolume(_volume);
    }
  }

  /// 获取当前音量
  double get volume => _volume;

  /// 是否正在播放
  bool get isPlaying => _isPlaying;

  /// 是否在 Web 平台 (UI 用来显示提示)
  bool get isWeb => kIsWeb;

  /// 释放资源
  Future<void> dispose() async {
    await _bgmPlayer?.dispose();
    await _sfxPlayer?.dispose();
  }
}