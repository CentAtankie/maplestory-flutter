# 🍁 冒险岛文字版 - Flutter 版

基于 Flutter + Riverpod 重构的冒险岛文字 RPG，支持多平台发布。

## ✨ 特性

- 🎮 **回合制战斗** - 攻击、技能、逃跑
- 🗺️ **地图探索** - 射手村、东部平原、树洞等多个地图
- 👹 **多种怪物** - 蜗牛、绿水灵、蘑菇等经典怪物
- 📈 **升级系统** - 经验值、属性成长
- 💰 **装备金币** - 掉落、装备、商店
- 📱 **跨平台** - iOS、Android、Web、Windows、macOS、Linux

## 🚀 快速开始

### 1. GitHub Actions 自动构建（推荐）

已配置 `.github/workflows/build.yml`，推送到 GitHub 后自动构建：

```bash
cd maplestory-flutter
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/你的用户名/maplestory-flutter.git
git push -u origin main
```

然后在 GitHub → Actions 中查看构建进度，下载构建产物。

### 2. 本地开发

#### 安装 Flutter
```bash
# Windows
choco install flutter

# macOS
brew install flutter
```

#### 运行项目
```bash
cd maplestory-flutter
flutter pub get
flutter run
```

#### 构建发布版本
```bash
# Web
flutter build web

# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# iOS（需要 Mac）
flutter build ios --release
```

## 🎮 游戏操作

| 操作 | 说明 |
|------|------|
| 方向键 | 移动到其他地图 |
| 探索/休息 | 野外探索可能遇怪，村庄休息恢复 HP/MP |
| 攻击 | 普通攻击 |
| 技能 | 消耗 MP 的强力攻击 |
| 逃跑 | 50% 几率逃跑 |

## 📁 项目结构

```
maplestory-flutter/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── providers/
│   │   └── game_provider.dart # 游戏状态管理
│   ├── screens/
│   │   ├── game_screen.dart   # 探索界面
│   │   └── battle_screen.dart # 战斗界面
│   ├── widgets/
│   │   ├── status_bar.dart    # 状态栏
│   │   ├── game_log.dart      # 游戏日志
│   │   └── action_panel.dart  # 操作面板
│   └── game/
│       └── models/
│           ├── player.dart    # 玩家数据
│           ├── mob.dart       # 怪物数据
│           └── map.dart       # 地图数据
├── android/                    # Android 配置
├── .github/workflows/
│   └── build.yml              # CI/CD 配置
├── pubspec.yaml
└── README.md
```

## 🗺️ 游戏地图

```
明珠港 (lith)
    ↑
射手村 (henesys) ← → 东部平原 (farm) ← → ???
    ↓                   ↓
   ???               北部小路 (trail) → 树洞 (cave)
```

## 👹 怪物列表

| 怪物 | 等级 | HP | 攻击 | 经验 |
|------|------|-----|------|------|
| 蜗牛 | 1 | 15 | 3 | 2 |
| 蓝蜗牛 | 2 | 20 | 5 | 3 |
| 红蜗牛 | 3 | 30 | 8 | 5 |
| 绿水灵 | 4 | 40 | 12 | 8 |
| 蘑菇仔 | 6 | 60 | 15 | 12 |
| 蓝蘑菇 | 8 | 80 | 20 | 18 |
| 刺蘑菇 | 12 | 120 | 30 | 28 |

## 🛠 技术栈

- **Flutter** - UI 框架
- **Riverpod** - 状态管理
- **GitHub Actions** - CI/CD

## 📄 许可证

MIT

---

祝你游戏愉快！🎮
