#!/bin/bash
#
# Star Office UI OpenClaw Plugin 安装脚本
# 
# 用法: ./install-plugin.sh [--uninstall] [API_URL] [API_TOKEN]
#
# 示例:
#   ./install-plugin.sh                           # 交互式安装
#   ./install-plugin.sh http://localhost:5000 token123  # 非交互式
#   ./install-plugin.sh --uninstall                # 卸载插件
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
PLUGIN_NAME="star-office"
PLUGIN_DIR="$HOME/.openclaw/extensions/star-office-plugin"
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
GIT_REPO="https://github.com/MISAKIGA/Star-Office-UI.git"
GIT_PLUGINS_DIR="plugins/openclaw"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_step "检查依赖..."
    
    if ! command -v git &> /dev/null; then
        log_error "git 未安装，请先安装 git"
        exit 1
    fi
    
    if ! command -v node &> /dev/null; then
        log_error "node 未安装，请先安装 Node.js"
        exit 1
    fi
    
    log_info "依赖检查完成"
}

# 解析参数
parse_args() {
    UNINSTALL=false
    API_URL=""
    API_TOKEN=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$API_URL" ]]; then
                    API_URL="$1"
                elif [[ -z "$API_TOKEN" ]]; then
                    API_TOKEN="$1"
                fi
                shift
                ;;
        esac
    done
}

# 显示帮助
show_help() {
    cat << EOF
Star Office UI OpenClaw Plugin 安装脚本

用法: 
    $0 [选项] [API_URL] [API_TOKEN]

选项:
    --uninstall     卸载插件
    --help, -h     显示帮助

参数:
    API_URL         Star Office UI 后端地址 (默认: http://localhost:5000)
    API_TOKEN       API 鉴权 Token

示例:
    $0
    $0 http://localhost:5000 my-token-123
    $0 --uninstall
EOF
}

# 交互式获取配置
prompt_config() {
    echo ""
    log_step "=== 插件配置 ==="
    
    if [[ -z "$API_URL" ]]; then
        read -p "Star Office UI 后端地址 [http://localhost:5000]: " API_URL
        API_URL=${API_URL:-http://localhost:5000}
    fi
    
    if [[ -z "$API_TOKEN" ]]; then
        read -p "API Token: " API_TOKEN
        while [[ -z "$API_TOKEN" ]]; do
            read -p "API Token 不能为空，请重新输入: " API_TOKEN
        done
    fi
    
    echo ""
    log_info "配置确认:"
    echo "  API 地址: $API_URL"
    echo "  API Token: $API_TOKEN"
    echo ""
}

# 安装插件
install_plugin() {
    log_step "安装 Star Office UI 插件..."
    
    # 创建插件目录
    mkdir -p "$PLUGIN_DIR"
    
    # 检查是否已有插件文件
    if [[ -f "$PLUGIN_DIR/index.ts" ]]; then
        log_info "插件已存在，跳过复制"
    else
        log_info "从 GitHub 克隆插件源码..."
        # 临时克隆获取插件源码
        TEMP_DIR=$(mktemp -d)
        git clone --depth 1 "$GIT_REPO" "$TEMP_DIR" 2>/dev/null || {
            log_error "无法从 GitHub 克隆，请检查网络连接"
            exit 1
        }
        
        if [[ -d "$TEMP_DIR/plugins/openclaw" ]]; then
            cp -r "$TEMP_DIR/plugins/openclaw/"* "$PLUGIN_DIR/"
            log_info "插件源码已复制到 $PLUGIN_DIR"
        else
            log_error "插件源码不存在于仓库中"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        rm -rf "$TEMP_DIR"
    fi
    
    # 安装依赖 (如果有)
    if [[ -f "$PLUGIN_DIR/package.json" ]]; then
        log_info "安装 npm 依赖..."
        cd "$PLUGIN_DIR"
        npm install 2>/dev/null || true
    fi
    
    # 配置 OpenClaw
    configure_openclaw
    
    log_info "安装完成!"
    echo ""
    log_step "下一步:"
    echo "  1. 重启 OpenClaw gateway: openclaw gateway restart"
    echo "  2. 访问 Star Office UI 验证状态同步"
    echo ""
}

# 配置 OpenClaw
configure_openclaw() {
    log_step "配置 OpenClaw..."
    
    # 确保 openclaw.json 存在
    if [[ ! -f "$OPENCLAW_CONFIG" ]]; then
        log_info "创建 OpenClaw 配置文件..."
        mkdir -p "$(dirname "$OPENCLAW_CONFIG")"
        echo '{"plugins": {}}' > "$OPENCLAW_CONFIG"
    fi
    
    # 使用 jq 或 python 更新配置
    if command -v jq &> /dev/null; then
        local config_json=$(cat "$OPENCLAW_CONFIG")
        config_json=$(echo "$config_json" | jq --arg url "$API_URL" --arg token "$API_TOKEN" \
            '.plugins["star-office"] = {"enabled": true, "config": {"apiUrl": $url, "apiToken": $token}}')
        echo "$config_json" > "$OPENCLAW_CONFIG"
    else
        # 使用 Python
        python3 << EOF
import json

config_file = "$OPENCLAW_CONFIG"
api_url = "$API_URL"
api_token = "$API_TOKEN"

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
except:
    config = {"plugins": {}}

config.setdefault("plugins", {})
config["plugins"]["star-office"] = {
    "enabled": True,
    "config": {
        "apiUrl": api_url,
        "apiToken": api_token
    }
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print("配置已更新")
EOF
    fi
    
    log_info "OpenClaw 配置已更新"
}

# 卸载插件
uninstall_plugin() {
    log_step "卸载 Star Office UI 插件..."
    
    # 从配置中移除
    if [[ -f "$OPENCLAW_CONFIG" ]]; then
        if command -v jq &> /dev/null; then
            local config_json=$(cat "$OPENCLAW_CONFIG")
            config_json=$(echo "$config_json" | jq 'del(.plugins["star-office"])')
            echo "$config_json" > "$OPENCLAW_CONFIG"
        else
            python3 << EOF
import json

config_file = "$OPENCLAW_CONFIG"

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    if "plugins" in config and "star-office" in config["plugins"]:
        del config["plugins"]["star-office"]
        
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
        print("配置已更新")
except Exception as e:
    print(f"配置更新失败: {e}")
EOF
        fi
    fi
    
    # 删除插件目录
    if [[ -d "$PLUGIN_DIR" ]]; then
        rm -rf "$PLUGIN_DIR"
        log_info "插件目录已删除"
    fi
    
    log_info "卸载完成!"
    echo ""
    log_step "下一步:"
    echo "  重启 OpenClaw gateway: openclaw gateway restart"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "  Star Office UI OpenClaw Plugin"
    echo "========================================"
    echo ""
    
    parse_args "$@"
    
    if [[ "$UNINSTALL" == "true" ]]; then
        uninstall_plugin
        exit 0
    fi
    
    check_dependencies
    prompt_config
    install_plugin
}

main "$@"
