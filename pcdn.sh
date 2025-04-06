#!/bin/bash

# PCDN 管理腳本

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 更新系統限制設置
update_system_limits() {
    echo -e "${BLUE}更新系統限制設置...${NC}"
    
    # 設定 limits.conf
    LIMITS_CONF="/etc/security/limits.conf"
    if [[ -f "$LIMITS_CONF" ]]; then
        if ! grep -q "^\* soft nofile 524288" "$LIMITS_CONF"; then
            echo "* soft nofile 524288" >> "$LIMITS_CONF"
        fi
        if ! grep -q "^\* hard nofile 524288" "$LIMITS_CONF"; then
            echo "* hard nofile 524288" >> "$LIMITS_CONF"
        fi
        echo -e "${GREEN}已更新 limits.conf${NC}"
    else
        echo -e "${YELLOW}警告: 找不到 $LIMITS_CONF 文件${NC}"
    fi

    # 讓當前 shell 立即生效新的文件描述符限制
    ulimit -n 524288
    echo -e "${GREEN}當前 shell 的文件描述符限制已設置為 $(ulimit -n)${NC}"

    # 設定 sysctl.conf
    SYSCTL_CONF="/etc/sysctl.conf"
    if [[ -f "$SYSCTL_CONF" ]]; then
        SYSCTL_SETTINGS=(
            "fs.inotify.max_user_instances = 25535"
            "net.core.rmem_max=600000000"
            "net.core.wmem_max=600000000"
        )
        for setting in "${SYSCTL_SETTINGS[@]}"; do
            if ! grep -q "^${setting}" "$SYSCTL_CONF"; then
                echo "$setting" >> "$SYSCTL_CONF"
            fi
        done
        echo -e "${GREEN}已更新 sysctl.conf${NC}"

        # 重新載入 sysctl 設定，立即生效
        sysctl -p > /dev/null 2>&1 || echo -e "${YELLOW}警告: sysctl -p 命令失敗${NC}"
        echo -e "${GREEN}sysctl 設定已重新載入${NC}"
    else
        echo -e "${YELLOW}警告: 找不到 $SYSCTL_CONF 文件${NC}"
    fi

    echo -e "${GREEN}系統限制設置已更新。注意：limits.conf 的設定對新會話生效，當前 shell 已透過 ulimit 指令更新。${NC}"
}

# 檢查 root 權限
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}錯誤: 此腳本需要 root 權限才能執行${NC}"
        echo -e "${YELLOW}請使用 sudo 或以 root 用戶身份運行此腳本${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}已確認 root 權限${NC}"
}

# 檢查是否提供了安裝標誌
parse_install_flag() {
    local auto_install="false"
    for arg in "$@"; do
        if [[ "$arg" == "-i" || "$arg" == "--install" ]]; then
            auto_install="true"
            break
        fi
    done
    echo "$auto_install"
}

# 在腳本開始前檢查 Docker 和 Docker Compose 是否已安裝
check_docker_environment() {
    local install_option="$1"
    
    # 檢查 Docker 是否已安裝
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安裝${NC}"
        if [[ "$install_option" == "true" || "$install_option" == "cn" ]]; then
            install_docker "$install_option"
        else
            read -p "是否現在安裝 Docker? (y/n): " confirm
            if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                install_docker "false"
            else
                echo -e "${RED}PCDN 服務需要 Docker，請先安裝 Docker 或使用 -i/--install 參數自動安裝${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}Docker 已安裝${NC}"
    fi
    
    # 檢查 Docker Compose 是否已可用 (現代版本的 Docker 已內建 Docker Compose)
    if ! docker compose version &> /dev/null; then
        echo -e "${YELLOW}警告: 無法使用 Docker Compose。請確保您安裝的是最新版本的 Docker。${NC}"
        echo -e "${YELLOW}嘗試安裝/重新安裝 Docker 以獲得 Docker Compose 功能...${NC}"
        
        if [[ "$install_option" == "true" || "$install_option" == "cn" ]]; then
            install_docker "$install_option"
        else
            read -p "是否現在安裝/重新安裝 Docker? (y/n): " confirm
            if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                install_docker "false"
            else
                echo -e "${RED}PCDN 服務需要 Docker Compose，無法繼續。${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}Docker Compose 已可用${NC}"
    fi
}

# 確保 conf 目錄存在
ensure_conf_dir() {
    if [[ ! -d "conf" ]]; then
        mkdir -p conf
        echo -e "${BLUE}已創建 conf 目錄${NC}"
    fi
}

# 啟動 PCDN 服務函數
start_pcdn() {
    if ! check_config; then
        echo -e "${RED}配置檢查失敗，無法啟動 PCDN 服務${NC}"
        return 1
    fi
    
    echo -e "${GREEN}正在啟動 PCDN 服務...${NC}"
    
    # 檢查服務是否已經運行
    if docker compose ps | grep -q "Up"; then
        echo -e "${YELLOW}PCDN 服務已經在運行中${NC}"
        read -p "是否重新啟動? (y/n): " restart
        if [[ $restart != [yY] && $restart != [yY][eE][sS] ]]; then
            echo -e "${BLUE}操作已取消${NC}"
            return 0
        fi
    fi

    # 停止現有的容器
    echo -e "${BLUE}停止現有容器...${NC}"
    docker compose down &> /dev/null

    # 拉取最新映像
    echo -e "${BLUE}拉取最新映像...${NC}"
    retry "docker compose pull" "拉取 Docker 映像"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}無法拉取最新映像，啟動失敗${NC}"
        return 1
    fi

    # 啟動服務
    echo -e "${BLUE}啟動 PCDN 服務...${NC}"
    retry "docker compose up -d --remove-orphans" "啟動 Docker 容器"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}啟動 PCDN 服務失敗${NC}"
        return 1
    fi

    echo -e "${GREEN}PCDN 服務已成功啟動！${NC}"
    
    # 顯示運行中的容器
    echo -e "${BLUE}目前運行中的服務:${NC}"
    docker compose ps
    return 0
}

# 停止 PCDN 服務函數
stop_pcdn() {
    echo -e "${RED}正在停止 PCDN 服務...${NC}"
    
    # 檢查服務是否正在運行
    if ! docker compose ps | grep -q "Up"; then
        echo -e "${YELLOW}沒有運行中的 PCDN 服務${NC}"
        return 0
    fi
    
    # 嘗試解除容器目錄的不可變屬性（如果存在）
    if [[ -d "./data/docker/containers" ]]; then
        echo -e "${BLUE}解除容器目錄屬性限制...${NC}"
        chattr -i -R ./data/docker/containers &> /dev/null || true
    fi
    
    # 停止服務
    echo -e "${BLUE}停止 Docker 容器...${NC}"
    retry "docker compose down" "停止 Docker 容器"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}停止 PCDN 服務失敗${NC}"
        return 1
    fi
    
    echo -e "${GREEN}PCDN 服務已成功停止${NC}"
    return 0
}

# 刪除 PCDN 服務函數
delete_pcdn() {
    echo -e "${YELLOW}警告: 即將刪除 PCDN 服務及所有相關數據!${NC}"
    echo -e "${YELLOW}此操作將會:${NC}"
    echo -e "${YELLOW}  - 停止所有 PCDN 容器${NC}"
    echo -e "${YELLOW}  - 刪除所有 PCDN 容器${NC}"
    echo -e "${YELLOW}  - 刪除所有數據 (./data/*)${NC}"
    echo -e "${YELLOW}此操作不可逆!${NC}"
    
    read -p "確定要繼續嗎? 輸入 'DELETE' 以確認: " confirm
    if [[ "$confirm" != "DELETE" ]]; then
        echo -e "${BLUE}操作已取消${NC}"
        return 0
    fi
    
    echo -e "${RED}開始執行刪除操作...${NC}"
    
    # 嘗試解除容器目錄的不可變屬性（如果存在）
    if [[ -d "./data/docker/containers" ]]; then
        echo -e "${BLUE}解除容器目錄屬性限制...${NC}"
        chattr -i -R ./data/docker/containers &> /dev/null || true
    fi
    
    # 停止所有容器
    echo -e "${BLUE}停止所有容器...${NC}"
    docker compose down &> /dev/null || true
    
    # 刪除容器
    echo -e "${BLUE}刪除所有容器...${NC}"
    docker compose rm -f &> /dev/null || true

    # 刪除所有映像
    echo -e "${BLUE}刪除所有映像...${NC}"
    docker rmi -f $(docker images -q) &> /dev/null || true
    
    # 刪除數據目錄
    if [[ -d "./data" ]]; then
        echo -e "${BLUE}刪除數據目錄...${NC}"
        rm -rf ./data
    fi
    
    echo -e "${GREEN}PCDN 服務及相關數據已成功刪除${NC}"
    return 0
}

# 配置 PCDN 服務函數
config_pcdn() {
    echo -e "${BLUE}正在配置 PCDN 服務...${NC}"
    
    # 配置 .env 檔案
    config_env
    
    # 配置 .key 檔案
    config_key
    
    echo -e "${GREEN}PCDN 服務配置已完成${NC}"
}

# 顯示選單函數
show_menu() {
    clear
    echo "===================================="
    echo "        PCDN 服務管理選單           "
    echo "===================================="
    echo "1. 啟動 PCDN 服務"
    echo "2. 停止 PCDN 服務"
    echo "3. 刪除 PCDN 服務"
    echo "4. 配置 PCDN 服務"
    echo "0. 退出"
    echo "===================================="
}

# 生成或修改 .env 檔案
config_env() {
    ensure_conf_dir
    local hook_enable=${1:-"false"}
    local hook_region=${2:-"cn"}
    
    echo -e "${BLUE}設定 HOOK_ENABLE (true/false): ${NC}"
    read -p "(預設: $hook_enable): " input_hook_enable
    hook_enable=${input_hook_enable:-$hook_enable}
    
    echo -e "${BLUE}設定 HOOK_REGION (當前只支援 cn): ${NC}"
    read -p "(預設: $hook_region): " input_hook_region
    hook_region=${input_hook_region:-$hook_region}
    
    # 生成 conf/.env 檔案
    cat > conf/.env << EOF
HOOK_ENABLE=${hook_enable}
HOOK_REGION=${hook_region}
EOF
    echo -e "${GREEN}conf/.env 檔案已生成${NC}"
}

# 生成或修改 .key 檔案
config_key() {
    ensure_conf_dir
    local token=${1:-""}
    
    if [[ -z "$token" ]]; then
        echo -e "${BLUE}請輸入 token: ${NC}"
        read -p "" token
    fi
    
    # 生成 conf/.key 檔案
    echo "$token" > conf/.key
    echo -e "${GREEN}conf/.key 檔案已生成${NC}"
}

# 檢查 Docker 及 Docker Compose 是否已安裝
check_docker_installed() {
    local auto_install=$1
    
    # 檢查 Docker 是否已安裝
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安裝${NC}"
        if [[ "$auto_install" == "true" ]]; then
            install_docker
        else
            read -p "是否現在安裝 Docker? (y/n): " confirm
            if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                install_docker
            else
                echo -e "${RED}PCDN 服務需要 Docker，請先安裝 Docker${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}Docker 已安裝${NC}"
    fi
    
    # 檢查 Docker Compose 是否已可用 (現代版本的 Docker 已內建 Docker Compose)
    if ! docker compose version &> /dev/null; then
        echo -e "${YELLOW}警告: 無法使用 Docker Compose。請確保您安裝的是最新版本的 Docker。${NC}"
        echo -e "${YELLOW}嘗試安裝/重新安裝 Docker 以獲得 Docker Compose 功能...${NC}"
        
        if [[ "$AUTO_INSTALL" == "true" ]]; then
            install_docker
        else
            read -p "是否現在安裝/重新安裝 Docker? (y/n): " confirm
            if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                install_docker
            else
                echo -e "${RED}PCDN 服務需要 Docker Compose，無法繼續。${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}Docker Compose 已可用${NC}"
    fi
    
    return 0
}

# 添加 Docker 安裝重試函數
retry() {
    local command="$1"
    local description="$2"
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        echo -e "${BLUE}嘗試 $attempt/$max_attempts: $description${NC}"
        eval $command && break
        
        echo -e "${YELLOW}嘗試 $attempt/$max_attempts 失敗，稍等後重試...${NC}"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        echo -e "${RED}錯誤: 在 $max_attempts 次嘗試後，$description 操作失敗${NC}"
        return 1
    fi
    
    return 0
}

# 使用中國地區源安裝 Docker
install_docker_cn() {
    echo -e "${BLUE}使用中國地區源安裝 Docker...${NC}"
    
    # 檢測 Linux 發行版
    local ID=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        ID=$ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        ID=$DISTRIB_ID
    else
        echo -e "${RED}無法識別的 Linux 發行版${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}檢測到 Linux 發行版: $ID${NC}"
    
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
        # Ubuntu/Debian 下使用阿里云 Docker 源安装
        apt update -y
        apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt update -y
        retry "apt install -y docker-ce docker-ce-cli containerd.io" "安裝 Docker"
    elif [[ "$ID" == "centos" || "$ID" == "rhel" ]]; then
        # CentOS/RHEL 下使用阿里云 Docker 源安装
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        retry "yum install -y docker-ce docker-ce-cli containerd.io" "安裝 Docker"
        systemctl start docker
    elif [[ "$ID" == "fedora" ]]; then
        # Fedora 下使用 dnf 安装
        dnf install -y yum-utils device-mapper-persistent-data lvm2
        dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        retry "dnf install -y docker-ce docker-ce-cli containerd.io" "安裝 Docker"
        systemctl start docker
    else
        echo -e "${RED}不支持的發行版: $ID${NC}"
        exit 1
    fi
    
    # 修改 Docker 源（設置鏡像加速器）
    echo -e "${BLUE}修改 Docker 源...${NC}"
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.dadunode.com"]
}
EOF
    retry "systemctl restart docker" "重啟 Docker"
    
    # 將當前用戶加入 docker 群組
    usermod -aG docker $USER
    echo -e "${GREEN}Docker 安裝完成！${NC}"
    echo -e "${GREEN}已設置 Docker 中國鏡像加速器${NC}"
}

# 安裝 Docker (根據選擇的區域)
install_docker() {
    local region="international"
    local install_option="$1"
    
    # 如果明確指定了中國區域安裝
    if [[ "$install_option" == "cn" ]]; then
        region="cn"
    else
        # 如果未指定區域，詢問用戶
        echo -e "${BLUE}請選擇 Docker 安裝源:${NC}"
        echo "1. 國際源 (默認)"
        echo "2. 中國源 (阿里雲)"
        read -p "請選擇 [1/2]: " choice
        
        case $choice in
            2)
                region="cn"
                ;;
            *)
                region="international"
                ;;
        esac
    fi
    
    echo -e "${BLUE}正在安裝 Docker (使用${region}源)...${NC}"
    
    if [[ "$region" == "cn" ]]; then
        install_docker_cn
        return $?
    fi
    
    # 檢測作業系統類型（國際版安裝）
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # 使用官方安裝腳本
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo -e "${GREEN}Docker 安裝完成！${NC}"
        echo -e "${GREEN}此安裝包含了 Docker Compose 功能${NC}"
        
        # 移除安裝腳本
        rm get-docker.sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}請從 https://docs.docker.com/desktop/install/mac/ 下載並安裝 Docker Desktop for Mac${NC}"
        echo -e "${YELLOW}Docker Desktop 已包含 Docker Compose 功能${NC}"
        exit 1
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo -e "${YELLOW}請從 https://docs.docker.com/desktop/install/windows/ 下載並安裝 Docker Desktop for Windows${NC}"
        echo -e "${YELLOW}Docker Desktop 已包含 Docker Compose 功能${NC}"
        exit 1
    else
        echo -e "${RED}無法識別的作業系統，請手動安裝 Docker${NC}"
        exit 1
    fi
}

# 解析命令行參數
parse_args() {
    local token=""
    local region=""
    local hook_enable="false"
    local command="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--token)
                token="$2"
                shift 2
                ;;
            -r|--region)
                region="$2"
                hook_enable="true"  # 當有指定 region 時，自動啟用 HOOK_ENABLE
                shift 2
                ;;
            -i|--install)
                # 已經在腳本開頭處理了
                shift
                ;;
            *)
                echo -e "${RED}錯誤：未知參數 $1${NC}"
                return 1
                ;;
        esac
    done
    
    case "$command" in
        start)
            # 如果提供了參數，先進行配置
            if [[ -n "$token" || -n "$region" ]]; then
                ensure_conf_dir
                
                # 如果提供了 region，更新 env 檔案
                if [[ -n "$region" ]]; then
                    config_env "$hook_enable" "$region"
                fi
                
                # 如果提供了 token，更新 key 檔案
                if [[ -n "$token" ]]; then
                    config_key "$token"
                fi
            fi
            
            start_pcdn
            ;;
        config)
            ensure_conf_dir
            
            # 如果提供了 region，更新 env 檔案
            if [[ -n "$region" ]]; then
                config_env "$hook_enable" "$region"
            fi
            
            # 如果提供了 token，更新 key 檔案
            if [[ -n "$token" ]]; then
                config_key "$token"
            fi
            
            # 如果沒有提供任何參數，進入互動式配置
            if [[ -z "$region" && -z "$token" ]]; then
                config_pcdn
            fi
            ;;
        stop)
            stop_pcdn
            ;;
        delete)
            delete_pcdn
            ;;
        *)
            show_menu
            read -p "請選擇操作 [0-4]: " choice
            handle_menu_choice "$choice"
            ;;
    esac
}

# 檢查配置文件是否存在
check_config() {
    local config_needed=false
    
    ensure_conf_dir
    
    if [[ ! -f "conf/.env" ]]; then
        echo -e "${YELLOW}conf/.env 檔案不存在，需要進行配置${NC}"
        config_needed=true
    fi
    
    if [[ ! -f "conf/.key" ]]; then
        echo -e "${YELLOW}conf/.key 檔案不存在，需要進行配置${NC}"
        config_needed=true
    fi
    
    if [[ "$config_needed" = true ]]; then
        read -p "是否現在進行配置? (y/n): " confirm
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            config_pcdn
        else
            echo -e "${RED}未完成配置，無法啟動服務${NC}"
            return 1
        fi
    fi
    
    return 0
}

# 初始化函數，處理所有啟動前的檢查和設置
init() {
    # 解析命令行參數
    parse_command_args "$@"
    
    # 更新系統限制設置
    update_system_limits
    
    # 檢查 root 權限
    check_root_privileges
    
    # 檢查 Docker 環境
    check_docker_environment "$CMD_INSTALL"
}

# 主程序函數
main() {
    # 初始化
    init "$@"
    
    if [[ -n "$CMD_ACTION" ]]; then
        # 執行指定的命令
        execute_command "$CMD_ACTION" "$CMD_TOKEN" "$CMD_REGION"
    else
        show_menu
        read -p "請選擇操作 [0-4]: " choice
        handle_menu_choice "$choice"
    fi
}

# 處理選單選擇
handle_menu_choice() {
    case "$1" in
        1)
            start_pcdn
            ;;
        2)
            stop_pcdn
            ;;
        3)
            delete_pcdn
            ;;
        4)
            config_pcdn
            ;;
        0)
            echo "感謝使用！再見！"
            exit 0
            ;;
        *)
            echo -e "${RED}錯誤：無效的選擇，請重新輸入${NC}"
            ;;
    esac
}

# 執行指定命令
execute_command() {
    local command="$1"
    local token="$2"
    local region="$3"
    local hook_enable="false"
    
    # 如果提供了 region，自動啟用 HOOK_ENABLE
    if [[ -n "$region" ]]; then
        hook_enable="true"
    fi
    
    case "$command" in
        start)
            # 如果提供了參數，先進行配置
            if [[ -n "$token" || -n "$region" ]]; then
                ensure_conf_dir
                
                # 如果提供了 region，更新 env 檔案
                if [[ -n "$region" ]]; then
                    config_env "$hook_enable" "$region"
                fi
                
                # 如果提供了 token，更新 key 檔案
                if [[ -n "$token" ]]; then
                    config_key "$token"
                fi
            fi
            
            start_pcdn
            return $?
            ;;
        stop)
            stop_pcdn
            return $?
            ;;
        delete)
            delete_pcdn
            return $?
            ;;
        config)
            ensure_conf_dir
            
            # 如果提供了 region，更新 env 檔案
            if [[ -n "$region" ]]; then
                config_env "$hook_enable" "$region"
            fi
            
            # 如果提供了 token，更新 key 檔案
            if [[ -n "$token" ]]; then
                config_key "$token"
            fi
            
            # 如果沒有提供任何參數，進入互動式配置
            if [[ -z "$region" && -z "$token" ]]; then
                config_pcdn
            fi
            return $?
            ;;
        *)
            show_menu
            read -p "請選擇操作 [0-4]: " choice
            handle_menu_choice "$choice"
            return $?
            ;;
    esac
}

# 統一解析命令行參數
parse_command_args() {
    # 重置全局變數
    CMD_ACTION=""
    CMD_TOKEN=""
    CMD_REGION=""
    CMD_INSTALL="false"
    
    # 如果沒有參數，直接返回
    if [[ $# -eq 0 ]]; then
        return 0
    fi
    
    # 第一個參數通常是命令
    CMD_ACTION="$1"
    shift
    
    # 處理剩餘參數
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--token)
                if [[ $# -gt 1 ]]; then
                    CMD_TOKEN="$2"
                    shift 2
                else
                    echo -e "${RED}錯誤: -t/--token 需要一個參數${NC}"
                    return 1
                fi
                ;;
            -r|--region)
                if [[ $# -gt 1 ]]; then
                    CMD_REGION="$2"
                    shift 2
                else
                    echo -e "${RED}錯誤: -r/--region 需要一個參數${NC}"
                    return 1
                fi
                ;;
            -i|--install)
                if [[ $# -gt 1 && "$2" != -* ]]; then
                    # 如果下一個參數不是以 - 開頭，就認為是此參數的值
                    CMD_INSTALL="$2"
                    shift 2
                else
                    CMD_INSTALL="true"
                    shift
                fi
                ;;
            *)
                echo -e "${RED}錯誤: 未知參數 $1${NC}"
                return 1
                ;;
        esac
    done
    
    # 可以添加參數驗證邏輯
    if [[ "$CMD_INSTALL" != "true" && "$CMD_INSTALL" != "false" && "$CMD_INSTALL" != "cn" ]]; then
        CMD_INSTALL="true"  # 如果值不合法，設為預設值
    fi
    
    return 0
}

# 執行主程序
main "$@"
