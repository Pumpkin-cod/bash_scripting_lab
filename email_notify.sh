#!/bin/bash

# Email subject
MAIL_SUBJECT="New User Account Created"

# Function to send notification email
send_email() {
    local recipient="$1"
    local username="$2"
    local temp_pass="$3"

    # Call the Python script to send the email
    python3 send_email.py "$recipient" "$username" "$temp_pass"
    if [[ $? -eq 0 ]]; then
        echo "Email sent to $recipient"
    else
        echo "Failed to send email to $recipient"
        return 1
    fi

    
    # Validate email format
    if [[ ! "$recipient" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "ERROR: Invalid email format for $recipient"
        return 1
    fi

    # Create email body
    local message="User account created\n\nUsername: $username\nTemporary Password: $temp_pass\n\nPlease change your password on first login."

     # Send email using Mailjet's SMTP server
    sendmail -S smtp.mailjet.com:587 -au"your_mailjet_access_key" -ap"your_mailjet_secret_key" "$recipient" <<< "$message"

    if [[ $? -eq 0 ]]; then
        echo "Email sent to $recipient"
    else
        echo "Failed to send email to $recipient"
        return 1
    fi
}

# Function to check password complexity
check_password_complexity() {
    local password="$1"
    if [[ ${#password} -lt 8 || ! "$password" =~ [A-Z] || ! "$password" =~ [a-z] || ! "$password" =~ [0-9] || ! "$password" =~ [\@\#\$\%\^\&\*\(\)\_\+\!] ]]; then
        echo "ERROR: Password does not meet complexity requirements."
        echo "Password must be at least 8 characters long, contain uppercase, lowercase, a number, and a special character."
        return 1
    fi
}

# Main execution
if [[ "$#" -eq 1 ]]; then
    CSV_FILE="$1"
    
    if [[ ! -f "$CSV_FILE" ]]; then
        echo "ERROR: CSV file not found: $CSV_FILE"
        exit 1
    fi

    while IFS=',' read -r username fullname group email; do
        # Skip header or empty lines
        [[ "$username" == "username" || -z "$username" ]] && continue

        # Generate a temporary password
        temp_pass="ChangeMe123!"

        # Check password complexity
        check_password_complexity "$temp_pass" || continue

        # Simulate user creation (replace this with actual user creation commands)
        echo "Creating user: $username, Full Name: $fullname, Group: $group"

        # Send email notification
        send_email "$email" "$username" "$temp_pass" || echo "Failed to send email to $email"
    done < "$CSV_FILE"
else
    echo "Usage: $0 <csv_file>"
    exit 1
fi