#!/bin/bash

# 删除派生数据
rm -rf ~/Library/Developer/Xcode/DerivedData/IAAdvisor2-*

# 确保Info.plist权限正确
chmod 644 IAAdvisor2/Info.plist

# 打印版本检查
echo "Xcode Info.plist fixing script"
echo "==============================="
echo "当前目录: $(pwd)"
echo "Info.plist文件: $(ls -la IAAdvisor2/Info.plist 2>/dev/null || echo '文件不存在')"

# 确保Info.plist中有完整需要的字段
cat > IAAdvisor2/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>IA法律顾问</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>UILaunchScreen</key>
	<dict/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIUserInterfaceStyle</key>
	<string>Dark</string>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
	</dict>
</dict>
</plist>
EOF

echo "Info.plist已更新，请重新打开Xcode并构建项目" 