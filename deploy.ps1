# 一键部署脚本 (PowerShell 版本)

Write-Host "🍁 冒险岛文字版 - 一键部署脚本" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在正确目录
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ 错误: 请在 maplestory-flutter 目录下运行此脚本" -ForegroundColor Red
    exit 1
}

# 读取 GitHub 用户名
$USERNAME = Read-Host "请输入你的 GitHub 用户名"

if ([string]::IsNullOrWhiteSpace($USERNAME)) {
    Write-Host "❌ 用户名不能为空" -ForegroundColor Red
    exit 1
}

$REPO_URL = "https://github.com/$USERNAME/maplestory-flutter.git"

Write-Host ""
Write-Host "📝 配置信息:" -ForegroundColor Yellow
Write-Host "  GitHub 用户: $USERNAME"
Write-Host "  仓库地址: $REPO_URL"
Write-Host ""

# 初始化 git（如果还没初始化）
if (-not (Test-Path ".git")) {
    Write-Host "🔧 初始化 Git 仓库..." -ForegroundColor Yellow
    git init
    git branch -M main
}

# 配置远程仓库
Write-Host "🔧 配置远程仓库..." -ForegroundColor Yellow
git remote remove origin 2>$null
git remote add origin "$REPO_URL"

# 提交代码
Write-Host "📦 提交代码..." -ForegroundColor Yellow
git add .
git commit -m "Initial commit: 冒险岛文字版 Flutter 版" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ 没有变更需要提交或提交失败" -ForegroundColor Yellow
}

# 推送到 GitHub
Write-Host "🚀 推送到 GitHub..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ 推送成功!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔗 访问以下链接查看构建进度:" -ForegroundColor Cyan
    Write-Host "  https://github.com/$USERNAME/maplestory-flutter/actions"
    Write-Host ""
    Write-Host "📥 构建完成后，在 Actions 页面下载:" -ForegroundColor Cyan
    Write-Host "  - web-build.zip (网页版)"
    Write-Host "  - android-apk.zip (Android 安装包)"
    Write-Host "  - windows-build.zip (Windows 版)"
    Write-Host ""
    Write-Host "🌐 部署到 Render (可选):" -ForegroundColor Cyan
    Write-Host "  1. 访问 https://render.com"
    Write-Host "  2. 创建 New Static Site"
    Write-Host "  3. 选择你的仓库"
    Write-Host "  4. Build Command: flutter build web"
    Write-Host "  5. Publish Directory: build/web"
} else {
    Write-Host ""
    Write-Host "❌ 推送失败，可能原因:" -ForegroundColor Red
    Write-Host "  1. 仓库不存在，请先创建: https://github.com/new"
    Write-Host "  2. 没有权限，请检查 GitHub 登录状态"
    Write-Host "  3. 网络问题"
    Write-Host ""
    Write-Host "💡 手动创建仓库步骤:" -ForegroundColor Yellow
    Write-Host "  1. 访问 https://github.com/new"
    Write-Host "  2. Repository name: maplestory-flutter"
    Write-Host "  3. 选择 Public"
    Write-Host "  4. 点击 Create repository"
    Write-Host "  5. 然后重新运行此脚本"
}

Write-Host ""
Write-Host "按任意键继续..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
