import requests
import sys
from dotenv import load_dotenv

load_dotenv()

def send_email(recipient, username, temp_pass):
    api_key = os.getenv("MAILJET_ACCESS_KEY")
    api_secret = os.getenv("MAILJET_SECRET_KEY")
    url = "https://api.mailjet.com/v3.1/send"

    data = {
        "Messages": [
            {
                "From": {
                    "Email": "catherine.gyamfi@amalitechtraining.org",
                    "Name": "Amalitech"
                },
                "To": [
                    {
                        "Email": recipient,
                        "Name": username
                    }
                ],
                "Subject": "New User Account Created",
                "TextPart": f"User account created\n\nUsername: {username}\nTemporary Password: {temp_pass}\n\nPlease change your password on first login."
            }
        ]
    }

    response = requests.post(url, json=data, auth=(api_key, api_secret))

    if response.status_code == 200:
        print(f"Email sent to {recipient}")
    else:
        print(f"Failed to send email to {recipient}: {response.text}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python send_email_mailjet.py <recipient> <username> <temp_pass>")
        sys.exit(1)

    recipient = sys.argv[1]
    username = sys.argv[2]
    temp_pass = sys.argv[3]
    send_email(recipient, username, temp_pass)