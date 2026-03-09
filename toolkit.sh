#!/bin/bash
#
# toolkit.sh - System Administration Toolkit
# A menu-driven script demonstrating all bash scripting concepts
#

# === Color Variables ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# === Base directory for data files ===
BASE_DIR="$(dirname "$0")"

# ============================================
# FUNCTION: file_inspector
# Uses: read, if/elif/else, file test operators
# ============================================
file_inspector() {
    echo -e "${CYAN}=== File Inspector ===${NC}"
    read -p "Enter file/directory path: " filepath

    if [ -z "$filepath" ]; then
        echo -e "${RED}Error: No path provided${NC}"
        return
    fi

    # Check existence
    if [ ! -e "$filepath" ]; then
        echo -e "${RED}ERROR: '$filepath' does not exist${NC}"
        return
    fi

    echo -e "${GREEN}File exists: YES${NC}"

    # Check type
    if [ -f "$filepath" ]; then
        echo "Type: Regular file"
    elif [ -d "$filepath" ]; then
        echo "Type: Directory"
    elif [ -L "$filepath" ]; then
        echo "Type: Symbolic link"
    else
        echo "Type: Other (special file)"
    fi

    # Check permissions
    if [ -r "$filepath" ]; then
        echo -e "Readable: ${GREEN}YES${NC}"
    else
        echo -e "Readable: ${RED}NO${NC}"
    fi

    if [ -w "$filepath" ]; then
        echo -e "Writable: ${GREEN}YES${NC}"
    else
        echo -e "Writable: ${RED}NO${NC}"
    fi

    if [ -x "$filepath" ]; then
        echo -e "Executable: ${GREEN}YES${NC}"
    else
        echo -e "Executable: ${RED}NO${NC}"
    fi

    # Check if empty
    if [ -s "$filepath" ]; then
        echo -e "Has content: ${GREEN}YES${NC} ($(wc -c < "$filepath") bytes)"
    else
        echo -e "Has content: ${YELLOW}NO (empty file)${NC}"
    fi
}

# ============================================
# FUNCTION: server_pinger
# Uses: while read loop, IFS, cut/awk, continue, ping
# ============================================
server_pinger() {
    echo -e "${CYAN}=== Server Pinger ===${NC}"
    local servers_file="$BASE_DIR/data/servers.txt"

    if [ ! -f "$servers_file" ]; then
        echo -e "${RED}Error: servers.txt not found${NC}"
        return
    fi

    printf "%-15s %-16s %-12s %-10s %s\n" "HOSTNAME" "IP" "STATUS" "SERVICE" "PING"
    echo "---------------------------------------------------------------"

    while IFS=',' read -r hostname ip status service; do
        # Skip if server is stopped or in maintenance
        if [ "$status" = "stopped" ] || [ "$status" = "maintenance" ]; then
            printf "%-15s %-16s %-12s %-10s " "$hostname" "$ip" "$status" "$service"
            echo -e "${YELLOW}SKIPPED${NC}"
            continue
        fi

        # Ping the server
        printf "%-15s %-16s %-12s %-10s " "$hostname" "$ip" "$status" "$service"
        if ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAIL${NC}"
        fi
    done < "$servers_file"
}

# ============================================
# FUNCTION: config_searcher
# Uses: read, for loop, file test operators, grep -i
# ============================================
config_searcher() {
    echo -e "${CYAN}=== Config Searcher ===${NC}"
    read -p "Enter search key: " search_key

    if [ -z "$search_key" ]; then
        echo -e "${RED}Error: No search key provided${NC}"
        return
    fi

    local config_dir="$BASE_DIR/configs"
    local found=0

    for conf_file in "$config_dir"/*.conf; do
        # Check if file exists and is readable
        if [ ! -f "$conf_file" ]; then
            continue
        fi
        if [ ! -r "$conf_file" ]; then
            echo -e "${YELLOW}Warning: Cannot read $conf_file${NC}"
            continue
        fi

        # Search case-insensitively
        local results
        results=$(grep -in "$search_key" "$conf_file")
        if [ -n "$results" ]; then
            echo -e "${GREEN}Found in: $(basename "$conf_file")${NC}"
            echo "$results" | while read -r line; do
                echo "  $line"
            done
            found=$((found + 1))
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo -e "${YELLOW}No matches found for '$search_key'${NC}"
    fi
}

# ============================================
# FUNCTION: log_counter
# Uses: read, grep, wc, pipeline
# ============================================
log_counter() {
    echo -e "${CYAN}=== Log Counter ===${NC}"
    read -p "Enter log file path: " logfile
    read -p "Enter search pattern: " pattern

    if [ ! -f "$logfile" ]; then
        echo -e "${RED}Error: File not found${NC}"
        return
    fi

    local count
    count=$(grep -c "$pattern" "$logfile")
    echo -e "Pattern '${YELLOW}$pattern${NC}' found ${GREEN}$count${NC} times in $(basename "$logfile")"

    read -p "Show matching lines? (y/n): " show
    if [ "$show" = "y" ]; then
        grep --color=always "$pattern" "$logfile" | head -20
        local total
        total=$(grep -c "$pattern" "$logfile")
        if [ "$total" -gt 20 ]; then
            echo -e "${YELLOW}... showing first 20 of $total matches${NC}"
        fi
    fi
}

# ============================================
# FUNCTION: batch_renamer
# Uses: read, for loop, file tests, mv
# ============================================
batch_renamer() {
    echo -e "${CYAN}=== Batch Renamer ===${NC}"
    read -p "Enter directory path: " dir_path
    read -p "Add prefix (or press Enter to skip): " prefix
    read -p "Add suffix before extension (or press Enter to skip): " suffix

    if [ ! -d "$dir_path" ]; then
        echo -e "${RED}Error: Directory not found${NC}"
        return
    fi

    for file in "$dir_path"/*; do
        if [ ! -f "$file" ]; then
            continue
        fi
        local basename
        basename=$(basename "$file")
        local name="${basename%.*}"
        local ext="${basename##*.}"
        local new_name="${prefix}${name}${suffix}.${ext}"
        echo "Rename: $basename -> $new_name"
    done

    read -p "Proceed with rename? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        for file in "$dir_path"/*; do
            [ ! -f "$file" ] && continue
            local basename=$(basename "$file")
            local name="${basename%.*}"
            local ext="${basename##*.}"
            mv "$file" "$dir_path/${prefix}${name}${suffix}.${ext}"
        done
        echo -e "${GREEN}Rename complete!${NC}"
    else
        echo "Cancelled."
    fi
}

# ============================================
# FUNCTION: service_checker
# Uses: read, if/else, systemctl
# ============================================
service_checker() {
    echo -e "${CYAN}=== Service Checker ===${NC}"
    read -p "Enter service name (e.g., nginx, mysql): " svc_name

    if [ -z "$svc_name" ]; then
        echo -e "${RED}Error: No service name provided${NC}"
        return
    fi

    if systemctl is-active --quiet "$svc_name" 2>/dev/null; then
        echo -e "${GREEN}Service '$svc_name' is RUNNING${NC}"
    else
        echo -e "${RED}Service '$svc_name' is NOT RUNNING${NC}"
        read -p "Do you want to start it? (y/n): " start_it
        if [ "$start_it" = "y" ]; then
            echo "Run: sudo systemctl start $svc_name"
        fi
    fi
}

# ============================================
# FUNCTION: disk_alert
# Uses: read, while read loop, if/else, df
# ============================================
disk_alert() {
    echo -e "${CYAN}=== Disk Alert ===${NC}"
    read -p "Enter alert threshold % (default 80): " threshold
    threshold=${threshold:-80}

    echo ""
    printf "%-20s %-8s %-8s %-8s %-6s %s\n" "FILESYSTEM" "SIZE" "USED" "AVAIL" "USE%" "STATUS"
    echo "--------------------------------------------------------------"

    df -h | grep "^/dev/" | while read -r fs size used avail pct mount; do
        local usage=${pct%\%}
        printf "%-20s %-8s %-8s %-8s %-6s " "$fs" "$size" "$used" "$avail" "$pct"

        if [ "$usage" -ge 90 ]; then
            echo -e "${RED}CRITICAL${NC}"
        elif [ "$usage" -ge "$threshold" ]; then
            echo -e "${YELLOW}WARNING${NC}"
        else
            echo -e "${GREEN}OK${NC}"
        fi
    done
}

# ============================================
# MAIN MENU - while true + case statement
# ============================================
while true; do
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     SYSTEM ADMIN TOOLKIT v1.0        ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  1) File Inspector                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  2) Server Pinger                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  3) Config Searcher                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  4) Log Counter                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  5) Batch Renamer                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  6) Service Checker                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  7) Disk Alert                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  0) Exit                             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    read -p "Enter choice [0-7]: " choice

    case $choice in
        1) file_inspector ;;
        2) server_pinger ;;
        3) config_searcher ;;
        4) log_counter ;;
        5) batch_renamer ;;
        6) service_checker ;;
        7) disk_alert ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid option: '$choice'. Please enter 0-7.${NC}"
            continue
            ;;
    esac
done

