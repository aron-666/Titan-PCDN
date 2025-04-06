# Titan-PCDN 服務管理腳本

<div align="center">
  
### ⚠️ **重要提示** ⚠️

</div>

> ### 💡 本服務需要加入**白名單**才能使用
> 
> <table>
> <tr>
> <td width="100"><b>👤 聯絡人:</b></td>
> <td><b>包包</b></td>
> </tr>
> <tr>
> <td><b>💬 微信:</b></td>
> <td><code>baobao11bd</code></td>
> </tr>
> <tr>
> <td><b>📱 Telegram:</b></td>
> <td><a href="https://t.me/bdbaobao">@bdbaobao</a></td>
> </tr>
> </table>

這是一個用於管理 PCDN (Peer-to-Peer Content Delivery Network) 服務的命令行工具。此腳本提供了簡單的界面來啟動、停止、配置和管理 PCDN 服務。

> 🚀 **網路優化提示:** 
> 
> ⚠️ 官方教學僅能實現 **NAT3/NAT4** 類型連接
> 
> ✅ 而我們的解決方案可以**一鍵部署**並實現 **NAT1/公網** 連接
> 
> 💰 **效果：網路質量提升，收益可達 2-3 倍！**

## 系統需求

- Linux 作業系統 (Ubuntu、Debian、CentOS、RHEL、Fedora 等)
- root 權限
- 網路連接

## 所有指令一覽

```bash
./pcdn.sh [指令] [選項]
```

基本指令:
- `start`: 啟動 PCDN 服務
- `stop`: 停止 PCDN 服務
- `delete`: 刪除 PCDN 服務及數據
- `config`: 配置 PCDN 服務
- `logs`: 查看 Docker 容器日誌
- `agent-logs`: 查看 PCDN 代理日誌

全局選項:
- `-i, --install [cn]`: 自動安裝 Docker 環境
  - 不帶參數: 使用國際源
  - 帶 `cn` 參數: 使用中國源

## 快速開始

### 基本安裝與啟動

```bash
# 下載腳本並設置權限
git clone https://github.com/aron-666/Titan-PCDN.git titan-pcdn
cd titan-pcdn
chmod +x pcdn.sh

# 啟動服務 (會進入互動式配置)
sudo ./pcdn.sh start
```

### 快速部署 (一鍵啟動)

```bash
# 下載腳本並設置權限
git clone https://github.com/aron-666/Titan-PCDN.git titan-pcdn
cd titan-pcdn
chmod +x pcdn.sh

# 使用特定參數快速啟動

# 中國區域
sudo ./pcdn.sh start -t 你的TOKEN -r cn -i cn

# 其他區域
sudo ./pcdn.sh start -t 你的TOKEN -i
```
> 注意: `-r` 參數為可選，用於指定區域。當設定為 `cn` 時會進行中國區域的特殊處理。
> `-i cn` 參數用於在中國區域安裝 Docker 時使用中國鏡像源。



## 指令詳解

### 啟動 PCDN 服務

```bash
sudo ./pcdn.sh start [選項]
```

選項:
- `-t, --token TOKEN`: 指定 token
- `-r, --region REGION`: 指定區域 (當設定為 `cn` 時會進行中國區域的特殊處理)

示例:
```bash
# 中國區域
sudo ./pcdn.sh start -t your_token_here -r cn

# 其他區域
sudo ./pcdn.sh start -t your_token_here
```

### 配置 PCDN 服務

```bash
sudo ./pcdn.sh config [選項]
```

選項:
- `-t, --token TOKEN`: 設置 token
- `-r, --region REGION`: 設置區域 (當設定為 `cn` 時會進行中國區域的特殊處理)

示例:
```bash
# 中國區域
sudo ./pcdn.sh config -t your_token_here -r cn

# 其他區域
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

### 查看 Docker 容器日誌

```bash
sudo ./pcdn.sh logs
```
此命令會顯示 Docker 容器的最新 100 條日誌記錄，並實時更新。可通過 Ctrl+C 退出。

### 查看 PCDN 代理日誌

```bash
sudo ./pcdn.sh agent-logs
```
此命令會顯示 PCDN 代理的最新 100 條日誌記錄，並實時更新。可通過 Ctrl+C 退出。

### 互動式選單

不帶參數執行腳本將顯示互動式選單：

```bash
sudo ./pcdn.sh
```

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

### 日誌查看問題

- 如果看不到日誌，請確認服務是否已啟動
- 新安裝的服務可能需要幾分鐘才會生成日誌
- 使用 `logs` 命令查看 Docker 容器日誌可以幫助診斷啟動問題

### 配置問題

- 如果服務無法啟動，請檢查配置文件是否正確生成
- 使用 `./pcdn.sh config` 命令重新配置服務

## 注意事項

- 此腳本需要 root 權限才能執行
- 系統限制設置的更改可能需要重新登入或重啟系統才能完全生效
