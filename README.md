![Total Visitors](https://komarev.com/ghpvc/?username=aron-666-pcdn&color=green)

# Titan-PCDN 服務管理腳本

---

<div align="center">
  
### ⚠️ **重要提示** ⚠️

</div>

> ### 💡 **本服務需要加入白名單才能使用**
> 
> 使用邀請碼 <code>LzA0HD</code> 註冊後再聯絡包包，才能取得白名單。
> 
> [立即註冊](https://test4.titannet.io/Invitelogin?code=LzA0HD)
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
---

> ## 🚀 **我們的解決方案 vs 官方教學**
> 
> | 比較項目 | 官方教學 | 我們的解決方案 |
> |---------|---------|--------------|
> | **網路連接** | ❌ NAT3/NAT4 類型，收益低 | ✅ NAT1/公網連接，收益高(路由器需要額外的設定) |
> | **VPS支援** | ❌ 中國區官方教程無法在VPS上運行 | ✅ 完美支援VPS環境 |
> | **部署複雜度** | ❌ 步驟繁瑣，需手動配置多項設定 | ✅ **一鍵部署**，省時高效 |
> | **守護進程** | ❌ 無守護進程，斷連後需手動重啟 | ✅ 內建守護進程，自動恢復 |
> | **收益效果** | ❌ 基礎收益 | ✅ 網路質量提升，**收益最高可達2-3倍！** (路由器需要額外的設定)|

---

## 系統需求

- Linux 作業系統 (Ubuntu、Debian、CentOS、RHEL、Fedora 等)
- root 權限
- 網路連接

---

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

---

## 快速開始

### 基本安裝與啟動

#### 中國區域安裝

```bash
# 1. 下載腳本並設置權限 (中國區域使用 Gitee 源，只需下載一次)
git clone https://gitee.com/hiro199/Titan-PCDN.git titan-pcdn
cd titan-pcdn
chmod +x pcdn.sh

# 2. 啟動服務 (會進入互動式配置)
sudo ./pcdn.sh start
```

#### 其他區域安裝

```bash
# 1. 下載腳本並設置權限 (國際區域使用 GitHub 源，只需下載一次)
git clone https://github.com/aron-666/Titan-PCDN.git titan-pcdn
cd titan-pcdn
chmod +x pcdn.sh

# 2. 啟動服務 (會進入互動式配置)
sudo ./pcdn.sh start
```

### 快速部署 (一鍵啟動)

#### 中國區域部署

```bash
# 1. 下載腳本並設置權限 (中國區域使用 Gitee 源，只需下載一次)
git clone https://gitee.com/hiro199/Titan-PCDN.git titan-pcdn
cd titan-pcdn
chmod +x pcdn.sh

# 2. 中國區域快速啟動
sudo ./pcdn.sh start -t 你的TOKEN -r cn -i cn
```

#### 其他區域部署

```bash
# 1. 下載腳本並設置權限 (國際區域使用 GitHub 源，只需下載一次)
git clone https://github.com/aron-666/Titan-PCDN.git titan-pcdn
cd titan-pcdn
chmod +x pcdn.sh

# 2. 其他區域快速啟動
sudo ./pcdn.sh start -t 你的TOKEN -i
```

> 注意: `-r` 參數為可選，用於指定區域。當設定為 `cn` 時會進行中國區域的特殊處理。
> `-i cn` 參數用於在中國區域安裝 Docker 時使用中國鏡像源。

---

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
