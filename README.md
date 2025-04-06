# Titan-PCDN 服務管理腳本

這是一個用於管理 PCDN (Peer-to-Peer Content Delivery Network) 服務的命令行工具。此腳本提供了簡單的界面來啟動、停止、配置和管理 PCDN 服務。

## 系統需求

- Linux 作業系統 (Ubuntu、Debian、CentOS、RHEL、Fedora 等)
- root 權限
- 網路連接

## 快速開始

### 安裝和配置

1. 下載腳本:
   ```bash
   git clone https://github.com/yourusername/Titan-Pcdn.git
   cd Titan-Pcdn
   chmod +x pcdn.sh
   ```

2. 使用自動安裝:
   ```bash
   sudo ./pcdn.sh -i      # 使用國際源安裝 Docker
   # 或
   sudo ./pcdn.sh -i cn   # 使用中國源安裝 Docker
   ```

3. 配置服務:
   ```bash
   sudo ./pcdn.sh config -t 你的TOKEN -r cn
   ```

### 基本命令

- 啟動服務: `sudo ./pcdn.sh start`
- 停止服務: `sudo ./pcdn.sh stop`
- 刪除服務: `sudo ./pcdn.sh delete`
- 配置服務: `sudo ./pcdn.sh config`
- 互動式選單: `sudo ./pcdn.sh`

## 命令詳解

### 啟動 PCDN 服務

```bash
sudo ./pcdn.sh start [選項]
```

選項:
- `-t, --token TOKEN`: 指定 token
- `-r, --region REGION`: 指定區域 (目前僅支援 cn)

示例:
```bash
sudo ./pcdn.sh start -t your_token_here -r cn
```

### 配置 PCDN 服務

```bash
sudo ./pcdn.sh config [選項]
```

選項:
- `-t, --token TOKEN`: 設置 token
- `-r, --region REGION`: 設置區域 (目前僅支援 cn)

示例:
```bash
sudo ./pcdn.sh config -t your_token_here
```

### 停止 PCDN 服務

```bash
sudo ./pcdn.sh stop
```

### 刪除 PCDN 服務

```bash
sudo ./pcdn.sh delete
```

### 全局選項

- `-i, --install [cn]`: 自動安裝 Docker 環境
  - 不帶參數: 使用國際源
  - 帶 `cn` 參數: 使用中國源

## 配置文件

腳本會在 `conf` 目錄下生成以下配置文件:

- `.env`: 包含 HOOK_ENABLE 和 HOOK_REGION 設置
- `.key`: 包含授權 token

## 系統優化

腳本會自動調整系統限制以優化 PCDN 服務性能:

- 設置文件描述符限制 (524288)
- 調整系統參數:
  - fs.inotify.max_user_instances = 25535
  - net.core.rmem_max=600000000
  - net.core.wmem_max=600000000

## 疑難排解

### Docker 相關問題

- 如果 Docker 安裝失敗，請嘗試使用 `-i` 參數再次運行腳本
- 如果在中國大陸地區，請使用 `-i cn` 參數以使用中國鏡像源

### 配置問題

- 如果服務無法啟動，請檢查配置文件是否正確生成
- 使用 `./pcdn.sh config` 命令重新配置服務

## 注意事項

- 此腳本需要 root 權限才能執行
- 系統限制設置的更改可能需要重新登入或重啟系統才能完全生效
