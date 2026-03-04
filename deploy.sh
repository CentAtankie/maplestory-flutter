#!/bin/bash
# 一键部署到 GitHub 并触发构建

echo "🍁 冒险岛文字版 - 一键部署脚本"
echo "================================"

# 检查是否在正确目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误: 请在 maplestory-flutter 目录下运行此脚本"
    exit 1
fi

# 读取 GitHub 用户名
echo ""
read -p "请输入你的 GitHub 用户名: " USERNAME

if [ -z "$USERNAME" ]; then
    echo "❌ 用户名不能为空"
    exit 1
fi

REPO_URL="https://github.com/$USERNAME/maplestory-flutter.git"

echo ""
echo "📝 配置信息:"
echo "  GitHub 用户: $USERNAME"
echo "  仓库地址: $REPO_URL"
echo ""

# 初始化 git（如果还没初始化）
if [ ! -d ".git" ]; then
    echo "🔧 初始化 Git 仓库..."
    git init
    git branch -M main
fi

# 配置远程仓库
echo "🔧 配置远程仓库..."
git remote remove origin 2>/dev/null
git remote add origin "$REPO_URL"

# 提交代码
echo "📦 提交代码..."
git add .
git commit -m "Initial commit: 冒险岛文字版 Flutter 版" || echo "⚠️ 没有变更需要提交"

# 推送到 GitHub
echo "🚀 推送到 GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 推送成功!"
    echo ""
    echo "🔗 访问以下链接查看构建进度:"
    echo "  https://github.com/$USERNAME/maplestory-flutter/actions"
    echo ""
    echo "📥 构建完成后，在 Actions 页面下载:"
    echo "  - web-build.zip (网页版)"
    echo "  - android-apk.zip (Android 安装包)"
    echo "  - windows-build.zip (Windows 版)"
    echo ""
    echo "🌐 部署到 Render (可选):"
    echo "  1. 访问 https://render.com"
    echo "  2. 创建 New Static Site"
    echo "  3. 选择你的仓库"
    echo "  4. Build Command: flutter build web"
    echo "  5. Publish Directory: build/web"
else
    echo ""
    echo "❌ 推送失败，可能原因:"
    echo "  1. 仓库不存在，请先创建: https://github.com/new"
    echo "  2. 没有权限，请检查 GitHub 登录状态"
    echo "  3. 网络问题"
    echo ""
    echo "💡 手动创建仓库步骤:"
    echo "  1. 访问 https://github.com/new"
    echo "  2. Repository name: maplestory-flutter"
    echo "  3. 选择 Public"
    echo "  4. 点击 Create repository"
    echo "  5. 然后重新运行此脚本"
fi
