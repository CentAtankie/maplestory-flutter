# 🚀 冒险岛文字版 - 自动构建指南

## 快速开始

### 方式 1：GitHub Actions 自动构建（推荐）

#### 步骤 1：创建 GitHub 仓库
1. 访问 https://github.com/new
2. 创建名为 `maplestory-flutter` 的仓库
3. 设置为 Public（免费使用 Actions）

#### 步骤 2：推送代码
```bash
cd C:\Users\forge\.openclaw\workspace\maplestory-flutter

# 初始化 git
git init
git add .
git commit -m "Initial commit"

# 添加远程仓库（替换为你的用户名）
git remote add origin https://github.com/你的用户名/maplestory-flutter.git
git branch -M main
git push -u origin main
```

#### 步骤 3：触发构建
1. 访问你的 GitHub 仓库
2. 点击 **Actions** 标签
3. 会看到工作流正在运行
4. 等待 5-10 分钟

#### 步骤 4：下载构建产物
构建完成后，在 **Actions** → 最新运行 → **Artifacts** 中下载：
- `web-build` - 网页版（部署到任意静态托管）
- `android-apk` - Android 安装包
- `windows-build` - Windows 可执行文件

---

### 方式 2：手动构建（需要安装 Flutter）

#### Windows 安装 Flutter
```powershell
# 1. 下载 Flutter
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" -OutFile "$env:TEMP\flutter.zip"

# 2. 解压到 C:\flutter
Expand-Archive -Path "$env:TEMP\flutter.zip" -DestinationPath "C:\"

# 3. 添加环境变量
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", "User")

# 4. 验证安装
flutter doctor
```

#### 构建命令
```bash
# 进入项目
cd C:\Users\forge\.openclaw\workspace\maplestory-flutter

# 获取依赖
flutter pub get

# 构建 Web
flutter build web --release
# 输出: build/web/

# 构建 Android APK
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk

# 构建 Windows
flutter build windows --release
# 输出: build/windows/x64/runner/Release/
```

---

### 方式 3：免费部署到 Render（Web 版）

#### 步骤 1：推送代码到 GitHub
（同上）

#### 步骤 2：部署到 Render
1. 访问 https://render.com
2. 注册账号（可用 GitHub 登录）
3. 点击 **New** → **Static Site**
4. 选择你的 GitHub 仓库
5. 配置：
   - **Build Command**: `flutter build web`
   - **Publish Directory**: `build/web`
6. 点击 **Create Static Site**

等待 3-5 分钟，获得免费网址：`https://maplestory-xxx.onrender.com`

---

## 📱 各平台运行

### Android
1. 下载 `app-release.apk`
2. 传输到手机
3. 安装（可能需要开启"允许未知来源"）
4. 开始游戏！

### Windows
1. 下载 `windows-build.zip`
2. 解压
3. 双击 `maplestory_flutter.exe`

### Web
1. 下载 `web-build.zip`
2. 解压到任意 Web 服务器
3. 或直接使用 Render/GitHub Pages 托管

---

## 🔧 常见问题

### Q: GitHub Actions 构建失败？
A: 检查：
- pubspec.yaml 格式是否正确
- lib 目录下是否有 dart 文件
- GitHub Actions 是否有权限（Settings → Actions → General）

### Q: APK 安装失败？
A: 需要在手机设置中开启：
- 设置 → 安全 → 未知来源 → 允许

### Q: Windows 版无法运行？
A: 需要安装 Visual C++ Redistributable：
https://aka.ms/vs/17/release/vc_redist.x64.exe

---

## 📝 项目文件说明

```
maplestory-flutter/
├── lib/                        # Dart 代码
│   ├── main.dart              # 应用入口
│   ├── providers/             # 状态管理
│   ├── screens/               # 界面
│   ├── widgets/               # 组件
│   └── game/                  # 游戏逻辑
│       └── models/            # 数据模型
├── .github/workflows/         # CI/CD 配置
│   └── build.yml              # 自动构建脚本
├── pubspec.yaml               # 依赖配置
└── BUILD.md                   # 本文件
```

---

祝你游戏愉快！🎮
