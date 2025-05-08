#!/bin/bash

INPUT_FILE=${1:-users.txt}
LOG_FILE="iam_setup.log"
TEMP_PASS="ChangeMe123"
EMAIL_SCRIPT="./email_notify.sh"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <input.csv>"
    exit 1
fi

# Password complexity regex
PASSWORD_REGEX='^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*]).{8,}$'

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

validate_password_complexity() {
    if [[ ! "$TEMP_PASS" =~ $PASSWORD_REGEX ]]; then
        log_action "ERROR: Password does not meet complexity requirements"
        echo "Password requirements:"
        echo "- 8+ characters"
        echo "- 1 uppercase, 1 lowercase"
        echo "- 1 number, 1 special character"
        exit 1
    fi
}

# Validate email script exists
if [ ! -f "$EMAIL_SCRIPT" ]; then
    log_action "ERROR: Email script $EMAIL_SCRIPT not found"
    exit 1
fi

validate_password_complexity

while IFS=, read -r username fullname group email; do
    [[ "$username" == "username" ]] && continue

    if [[ -z "$username" || -z "$fullname" || -z "$group" || -z "$email" ]]; then
        log_action "ERROR: Missing fields for user $username. Skipping."
        continue
    fi

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

while IFS=, read -r username fullname group; do
    # Skip header
    [[ "$username" == "username" ]] && continue

    # Create group if it doesn't exist 
    if ! dscl . -read /Groups/"$group" &> /dev/null; then
        # Find next available GroupID
        gid=$(dscl . -list /Groups PrimaryGroupID | awk '{print $2}' | sort -ug | tail -1)
        gid=$((gid + 1))
        dscl . -create /Groups/"$group"
        dscl . -create /Groups/"$group" PrimaryGroupID "$gid"
        log_action "Group '$group' created with ID $gid."
    fi

    # Create user if it doesn't exist
    if ! id "$username" &> /dev/null; then
        # Create user with dscl
        uid=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
        uid=$((uid + 1))
        
        dscl . -create /Users/"$username"
        dscl . -create /Users/"$username" UserShell /bin/bash
        dscl . -create /Users/"$username" RealName "$fullname"
        dscl . -create /Users/"$username" UniqueID "$uid"
        dscl . -create /Users/"$username" PrimaryGroupID "$gid"
        dscl . -create /Users/"$username" NFSHomeDirectory "/Users/$username"
        
        # Create home directory and set permissions
        mkdir -p "/Users/$username"
        chown "$username" "/Users/$username"
        chmod 700 "/Users/$username"
        
        # Set temporary password
        dscl . -passwd /Users/"$username" "$TEMP_PASS"
        
        # Force password change on first login
        pwpolicy -u "$username" setpolicy "newPasswordRequired=1"
        
        log_action "User '$username' created, assigned to '$group', home set, password policy enforced."
    else
        log_action "User '$username' already exists. Skipping."
    fi
done < "$INPUT_FILE"
