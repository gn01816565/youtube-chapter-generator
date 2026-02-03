# 🎵 YouTube Chapter Generator

自動掃描音訊檔案並產生 YouTube 章節時間戳的命令列工具。

適合音樂創作者、Podcast 製作人、以及任何需要為長影片添加章節的創作者使用。

## ✨ 功能特色

- 🎯 **自動計算時長** - 支援從檔名解析或使用 ffprobe 讀取
- 📂 **批次處理** - 一次處理整個資料夾的音訊檔案
- 🎨 **智能命名** - 自動提取歌曲名稱（移除編號、時長標記）
- ⏱️ **精確時間戳** - 自動格式化為 YouTube 格式（M:SS 或 H:MM:SS）
- 🎵 **多格式支援** - `.mp3`, `.wav`, `.flac`, `.m4a`, `.ogg`
- 🌈 **彩色輸出** - 清楚的終端機顯示
- 📝 **多種輸出格式** - 純文字、JSON、完整 YouTube 說明欄 (v1.1+)

## 📋 系統需求

- **Bash** 4.0+（macOS / Linux / Windows WSL）
- **ffmpeg / ffprobe** - 用於讀取音訊時長

### 安裝 ffmpeg

**macOS:**
```bash
brew install ffmpeg
```

**Ubuntu / Debian:**
```bash
sudo apt install ffmpeg
```

**Windows:**
下載並安裝：https://ffmpeg.org/download.html

## 🚀 快速開始

### 1. 下載腳本

```bash
# 下載腳本
curl -O https://raw.githubusercontent.com/gn01816565/youtube-chapter-generator/main/generate_chapters.sh

# 設定執行權限
chmod +x generate_chapters.sh
```

### 2. 準備音訊檔案

將你的音訊檔案放在同一個資料夾中，建議命名格式：

```
my_music/
├── 01_Song Name_2m39s.mp3
├── 02_Another Song_3m21s.mp3
└── 03_Final Track_4m15s.mp3
```

**命名格式說明：**
- `01_` - 編號（用於排序，會自動移除）
- `Song Name` - 歌曲名稱（會保留）
- `_2m39s` - 時長標記（可選，會自動移除）
- `.mp3` - 副檔名

### 3. 產生章節

```bash
./generate_chapters.sh ./my_music
```

**輸出範例：**
```
0:00 Song Name
2:39 Another Song
5:54 Final Track
```

### 4. 使用章節

1. 打開產生的 `chapters.txt`
2. 複製內容（跳過 `#` 開頭的註解行）
3. 貼到 YouTube 影片說明欄

## 📖 使用方式

### 基本用法

```bash
./generate_chapters.sh <音訊檔案目錄>
```

### 輸出格式

支援三種輸出格式：

#### 1️⃣ 純文字格式（預設）
```bash
./generate_chapters.sh ./music
# 或
./generate_chapters.sh ./music --format text
```

輸出：
```
0:00 Song Name
2:39 Another Song
5:54 Final Track
```

#### 2️⃣ JSON 格式
```bash
./generate_chapters.sh ./music --format json -o chapters.json
```

輸出：
```json
{
  "generator": "youtube-chapter-generator",
  "version": "1.1.0",
  "total_duration": "14:18",
  "total_seconds": 858,
  "chapters": [
    {"time": "0:00", "time_seconds": 0, "title": "Song Name"},
    {"time": "2:39", "time_seconds": 159, "title": "Another Song"}
  ]
}
```

#### 3️⃣ YouTube 完整說明欄格式
```bash
./generate_chapters.sh ./music --format youtube \
  --title "My Music Mix" \
  --tags "music,lofi,chill"
```

輸出：
```
My Music Mix

---

🕐 章節 / Chapters:

0:00 Song Name
2:39 Another Song
5:54 Final Track

⏱️ 總時長 / Total Duration: 14:18

---

#music #lofi #chill
```

### 完整參數說明

```bash
# 指定輸出檔案
./generate_chapters.sh ./music -o output.txt

# JSON 格式輸出
./generate_chapters.sh ./music --format json -o data.json

# YouTube 完整格式
./generate_chapters.sh ./music --format youtube \
  --title "Late Night Vibes" \
  --tags "nightdrive,lofi,jazz"

# 查看版本
./generate_chapters.sh --version

# 查看說明
./generate_chapters.sh --help
```

## 🎯 檔名格式

腳本會自動處理以下格式：

| 輸入檔名 | 輸出章節名稱 |
|---------|-------------|
| `01_Tokyo Night_2m39s.mp3` | `Tokyo Night` |
| `02-Midnight Drive-3m21s.mp3` | `Midnight Drive` |
| `03_Neon Dreams.mp3` | `Neon Dreams` |
| `Track_04_Final Song_4m15.wav` | `Final Song` |

**自動移除：**
- ✂️ 開頭編號（`01_`, `02-`, `Track 03`, etc.）
- ✂️ 時長標記（`_2m39s`, `_3m21`, etc.）
- ✂️ 底線與破折號（轉換為空格）

## 💡 實用技巧

### 時長標記格式

如果你的檔名包含時長標記，腳本會優先使用（更快）：

```
支援格式：
  _2m39s.mp3    ← 推薦
  _2m39.mp3     ← 也可以
```

### 批次重新命名

使用 shell 腳本批次加入編號：

```bash
i=1
for file in *.mp3; do
  mv "$file" "$(printf "%02d_%s" $i "$file")"
  ((i++))
done
```

## 📊 輸出格式

產生的 `chapters.txt` 包含：

```
# YouTube 章節時間戳
# 產生時間: 2026-02-03 08:00:00
# 來源目錄: ./my_music

0:00 First Song
2:39 Second Song
5:54 Third Song
10:15 Fourth Song
```

**直接複製貼到 YouTube：**
（跳過 `#` 開頭的註解行）

```
0:00 First Song
2:39 Second Song
5:54 Third Song
10:15 Fourth Song
```

## 🛠️ 進階使用

### 整合到工作流程

**配合 FFmpeg 合併音訊：**
```bash
# 1. 合併所有 MP3
ffmpeg -f concat -safe 0 -i <(find . -name "*.mp3" | sort | sed 's/^/file /') -c copy output.mp3

# 2. 產生章節
./generate_chapters.sh . chapters.txt
```

**配合 YouTube 上傳腳本：**
```bash
# 產生章節並自動加入說明欄
./generate_chapters.sh ./music chapters.txt
youtube-upload --title="My Mix" --description="$(cat chapters.txt | grep -v '^#')" output.mp4
```

## 🤝 貢獻

歡迎提交 Issue 或 Pull Request！

### 開發待辦

- [ ] 支援自訂輸出格式
- [ ] JSON 格式輸出
- [ ] 自動加入 hashtags
- [ ] 圖形化介面 (GUI)
- [ ] Windows 原生支援（PowerShell 版本）

## 📄 授權

MIT License - 自由使用、修改、分發

## 👤 作者

**Kuan** ([@gn01816565](https://github.com/gn01816565))

- 個人網站：[showgan.com](https://showgan.com)
- YouTube：[Neon Rhythm Station](https://www.youtube.com/@NeonRhythmStation)

## ⭐ 喜歡這個專案？

請給個 Star ⭐，讓更多人看到！

有問題或建議歡迎開 Issue 討論 💬

---

*Made with 🍞 by a toaster who loves automating things*
