# Nextcloud Watchdog

## Overview
Nextcloud Watchdog is a Bash script that monitors the health and HTTPS availability of your Nextcloud instance. If the service becomes unreachable (externally or locally), the script can automatically reboot the host and send notifications via Telegram. It also supports manual and cooldown blocks to prevent unwanted reboots.

## Features
- Monitors HTTPS availability from both external and local perspectives
- Sends Telegram notifications on failure and recovery
- Logs all actions and status changes
- Cooldown mechanism to avoid frequent reboots
- Manual block to prevent automatic reboots
- Easy configuration via `.env` file

## Repository
Source code: [https://github.com/rafahsolis/nc_watchdog](https://github.com/rafahsolis/nc_watchdog)

## Installation

### Prerequisites
- Linux system with Bash
- `curl` and `ss` installed
- Telegram bot and chat ID (for notifications)

### Steps
1. Clone the repository:
   ```bash
   git clone git@github.com:rafahsolis/nc_watchdog.git
   cd nc_watchdog
   ```
2. Copy and edit the environment file:
   ```bash
   cp .env_template .env
   # Edit .env to set DOMAIN, Telegram credentials, and other options
   ```
3. Make the script executable:
   ```bash
   chmod +x nc_watchdog.sh
   ```

## Usage
Run the script manually or set it up as a cron job:
```bash
./nc_watchdog.sh
```

### Example Cron Setup
To run every 5 minutes:
```
*/5 * * * * /path/to/nc_watchdog.sh
```

## Behavior
- The script checks HTTPS availability externally and locally.
- If either check fails, it logs the failure and, after retries, reboots the host (unless blocked or in cooldown).
- Telegram notifications are sent on failure and recovery.
- All actions are logged in `nc_watchdog.log`.
- Manual block: create a file named `block_restart.txt` in the script directory to prevent reboots.
- Cooldown: after a reboot, the script waits a configurable period before allowing another reboot.

## Troubleshooting
- Check `nc_watchdog.log` for details on failures and actions.
- Ensure your `.env` file is correctly configured.
- Make sure required dependencies (`curl`, `ss`) are installed and in your PATH.
- If Telegram notifications do not work, verify your bot token and chat ID.

## License
See the repository for license details.

## Author
[rafahsolis](https://github.com/rafahsolis)
