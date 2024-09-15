#!/bin/sh

# Version of the script
SCRIPT_VERSION="0.1.0"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/phantasm22/gnMerlin/main/version.txt"

# Variables
SELECTED_INTERFACES=""
CONFIGURED_INTERFACES=""
SCRIPT_DIR="/jffs/scripts"
SCRIPT_NAME="gnMerlin.sh"
SERVICE_START_SCRIPT="/jffs/scripts/services-start"

# Function to display gnMerlin ASCII art with dynamic version
display_ascii_art() {
    echo -e "\033[38;5;214m"  # Set color to orange
    echo "                 __  __           _ _       "
    echo "                |  \/  |         | (_)      "
    echo "      __ _ _ __ | \  / | ___ _ __| |_ _ __  "
    echo "     / _\` | '_ \| |\/| |/ _ \ '__| | | '_ \ "
    echo "    | (_| | | | | |  | |  __/ |  | | | | | |"
    echo "     \__, |_| |_|_|  |_|\___|_|  |_|_|_| |_|"
    echo -e "      __/ |"
    echo -e "     |___/               \033[32mv$SCRIPT_VERSION\033[0m"  # Version number in dark green
    echo -e "\033[38;5;214m================= By Phantasm22 =================\033[0m"
    echo -e "\033[0m"  # Reset color
    echo ""
}

# Function to check already configured interfaces
check_configured_interfaces() {
    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        CONFIGURED_INTERFACES=$(grep -Eo "wl[0-1]\.[1-4]" "$SCRIPT_DIR/$SCRIPT_NAME" | sort -u | paste -sd, -)
        if [ -n "$CONFIGURED_INTERFACES" ]; then
            echo -e "gnMerlin status: \033[34mInstalled: $CONFIGURED_INTERFACES\033[0m"
        else
            echo -e "gnMerlin status: \033[34mInstalled\033[0m"
        fi
    else
        echo -e "gnMerlin status: \033[31mUninstalled\033[0m"
    fi
}

# Function to dynamically get all wireless interfaces matching 'wl<digit>.<digit>'
get_available_interfaces() {
    INTERFACES=$(brctl show | grep -o 'wl[0-9]\.[0-9]' | sort -u)
    
    if [ -z "$INTERFACES" ]; then
        echo "Error: No wireless interfaces (matching 'wl<digit>.<digit>') found. Exiting."
        exit 1
    fi
}

# Function to ask the user to select interfaces
select_interfaces() {
    echo "Available interfaces for guest network:"
    echo "$INTERFACES"
    echo ""

    for interface in $INTERFACES; do
        echo -n "Do you want to apply guest network isolation on $interface? (y/n): "
        read answer
        if [ "$answer" = "y" ]; then
            SELECTED_INTERFACES="$SELECTED_INTERFACES $interface"
        fi
    done

    if [ -z "$SELECTED_INTERFACES" ]; then
        echo "No interfaces selected. Returning to the main menu."
        return
    fi

    echo "Selected interfaces: $SELECTED_INTERFACES"
    echo -n "Is this correct? (y/n): "
    read confirm
    if [ "$confirm" != "y" ]; then
        echo "Returning to the main menu."
        return
    fi
}

# Function to write the guest network script and make it executable
write_script() {
    cat > "$SCRIPT_DIR/$SCRIPT_NAME" <<EOF
#!/bin/sh
# gnMerlin Guest Network Isolation Script

# Guest Network Isolation for selected interfaces
EOF

    for interface in $SELECTED_INTERFACES; do
        cat >> "$SCRIPT_DIR/$SCRIPT_NAME" <<EOF
/usr/sbin/ebtables -I FORWARD -i $interface -j DROP
/usr/sbin/ebtables -I FORWARD -o $interface -j DROP
/usr/sbin/ebtables -I FORWARD -d Broadcast -j ACCEPT
/usr/sbin/ebtables -I FORWARD -d \$MACADDRESS -j ACCEPT
/usr/sbin/ebtables -I FORWARD -s \$MACADDRESS -j ACCEPT
EOF
    done

    chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
    echo ""
    echo "Guest network script written and made executable."
}

# Function to add the script to /jffs/scripts/services-start
add_to_services_start() {
    if ! grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        echo "$SCRIPT_DIR/$SCRIPT_NAME # Added by gnMerlin" >> "$SERVICE_START_SCRIPT"
        echo "Added gnMerlin script to $SERVICE_START_SCRIPT."
    else
        echo "gnMerlin script already added to $SERVICE_START_SCRIPT."
    fi
}

# Function to handle existing script removal
uninstall_guest_network() {
    if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ] && ! grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        echo "gnMerlin is not currently installed."
        return
    fi
    
    echo -n "Are you sure you want to uninstall gnMerlin? (y/n): "
    read confirm
    if [ "$confirm" != "y" ]; then
        echo "Uninstall cancelled."
        return
    fi

    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        rm "$SCRIPT_DIR/$SCRIPT_NAME"
        if [ $? -eq 0 ]; then
            echo "Removed $SCRIPT_NAME."
        else
            echo "Error removing $SCRIPT_NAME."
            echo ""
            echo "Press enter to return to the menu"
            read
            return
        fi
    fi

    if grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        sed -i "/$SCRIPT_NAME/d" "$SERVICE_START_SCRIPT"
        if [ $? -eq 0 ]; then
            echo "Removed gnMerlin entry from $SERVICE_START_SCRIPT."
        else
            echo "Error removing gnMerlin entry from $SERVICE_START_SCRIPT."
            echo ""
            echo "Press enter to return to the menu"
            read
            return
        fi
    fi

    echo "gnMerlin has been uninstalled successfully."
    echo ""
    echo "Press enter to continue"
    read
}

# Function to update the script version
update_script() {
    REMOTE_VERSION=$(curl -s "$REMOTE_VERSION_URL")
    if [ $? -ne 0 ]; then
        echo "Error fetching remote version. Exiting."
        return
    fi

    if [ "$SCRIPT_VERSION" != "$REMOTE_VERSION" ]; then
        echo -e "New version \033[34mv$REMOTE_VERSION\033[0m available."
        echo -n "Would you like to update? (y/n): "
        read confirm
        if [ "$confirm" != "y" ]; then
            echo "Update cancelled."
            return
        fi

        # Download the new script and replace the current version
        curl -o "$SCRIPT_DIR/$SCRIPT_NAME" "https://raw.githubusercontent.com/phantasm22/gnMerlin/main/gnMerlin.sh"
        if [ $? -eq 0 ]; then
            echo "Update successful. Restarting the script."
            chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
            exec "$SCRIPT_DIR/$SCRIPT_NAME"
        else
            echo "Error updating the script."
            echo ""
            echo "Press enter to return to the menu"
            read
            return
        fi
    else
        echo "You already have the latest version."
    fi

    echo ""
    echo "Press enter to continue"
    read
}

# Function to install or update guest network
install_update_guest_network() {
    get_available_interfaces
    select_interfaces
    if [ -n "$SELECTED_INTERFACES" ]; then
        write_script
        add_to_services_start
        echo "Installation/Update completed!"
        check_configured_interfaces
    fi

    echo ""
    echo "Press enter to continue"
    read
}

# Main menu function
main_menu() {
    while true; do
        clear
        display_ascii_art
        check_configured_interfaces
        echo ""
        echo -e "\033[34mi\033[0m - Install or Update Guest Network\033[0m"
        echo -e "\033[34mu\033[0m - Uninstall Guest Network\033[0m"
        echo -e "\033[34mv\033[0m - Check for Script Updates\033[0m"
        echo -e "\033[34me\033[0m - Exit\033[0m"
        echo ""
        echo -n "Enter your choice: "
        read choice

        case "$choice" in
            [Ii]) install_update_guest_network ;;
            [Uu]) uninstall_guest_network ;;
            [Vv]) update_script ;;
            [Ee]) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# Start the script with the main menu
