# 範例

## 檔案命名範例

假設你有以下音訊檔案：

```
my_music/
├── 01_Tokyo Neon City Pop_2m39s.mp3
├── 02_Midnight Drive_3m15s.mp3
├── 03_Paper Cups in Tokyo_2m27s.mp3
├── 04_Room For One_2m41s.mp3
├── 05_Quiet Corners_3m16s.mp3
└── 06_Late Night Vibes_4m02s.mp3
```

## 執行指令

```bash
./generate_chapters.sh ./my_music
```

## 輸出結果

產生的 `chapters.txt` 內容如下：

```
0:00 Tokyo Neon City Pop
2:39 Midnight Drive
5:54 Paper Cups in Tokyo
8:21 Room For One
11:02 Quiet Corners
14:18 Late Night Vibes
```

## YouTube 使用方式

1. 打開 `chapters.txt`
2. 複製章節內容（跳過 `#` 開頭的註解）
3. 貼到 YouTube 影片說明欄
4. YouTube 會自動辨識並建立章節

## 完整說明欄範例

```
🎵 Neon Rhythm Station - Night Drive Mix Vol.1

---

🕐 章節 / Chapters:

0:00 Tokyo Neon City Pop
2:39 Midnight Drive
5:54 Paper Cups in Tokyo
8:21 Room For One
11:02 Quiet Corners
14:18 Late Night Vibes

---

🔔 訂閱頻道 / Subscribe: https://www.youtube.com/@NeonRhythmStation
🎧 Spotify / Apple Music: (連結)

#CityPop #JapaneseMusic #Synthwave
```
