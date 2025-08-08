#!/bin/bash

# IA法律顾问 - 生产环境构建脚本
# 用于创建App Store提交的归档文件

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="IAAdvisor2"
SCHEME_NAME="IAAdvisor2"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build/"
BUILD_DIR="./build"

# 函数：打印带颜色的消息
print_message() {
    echo -e "${2}$1${NC}"
}

print_success() {
    print_message "$1" "$GREEN"
}

print_error() {
    print_message "$1" "$RED"
}

print_warning() {
    print_message "$1" "$YELLOW"
}

print_info() {
    print_message "$1" "$BLUE"
}

# 函数：检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 函数：检查Xcode版本
check_xcode_version() {
    if ! command_exists xcodebuild; then
        print_error "错误: 未找到xcodebuild命令，请确保已安装Xcode"
        exit 1
    fi
    
    local xcode_version=$(xcodebuild -version | head -n 1)
    print_info "当前Xcode版本: $xcode_version"
}

# 函数：检查项目文件
check_project_files() {
    if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
        print_error "错误: 未找到项目文件 ${PROJECT_NAME}.xcodeproj"
        exit 1
    fi
    
    print_success "项目文件检查通过"
}

# 函数：创建构建目录
create_build_directory() {
    if [ -d "$BUILD_DIR" ]; then
        print_warning "清理旧的构建目录..."
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_success "构建目录创建完成: $BUILD_DIR"
}

# 函数：检查证书和描述文件
check_certificates() {
    print_info "检查代码签名证书..."
    
    # 列出可用的证书
    security find-identity -v -p codesigning | grep "iPhone Distribution" > /dev/null
    if [ $? -eq 0 ]; then
        print_success "找到有效的分发证书"
    else
        print_warning "警告: 未找到iPhone Distribution证书，将尝试自动管理签名"
    fi
}

# 函数：清理项目
clean_project() {
    print_info "清理项目..."
    
    xcodebuild clean \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        > "$BUILD_DIR/clean.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "项目清理完成"
    else
        print_error "项目清理失败，请检查日志: $BUILD_DIR/clean.log"
        exit 1
    fi
}

# 函数：构建归档
build_archive() {
    print_info "开始构建归档文件..."
    
    xcodebuild archive \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
        > "$BUILD_DIR/archive.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "归档构建完成: $ARCHIVE_PATH"
    else
        print_error "归档构建失败，请检查日志: $BUILD_DIR/archive.log"
        tail -n 20 "$BUILD_DIR/archive.log"
        exit 1
    fi
}

# 函数：导出IPA
export_ipa() {
    print_info "导出IPA文件..."
    
    # 检查ExportOptions.plist文件
    if [ ! -f "ExportOptions.plist" ]; then
        print_warning "未找到ExportOptions.plist，创建默认配置..."
        create_export_options
    fi
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "ExportOptions.plist" \
        > "$BUILD_DIR/export.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "IPA导出完成"
        
        # 查找生成的IPA文件
        IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)
        if [ -n "$IPA_FILE" ]; then
            print_success "IPA文件位置: $IPA_FILE"
            
            # 显示文件大小
            IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
            print_info "IPA文件大小: $IPA_SIZE"
        fi
    else
        print_error "IPA导出失败，请检查日志: $BUILD_DIR/export.log"
        tail -n 20 "$BUILD_DIR/export.log"
        exit 1
    fi
}

# 函数：创建默认ExportOptions.plist
create_export_options() {
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
    print_success "创建默认ExportOptions.plist"
}

# 函数：验证构建产物
validate_build() {
    print_info "验证构建产物..."
    
    if [ -d "$ARCHIVE_PATH" ]; then
        print_success "归档文件验证通过"
        
        # 显示归档信息
        local archive_info=$(xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "/tmp" -exportOptionsPlist ExportOptions.plist -exportFormat None 2>&1 | grep -E "(Name|Version|Build)")
        print_info "归档信息:\n$archive_info"
    else
        print_error "归档文件验证失败"
        exit 1
    fi
    
    IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)
    if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
        print_success "IPA文件验证通过"
    else
        print_error "IPA文件验证失败"
        exit 1
    fi
}

# 函数：生成构建报告
generate_report() {
    print_info "生成构建报告..."
    
    local report_file="$BUILD_DIR/build-report.txt"
    
    cat > "$report_file" << EOF
IA法律顾问 构建报告
=====================

构建时间: $(date)
项目名称: $PROJECT_NAME
配置方案: $CONFIGURATION
构建机器: $(hostname)
Xcode版本: $(xcodebuild -version | head -n 1)

文件信息:
- 归档文件: $ARCHIVE_PATH
- IPA文件: $(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)
- IPA大小: $(du -h "$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)" | cut -f1)

Git信息:
- 提交哈希: $(git rev-parse HEAD 2>/dev/null || echo "未知")
- 分支名称: $(git branch --show-current 2>/dev/null || echo "未知")
- 最后提交: $(git log -1 --pretty=format:"%h - %an, %ar : %s" 2>/dev/null || echo "未知")

构建状态: 成功 ✅
EOF
    
    print_success "构建报告生成完成: $report_file"
}

# 函数：显示使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --clean    仅清理项目，不构建"
    echo "  -v, --validate 构建后验证产物"
    echo ""
    echo "环境变量:"
    echo "  DEVELOPMENT_TEAM  开发团队ID (必需)"
    echo ""
    echo "示例:"
    echo "  DEVELOPMENT_TEAM=ABC123DEFG $0"
    echo "  $0 --clean"
    echo "  $0 --validate"
}

# 主函数
main() {
    print_info "🚀 开始IA法律顾问生产环境构建流程"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                CLEAN_ONLY=true
                shift
                ;;
            -v|--validate)
                VALIDATE_ONLY=true
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 检查开发团队ID
    if [ -z "$DEVELOPMENT_TEAM" ]; then
        print_warning "警告: 未设置DEVELOPMENT_TEAM环境变量"
        print_info "示例: DEVELOPMENT_TEAM=ABC123DEFG $0"
    fi
    
    # 执行预检查
    check_xcode_version
    check_project_files
    check_certificates
    
    # 如果只是清理
    if [ "$CLEAN_ONLY" = true ]; then
        clean_project
        print_success "清理完成"
        exit 0
    fi
    
    # 如果只是验证
    if [ "$VALIDATE_ONLY" = true ]; then
        if [ -d "$ARCHIVE_PATH" ]; then
            validate_build
            print_success "验证完成"
        else
            print_error "未找到归档文件，请先执行构建"
            exit 1
        fi
        exit 0
    fi
    
    # 执行完整构建流程
    create_build_directory
    clean_project
    build_archive
    export_ipa
    validate_build
    generate_report
    
    print_success "🎉 构建流程完成！"
    print_info "构建产物位置: $BUILD_DIR"
    print_info "下一步: 上传到App Store Connect"
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi