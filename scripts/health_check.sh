#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# health_check.sh - 家老・足軽のヘルスチェック+自動復旧スクリプト
# ═══════════════════════════════════════════════════════════════════════════════
#
# 機能:
#   1. コンテキスト残量を確認（10%以下で警告、5%以下で自動復旧）
#   2. 入力待ち状態を検知して自動でEnter送信
#   3. 停止状態のエージェントを検知してアラート
#
# 使用方法:
#   ./scripts/health_check.sh           # 1回チェック
#   ./scripts/health_check.sh --watch   # 継続監視（30秒間隔）
#   ./scripts/health_check.sh --fix     # 問題を自動修正
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 色付きログ関数
log_ok() { echo -e "\033[1;32m[OK]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[警告]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[危険]\033[0m $1"; }
log_info() { echo -e "\033[1;36m[情報]\033[0m $1"; }
log_fix() { echo -e "\033[1;35m[修復]\033[0m $1"; }

# オプション解析
WATCH_MODE=false
AUTO_FIX=false
INTERVAL=30

while [[ $# -gt 0 ]]; do
    case $1 in
        --watch|-w)
            WATCH_MODE=true
            shift
            ;;
        --fix|-f)
            AUTO_FIX=true
            shift
            ;;
        --interval|-i)
            INTERVAL="$2"
            shift 2
            ;;
        --help|-h)
            echo "使用方法: $0 [オプション]"
            echo ""
            echo "オプション:"
            echo "  --watch, -w     継続監視モード（30秒間隔）"
            echo "  --fix, -f       問題を自動修正"
            echo "  --interval, -i  監視間隔（秒、デフォルト: 30）"
            echo "  --help, -h      ヘルプを表示"
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            exit 1
            ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════════
# コンテキスト残量を取得
# ═══════════════════════════════════════════════════════════════════════════════
get_context_percent() {
    local pane="$1"
    local output
    output=$(tmux capture-pane -t "$pane" -p 2>/dev/null | tail -10)

    # "Context left until auto-compact: XX%" のパターンを検索（macOS互換）
    local percent
    percent=$(echo "$output" | grep -o 'Context left until auto-compact:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' | tail -1)

    if [ -n "$percent" ]; then
        echo "$percent"
    else
        echo "?"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 入力待ち状態かどうかを確認
# ═══════════════════════════════════════════════════════════════════════════════
is_waiting_for_input() {
    local pane="$1"
    local output
    output=$(tmux capture-pane -t "$pane" -p 2>/dev/null | tail -5)

    # 典型的な入力待ちパターン
    if echo "$output" | grep -qE '(❯\s*$|bypass permissions|Worked for|Baked for|Cooked for)'; then
        # 作業完了後の待機状態
        if echo "$output" | grep -qE '(Worked for|Baked for|Cooked for|Churned for)'; then
            echo "completed"
        else
            echo "waiting"
        fi
    elif echo "$output" | grep -qE '(thinking|Galloping|Twisting|Channelling|Unravelling)'; then
        echo "working"
    else
        echo "unknown"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# エージェントの状態をチェック
# ═══════════════════════════════════════════════════════════════════════════════
check_agent() {
    local pane="$1"
    local name="$2"

    local context_pct
    context_pct=$(get_context_percent "$pane")

    local status
    status=$(is_waiting_for_input "$pane")

    local status_icon
    case "$status" in
        "working") status_icon="🔄" ;;
        "completed") status_icon="✅" ;;
        "waiting") status_icon="⏸️" ;;
        *) status_icon="❓" ;;
    esac

    # コンテキスト残量に応じた色分け
    local context_display
    if [ "$context_pct" = "?" ]; then
        context_display="---"
    elif [ "$context_pct" -le 5 ]; then
        context_display="\033[1;31m${context_pct}%\033[0m"  # 赤
    elif [ "$context_pct" -le 10 ]; then
        context_display="\033[1;33m${context_pct}%\033[0m"  # 黄
    else
        context_display="\033[1;32m${context_pct}%\033[0m"  # 緑
    fi

    echo -e "  $status_icon $name: コンテキスト $context_display ($status)"

    # 問題検出
    local has_problem=false

    if [ "$context_pct" != "?" ] && [ "$context_pct" -le 5 ]; then
        log_error "  └─ $name のコンテキストが枯渇寸前！（${context_pct}%）"
        has_problem=true

        if [ "$AUTO_FIX" = true ]; then
            fix_agent "$pane" "$name" "context_low"
        fi
    elif [ "$context_pct" != "?" ] && [ "$context_pct" -le 10 ]; then
        log_warn "  └─ $name のコンテキストが低下中（${context_pct}%）"
    fi

    # 完了後に長時間待機している場合
    if [ "$status" = "completed" ] || [ "$status" = "waiting" ]; then
        if [ "$AUTO_FIX" = true ]; then
            # 特に何もしない（完了は正常）
            :
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# エージェントの自動修復
# ═══════════════════════════════════════════════════════════════════════════════
fix_agent() {
    local pane="$1"
    local name="$2"
    local issue="$3"

    case "$issue" in
        "context_low")
            log_fix "$name をクリアして再起動中..."
            tmux send-keys -t "$pane" "/clear" Enter
            sleep 2

            # エージェントの種類に応じて適切な指示を送信
            if [ "$name" = "家老" ]; then
                tmux send-keys -t "$pane" "instructions/karo.md を読んで役割を理解せよ。コンテキストが枯渇したため再起動した。" Enter
            else
                local agent_num
                agent_num=$(echo "$name" | grep -o '[0-9]*')
                tmux send-keys -t "$pane" "instructions/ashigaru.md を読んで役割を理解せよ。汝は足軽${agent_num}号である。コンテキストが枯渇したため再起動した。" Enter
            fi
            log_ok "$name の再起動完了"
            ;;
        "input_waiting")
            log_fix "$name に Enter を送信中..."
            tmux send-keys -t "$pane" Enter
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# 全エージェントをチェック
# ═══════════════════════════════════════════════════════════════════════════════
check_all_agents() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo " 🏥 エージェントヘルスチェック - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""

    # セッションが存在するか確認
    if ! tmux has-session -t multiagent 2>/dev/null; then
        log_error "multiagent セッションが存在しません"
        return 1
    fi

    echo "【家老・足軽の陣】"

    # 家老
    check_agent "multiagent:0.0" "家老"

    # 足軽1-8
    for i in {1..8}; do
        check_agent "multiagent:0.$i" "足軽$i"
    done

    echo ""

    # 将軍セッションも確認
    if tmux has-session -t shogun 2>/dev/null; then
        echo "【将軍の本陣】"
        check_agent "shogun:0.0" "将軍"
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════════════"

    if [ "$AUTO_FIX" = true ]; then
        echo " 🔧 自動修復モード: ON"
    else
        echo " 💡 自動修復を有効にするには: $0 --fix"
    fi
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# メイン処理
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$WATCH_MODE" = true ]; then
    log_info "監視モードを開始（間隔: ${INTERVAL}秒、Ctrl+C で終了）"
    echo ""

    while true; do
        check_all_agents
        sleep "$INTERVAL"
    done
else
    check_all_agents
fi
