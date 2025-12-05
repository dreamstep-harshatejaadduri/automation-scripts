# Copilot Instructions for automation-scripts

## Project Overview
This repository contains **production deployment automation scripts** for the OWMS2 API application. Scripts handle critical operations including Angular frontend builds, environment configuration, and PM2 process management.

## Core Architecture & Components

### Script Structure (`demo.sh`)
- **Purpose**: Automated deployment pipeline for OWMS2 API
- **Key Responsibilities**:
  - Root privilege validation (security requirement)
  - Centralized logging to `/var/log/script-logs/`
  - Directory navigation with validation (from `/app/owms2_api`)
  - Git synchronization
  - Angular production build with memory optimization (`--max_old_space_size=8048`)
  - URL replacement from localhost to production (`apcmms.ap.gov.in`)
  - Build versioning with timestamps
  - PM2 process management for application restart

## Developer Workflows

### Deployment Process
1. **Root Execution Required**: Scripts must run as root (checked via `USERID=$(id -u)`)
2. **Centralized Logging**: All operations logged to `$LOGS_FOLDER/$SCRIPT_NAME.log` using `tee -a`
3. **Error Handling**: `VALIDATE()` function terminates script on failure (exit code checking)
4. **Build Versioning**: Timestamps appended to old builds (`enlink_$TIME`) to preserve deployment history

### Testing Scripts Locally
- Must run from `/app/owms2_api` directory (primary working directory)
- Angular build requires significant memory allocation (`max_old_space_size=8048`)
- URL replacements use `find` + `sed` for bulk text substitution in built artifacts

## Key Patterns & Conventions

### Color-Coded Logging
```bash
R="\e[31m"  # Red (errors)
G="\e[32m"  # Green (success)
Y="\e[33m"  # Yellow (warnings/info)
N="\e[0m"   # Normal (reset)
```
Use these ANSI codes when adding logging statements for consistency.

### Validation Pattern
```bash
VALIDATE() {
    if [ "$1" -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE"
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE"
        exit 1
    fi
}
```
All critical operations (git, build, deployment) validate immediately after execution.

### Append Output Redirection
- Use `&>> "$LOG_FILE"` to redirect both stdout and stderr to logs without terminal output duplication
- Use `tee -a` for messages that should appear both in logs and terminal

## External Dependencies
- **Git**: Version control synchronization
- **Node.js**: Angular CLI builds (requires >= 12GB free memory)
- **PM2**: Application process manager for restart operations
- **sed/find**: Text processing for URL replacements in built artifacts

## Important Notes
- Scripts are **production-critical** — test changes thoroughly in staging
- PM2 manages multiple processes; `pm2 restart` restarts all configured apps
- URL replacement is hardcoded to production domain; use environment variables for flexibility
- Build artifacts archived with timestamps to prevent data loss
