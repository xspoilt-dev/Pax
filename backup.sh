#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

BACKUP_DIR="$HOME/termux_backup"
STORAGE_FILE="/sdcard/termux_backup/termux_backup.tar.gz"
THREADS=$(nproc)

check_and_install() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}Installing '$1'...${NC}"
        pkg install -y $1
    fi
}

check_and_install pv
check_and_install pigz
check_and_install tar

backup_termux() {
    echo -e "${BLUE}Starting Termux backup with $THREADS threads...${NC}"
    mkdir -p "$BACKUP_DIR"
    EXCLUDE_LIST="--exclude=$PREFIX/tmp --exclude=$PREFIX/var/tmp --exclude=$PREFIX/lib/apt/lists/*"
    
    if [ -f "$HOME/.termuxrc" ]; then
        tar -cvf - $EXCLUDE_LIST -C "$PREFIX" . -C "$HOME" .termux .termuxrc | pv | pigz -p $THREADS > "$STORAGE_FILE"
    else
        tar -cvf - $EXCLUDE_LIST -C "$PREFIX" . -C "$HOME" .termux | pv | pigz -p $THREADS > "$STORAGE_FILE"
    fi

    echo -e "${GREEN}Backup completed and saved to $STORAGE_FILE${NC}"
}

restore_termux() {
    echo -e "${BLUE}Starting Termux restore...${NC}"
    
    if [ ! -f "$STORAGE_FILE" ]; then
        echo -e "${RED}Backup file not found in /sdcard/termux_backup!${NC}"
        exit 1
    fi
    
    check_and_install pv
    check_and_install pigz
    check_and_install tar

    echo -e "${YELLOW}Clearing current Termux environment...${NC}"
    rm -rf "$PREFIX"/*
    
    echo -e "${YELLOW}Restoring from backup...${NC}"
    pv "$STORAGE_FILE" | pigz -d -p $THREADS | tar -xv -C "$PREFIX"
    
    echo -e "${GREEN}Restore completed!${NC}"
}

cd $HOME
mkdir -p "/sdcard/termux_backup"

if [ "$1" == "backup" ]; then
    backup_termux
elif [ "$1" == "restore" ]; then
    restore_termux
else
    echo -e "${RED}Usage: $0 {backup|restore}${NC}"
fi
