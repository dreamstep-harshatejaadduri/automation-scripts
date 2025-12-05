#!/bin/bash

TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/script-logs"
SCRIPT_NAME=$(basename "$0" | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"
echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

# --- Check Root Privileges ---
if [ "$USERID" -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a "$LOG_FILE"
    exit 1
else
    echo "You are running with root access" | tee -a "$LOG_FILE"
fi

# --- Validate Function ---
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# --- Navigate to directory ---
if [[ ! "$(basename "$PWD")" == "owms2_api" ]]; then
    cd /app/owms2_api || exit 1
    VALIDATE $? "Changed directory to owms2_api"
else
    echo -e "$Y You are already in owms2_api $N"
fi

# --- Git Pull ---
git pull &>> "$LOG_FILE"
VALIDATE $? "Git Pull"

# --- Build Angular ---
cd client/admin || exit 1
VALIDATE $? "Redirected to client/admin"

node --max_old_space_size=8048 ./node_modules/@angular/cli/bin/ng build --configuration production &>> "$LOG_FILE"
VALIDATE $? "Angular Build"

# --- Update API URLs ---
cd dist/build || exit 1
VALIDATE $? "Redirected to dist/build"

find ./ -type f -exec sed -i 's/http:\/\/localhost:4901/https:\/\/apcmms.ap.gov.in/g' {} + &>> "$LOG_FILE"
VALIDATE $? "URL Replacement"

cd ../

# --- Rename Build ---
mv enlink enlink_"$TIME"
VALIDATE $? "Renaming enlink"

mv build enlink
VALIDATE $? "Replacing old build"

# -- Restarting Server --
pm2 restart 
VALIDATE $? "Restart"

pm2 log

