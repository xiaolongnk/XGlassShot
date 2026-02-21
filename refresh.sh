#!/bin/bash

# =================================================================
# GlassCap 开发环境权限重置工具
# =================================================================

# 1. 设置你的 App Bundle Identifier
BUNDLE_ID="com.xiaolongou.glasscap"

echo "🚀 开始为 $BUNDLE_ID 重置开发环境权限..."

# 2. 重置屏幕录制权限 (Screen Recording)
echo "🔹 正在重置屏幕录制权限..."
sudo tccutil reset ScreenCapture $BUNDLE_ID

# 3. 重置辅助功能权限 (Accessibility - 如果你的截图工具需要监听全局快捷键)
echo "🔹 正在重置辅助功能权限..."
sudo tccutil reset Accessibility $BUNDLE_ID

# 4. 重置完全磁盘访问权限 (如果涉及保存文件到受限目录)
echo "🔹 正在重置完全磁盘访问权限..."
sudo tccutil reset All $BUNDLE_ID

cd ~/Library/Developer/Xcode/DerivedData/GlassCap-dvrfekbfomdokbaxdlignpcjiacm/Build/Products/Debug/
./GlassCap.app/Contents/MacOS/GlassCap
echo "✅ 重置完成！"
echo "💡 下次从 Cursor/Xcode 启动应用时，系统会重新触发权限引导。"
echo "⚠️ 请记得在 '系统设置 -> 隐私与安全性 -> 屏幕录制' 中手动重新勾选一次。"
