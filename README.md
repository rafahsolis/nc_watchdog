# Nextcloud Watchdog

## Overview
The Nextcloud Watchdog script is designed to monitor the health and availability of a Nextcloud instance. It performs periodic checks and takes corrective actions, such as restarting the system, if issues are detected. Notifications about the status are sent via Telegram.

## Features
- Monitors the availability of a Nextcloud instance.
- Sends notifications to a specified Telegram chat.
- Logs status and actions taken.
- Implements cooldown periods to avoid frequent restarts.
- Configurable via an `.env` file.

## Repository
The source code for this project is hosted on GitHub:
[git@github.com:rafahsolis/nc_watchdog.git](git@github.com:rafahsolis/nc_watchdog.git)

## Installation

### Prerequisites
Ensure the following dependencies are installed on your system:
- `curl`
- `ss`

### Steps
1. Clone or copy the script files to your desired directory:
   ```bash
   git clone git@github.com:rafahsolis/nc_watchdog.git
   cd nc_watchdog
   ```
2. Navigate to the script directory:
   ```bash
   cd /path/to/nextcloud/watchdog
   ```
3. Create an `.env` file by copying the provided `.env_template`:
   ```bash
   cp .env_template .env
   ```
4. Edit the `.env` file to configure the script:
   - Set the `DOMAIN` to your Nextcloud instance domain.
   - Provide your Telegram bot token and chat ID.
   - Adjust other settings as needed (e.g., timeouts, file paths).
5. Make the script executable:
   ```bash
   chmod +x nc_watchdog.sh
   ```
6. (Optional) Set up a cron job to run the script periodically. For example, to run it every 5 minutes:
   ```bash
   */5 * * * * /path/to/nextcloud/watchdog/nc_watchdog.sh
   ```

## Configuration
The script uses an `.env` file for configuration. Below are the key settings:

- **Domain and Basic Settings**
  - `DOMAIN`: The domain of your Nextcloud instance.
  - `RETRIES`: Number of retries before taking action.
  - `SLEEP_BETWEEN`: Time (in seconds) between retries.
  - `COOLDOWN_SECS`: Cooldown period (in seconds) after a restart.

- **Telegram Notification Settings**
  - `TELEGRAM_BOT_TOKEN`: Token for your Telegram bot.
  - `TELEGRAM_CHAT_ID`: Chat ID to send notifications to.

- **Paths and File Names**
  - `WATCHDOG_DIR`: Directory where the script is located.
  - `ENV_FILE`: Name of the `.env` file.
  - `BLOCK_FILENAME`, `LOG_FILENAME`, `COOLDOWN_FILENAME`, `STATUS_FILENAME`: File names used by the script.

- **Network Settings**
  - `HTTPS_PORT`: Port to check for HTTPS availability.
  - `EXTERNAL_CONNECT_TIMEOUT`, `EXTERNAL_MAX_TIME`: Timeouts for external checks.
  - `LOCAL_CONNECT_TIMEOUT`, `LOCAL_MAX_TIME`: Timeouts for local checks.

- **System Dependencies**
  - `REQUIRED_DEPS`: Space-separated list of required system commands.

- **Reboot Commands**
  - `REBOOT_COMMANDS`: Commands to attempt for restarting the system.

## Logging
The script logs its actions and status to the file specified in the `LOG_FILENAME` variable (default: `nc_watchdog.log`).

## License
This script is provided as-is. Use at your own risk.
