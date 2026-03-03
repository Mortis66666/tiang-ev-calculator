#!/usr/bin/env bash

set -e

C_RESET=$(tput sgr0)
C_BOLD=$(tput bold)
C_DIM=$(tput dim)
C_REV=$(tput rev)
C_EL=$(tput el)

C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_BLUE=$(tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_CYAN=$(tput setaf 6)
C_WHITE=$(tput setaf 7)
C_BLACK=$(tput setaf 0)

BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_WHITE=$(tput setab 7)
BG_BLACK=$(tput setab 0)

UI_WIDTH=78  # Total width of the interface
UI_PAD=""    # Left padding string (calculated dynamically)
UI_HEIGHT=24 # Approximate height for vertical centering
CURRENT_STATE="init" # init, setup, game

SPACES="                                                                                                                                                                                                        "
DASHES="────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
BARS="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DECK_COUNT=1
CARD_ORDER="A23456789TJQK"
declare -a COUNTS
declare -a HISTORY
declare -a TIANGS
declare -a HIST_DISCARD
declare -a HIST_CALC
MODE="discard"
STATUS_MSG="Welcome! Select cards to track discards."
LAST_EV=""

cleanup() {
    tput cnorm # Show cursor
    stty echo < /dev/tty # Enable echo
    echo "${C_RESET}"
    clear
    exit
}
trap cleanup EXIT INT TERM

check_deps() {
    if ! command -v awk &> /dev/null; then
        echo "Error: 'awk' is required."
        exit 1
    fi
}

read_char() {
    old_stty_cfg=$(stty -g < /dev/tty)
    stty raw -echo < /dev/tty
    eval "$1=\$(dd bs=1 count=1 2>/dev/null < /dev/tty)"
    stty $old_stty_cfg < /dev/tty
}

get_index() {
    local rank=$1
    local str=$CARD_ORDER
    for (( j=0; j<${#str}; j++ )); do
        if [[ "${str:$j:1}" == "$rank" ]]; then
            echo $j
            return
        fi
    done
    echo -1
}

key_to_rank() {
    local key=$1
    case $key in
        1|a|A) echo "A" ;;
        2) echo "2" ;;
        3) echo "3" ;;
        4) echo "4" ;;
        5) echo "5" ;;
        6) echo "6" ;;
        7) echo "7" ;;
        8) echo "8" ;;
        9) echo "9" ;;
        0|t|T) echo "T" ;;
        j|J) echo "J" ;;
        q|Q) echo "Q" ;;
        k|K) echo "K" ;;
        *) echo "" ;;
    esac
}

str_len_no_ansi() {
    local str=$1

    local clean=$(echo -e "$str" | sed "s/$(printf '\033')\[[0-9;]*[a-zA-Z]//g")
    echo ${#clean}
}

recalc_layout() {
    local cols=$(tput cols)
    
    if [ $cols -ge 78 ]; then
        UI_WIDTH=78
    else
        UI_WIDTH=$cols
    fi

    if [ $UI_WIDTH -lt 30 ]; then UI_WIDTH=30; fi
    
    if [ $cols -gt $UI_WIDTH ]; then
        local pad_x=$(( (cols - UI_WIDTH) / 2 ))
        if [ $pad_x -lt 0 ]; then pad_x=0; fi
        UI_PAD="${SPACES:0:$pad_x}"
    else
        UI_PAD=""
    fi
    
    local lines=$(tput lines)
    local pad_y=$(( (lines - UI_HEIGHT) / 2 ))
    if [ $pad_y -lt 0 ]; then pad_y=0; fi
    
    UI_PAD_Y=$pad_y
}

calc_padding() {
    if [ "$1" == "move" ]; then
        tput cup $UI_PAD_Y 0
    fi
}

handle_winch() {
    recalc_layout
    clear
    
    if [ "$CURRENT_STATE" == "game" ]; then
        draw_ui
    elif [ "$CURRENT_STATE" == "setup" ]; then
        draw_header
        echo " (Terminal resized. Please complete current input step)"
    fi
}

trap handle_winch WINCH

print_box_centered() {
    local text="$1"
    local len=$(str_len_no_ansi "$text")
    local pad_len=$(( (UI_WIDTH - len) / 2 ))
    local pad="${SPACES:0:$pad_len}"
    echo "${UI_PAD}${pad}${text}${C_EL}"
}

print_separator() {
    local line="${DASHES:0:$UI_WIDTH}"
    echo "${UI_PAD}${C_DIM}${line}${C_RESET}${C_EL}"
}

init_game() {
    for (( i=0; i<13; i++ )); do
        COUNTS[$i]=$(( 4 * DECK_COUNT ))
    done
    HIST_DISCARD=()
    HIST_CALC=()
    TIANGS=()
    MODE="discard"
    STATUS_MSG="Game reset. Ready."
    LAST_EV=""
}

undo_action() {
    if [ "$MODE" == "discard" ]; then
        if [ ${#HIST_DISCARD[@]} -gt 0 ]; then
            local idx="${HIST_DISCARD[-1]}"
            unset 'HIST_DISCARD[${#HIST_DISCARD[@]}-1]'
            COUNTS[$idx]=$(( COUNTS[$idx] + 1 ))
            STATUS_MSG="Undid discard of ${CARD_ORDER:$idx:1}"
        else
            STATUS_MSG="Nothing to undo in discard mode."
        fi
    else
        if [ ${#TIANGS[@]} -eq 0 ]; then
            if [ ${#HIST_CALC[@]} -gt 0 ]; then
                local data="${HIST_CALC[-1]}"
                unset 'HIST_CALC[${#HIST_CALC[@]}-1]'
                local idx1=${data%%,*}
                local idx2=${data#*,}
                TIANGS=($idx1)
                COUNTS[$idx2]=$(( COUNTS[$idx2] + 1 ))
                STATUS_MSG="Undid calculation. Selection restored."
                LAST_EV=""
            else
                STATUS_MSG="Nothing to undo."
            fi
        elif [ ${#TIANGS[@]} -eq 1 ]; then
             local idx=${TIANGS[-1]}
             unset 'TIANGS[${#TIANGS[@]}-1]'
             COUNTS[$idx]=$(( COUNTS[$idx] + 1 ))
             STATUS_MSG="Unselected ${CARD_ORDER:$idx:1}"
             LAST_EV=""
        fi
    fi
}

calculate_ev() {
    local t1=${TIANGS[0]}
    local t2=${TIANGS[1]}
    local min=$(( t1 < t2 ? t1 : t2 ))
    local max=$(( t1 > t2 ? t1 : t2 ))
    
    local win_outs=0
    for (( i=min+1; i<max; i++ )); do
        win_outs=$(( win_outs + COUNTS[i] ))
    done
    
    local tiang_outs=${COUNTS[t1]}
    if [ $t1 -ne $t2 ]; then
        tiang_outs=$(( tiang_outs + COUNTS[t2] ))
    fi
    
    local total_cards=$(( 52 * DECK_COUNT ))
    local current_hand=2
    local prev_hands=$(( ${#HIST_CALC[@]} * 2 ))
    local discards=${#HIST_DISCARD[@]}
    local total_outs=$(( total_cards - current_hand - prev_hands - discards ))
    
    local ev=$(awk "BEGIN { printf \"%.2f\", (2 * $win_outs - $tiang_outs) / $total_outs - 1 }")
    local c1_char="${CARD_ORDER:$min:1}"
    local c2_char="${CARD_ORDER:$max:1}"
    
    LAST_EV="${C_BOLD}${C_CYAN}[${c1_char} - ${c2_char}] EV: ${ev}${C_RESET}"
    STATUS_MSG="Calculation complete."
}

draw_header() {
    local line="${BARS:0:$UI_WIDTH}"
    echo "${UI_PAD}${C_BOLD}${C_BLUE}┏${line}┓${C_RESET}${C_EL}"
    

    local title="TIANG EV CALCULATOR"
    local t_len=${#title}
    local pad_len=$(( (UI_WIDTH - t_len) / 2))
    local pad="${SPACES:0:$pad_len}"

    local extra=""

    if [ $(( (UI_WIDTH - t_len) % 2 )) -ne 0 ]; then extra=" "; fi
    
    echo "${UI_PAD}${C_BOLD}${C_BLUE}┃${pad}${C_WHITE}${title}${C_BLUE}${pad}${extra}┃${C_RESET}${C_EL}"
    echo "${UI_PAD}${C_BOLD}${C_BLUE}┗${line}┛${C_RESET}${C_EL}"
}

draw_status_bar() {
    local mode_txt=""
    local desc_txt=""
    local color=""
    local bg=""
    
    if [ "$MODE" == "discard" ]; then
        mode_txt=" DISCARD MODE "
        desc_txt="Track played cards"
        color="${C_BLACK}"
        bg="${BG_BLUE}"
    else
        mode_txt=" CALCULATOR MODE "
        desc_txt="Select your hand"
        color="${C_BLACK}"
        bg="${BG_YELLOW}"
    fi
    

    local bar_len=$UI_WIDTH
    local txt_len=${#mode_txt}
    local desc_len=${#desc_txt}
    local spacing=2
    
    local total_content_len=$(( txt_len + spacing + desc_len ))
    local side_pad_len=$(( (UI_WIDTH - total_content_len) / 2 ))
    local pad_l="${SPACES:0:$side_pad_len}"
    
    echo "${C_EL}"

    echo -e "${UI_PAD}${pad_l}${bg}${color}${C_BOLD}${mode_txt}${C_RESET}  ${C_DIM}${desc_txt}${C_RESET}${C_EL}"
    echo "${C_EL}"
}

draw_grid() {
    local rows=5
    local cols=3
    
    local spacer_len=2
    local total_spacer_len=4
    local avail_for_cells=$(( UI_WIDTH - total_spacer_len ))
    
    local cell_w=$(( avail_for_cells / 3 ))
    
    local used_w=$(( cell_w * 3 + total_spacer_len ))
    local rem_w=$(( UI_WIDTH - used_w ))
    local margin_l_w=$(( rem_w / 2 ))
    
    local spacer="${SPACES:0:$spacer_len}"
    local side_margin_l="${SPACES:0:$margin_l_w}"
    local empty_box="${SPACES:0:$cell_w}"
    
    for (( r=0; r<rows; r++ )); do
        local line_vis="${side_margin_l}"
        
        for (( c=0; c<cols; c++ )); do
            local idx=$(( r * 3 + c ))
            
            if [ $idx -ge 13 ]; then 
                line_vis+="${empty_box}"
                if [ $c -lt 2 ]; then line_vis+="${spacer}"; fi
                continue
            fi
            
            local rank="${CARD_ORDER:$idx:1}"
            local count="${COUNTS[$idx]}"
            
            local style_card="${C_BOLD}${C_WHITE}"
            local style_count="${C_GREEN}"
            local border_col="${C_DIM}"
            local bg=""
            local reset_bg="${C_RESET}"
            
            local is_selected=0
            for s in "${TIANGS[@]}"; do
                if [ "$s" -eq "$idx" ]; then is_selected=1; fi
            done
            
            if [ $is_selected -eq 1 ]; then
                bg="${BG_YELLOW}${C_BLACK}"
                reset_bg="${C_RESET}" # Reset clears BG
                style_card="${C_BLACK}"
                style_count="${C_BLACK}"
                border_col="${C_YELLOW}"
            elif [ $count -eq 0 ]; then
                style_card="${C_DIM}${C_RED}"
                style_count="${C_DIM}${C_RED}"
                border_col="${C_DIM}"
            fi
            
            local text="${rank} (${count})"
            local text_len=${#text}
            
            local total_pad=$(( cell_w - 2 - text_len )) # -2 for brackets
            local pad_l_len=$(( total_pad / 2 ))
            local pad_r_len=$(( total_pad - pad_l_len ))
            
            local pad_l="${SPACES:0:$pad_l_len}"
            local pad_r="${SPACES:0:$pad_r_len}"
            
            if [ $is_selected -eq 1 ]; then
                line_vis+="${bg}[${pad_l}${style_card}${text}${style_count}${pad_r}]${C_RESET}"
            else
                line_vis+="${border_col}[${C_RESET}${bg}${pad_l}${style_card}${rank} ${style_count}(${count})${pad_r}${C_RESET}${border_col}]${C_RESET}"
            fi
            
            if [ $c -lt 2 ]; then line_vis+="${spacer}"; fi
            
        done
        echo -e "${UI_PAD}${line_vis}${C_EL}"
        echo "${C_EL}" 
    done
}

draw_footer() {
    print_separator
    
    if [ -n "$LAST_EV" ]; then
        print_box_centered "${C_BOLD}RESULT:${C_RESET} $LAST_EV"
    else
        print_box_centered "${C_DIM}Waiting for input...${C_RESET}"
    fi
    echo "${C_EL}"
    
    print_box_centered "${C_WHITE}STATUS:${C_RESET} $STATUS_MSG"
    
    print_separator
    
    echo -e "${UI_PAD} ${C_BOLD}KEYS:${C_RESET} ${C_CYAN}[1-9, 0=10, a,j,q,k]${C_RESET} Select ${C_CYAN}[m]${C_RESET} Mode ${C_CYAN}[u]${C_RESET} Undo ${C_CYAN}[r]${C_RESET} Reset ${C_CYAN}[q]${C_RESET} Quit${C_EL}"
}

draw_ui() {

    if [ -z "$UI_PAD" ]; then recalc_layout; fi
    
    calc_padding "move"
    
    draw_header
    draw_status_bar
    draw_grid
    draw_footer
    
    tput ed 
}

draw_setup_step() {
    local step=$1
    local title=$2
    local details=$3
    
    calc_padding "move"
    draw_header
    echo "${C_EL}"
    print_box_centered "${C_BOLD}${C_YELLOW}SETUP WIZARD${C_RESET}"
    echo "${C_EL}"
    print_separator
    echo "${C_EL}"
    
    print_box_centered "${C_REV} STEP ${step} ${C_RESET}"
    echo "${C_EL}"
    echo "${C_EL}"
    
    print_box_centered "${C_BOLD}${C_WHITE}${title}${C_RESET}"
    echo "${C_EL}"
    
    if [ -n "$details" ]; then
        echo -e "$details" | while IFS= read -r line; do
            print_box_centered "${C_DIM}${line}${C_RESET}"
        done
    fi
    echo "${C_EL}"
    
    local arrow="> "
    local len=${#arrow}
    local pad_len=$(( (UI_WIDTH - len) / 2 ))
    local pad="${SPACES:0:$pad_len}"
    echo -ne "${UI_PAD}${pad}${C_CYAN}${arrow}${C_RESET}"
}

setup_wizard() {
    CURRENT_STATE="setup"
    tput civis
    clear
    

    recalc_layout
    draw_setup_step 1 "Number of Decks" "How many decks are in play?\n(Default: 1)\n\n[q] Quit"
    tput cnorm # show cursor for input
    read input_decks < /dev/tty
    
    if [[ "$input_decks" == "q" || "$input_decks" == "Q" ]]; then
        cleanup
    fi
    
    DECK_COUNT=${input_decks:-1}
    tput civis
    

    recalc_layout
    draw_setup_step 2 "Card Rank Order" "Select the hierarchy of cards:\n\n[1] A-K (Ace Low)\n[2] 2-A (Ace High)\n[3] Custom Order\n\n[q] Quit"
    tput cnorm
    read order_choice < /dev/tty
    
    if [[ "$order_choice" == "q" || "$order_choice" == "Q" ]]; then
        cleanup
    fi
    
    tput civis
    
    case $order_choice in
        2) CARD_ORDER="23456789TJQKA" ;;
        3) 
            recalc_layout
            draw_setup_step 3 "Custom Order" "Enter 13 characters from Low to High.\nExample: A23456789TJQK\n\n[q] Quit"
            tput cnorm
            read custom_order < /dev/tty
            
            if [[ "$custom_order" == "q" || "$custom_order" == "Q" ]]; then
                cleanup
            fi
            
            tput civis
            if [ ${#custom_order} -ne 13 ]; then

                CARD_ORDER="A23456789TJQK" 
            else
                CARD_ORDER=$(echo "$custom_order" | tr 'a-z' 'A-Z')
            fi
            ;;
        *) CARD_ORDER="A23456789TJQK" ;;
    esac
    CURRENT_STATE="game"
}

check_deps

tput civis
recalc_layout
CURRENT_STATE="setup"

setup_wizard
init_game
clear

while true; do
    draw_ui
    
    read_char key
    key=$(echo "$key" | tr 'A-Z' 'a-z')
    
    if [[ "$key" == "q" ]]; then
        cleanup
    elif [[ "$key" == "r" ]]; then
        init_game
    elif [[ "$key" == "u" ]]; then
        undo_action
    elif [[ "$key" == "m" ]]; then
        if [ "$MODE" == "discard" ]; then
            MODE="calc"
            STATUS_MSG="Switched to Calculator."
        else
            if [ ${#TIANGS[@]} -gt 0 ]; then
                STATUS_MSG="${C_RED}Cannot switch! Finish calculation or Undo.${C_RESET}"
            else
                MODE="discard"
                STATUS_MSG="Switched to Discard."
                LAST_EV=""
            fi
        fi
    else
        rank=$(key_to_rank "$key")
        if [ -n "$rank" ]; then
            idx=$(get_index "$rank")
            if [ "$idx" -ge 0 ]; then
                if [ ${COUNTS[$idx]} -le 0 ]; then
                    STATUS_MSG="${C_RED}No more ${rank}s left!${C_RESET}"
                else
                    if [ "$MODE" == "discard" ]; then
                        COUNTS[$idx]=$(( COUNTS[$idx] - 1 ))
                        HIST_DISCARD+=("$idx")
                        STATUS_MSG="Discarded ${rank}"
                    else
                        if [ ${#TIANGS[@]} -lt 2 ]; then
                            TIANGS+=("$idx")
                            COUNTS[$idx]=$(( COUNTS[$idx] - 1 ))
                            STATUS_MSG="Selected ${rank}..."
                            if [ ${#TIANGS[@]} -eq 2 ]; then
                                calculate_ev
                                saved="${TIANGS[0]},${TIANGS[1]}"
                                HIST_CALC+=("$saved")
                                TIANGS=()
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
done
