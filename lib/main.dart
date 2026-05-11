import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/game_provider.dart';
import 'repositories/hive_save_repository.dart';
import 'repositories/save_repository.dart';
import 'repositories/supabase_save_repository.dart';
import 'screens/game_screen.dart';
import 'services/audio_manager.dart';

// ===================== Supabase 配置 =====================
const String supabaseUrl = 'https://jwanzezqcwzievzpjnil.supabase.co';
const String supabaseAnonKey = 'sb_publishable_SCgGMpokhJuu3JVoWM2slQ_zYocgZSm';
// =========================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive 本地存档（作为离线回退）
  await HiveSaveRepository().init();

  // 初始化 Supabase（如果配置了 URL）
  SaveRepository? cloudRepository;
  if (supabaseUrl.startsWith('https://')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      final repo = SupabaseSaveRepository();
      await repo.init();
      cloudRepository = repo;
    } catch (e) {
      // Supabase 初始化失败时回退到本地 Hive 存档
      // ignore: avoid_print
      print('Supabase 初始化失败，使用本地存档: $e');
    }
  }

  // 初始化音频并播放背景音乐
  await AudioManager().init();
  await AudioManager().playHenesysBGM();

  runApp(
    ProviderScope(
      overrides: [
        if (cloudRepository != null)
          saveRepositoryProvider.overrideWithValue(cloudRepository),
      ],
      child: const MapleStoryApp(),
    ),
  );
}

class MapleStoryApp extends ConsumerStatefulWidget {
  const MapleStoryApp({super.key});

  @override
  ConsumerState<MapleStoryApp> createState() => _MapleStoryAppState();
}

class _MapleStoryAppState extends ConsumerState<MapleStoryApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // app 进入后台/隐藏/即将销毁时立即存档
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(gameProvider.notifier).flushSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '冒险岛文字版',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const GameScreenWrapper(),
    );
  }
}
