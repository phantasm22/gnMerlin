Here’s the updated README.md content with the “Download the script using wget” section formatted correctly in Markdown:

# gnMerlin

## Description
gnMerlin is a shell script designed for managing guest network isolation on Merlin firmware routers that don't leverage the native guest network isolation. For example, routers in AP mode do not have native guest network isolation. This script allows users to install, update, and uninstall guest network isolation features seamlessly.

## Features
- Install or update guest network settings.
- Check for script updates and download the latest version.
- Uninstall guest network settings easily.
- User-friendly command-line interface with status notifications.

## Prerequisites
- Merlin firmware router.
- `curl`, `wget`, and `ebtables` installed on the router.

## Installation

### Clone the repository
```
git clone https://github.com/phantasm22/gnMerlin.git
cd gnMerlin
```

### Download the script using wget

wget https://raw.githubusercontent.com/phantasm22/gnMerlin/main/gnMerlin.sh
chmod +x gnMerlin.sh

### Run the installer

./gnMerlin.sh

### Usage

Upon running the script, you will see a menu with the following options:

	•	Install or update the guest network settings.
	•	Uninstall the guest network settings.
	•	Check for updates to the script.
	•	Exit the script.

### Example Menu

```
                 __  __           _ _       
                |  \/  |         | (_)      
      __ _ _ __ | \  / | ___ _ __| |_ _ __  
     / _` | '_ \| |\/| |/ _ \ '__| | | '_ \ 
    | (_| | | | | |  | |  __/ |  | | | | | |
     \__, |_| |_|_|  |_|\___|_|  |_|_|_| |_|
      __/ |
     |___/                            v0.1.9
================= By Phantasm22 =================



   i. Install or Update Guest Network Isolation
      [Installed: wl0.1]

   u. Update gnMerlin script version
      [No update available]

   z. Uninstall Guest Network Isolation

   e. Exit

Enter your choice: 
```

### Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

### License

This project is licensed under the GNU License. See the LICENSE file for details.

### Acknowledgments

	•	Special thanks to the Merlin firmware community for their support and resources.

### Contact

For any inquiries, please reach out
