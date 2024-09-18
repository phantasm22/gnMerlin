
# gnMerlin - Guest Network Isolation for ASUS Merlin

gnMerlin is a shell script designed to isolate guest wireless networks on routers running ASUS Merlin firmware. This script utilizes `ebtables` to block traffic between the main network and guest networks while allowing communication with the router.

## Features
- Isolates guest networks on selected wireless interfaces.
- Blocks forwarding of guest traffic, ensuring guest clients can only communicate with the router.
- Simple CLI interface to manage and configure isolation.
- Supports update checks and installation of the latest version.
- Handles custom network interface selection.
- Option to uninstall and remove all configured rules.

## Requirements
- ASUS Merlin firmware installed on your router.
- Access to `/jffs` partition for custom scripts.
- `ebtables` installed (can be checked via `ebtables -L`).

## Installation

1. **Download Script**  
   Download `gnMerlin.sh` file to a suitable location. Options:
   - `curl -o ./gnMerlin.sh https://raw.githubusercontent.com/phantasm22/gnMerlin/main/gnMerlin.sh`
   - `wget https://raw.githubusercontent.com/phantasm22/gnMerlin/main/gnMerlin.sh`

3. **Make Script Executable**  
   Run the following command to make the script executable:
   ```bash
   chmod +x ./gnMerlin.sh
   ```

4. **Run Script**  
   To run the script and configure guest network isolation:
   ```bash
   ./gnMerlin.sh
   ```

## Usage

Once the script is running, you will be presented with a menu offering several options:

1. **Install or Update Guest Network Isolation**  
   Configure or update network isolation for your guest interfaces. You can select from available wireless interfaces for isolation. Examples of interfaces:
   * wl0.1 = first guest network on 2.4GHz
   * wl0.2 = second guest network on 2.4GHz
   * wl1.1 = first guest network on 5GHz
   * wl1.1 = second guest network on 5GHz
   
3. **List All Ebtables Rules**  
   Display the current `ebtables` rules and chains.
   
4. **Delete Ebtables Rules for gnMerlin**  
   Remove the `ebtables` rules created by gnMerlin for network isolation.
   
5. **Flush All Ebtables Rules**  
   Flush all `ebtables` rules, including those unrelated to gnMerlin.
   
6. **Update gnMerlin Script**  
   Check for new versions of the script and update if available.
   
7. **Uninstall Guest Network Isolation**  
   Remove all gnMerlin-related configurations, including the script and any applied rules.

## Uninstall

To uninstall gnMerlin and remove all its rules:
1. Run the script and select the `Uninstall Guest Network Isolation` option from the main menu.
2. Alternatively, you can manually delete the script and any related entries from `/jffs/scripts/services-start`:
   ```
   rm /jffs/scripts/gnMerlin.sh
   sed -i '/gnMerlin.sh/d' /jffs/scripts/services-start
   ```

## Troubleshooting

- **No Wireless Interfaces Found**  
  Ensure that wireless interfaces on your router match the `wl<digit>.<digit>` format. The script will only recognize interfaces with this format.

- **Ebtables Not Installed**  
  If `ebtables` is not found, install it using your router's package manager, or ensure your firmware includes it.

- **MAC Address or Gateway Not Found**  
  The script relies on your router's default gateway and ARP table to configure forwarding exceptions. Ensure your router is properly configured and has an active network.

## Versioning

This project follows Semantic Versioning (SemVer). For the available versions, see the tags on this repository.

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

## Contact

For any issues or suggestions, feel free to open an issue on the [GitHub repository](https://github.com/phantasm22/gnMerlin) or [contact me directly](https://www.snbforums.com/conversations/add?to=vlord).
