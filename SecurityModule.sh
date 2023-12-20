#!/usr/bin/env bash

# Security Settings

# Function to check and create the lock directory
check_and_create_lock_dir() {
    LOCK_FILE="/etc/lock/lock.file"
    LOG_FILE="/var/log/lock_file.log"

    # Check and create the directory
    [ ! -d "$(dirname "${LOCK_FILE}")" ] && mkdir -p "$(dirname "${LOCK_FILE}")"
    
    # Check and create the log file
    [ ! -e "$LOG_FILE" ] && touch "$LOG_FILE"

    # Check permissions
    [ ! -w "$(dirname "${LOCK_FILE}")" ] || [ ! -x "$(dirname "${LOCK_FILE}")" ] && \
        echo "Directory does not have proper permissions (write and execute)." && exit 1
    [ ! -w "$LOG_FILE" ] || [ ! -a "$LOG_FILE" ] && \
        echo "Log file does not have proper permissions (write and append)." && exit 1
}

# Function for the main script logic
main_script_logic() {
    LOCK_FILE="/etc/lock/lock.file"
    PASSWORD_ENCRYPTED=$(curl -sS https://yourbucket.s3.sa-east-1.amazonaws.com/yourfile.txt)

    # Prompt for the password
    read -p "Enter the password: " password

    # Encrypt the password for comparison
    encrypted_password=$(echo -n "$password" | openssl dgst -sha256 -binary | base64)

    # Check if the password is valid
    [ "$encrypted_password" = "$PASSWORD_ENCRYPTED" ] || \
        { echo -e "$(date) $USER [FAILURE] Incorrect password attempt" >> $LOG_FILE; exit 1; }

    # Log success and create lock file
    echo -e "$(date) $USER [SUCCESS] Starting the script" >> $LOG_FILE
    [ -e "$LOCK_FILE" ] && { echo "The script is already running."; exit 1; }
    trap 'rm -f "$LOCK_FILE"' EXIT  # Remove lock file on exit
    trap 'rm -f "$LOCK_FILE"' 9     # Remove lock file on SIGKILL (9)
    touch "$LOCK_FILE"
}

# Function to execute the complete script
execute_lock() {
    check_and_create_lock_dir
    main_script_logic
}