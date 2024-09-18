# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.2.5

### Added
- Initial implementation of `install_update_guest_network` function.
- `get_available_interfaces` function to fetch available network interfaces.
- `select_interfaces` function to allow users to choose network interfaces for guest network isolation.
- `delete_ebtables_rules` function to remove old ebtables rules.
- Functionality to write new network rules into the guest network isolation script.
- Integration of guest network with services startup via `add_to_services_start` function.
- User confirmation prompt for interface selection in `select_interfaces` with `y/n` options.
- Exit functionality if no interfaces are selected or if confirmation is "n" in `select_interfaces`.
- Debugging outputs for interface selection and confirmation process.
- User prompt to continue after successful guest network installation/update.

### Changed
- Modified the logic in `install_update_guest_network` to exit if `select_interfaces` returns a `1` status.
- Refined user prompts and echo statements for better clarity and user interaction.
- Changed logic in `select_interfaces` to allow re-selection if the confirmation is negative (user presses "n").
- Updated ebtables rule deletion to handle errors during rule execution, preventing unwanted errors from being printed.

### Fixed
- Corrected condition checks in `install_update_guest_network` to properly handle return statuses from `select_interfaces`.
- Fixed bug in `select_interfaces` where selecting "n" at the confirmation prompt would not exit the installation process.
- Fixed issue where ebtables rules deletion was showing unexpected error messages by updating the `$delete_rule` execution logic.

### Removed
- Deprecated old logic handling in the guest network installation process.
