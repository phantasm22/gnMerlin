#!/bin/sh

# Version 0.1 - Guest Network for Merlin Script Installer

# Variables
SELECTED_INTERFACES=""
CONFIGURED_INTERFACES=""
SCRIPT_DIR="/jffs/scripts"
SCRIPT_NAME="gnMerlin.sh"
SERVICE_START_SCRIPT="/jffs/scripts/services-start"

# Function to display gnMerlin ASCII art in orange with separation
display_ascii_art() {
    echo -e "\033[38;5;214m"  # Set color to orange
    echo "              __  __           _ _       "
    echo "             |  \/  |         | (_)      "
    echo "   __ _ _ __ | \  / | ___ _ __| |_ _ __  "
    echo "  / _\` | '_ \| |\/| |/ _ \ '__| | | '_ \ "
    echo " | (_| | | | | |  | |  __/ |  | | | | | |"
    echo "  \__, |_| |_|_|  |_|\___|_|  |_|_|_| |_|"
    echo "   __/ |                                 "
    echo "  |___/                                  "
    echo "========================================"
    echo -e "\033[0m"  # Reset color
    echo ""
}

# Function to check already configured interfaces
check_configured_interfaces() {
    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        CONFIGURED_INTERFACES=$(grep -E "wl[0-1]\.[1-4]" "$SCRIPT_DIR/$SCRIPT_NAME" | awk '{print $5}')
        if [ -n "$CONFIGURED_INTERFACES" ]; then
            echo "The following interfaces are already configured with guest network isolation:"
            echo "$CONFIGURED_INTERFACES"
        else
            echo "No interfaces are currently configured with guest network isolation."
        fi
    else
        echo "No previous guest network isolation script found."
    fi
}

# Function to dynamically get all wireless interfaces matching 'wl<digit>.<digit>'
get_available_interfaces() {
    # Extract interfaces matching "wl<digit>.<digit>" from the output of brctl show
    INTERFACES=$(brctl show | grep -o 'wl[0-9]\.[0-9]' | sort -u)
    
    if [ -z "$INTERFACES" ]; then
        echo "Error: No wireless interfaces (matching 'wl<digit>.<digit>') found. Exiting."
        exit 1
    fi
}

# Function to ask the user to select interfaces
select_interfaces() {
    echo "Available interfaces for guest network:"
    if [ -z "$INTERFACES" ]; then
        echo "No wireless interfaces found. Exiting."
        exit 0
    fi

    for interface in $INTERFACES; do
        echo "Do you want to apply guest network isolation on $interface? (y/n)"
        read answer
        if [ "$answer" = "y" ]; then
            SELECTED_INTERFACES="$SELECTED_INTERFACES $interface"
        fi
    done

    if [ -z "$SELECTED_INTERFACES" ]; then
        echo "No interfaces selected. Exiting."
        exit 0
    fi

    echo "Selected interfaces: $SELECTED_INTERFACES"
    echo "Is this correct? (y/n)"
    read confirm
    if [ "$confirm" != "y" ]; then
        echo "Exiting."
        exit 0
    fi
}

# Function to ask if user wants to backup, overwrite, or quit
handle_existing_script() {
    OUTPUT_SCRIPT="$SCRIPT_DIR/$SCRIPT_NAME"
    while true; do
        echo "Script $SCRIPT_NAME already exists."
        echo "Do you want to backup, overwrite, or quit? (b/o/q)"
        read choice
        case "$choice" in
            [bB])
                mv "$OUTPUT_SCRIPT" "$OUTPUT_SCRIPT.bak"
                echo "Backup created: $OUTPUT_SCRIPT.bak"
                break
                ;;
            [oO])
                echo "Overwriting existing script."
                break
                ;;
            [qQ])
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please choose 'b' for backup, 'o' for overwrite, or 'q' for quit."
                ;;
        esac
    done
}

# Function to extract MAC address of the default gateway
get_mac_address() {
    IPADDRESS=$( /usr/sbin/ip route | awk '/^default/ {print $3}' )
    if [ -n "$IPADDRESS" ]; then
        echo "Default Gateway IP: $IPADDRESS"
        MACADDRESS=$( /sbin/arp | grep "($IPADDRESS)" | awk '{print $4}' )
        MAC_COUNT=$( /sbin/arp | grep "($IPADDRESS)" | wc -l )

        if [ "$MAC_COUNT" -ne 1 ]; then
            echo "Error: Multiple or no MAC addresses found for $IPADDRESS. Exiting."
            exit 1
        elif [ -n "$MACADDRESS" ]; then
            echo "MAC Address: $MACADDRESS"
        else
            echo "Error: MAC Address not found. Exiting."
            exit 1
        fi
    else
        echo "Error: Default Gateway not found. Exiting."
        exit 1
    fi
}

# Function to write the script to /jffs/scripts
write_script() {
    OUTPUT_SCRIPT="$SCRIPT_DIR/$SCRIPT_NAME"
    cat <<EOL >"$OUTPUT_SCRIPT"
#!/bin/sh
# Version 0.1 - Guest Network for Merlin

# Extract the default gateway
IPADDRESS=\`/usr/sbin/ip route | awk '/^default/ {print \$3}'\`

if [ -n "\$IPADDRESS" ]; then
    echo "Default Gateway IP: \$IPADDRESS"
    MACADDRESS=\`/sbin/arp | grep "(\$IPADDRESS)" | awk '{print \$4}'\`
    MAC_COUNT=\`/sbin/arp | grep "(\$IPADDRESS)" | wc -l\`

    if [ "\$MAC_COUNT" -ne 1 ]; then
        echo "Error: Multiple or no MAC addresses found for \$IPADDRESS. Exiting."
        exit 1
    elif [ -n "\$MACADDRESS" ]; then
        echo "MAC Address: \$MACADDRESS"
    else
        echo "MAC Address not found. Exiting."
        exit 1
    fi
else
    echo "Default Gateway not found. Exiting."
    exit 1
fi

# Guest Network Isolation commands using the extracted MAC address
EOL

    for interface in $SELECTED_INTERFACES; do
        echo "Adding commands for interface: $interface"
        echo "/usr/sbin/ebtables -I FORWARD -i $interface -j DROP" >>"$OUTPUT_SCRIPT"
        echo "/usr/sbin/ebtables -I FORWARD -o $interface -j DROP" >>"$OUTPUT_SCRIPT"
    done

    cat <<EOL >>"$OUTPUT_SCRIPT"
/usr/sbin/ebtables -I FORWARD -d Broadcast -j ACCEPT
/usr/sbin/ebtables -I FORWARD -d "\$MACADDRESS" -j ACCEPT
/usr/sbin/ebtables -I FORWARD -s "\$MACADDRESS" -j ACCEPT
echo "Network isolation rules applied successfully."
EOL

    # Make the script executable
    chmod +x "$OUTPUT_SCRIPT"
    if [ $? -eq 0 ]; then
        echo "Script written successfully and made executable."
    else
        echo "Error: Failed to make the script executable."
        exit 1
    fi
}

# Function to add the script to /jffs/scripts/services-start
add_to_services_start() {
    if ! grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        echo "Adding script to $SERVICE_START_SCRIPT"
        echo "if [ -f \"$SCRIPT_DIR/$SCRIPT_NAME\" ]; then" >>"$SERVICE_START_SCRIPT"
        echo "    sh \"$SCRIPT_DIR/$SCRIPT_NAME\"" >>"$SERVICE_START_SCRIPT"
        echo "fi #Added by gnMerlin" >>"$SERVICE_START_SCRIPT"
    else
        echo "Script already exists in $SERVICE_START_SCRIPT"
   
