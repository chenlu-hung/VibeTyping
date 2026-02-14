# VibeTyping

macOS 語音輸入法，使用 [WhisperKit](https://github.com/argmaxinc/WhisperKit) 搭配 [Breeze-ASR-25](https://github.com/mtkresearch/Breeze-ASR-25) CoreML 模型在本地端進行台灣中文語音辨識，並可選擇透過雲端 LLM 進一步校正同音錯字與標點符號。

## 功能特色

- **本地語音辨識** — 使用 Apple Neural Engine 加速，無需上傳音訊到雲端
- **台灣中文優化** — 採用 Breeze-ASR-25（基於 Whisper large-v2 微調）
- **LLM 校正** — 支援任意 OpenAI 相容 API 端點，修正同音錯字、補標點
- **自動停止** — 透過靜音偵測（VAD）自動判斷說話結束
- **原生整合** — 基於 InputMethodKit，作為系統輸入法運作於所有應用程式
- **自動下載模型** — 首次啟動時自動從 HuggingFace 下載模型，附進度條顯示

## 系統需求

- macOS 14.0 (Sonoma) 或更新版本
- Apple Silicon (M1/M2/M3/M4)
- Xcode 15.0+（建置用）
- 約 3GB 磁碟空間（模型下載）

## 建置與安裝

```bash
# 1. Clone 專案
git clone https://github.com/chenlu-hung/VibeTyping.git
cd VibeTyping

# 2. 確認 xcode-select 指向 Xcode.app
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 3. 解析 SPM 依賴
xcodebuild -resolvePackageDependencies \
  -project VibeTyping.xcodeproj \
  -scheme VibeTyping

# 4. 建置
xcodebuild -project VibeTyping.xcodeproj \
  -scheme VibeTyping \
  -configuration Release build

# 5. 安裝到輸入法目錄
cp -R ~/Library/Developer/Xcode/DerivedData/VibeTyping-*/Build/Products/Release/VibeTyping.app \
  ~/Library/Input\ Methods/

# 6. 登出再登入（或重新啟動），讓系統載入新的輸入法
```

## 註冊輸入法

1. 開啟 **系統設定** → **鍵盤** → **輸入來源** → **編輯**
2. 點選 **+** 按鈕
3. 找到 **VibeTyping** 並加入

## 使用方式

| 操作 | 說明 |
|------|------|
| `Ctrl + /`（預設，可自訂） | 開始錄音（再按一次手動停止） |
| 說完話後靜默 1.5 秒 | 自動停止錄音並開始辨識 |

快捷鍵可在設定視窗中自訂，支援任何包含修飾鍵（Ctrl/Cmd/Option）的組合。

辨識流程：

```
🎤 錄音中 → 📝 辨識中（WhisperKit 本地辨識）→ ✨ 校正中（LLM）→ 文字輸出
```

## 設定

在輸入法選單中選擇 **「VibeTyping 設定...」** 開啟設定視窗。

### 語音辨識

| 設定項 | 預設值 | 說明 |
|--------|--------|------|
| 靜音偵測秒數 | 1.5 秒 | 說話停頓多久後自動停止錄音 |
| 自訂模型資料夾 | （空） | 留空則自動下載到 `~/Library/Application Support/VibeTyping/HubCache/` |
| 錄音快捷鍵 | `⌃/` (Ctrl+/) | 點擊按鈕後按下新的組合鍵即可變更 |

### LLM 校正

| 設定項 | 預設值 | 說明 |
|--------|--------|------|
| 啟用 LLM 校正 | 開啟 | 關閉則直接輸出原始辨識結果 |
| API Endpoint | `https://api.openai.com` | 任何 OpenAI 相容端點 |
| API Key | （空） | 需填入才會啟用校正 |
| Model | `gpt-4o-mini` | 建議使用快速模型以降低延遲 |

## 專案結構

```
VibeTyping/
├── App/                 # 應用程式入口與 IMKServer 初始化
├── InputMethod/         # IMKInputController 核心控制器
├── Audio/               # AVAudioEngine 錄音與靜音偵測
├── Transcription/       # WhisperKit 模型載入與轉錄
├── LLM/                 # OpenAI 相容 API 客戶端與校正 Prompt
├── UI/                  # 浮動狀態面板與 SwiftUI 設定介面
├── Settings/            # UserDefaults 設定管理
└── Resources/           # Info.plist、Entitlements
```

## 依賴

| 套件 | 用途 |
|------|------|
| [WhisperKit](https://github.com/argmaxinc/WhisperKit) (SPM) | 本地語音辨識引擎 |
| [Breeze-ASR-25_coreml](https://huggingface.co/aoiandroid/Breeze-ASR-25_coreml) | 台灣中文 ASR CoreML 模型 |

系統框架：InputMethodKit、AVFoundation、SwiftUI。

## 開發

重新建置後需重新安裝並重啟輸入法程序：

```bash
killall VibeTyping 2>/dev/null
cp -R ~/Library/Developer/Xcode/DerivedData/VibeTyping-*/Build/Products/Debug/VibeTyping.app \
  ~/Library/Input\ Methods/
```

## 授權

MIT License
