#!/bin/sh

# Version of the script
SCRIPT_VERSION="0.2.0"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/phantasm22/gnMerlin/main"

# Variables
SELECTED_INTERFACES=""
CONFIGURED_INTERFACES=""
SCRIPT_DIR="/jffs/scripts"
SCRIPT_NAME="gnMerlin.sh"
SCRIPT_VER="version.txt"
SERVICE_START_SCRIPT="/jffs/scripts/services-start"
CONFIGURATION_STATUS=""

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
    echo -e "     |___/                            \033[1;32mv$SCRIPT_VERSION\033[0m"  # Version number in dark green
    echo -e "\033[38;5;214m================= By Phantasm22 =================\033[0m"
    echo -e "\033[0m"  # Reset color
    echo ""
}

# Function to check already configured interfaces
check_configured_interfaces() {
    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        CONFIGURED_INTERFACES=$(grep -Eo "wl[0-1]\.[1-4]" "$SCRIPT_DIR/$SCRIPT_NAME" | sort -u | tr '\n' ',' | sed 's/,$//')
        if [ -n "$CONFIGURED_INTERFACES" ]; then
            CONFIGURATION_STATUS="\033[1;32m[Installed: \033[1;34m$CONFIGURED_INTERFACES\033[1;32m]\033[0m"
        else
            CONFIGURATION_STATUS="\033[1;32m[Installed]\033[0m"
        fi
    else
        CONFIGURATION_STATUS="\033[1;33m[Uninstalled]\033[0m"
    fi
}

# Function to dynamically get all wireless interfaces matching 'wl<digit>.<digit>'
get_available_interfaces() {
    INTERFACES=$(brctl show | grep -o 'wl[0-9]\.[0-9]' | sort -u)
    
    if [ -z "$INTERFACES" ]; then
        echo -e "\033[1;31mError: No wireless interfaces (matching 'wl<digit>.<digit>') found. Exiting.\033[0m"
        return 1
    fi
}

# Function to ask the user to select interfaces
select_interfaces() {
    echo -e "\033[1;32mAvailable interfaces for guest network:\033[0m"
    echo "$INTERFACES"
    echo ""
    SELECTED_INTERFACES=""

    for interface in $INTERFACES; do
        echo -ne "\033[1;32mDo you want to apply guest network isolation on \033[1;34m$interface\033[1;32m? (y/n): \033[0m"
        read answer
        if [ "$answer" = "y" ]; then
            SELECTED_INTERFACES="$SELECTED_INTERFACES $interface"
        fi
    done

    if [ -z "$SELECTED_INTERFACES" ]; then
        echo -e "\033[1;33mNo interfaces selected. Returning to the main menu.\033[0m"
        return 1
    fi

    echo -e "\033[1;32mSelected interfaces: \033[1;34m$SELECTED_INTERFACES\033[0m"
    echo -ne "\033[1;32mIs this correct? (y/n): \033[0m"
    read confirm
    if [ "$confirm" != "y" ]; then
        echo -e "\033[1;33mReturning to the main menu.\033[0m"
        return "1"
    fi
}

# Function to write the guest network script and make it executable
write_script() {
    
    # Extract the default gateway from the output of /usr/sbin/ip route
    IPADDRESS=$(/usr/sbin/ip route | awk '/^default/ {print $3}')

    # Check if the IPADDRESS is not empty
    if [ -n "$IPADDRESS" ]; then
        # Extract the MAC address using arp and grep
        MACADDRESS=$(/sbin/arp | grep "($IPADDRESS)" | awk '{print $4}')
    
        # Check if the MACADDRESS is not empty
        if [ -z "$MACADDRESS" ]; then
            echo ""
            echo -e "\033[1;31mError: MAC Address not found.\033[0m"
            echo ""
            echo -e "\033[1;32mPress enter to return to the menu\033[0m"
            read
            return
        fi
    else
        echo ""
        echo -e "\033[1;31mError: Default Gateway not found.\033[0m"
        echo ""
        echo -e "\033[1;32mPress enter to return to the menu\033[0m"
        read
        return
    fi

    cat > "$SCRIPT_DIR/$SCRIPT_NAME" <<EOF
#!/bin/sh
# gnMerlin Guest Network Isolation Script

# Guest Network Isolation for selected interfaces
EOF

    for interface in $SELECTED_INTERFACES; do
        cat >> "$SCRIPT_DIR/$SCRIPT_NAME" <<EOF
/usr/sbin/ebtables -I FORWARD -i $interface -j DROP
/usr/sbin/ebtables -I FORWARD -o $interface -j DROP
EOF
    done
    cat >> "$SCRIPT_DIR/$SCRIPT_NAME" <<EOF
/usr/sbin/ebtables -I FORWARD -d Broadcast -j ACCEPT
/usr/sbin/ebtables -I FORWARD -d $MACADDRESS -j ACCEPT
/usr/sbin/ebtables -I FORWARD -s $MACADDRESS -j ACCEPT
EOF
    chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
    echo "gnMerlin script written and made executable."
}

# Function to add the script to /jffs/scripts/services-start
add_to_services_start() {
    if ! grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        echo "$SCRIPT_DIR/$SCRIPT_NAME & #Added by gnMerlin" >> "$SERVICE_START_SCRIPT"
        echo "Added gnMerlin script to $SERVICE_START_SCRIPT."
    else
        echo "gnMerlin script already added to $SERVICE_START_SCRIPT."
    fi
}

start_gnMerlin() {
    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        echo "Starting gnMerlin script..."
        nohup sh "$SCRIPT_DIR/$SCRIPT_NAME" >/dev/null 2>&1 &
        if [ $? -eq 0 ]; then
            echo "gnMerlin started successfully."
        else
            echo "Error: Failed to start gnMerlin."
            return
        fi
    else
        echo ""
        echo -e "\033[1;31mError: gnMerlin script not found at $SCRIPT_DIR/$SCRIPT_NAME.\033[0m"
        echo ""
        echo -e "\033[1;32mPress enter to return to the menu\033[0m"
        read
        return
    fi
}

# Function to list ebtables chains
list_ebtables_chains() {
    echo ""
    echo -e "\033[1;32mListing all ebtables rules:\033[0m"
    
    # Execute the ebtables command and capture its status
    if ! ebtables -L > /dev/null 2>&1; then
        echo -e "\033[1;31mError: Failed to list ebtables rules. Please check if ebtables is installed and try again.\033[0m"
    else
        # If successful, show the output of ebtables
        ebtables -L
    fi
    
    echo ""
    echo -e "\033[1;32mPress enter to return to the menu\033[0m"
    read
}

# Function to flush ebtables chains
flush_ebtables_chains() {
    echo ""
    echo -e "\033[1;33mWarning: This will flush all ebtables rules.\033[0m"
    echo -ne "\033[1;32mEnter \033[1;34mflush\033[1;32m to confirm: \033[0m"
    read confirmation

    # Check if the user entered the correct confirmation
    if [ "$confirmation" = "flush" ] || [ "$confirmation" = "Flush" ] || [ "$confirmation" = "FLUSH" ]; then
        echo -e "\033[1;31mFlushing all ebtables rules...\033[0m"
        
        # Execute the ebtables flush command and check its status
        if ! ebtables -F > /dev/null 2>&1; then
            echo -e "\033[1;31mError: Failed to flush ebtables rules. Please check if ebtables is installed and try again.\033[0m"
        else
            echo -e "\033[1;32mDone! All ebtables rules have been flushed.\033[0m"
        fi
    else
        # If the confirmation is incorrect, display a cancellation message
        echo -e "\033[1;33mFlush operation cancelled. Incorrect confirmation.\033[0m"
    fi

    echo ""
    echo -e "\033[1;32mPress enter to return to the menu\033[0m"
    read
}

#Function wrapper for deleting ebtables and rules from script
delete_ebtables_rules_wrapper() {
    echo ""
    echo -e "\033[1;33mWarning: This will delete all ebtables rules written by gnMerlin.\033[0m"
    echo -ne "\033[1;32mAre you sure you want to continue? (y/n): \033[0m"
    read confirm
    if [ "$confirm" != "y" ]; then
        echo -e "\033[1;32mCancelled.\033[0m"
        return
    fi
    delete_ebtables_rules
    echo ""
    echo -e "\033[1;32mPress enter to return to the menu\033[0m"
    read
}

# Function to delete ebtables rules from script
delete_ebtables_rules() {
    if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        echo ""
        echo -e "\033[1;31mError: gnMerlin not installed. Nothing to do.\033[0m"
        return 0
    fi
    echo ""
    echo -e "\033[1;32mReading ebtables rules from $SCRIPT_DIR/$SCRIPT_NAME...\033[0m"
    
    # Loop through each line in the script
    while IFS= read -r line; do
        # Check if the line contains an ebtables rule
        case "$line" in
            /usr/sbin/ebtables*)  # Match lines that start with /usr/sbin/ebtables
                # Replace "-I" with "-D" to delete the rule
                delete_rule=$(echo "$line" | sed 's/-I/-D/')
                echo "Deleting rule: $delete_rule"
                $delete_rule > /dev/null 2>&1
                ;;
        esac
    done < "$SCRIPT_DIR/$SCRIPT_NAME"
    
    echo -e "\033[1;32mCompleted deleting ebtables rules from $SCRIPT_DIR/$SCRIPT_NAME.\033[0m"
    return
}

# Function to handle existing script removal
uninstall_guest_network() {
    if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ] && ! grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        echo ""
        echo -e "\033[1;31mgnMerlin is not currently installed.\033[0m"
        echo ""
        echo -e "\033[1;32mPress enter to return to the menu\033[0m"
        read
        return
    fi
    
    echo -ne "\033[1;32mAre you sure you want to uninstall gnMerlin? (y/n): \033[0m"
    read confirm
    if [ "$confirm" != "y" ]; then
        echo -e "\033[1;32mUninstall cancelled.\033[0m"
        return
    fi

   # Attempt to remove the gnMerlin script
    script_removal_success=0
    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        delete_ebtables_rules
        rm "$SCRIPT_DIR/$SCRIPT_NAME"
        if [ $? -eq 0 ]; then
            echo "Removed $SCRIPT_NAME."
        else
            echo -e "\033[1;31mError removing $SCRIPT_NAME.\033[0m"
            script_removal_success=1
        fi
    fi

    # Attempt to remove the gnMerlin entry from service-start script
    service_entry_removal_success=0
    if grep -q "$SCRIPT_NAME" "$SERVICE_START_SCRIPT"; then
        sed -i "/$SCRIPT_NAME/d" "$SERVICE_START_SCRIPT"
        if [ $? -eq 0 ]; then
            echo "Removed gnMerlin entry from $SERVICE_START_SCRIPT."
        else
            echo -e "\033[1;31mError removing gnMerlin entry from $SERVICE_START_SCRIPT.\033[0m"
            service_entry_removal_success=1
        fi
    fi

    # Check if either removal failed and exit the function if so
    if [ $script_removal_success -eq 1 ] || [ $service_entry_removal_success -eq 1 ]; then
        echo ""
        echo -e "\033[1;32mPress enter to return to the menu\033[0m"
        read
        return
    fi
    
    echo ""
    echo -e "\033[1;32mgnMerlin has been uninstalled successfully.\033[0m"
    echo ""
    echo -e "\033[1;32mPress enter to continue\033[0m"
    read
}

# Function to check for a new version
check_for_update() {
    REMOTE_VERSION=$(curl -s "$REMOTE_VERSION_URL/$SCRIPT_VER")
    if [ $? -ne 0 ]; then
        UPDATE_STATUS="\033[1;31m[Update check failed]\033[0m"
        return 1  # Update check failed
    fi

    if [ "$SCRIPT_VERSION" != "$REMOTE_VERSION" ]; then
        UPDATE_STATUS="\033[1;32m[New version \033[1;34mv$REMOTE_VERSION\033[1;32m available]\033[0m"
        return 0  # New version available
    else
        UPDATE_STATUS="\033[1;32m[No update available]\033[0m"
        return 1  # No update needed
    fi
}

# Function to prompt for a forced update
prompt_for_forced_update() {
    echo ""
    echo -ne "\033[1;33mYou already have the latest version installed.\n   \033[1;32mWould you like to force an update? (y/n): \033[0m"
    read force_update_confirm
    if [ "$force_update_confirm" != "y" ]; then
        echo "Update cancelled."
        echo ""
        echo -e "\033[1;32mPress enter to return to the menu\033[0m"
        read
        return 1
    fi
    return 0
}

# Function to download and install the new script
install_update() {
    echo ""
    echo -e "\033[1;32mDownloading the latest version...\033[0m"
    curl -o "$PWD/$SCRIPT_NAME" "$REMOTE_VERSION_URL/$SCRIPT_NAME" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "\033[1;32mUpdate successful. Restarting the script.\033[0m"
        chmod +x "$PWD/$SCRIPT_NAME"
        sleep 2
        exec "$PWD/$SCRIPT_NAME"
    else
        echo -e "\033[1;31mError updating the script.\033[0m"
        echo ""
        echo -e "\033[1;32mPress enter to return to the menu\033[0m"
        read
        return 1
    fi
}

# Main function to handle the update process
update_script() {
    check_for_update
    if [ $? -eq 0 ]; then  # If a new version is available
        echo -e "\033[1;32mNew version \033[1;34mv$REMOTE_VERSION\033[1;32m available.\033[0m"
        echo -ne "\033[1;32mWould you like to update? (y/n): \033[0m"
        read confirm
        if [ "$confirm" != "y" ]; then
            echo "Update cancelled."
            return 1
        fi
        install_update
    else  # No new version, prompt for a forced update
        prompt_for_forced_update
        if [ $? -eq 0 ]; then
            install_update
        fi
    fi
}

# Function to install or update guest network
install_update_guest_network() {
    get_available_interfaces
    select_interfaces
    # Debugging line to check the return status of select_interfaces
    echo "Return status of select_interfaces: $?"
    if [ $? -ne 0 ]; then
        echo "about to run return command"
        return
    fi
    if [ -n "$SELECTED_INTERFACES" ]; then
        delete_ebtables_rules #clear out any old rules first
        write_script
        add_to_services_start
        start_gnMerlin
        echo -e "\033[1;32mInstallation/Update completed!\033[0m"
        check_configured_interfaces
    fi
    echo ""
    echo -e "\033[1;32mPress enter to continue\033[0m"
    read
}

# Main menu function
main_menu() {
    check_for_update
    while true; do
        clear
        display_ascii_art
        check_configured_interfaces
        echo -e ""
        echo -e "   1. Install or Update Guest Network Isolation"
        echo -e "      $CONFIGURATION_STATUS"
        echo ""
        echo -e "   2. List all ebtables rules in place"
        echo -e ""
        echo -e "   3. Delete all ebtables rules used by gnMerlin"
        echo -e ""
        echo -e "   4. Flush all ebtables rules in place"
        echo -e ""
        echo -e "   u. Update gnMerlin script version"
        echo -e "      $UPDATE_STATUS"
        echo -e ""
        echo -e "   z. Uninstall Guest Network Isolation\033[0m"
        echo -e ""
        echo -e "   e. Exit"
        echo -e ""
        echo -ne "Enter your choice: "
        read choice

        case "$choice" in
            [1]) install_update_guest_network ;;
            [2]) list_ebtables_chains ;;
            [3]) delete_ebtables_rules_wrapper ;;
            [4]) flush_ebtables_chains ;;
            [Uu]) update_script ;;
            [Zz]) uninstall_guest_network ;;
            [Ee]) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# Start the script with the main menu
main_menu


