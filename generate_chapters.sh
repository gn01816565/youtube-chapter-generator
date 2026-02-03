#!/bin/bash
# ========================================
# YouTube Chapter Generator
# ========================================
# 自動掃描音訊檔案並產生 YouTube 章節時間戳
# 
# 作者: Kuan (https://github.com/gn01816565)
# 授權: MIT License
# ========================================

set -e

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 顯示使用說明
show_usage() {
    echo "用法: $0 <音訊檔案目錄> [輸出檔案]"
    echo ""
    echo "參數:"
    echo "  <音訊檔案目錄>  包含音訊檔案的資料夾路徑"
    echo "  [輸出檔案]      輸出檔案路徑（可選，預設為 chapters.txt）"
    echo ""
    echo "範例:"
    echo "  $0 ./my_music"
    echo "  $0 ./my_music output.txt"
    echo "  $0 /path/to/music /path/to/chapters.txt"
    echo ""
    echo "支援的檔案格式:"
    echo "  .mp3, .wav, .flac, .m4a, .ogg"
    echo ""
    echo "檔名格式建議:"
    echo "  01_Song Name_2m39s.mp3  （自動辨識時長）"
    echo "  01_Song Name.mp3        （使用 ffprobe 讀取）"
    echo ""
}

# 檢查是否安裝 ffprobe
check_dependencies() {
    if ! command -v ffprobe &> /dev/null; then
        echo -e "${RED}錯誤: 找不到 ffprobe${NC}"
        echo ""
        echo "請先安裝 ffmpeg:"
        echo "  macOS:   brew install ffmpeg"
        echo "  Ubuntu:  sudo apt install ffmpeg"
        echo "  Windows: 下載 https://ffmpeg.org/download.html"
        exit 1
    fi
}

# 格式化時間戳
format_timestamp() {
    local total_seconds=$1
    
    if [ $total_seconds -ge 3600 ]; then
        # 超過 1 小時：H:MM:SS
        hours=$((total_seconds / 3600))
        mins=$(( (total_seconds % 3600) / 60 ))
        secs=$((total_seconds % 60))
        printf "%d:%02d:%02d" $hours $mins $secs
    else
        # 小於 1 小時：M:SS
        mins=$((total_seconds / 60))
        secs=$((total_seconds % 60))
        printf "%d:%02d" $mins $secs
    fi
}

# 從檔名提取歌名
extract_song_name() {
    local filename="$1"
    
    # 移除副檔名
    local name="${filename%.*}"
    
    # 移除開頭編號 (01_, 02_, etc.)
    name=$(echo "$name" | sed -E 's/^[0-9]+[_\-\.\s]+//')
    
    # 移除時長標記 (_2m39s, _2m39, etc.)
    name=$(echo "$name" | sed -E 's/_[0-9]+m[0-9]+s?$//')
    
    # 移除多餘的底線或破折號
    name=$(echo "$name" | sed 's/_/ /g' | sed 's/-/ /g')
    
    echo "$name"
}

# 取得音訊時長
get_duration() {
    local file="$1"
    local filename=$(basename "$file")
    
    # 嘗試從檔名解析時長 (格式: _2m39s)
    if [[ "$filename" =~ _([0-9]+)m([0-9]+)s?\. ]]; then
        local minutes="${BASH_REMATCH[1]}"
        local seconds="${BASH_REMATCH[2]}"
        echo $((minutes * 60 + seconds))
        return 0
    fi
    
    # 使用 ffprobe 取得精確時長
    local duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null | cut -d'.' -f1)
    
    if [ -n "$duration" ] && [ "$duration" -gt 0 ]; then
        echo "$duration"
        return 0
    else
        return 1
    fi
}

# 主程式
main() {
    # 檢查參數
    if [ $# -lt 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        show_usage
        exit 0
    fi
    
    local input_dir="$1"
    local output_file="${2:-chapters.txt}"
    
    # 檢查輸入目錄
    if [ ! -d "$input_dir" ]; then
        echo -e "${RED}錯誤: 找不到目錄 '$input_dir'${NC}"
        exit 1
    fi
    
    # 檢查依賴
    check_dependencies
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  YouTube Chapter Generator${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}📂 掃描目錄:${NC} $input_dir"
    echo -e "${YELLOW}📝 輸出檔案:${NC} $output_file"
    echo ""
    
    # 找出所有支援的音訊檔案
    local audio_files=()
    while IFS= read -r -d '' file; do
        audio_files+=("$file")
    done < <(find "$input_dir" -maxdepth 1 -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.ogg" \) -print0 | sort -z)
    
    if [ ${#audio_files[@]} -eq 0 ]; then
        echo -e "${RED}錯誤: 在 '$input_dir' 中找不到任何音訊檔案${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 找到 ${#audio_files[@]} 個音訊檔案${NC}"
    echo ""
    
    # 初始化
    local total_seconds=0
    local processed_count=0
    
    # 建立輸出檔案
    {
        echo "# YouTube 章節時間戳"
        echo "# 產生時間: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# 來源目錄: $input_dir"
        echo ""
    } > "$output_file"
    
    echo -e "${BLUE}🎵 處理中...${NC}"
    echo ""
    
    # 處理每個檔案
    for audio_file in "${audio_files[@]}"; do
        local filename=$(basename "$audio_file")
        
        # 取得時長
        local duration
        if ! duration=$(get_duration "$audio_file"); then
            echo -e "${YELLOW}⚠️  跳過:${NC} $filename ${RED}(無法讀取時長)${NC}"
            continue
        fi
        
        # 提取歌名
        local song_name=$(extract_song_name "$filename")
        
        # 格式化時間戳
        local timestamp=$(format_timestamp $total_seconds)
        
        # 輸出章節
        echo "$timestamp $song_name" | tee -a "$output_file"
        
        # 累加時長
        total_seconds=$((total_seconds + duration))
        processed_count=$((processed_count + 1))
    done
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ 完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "📊 統計:"
    echo -e "   • 處理檔案: ${GREEN}$processed_count${NC} / ${#audio_files[@]}"
    echo -e "   • 總時長:   ${GREEN}$(format_timestamp $total_seconds)${NC}"
    echo -e "   • 輸出檔案: ${GREEN}$output_file${NC}"
    echo ""
    echo -e "${BLUE}💡 下一步:${NC}"
    echo -e "   1. 打開 $output_file"
    echo -e "   2. 複製內容（跳過 # 開頭的註解行）"
    echo -e "   3. 貼到 YouTube 影片說明欄"
    echo ""
}

# 執行主程式
main "$@"
