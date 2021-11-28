#!/bin/bash

# Tested on Ubutnu 20.04 LTS bash 5.0.17

BOARD=("1" "2" "3" "4" "5" "6" "7" "8" "9")
DIMENSION=3
ARRAY_SIZE=8
IS_PLAYER_1_MOVE="true"
MARK="X"
CURRENT_PLAYER="1"

# 1 - 2 players
function is_single_player {
    while ! [[ $NUMBER_OF_PLAYERS =~ ^[0-9]+$ && $NUMBER_OF_PLAYERS -lt 3 && $NUMBER_OF_PLAYERS -gt 0 ]]; do
        read -p "Please enter how many players gonna play (1 or 2): " NUMBER_OF_PLAYERS
    done
    if [[ $NUMBER_OF_PLAYERS -eq 1 ]]; then
        COMPUTER_PLAYING="true"
    else
        COMPUTER_PLAYING="false"
    fi
    TURNS=0
}

# If possible (i.e file exists) ask for loading
function load_game {
    if [ -f file.txt ]; then
        read -p "Do you want to load a saved game? (type 'yes' or anything else to discard): " IF_LOAD_GAME
        if [ $IF_LOAD_GAME == "yes" ]; then 
            field=0
            while read element; do
                if [ $field -lt 9 ]; then
                    BOARD[$(($field))]="$element"
                    field=$((field+1))
                else
                    break
                fi
            done < file.txt
            COMPUTER_PLAYING=$(cat file.txt | grep ComputerPlaying | cut -d ":" -f2 | tr -d ' ')
            IS_PLAYER_1_MOVE=$(cat file.txt | grep IsPlayerOneMove | cut -d ":" -f2 | tr -d ' ')
            TURNS=$(cat file.txt | grep Turns | cut -d ":" -f2 | tr -d ' ')
            set_player_variables "false"
        else
            is_single_player
        fi
    else
        is_single_player
    fi
}

# Print board
function show_board {
    echo "========="
    for i in $(eval echo {0..$ARRAY_SIZE..$DIMENSION})
    do
        echo "${BOARD[$i]} | ${BOARD[$i+1]} | ${BOARD[$i+2]}"
    done
    echo "========="
}

# Check - 4 possibilities
function check_win {
    for i in $(eval echo {0..6..3})
    do
        if [[ "${BOARD[$i]}" == "${BOARD[$((i+1))]}" && "${BOARD[$i]}" == "${BOARD[$((i+2))]}" ]]; then
            false
            return
        fi
    done
    for i in $(eval echo {0..3})
    do
        if [[ "${BOARD[$i]}" == "${BOARD[$((i+3))]}" && "${BOARD[$i]}" == "${BOARD[$((i+6))]}" ]]; then
            false
            return
        fi
    done
    if [[ "${BOARD[0]}" == "${BOARD[4]}" && "${BOARD[0]}" == "${BOARD[8]}" ]]; then
        false
        return
    fi
    if [[ "${BOARD[2]}" == "${BOARD[4]}" && "${BOARD[2]}" == "${BOARD[6]}" ]]; then
        false
        return
    fi
    true
}

function set_player_variables {
    if [[ $IS_PLAYER_1_MOVE == $1 ]]; then
        set_player "false" "O" "2"
    else
        set_player "true" "X" "1"
    fi
}

function set_player {
    IS_PLAYER_1_MOVE=$1
    MARK=$2
    CURRENT_PLAYER=$3
}

# Check if selected field is in proper range + if it is not already selected
function check_field {
    if ! [[ $SELECTED_FIELD =~ ^[0-9]+$ && $SELECTED_FIELD -lt 10 && $SELECTED_FIELD -gt 0 ]]; then
        echo "Please enter integer in range 1 - 9!"
        false
        return
    fi
    if [[ ${BOARD[$(($SELECTED_FIELD-1))]} == "X" || ${BOARD[$(($SELECTED_FIELD-1))]} == "O" ]]; then
        if ! [[ $COMPUTER_PLAYING == "true" && "$IS_PLAYER_1_MOVE" == "false" ]]; then
            echo "This field has already been selected!"
        fi
        false
        return
    fi
    return
}

function enter_field {
    echo "Player $CURRENT_PLAYER move!"
    read -p "Please enter field: " SELECTED_FIELD
}

function mark {
    get_field
    while ! check_field $SELECTED_FIELD; do
        get_field
    done
    BOARD[$(($SELECTED_FIELD-1))]="$MARK"  
}

function get_field {
    if [[ "$IS_PLAYER_1_MOVE" == "false" && $COMPUTER_PLAYING == "true" ]]; then
        SELECTED_FIELD=$(($RANDOM%9+1))
    else
        enter_field
    fi
}

function save_to_file {
    echo -n "" > file.txt
    for element in "${BOARD[@]}"; do
        echo "$element" >> file.txt
    done
    echo "ComputerPlaying: $COMPUTER_PLAYING" >> file.txt
    echo "IsPlayerOneMove: $IS_PLAYER_1_MOVE" >> file.txt
    echo "Turns: $TURNS" >> file.txt
}

load_game
echo "Autosave enabled after every move! Press CTRL-C to stop a game, then re-launch a script and you will have an option to resume the previous game."

# while loop for 9 turns (max in game)
while [ $TURNS -lt 9 ]; do
    show_board
    mark
    check_win
    if [[ $? -ne 0 ]]; then
        echo "End of game!"
        show_board
        echo "Player $CURRENT_PLAYER won!"
        rm file.txt
        exit
    fi
    set_player_variables "true"
    TURNS=$((TURNS+1))
    save_to_file
done

# If turns == 9 we have a draw :)
rm file.txt
show_board
echo "Draw! Thanks for playing!"

