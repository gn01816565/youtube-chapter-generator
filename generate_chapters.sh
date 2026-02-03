#!/bin/bash
# ========================================
# YouTube Chapter Generator
# ========================================
# 自動掃描音訊檔案並產生 YouTube 章節時間戳
# 
# 作者: Kuan (https://github.com/gn01816565)
# 授權: MIT License
# 版本: 1.1.0
# ========================================

set -e

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本號
VERSION="1.1.0"

# 顯示使用說明
show_usage() {
    echo "YouTube Chapter Generator v$VERSION"
    echo ""
    echo "用法: $0 <音訊檔案目錄> [選項]"
    echo ""
    echo "參數:"
    echo "  <音訊檔案目錄>  包含音訊檔案的資料夾路徑"
    echo ""
    echo "選項:"
    echo "  -o, --output <檔案>     指定輸出檔案 (預設: chapters.txt)"
    echo "  -f, --format <格式>     輸出格式: text, json, youtube (預設: text)"
    echo "  -t, --title <標題>      影片標題 (用於 youtube 格式)"
    echo "  --tags <標籤>           YouTube 標籤，逗號分隔 (用於 youtube 格式)"
    echo "  -v, --version           顯示版本號"
    echo "  -h, --help              顯示此說明"
    echo ""
    echo "輸出格式說明:"
    echo "  text     - 純文字章節列表 (預設)"
    echo "  json     - JSON 格式 (方便程式處理)"
    echo "  youtube  - 完整 YouTube 說明欄格式 (包含標題、章節、標籤)"
    echo ""
    echo "範例:"
    echo "  $0 ./my_music"
    echo "  $0 ./my_music -o chapters.txt"
    echo "  $0 ./my_music --format json -o output.json"
    echo "  $0 ./my_music --format youtube --title \"My Mix\" --tags \"music,lofi,chill\""
    echo ""
    echo "支援的檔案格式:"
    echo "  .mp3, .wav, .flac, .m4a, .ogg"
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
    
    # 移除開頭的點和空格
    name=$(echo "$name" | sed -E 's/^[\.\s]+//')
    
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

# 輸出 JSON 格式
output_json() {
    local chapters_array="$1"
    local total_seconds=$2
    local output_file="$3"
    
    local total_time=$(format_timestamp $total_seconds)
    
    {
        echo "{"
        echo "  \"generator\": \"youtube-chapter-generator\","
        echo "  \"version\": \"$VERSION\","
        echo "  \"generated_at\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
        echo "  \"total_duration\": \"$total_time\","
        echo "  \"total_seconds\": $total_seconds,"
        echo "  \"chapters\": ["
        echo "$chapters_array" | sed '$ s/,$//'
        echo "  ]"
        echo "}"
    } > "$output_file"
}

# 輸出 YouTube 完整格式
output_youtube() {
    local chapters_text="$1"
    local title="$2"
    local tags="$3"
    local total_seconds=$4
    local output_file="$5"
    
    local total_time=$(format_timestamp $total_seconds)
    
    {
        echo "$title"
        echo ""
        echo "---"
        echo ""
        echo "🕐 章節 / Chapters:"
        echo ""
        echo "$chapters_text"
        echo ""
        echo "⏱️ 總時長 / Total Duration: $total_time"
        echo ""
        echo "---"
        echo ""
        if [ -n "$tags" ]; then
            # 轉換逗號分隔的標籤為 hashtags
            echo "$tags" | sed 's/,/ #/g' | sed 's/^/#/'
        fi
    } > "$output_file"
}

# 主程式
main() {
    # 預設值
    local input_dir=""
    local output_file="chapters.txt"
    local output_format="text"
    local video_title=""
    local video_tags=""
    
    # 解析參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "YouTube Chapter Generator v$VERSION"
                exit 0
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -f|--format)
                output_format="$2"
                shift 2
                ;;
            -t|--title)
                video_title="$2"
                shift 2
                ;;
            --tags)
                video_tags="$2"
                shift 2
                ;;
            *)
                if [ -z "$input_dir" ]; then
                    input_dir="$1"
                else
                    echo -e "${RED}錯誤: 未知參數 '$1'${NC}"
                    echo ""
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 檢查必要參數
    if [ -z "$input_dir" ]; then
        show_usage
        exit 1
    fi
    
    # 檢查輸入目錄
    if [ ! -d "$input_dir" ]; then
        echo -e "${RED}錯誤: 找不到目錄 '$input_dir'${NC}"
        exit 1
    fi
    
    # 驗證輸出格式
    if [[ ! "$output_format" =~ ^(text|json|youtube)$ ]]; then
        echo -e "${RED}錯誤: 不支援的輸出格式 '$output_format'${NC}"
        echo "支援的格式: text, json, youtube"
        exit 1
    fi
    
    # YouTube 格式需要標題
    if [ "$output_format" == "youtube" ] && [ -z "$video_title" ]; then
        echo -e "${YELLOW}警告: YouTube 格式建議提供標題 (--title)${NC}"
        video_title="Music Mix"
    fi
    
    # 檢查依賴
    check_dependencies
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  YouTube Chapter Generator v$VERSION${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}📂 掃描目錄:${NC} $input_dir"
    echo -e "${YELLOW}📝 輸出檔案:${NC} $output_file"
    echo -e "${YELLOW}📋 輸出格式:${NC} $output_format"
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
    echo -e "${BLUE}🎵 處理中...${NC}"
    echo ""
    
    # 初始化
    local total_seconds=0
    local processed_count=0
    local chapters_text=""
    local chapters_json=""
    
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
        
        # 顯示進度
        echo "$timestamp $song_name"
        
        # 累積文字格式
        chapters_text+="$timestamp $song_name"$'\n'
        
        # 累積 JSON 格式
        chapters_json+="    {\"time\": \"$timestamp\", \"time_seconds\": $total_seconds, \"title\": \"$song_name\"},"$'\n'
        
        # 累加時長
        total_seconds=$((total_seconds + duration))
        processed_count=$((processed_count + 1))
    done
    
    # 移除 chapters_text 最後的換行
    chapters_text="${chapters_text%$'\n'}"
    
    echo ""
    
    # 根據格式輸出
    case "$output_format" in
        json)
            output_json "$chapters_json" "$total_seconds" "$output_file"
            ;;
        youtube)
            output_youtube "$chapters_text" "$video_title" "$video_tags" "$total_seconds" "$output_file"
            ;;
        text|*)
            {
                echo "# YouTube 章節時間戳"
                echo "# 產生時間: $(date '+%Y-%m-%d %H:%M:%S')"
                echo "# 來源目錄: $input_dir"
                echo ""
                echo "$chapters_text"
            } > "$output_file"
            ;;
    esac
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ 完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "📊 統計:"
    echo -e "   • 處理檔案: ${GREEN}$processed_count${NC} / ${#audio_files[@]}"
    echo -e "   • 總時長:   ${GREEN}$(format_timestamp $total_seconds)${NC}"
    echo -e "   • 輸出檔案: ${GREEN}$output_file${NC}"
    echo -e "   • 輸出格式: ${GREEN}$output_format${NC}"
    echo ""
    
    if [ "$output_format" == "text" ]; then
        echo -e "${BLUE}💡 下一步:${NC}"
        echo -e "   1. 打開 $output_file"
        echo -e "   2. 複製內容（跳過 # 開頭的註解行）"
        echo -e "   3. 貼到 YouTube 影片說明欄"
    elif [ "$output_format" == "json" ]; then
        echo -e "${BLUE}💡 提示:${NC}"
        echo -e "   JSON 格式適合程式處理，包含時間戳秒數和格式化時間"
    elif [ "$output_format" == "youtube" ]; then
        echo -e "${BLUE}💡 提示:${NC}"
        echo -e "   完整說明欄格式已產生，可直接複製貼上到 YouTube"
    fi
    echo ""
}

# 執行主程式
main "$@"
