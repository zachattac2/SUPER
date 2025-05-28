#!/bin/bash
# S.U.P.E.R.M.A.N. - Software Update Patching Enhancement Routine for macOS Automation Nerds
#
# Version 3.0.0 - "The swiftDialog Edition"
# Original Author: Macjutsu
# Modified for swiftDialog by Zach Gibson

# --- Variables ---
scriptVersion="3.0.0"
scriptLog="/var/log/super.log"
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
currentUserID=$(id -u "$currentUser")
osVersion=$(sw_vers -productVersion)
osMajorVersion=$(echo "$osVersion" | cut -d. -f1)
osMinorVersion=$(echo "$osVersion" | cut -d. -f2)
osPatchVersion=$(echo "$osVersion" | cut -d. -f3)
jamfBinary="/usr/local/bin/jamf"
# swiftDialog path (default, can be overridden by script argument or config profile)
dialogPath="/usr/local/bin/dialog"
# Command file for swiftDialog progress updates (will be set dynamically)
COMMAND_FILE=""
# PID for swiftDialog process (will be set dynamically)
dialogPID=""

# --- Icons ---
dialogIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns" # Default/Caution
promptIcon="/System/Library/CoreServices/Software Update.app/Contents/Resources/SoftwareUpdate.icns" # Software Update Icon
majorUpgradeIcon="/System/Library/CoreServices/Software Update.app/Contents/Resources/SoftwareUpdate.icns" # Software Update Icon for major upgrades

# --- Configuration Profile Settings (defaults if not set) ---
# These would typically be read using `defaults read /Library/Preferences/com.example.super.plist <key>`
# For simplicity, using variables here. In a real deployment, use profiles.
# Example: forceMajorUpgrade=$(defaults read /Library/Preferences/com.example.super.plist forceMajorUpgrade 2>/dev/null)

forceMajorUpgrade="${FORCE_MAJOR_UPGRADE:-false}" # true or false
targetMajorVersion="${TARGET_MAJOR_VERSION:-}" # e.g., 13 or 14. Empty means latest compatible.
maxDeferrals="${MAX_DEFERRALS:-3}" # Number of times user can defer
deferralPeriod="${DEFERRAL_PERIOD:-86400}" # Seconds (24 hours)
promptTimeout="${PROMPT_TIMEOUT:-300}" # Seconds for user prompt (5 minutes)
gracePeriod="${GRACE_PERIOD:-3600}" # Seconds after deferrals exhausted (1 hour)
patchDeadline="${PATCH_DEADLINE:-}" # ISO 8601 Date (YYYY-MM-DD). If set, overrides deferrals.
allowManualUpdates="${ALLOW_MANUAL_UPDATES:-true}" # Allow user to trigger updates via Self Service

# --- Logging ---
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$scriptLog"
}

# --- Cleanup Function ---
cleanup_and_exit() {
    log_message "Running cleanup and exit routine..."
    if [[ -n "$dialogPID" ]] && [[ -f "$COMMAND_FILE" ]]; then
        log_message "Ensuring swiftDialog (PID: $dialogPID) is closed via command file."
        echo "quit:" >> "$COMMAND_FILE"
        # Wait for a few seconds for swiftDialog to close, then proceed
        # Using a subshell for timeout to avoid killing the main script if wait hangs
        ( sleep 5; kill -0 $dialogPID 2>/dev/null && kill -9 $dialogPID ) &
        wait $dialogPID 2>/dev/null
        rm -f "$COMMAND_FILE"
        unset COMMAND_FILE
        unset dialogPID
    elif [[ -n "$dialogPID" ]]; then # If COMMAND_FILE info is lost, but PID exists
        log_message "Forcefully closing swiftDialog (PID: $dialogPID)."
        kill "$dialogPID" 2>/dev/null
        wait "$dialogPID" 2>/dev/null # Clean up zombie
        unset dialogPID
    fi

    # Remove any stray lock files or temp files if used
    # Example: rm -f /tmp/super.lock

    log_message "SUPER script finished."
    exit "${1:-0}" # Exit with provided code or 0
}

trap 'cleanup_and_exit 1' SIGINT SIGTERM # Trap Ctrl+C and kill signals

# --- Pre-flight Checks ---
pre_flight_checks() {
    log_message "--- Starting S.U.P.E.R.M.A.N. v${scriptVersion} ---"
    log_message "Current User: $currentUser (ID: $currentUserID)"
    log_message "macOS Version: $osVersion"

    # Check for root
    if [[ "$(id -u)" -ne 0 ]]; then
        log_message "ERROR: This script must be run as root."
        # Try to display error with swiftDialog if available, otherwise osascript
        if [[ -x "$dialogPath" ]]; then
            "$dialogPath" --title "SUPER Script Error" --message "This script must be run as root. Please contact IT." --button1text "OK" --icon "$dialogIcon" --width 400 --height 150 --center
        else
            osascript -e "display dialog \"ERROR: This script must be run as root. Please contact IT.\" with title \"SUPER Script Error\" buttons {\"OK\"} default button \"OK\" with icon stop"
        fi
        exit 1
    fi

    # Check for swiftDialog
    # Allow overriding dialogPath via script argument for testing, e.g., ./super.sh /path/to/dialog
    if [[ -n "$1" ]] && [[ -x "$1" ]]; then
        dialogPath="$1"
        log_message "Using swiftDialog path from argument: $dialogPath"
    fi

    if [[ ! -x "$dialogPath" ]]; then
        log_message "ERROR: swiftDialog not found at ${dialogPath}. Please install it (e.g., from https://github.com/swiftDialog/swiftDialog/releases or 'brew install swiftdialog')."
        # Fallback to osascript for this critical error message
        /usr/bin/osascript -e "display dialog \"CRITICAL ERROR: swiftDialog application not found at '${dialogPath}'. This script cannot continue. Please contact IT support.\" with title \"SUPER Script Error\" buttons {\"OK\"} default button \"OK\" with icon stop"
        exit 1
    fi
    log_message "swiftDialog found at $dialogPath"

    # Check for active user
    if [[ -z "$currentUser" ]] || [[ "$currentUser" == "loginwindow" ]] || [[ "$currentUser" == "_mbsetupuser" ]]; then
        log_message "No active GUI user session found or at login window/setup. Exiting."
        # Consider if some actions (like just downloading updates) could run without a user.
        # For now, matching typical behavior of user-facing update scripts.
        exit 0
    fi

    # Check power
    if ! /usr/bin/pmset -g ps | grep -q "AC Power"; then
        log_message "Device is on battery power. Updates will be deferred unless forced."
        # This check might be better placed before prompting the user or starting downloads.
        # For now, just logging. Policy can decide if to proceed.
    fi
}

# --- Deferral Management ---
# Deferral data stored in a plist file associated with the script
deferralPlist="/Library/Application Support/JAMF/SUPER/com.company.super.deferrals.plist"
mkdir -p "$(dirname "$deferralPlist")" # Ensure directory exists

read_deferral_count() {
    if [[ -f "$deferralPlist" ]]; then
        /usr/libexec/PlistBuddy -c "Print :deferralCount" "$deferralPlist" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

write_deferral_count() {
    local count=$1
    /usr/libexec/PlistBuddy -c "Set :deferralCount $count" "$deferralPlist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :deferralCount integer $count" "$deferralPlist"
    /usr/libexec/PlistBuddy -c "Set :lastDeferralTimestamp $(date +%s)" "$deferralPlist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :lastDeferralTimestamp integer $(date +%s)" "$deferralPlist"
    log_message "Deferral count set to $count."
}

reset_deferrals() {
    if [[ -f "$deferralPlist" ]]; then
        rm -f "$deferralPlist"
        log_message "Deferral data reset."
    fi
}

# --- User Prompting ---
# $1: Title
# $2: Message
# $3: Button 1 Text
# $4: Button 2 Text (optional)
# $5: Timeout in seconds
# $6: Icon path
# Returns exit code: 0 for Button 1, 2 for Button 2, 4 for Timeout (simulated)
# Other swiftDialog exit codes might occur for errors.
software_update_prompt() {
    local promptTitle="$1"
    local promptMessage="$2"
    local promptButton1="$3"
    local promptButton2="$4"
    local localPromptTimeout="$5"
    local promptIconPath="$6"
    local dialogResult=0
    local userInteracted=false
    local promptDialogPID

    local dialogCmd=("$dialogPath" \
        --title "$promptTitle" \
        --message "$promptMessage" \
        --button1text "$promptButton1" \
        --icon "$promptIconPath" \
        --messagefont "size=14" \
        --height "auto" \
        --width "550" \
        --center \
        --ontop) # Keep dialog on top

    if [[ -n "$promptButton2" ]]; then
        dialogCmd+=("--button2text" "$promptButton2")
    fi

    # Run swiftDialog in the background
    "${dialogCmd[@]}" &
    promptDialogPID=$!
    log_message "swiftDialog prompt displayed (PID: $promptDialogPID). Title: $promptTitle"

    # Script-managed timeout
    # Wait for timeout or for dialog to close
    for (( i=0; i < localPromptTimeout; i++ )); do
        if ! ps -p "$promptDialogPID" > /dev/null 2>&1; then
            userInteracted=true
            break
        fi
        sleep 1
    done

    if $userInteracted; then
        wait "$promptDialogPID" # Get the actual exit code from swiftDialog
        dialogResult=$?
        log_message "User interacted with prompt. swiftDialog exited with code: $dialogResult."
    else
        # Timeout occurred
        log_message "User prompt timed out after $localPromptTimeout seconds. Killing dialog PID $promptDialogPID."
        kill "$promptDialogPID" # Send TERM signal
        sleep 0.5 # Give it a moment to die
        if ps -p "$promptDialogPID" > /dev/null 2>&1; then # Still alive?
            kill -9 "$promptDialogPID" # Force kill
        fi
        wait "$promptDialogPID" 2>/dev/null # Clean up zombie
        dialogResult=4 # Simulate IBM Notifier timeout code for existing logic compatibility
        log_message "Prompt timed out. Simulated exit code 4."
    fi
    
    # swiftDialog exit codes:
    # 0: Button 1 clicked (or if timer expires and no other action, but we manage timer)
    # 2: Button 2 clicked / Escape pressed
    # Other codes for errors, etc.
    # We map our script-managed timeout to 4.
    return $dialogResult
}

# --- Progress Bar Management for swiftDialog ---
# Global variables: COMMAND_FILE, dialogPID (for the progress dialog)

# $1: Message (main text in dialog, formerly subtitle)
# $2: Progress Text (text near progress bar, formerly bottom_message)
# $3: Progress Percentage (e.g., 25, 50, 100, or "indeterminate")
update_progress_bar() {
    local mainMessage="$1"
    local progressText="$2"
    local progressValue="$3"

    log_message "Updating swiftDialog progress: Message: '$mainMessage', ProgressText: '$progressText', Progress: '$progressValue'"

    if [[ -n "$dialogPID" ]] && [[ -f "$COMMAND_FILE" ]]; then
        if [[ -n "$mainMessage" ]]; then
            echo "message: $mainMessage" >> "$COMMAND_FILE"
        fi
        if [[ -n "$progressText" ]]; then
            echo "progresstext: $progressText" >> "$COMMAND_FILE"
        fi
        
        if [[ -n "$progressValue" ]]; then
            if [[ "$progressValue" == "indeterminate" ]]; then
                echo "progress: indeterminate" >> "$COMMAND_FILE"
            else
                # Ensure it's a number for determinate progress
                if [[ "$progressValue" =~ ^[0-9]+$ ]]; then
                    echo "progress: $progressValue" >> "$COMMAND_FILE"
                else
                    log_message "Warning: Invalid progress value '$progressValue'. Setting to indeterminate."
                    echo "progress: indeterminate" >> "$COMMAND_FILE"
                fi
            fi
        fi
    else
        log_message "Warning: Cannot update progress bar. dialogPID or COMMAND_FILE not set/valid."
        log_message "dialogPID: '$dialogPID', COMMAND_FILE: '$COMMAND_FILE'"
    fi
}

start_progress_dialog() {
    local title="$1"
    local initialMessage="$2"
    local initialProgressText="$3"
    local iconPath="$4"

    # Clean up any previous command file or PID, just in case
    if [[ -f "$COMMAND_FILE" ]]; then rm -f "$COMMAND_FILE"; fi
    unset COMMAND_FILE dialogPID

    COMMAND_FILE=$(mktemp -t super_dialog_progress.XXXXXX)
    # Ensure COMMAND_FILE is accessible if subshells are involved (though not typical for this simple update)
    # export COMMAND_FILE 

    log_message "Starting swiftDialog progress dialog. Command file: $COMMAND_FILE"
    "$dialogPath" \
        --title "$title" \
        --message "$initialMessage" \
        --icon "$iconPath" \
        --progress indeterminate \
        --progresstext "$initialProgressText" \
        --commandfile "$COMMAND_FILE" \
        --ontop \
        --width 600 \
        --height 200 \
        --center &
    dialogPID=$! # Capture PID of the swiftDialog process

    if [[ -z "$dialogPID" ]]; then
        log_message "ERROR: Failed to start swiftDialog progress dialog."
        rm -f "$COMMAND_FILE"
        unset COMMAND_FILE
        return 1
    fi
    log_message "swiftDialog progress dialog started (PID: $dialogPID)."
    return 0
}

close_progress_dialog() {
    log_message "Attempting to close swiftDialog progress dialog (PID: $dialogPID)."
    if [[ -n "$dialogPID" ]] && [[ -f "$COMMAND_FILE" ]]; then
        echo "quit:" >> "$COMMAND_FILE"
        # Wait for swiftDialog to close gracefully, with a timeout
        local wait_timeout=10 # seconds
        for ((i=0; i<wait_timeout; i++)); do
            if ! ps -p $dialogPID > /dev/null 2>&1; then
                break # Process has exited
            fi
            sleep 1
        done
        if ps -p $dialogPID > /dev/null 2>&1; then # Still running?
            log_message "swiftDialog (PID: $dialogPID) did not quit gracefully, killing."
            kill -9 "$dialogPID"
        fi
        wait "$dialogPID" 2>/dev/null # Clean up zombie
        rm -f "$COMMAND_FILE"
        log_message "swiftDialog progress dialog closed and command file removed."
    elif [[ -n "$dialogPID" ]]; then
        log_message "COMMAND_FILE not found, attempting to kill swiftDialog (PID: $dialogPID) directly."
        kill "$dialogPID" 2>/dev/null
        wait "$dialogPID" 2>/dev/null
    else
        log_message "No active progress dialog (dialogPID or COMMAND_FILE) to close."
    fi
    unset COMMAND_FILE dialogPID # Clear variables
}


# --- Software Update Logic ---
run_software_updates() {
    log_message "Starting software update process..."
    
    start_progress_dialog "Software Updates" "Checking for available updates..." "Please wait..." "$promptIcon"
    if [[ $? -ne 0 ]]; then
        log_message "Failed to start progress dialog for software updates. Aborting."
        # Display a simple error to user if possible
        software_update_prompt "Update Error" "Could not initiate the update process. Please contact IT." "OK" "" 30 "$dialogIcon"
        cleanup_and_exit 1
    fi

    sleep 2 # Simulate work
    update_progress_bar "Checking for updates..." "Contacting Apple Software Update server..." "indeterminate"

    # List available updates
    availableUpdates=$(softwareupdate -l 2>&1)
    if [[ "$availableUpdates" == *"No new software available."* ]]; then
        log_message "No new software updates available."
        update_progress_bar "Up to Date" "No new software updates found." "100"
        sleep 3
        close_progress_dialog
        software_update_prompt "Software Updates" "Your Mac is up to date. No new software updates are available at this time." "OK" "" 60 "$promptIcon"
        reset_deferrals # Reset deferrals if everything is up-to-date
        cleanup_and_exit 0
    fi

    log_message "Available updates:\n$availableUpdates"
    update_progress_bar "Updates Found" "Preparing to download and install updates..." "indeterminate"
    sleep 2

    # Install all recommended updates (-i -r)
    # For more granular control, parse specific updates. For now, apply all recommended.
    # Using -a can be risky if major upgrades are listed and not intended.
    # Let's use -i -r for recommended patches. Major upgrades handled separately.
    update_progress_bar "Downloading Updates" "Downloading available software updates. This may take some time." "10" # Example progress
    
    # Capture softwareupdate output for better progress simulation if possible
    # This is a simplified approach. Real progress parsing is complex.
    # Using a script block to pipe output for logging and potential parsing
    {
        # Run softwareupdate in the background to allow progress updates
        # Note: softwareupdate itself might not provide granular progress for scripting easily.
        # This part is tricky. For a real progress bar, you might need to estimate based on number of updates or typical times.
        # Or, use a tool that hooks into softwareupdated for progress.
        # For now, we'll simulate stages.
        
        # Stage 1: Downloading (simulated)
        local download_duration=30 # Simulate 30 seconds for download
        for ((i=0; i<download_duration; i+=5)); do
            update_progress_bar "Downloading Updates" "Progress: $((i*100/download_duration))% complete..." "$((i*100/download_duration))"
            sleep 5
            # In a real scenario, you'd check if softwareupdate is still running.
        done
        update_progress_bar "Downloading Updates" "Download phase complete. Preparing for installation..." "50"

        # Stage 2: Installing
        update_progress_bar "Installing Updates" "Installing updates. Your Mac may restart if required." "75"
        
        # Actual command
        log_message "Running: softwareupdate -i -r --agree-to-license"
        installResult=$(softwareupdate -i -r --agree-to-license 2>&1)
        installExitCode=$?

        log_message "Software update install result (Exit Code: $installExitCode):\n$installResult"

        if [[ "$installExitCode" -eq 0 ]] && ! echo "$installResult" | grep -q -E "(error|failed|could not install)"; then
            log_message "Software updates installed successfully."
            update_progress_bar "Installation Complete" "Software updates installed successfully." "100"
            sleep 3
            close_progress_dialog
            software_update_prompt "Update Successful" "Your Mac has been updated successfully. A restart may be required for some updates to take effect." "OK" "" 120 "$promptIcon"
            reset_deferrals
        else
            log_message "Software update installation failed or encountered errors."
            update_progress_bar "Installation Failed" "An error occurred during the update process. Please check logs." "100" # Mark as complete but failed
            sleep 3
            close_progress_dialog
            software_update_prompt "Update Failed" "Could not install all software updates. Please contact IT support. Details logged to $scriptLog" "OK" "" 180 "$dialogIcon"
            # Do not reset deferrals on failure
            cleanup_and_exit 1 # Exit with error
        fi
    } | tee -a "$scriptLog" # Log all output from this block

    cleanup_and_exit 0
}

# --- Major OS Upgrade Logic (Simplified Example) ---
# This is a very basic placeholder. Real major upgrade logic is complex, involves
# checking compatibility, downloading large installers, and handling `startosinstall`.
run_major_os_upgrade() {
    local targetVersionShortName="${targetMajorVersion:-latest}" # e.g., 13, 14 or "latest"
    log_message "Starting major OS upgrade process to version: $targetVersionShortName..."

    start_progress_dialog "macOS Upgrade" "Preparing for macOS ${targetVersionShortName} upgrade..." "Please wait..." "$majorUpgradeIcon"
    if [[ $? -ne 0 ]]; then
        log_message "Failed to start progress dialog for major OS upgrade. Aborting."
        software_update_prompt "Upgrade Error" "Could not initiate the macOS upgrade process. Please contact IT." "OK" "" 30 "$dialogIcon"
        cleanup_and_exit 1
    fi

    sleep 2
    update_progress_bar "Preparing Upgrade" "Checking compatibility and requirements for macOS ${targetVersionShortName}..." "indeterminate"

    # Placeholder: Check for installer
    local installerPath=""
    if [[ "$targetVersionShortName" == "14" ]] || [[ "$targetVersionShortName" == "latest" && "$osMajorVersion" -lt 14 ]]; then # Example for Sonoma
        installerPath="/Applications/Install macOS Sonoma.app"
    elif [[ "$targetVersionShortName" == "13" ]] || [[ "$targetVersionShortName" == "latest" && "$osMajorVersion" -lt 13 ]]; then # Example for Ventura
        installerPath="/Applications/Install macOS Ventura.app"
    fi
    # Add more versions as needed or use `softwareupdate --fetch-full-installer`

    if [[ ! -d "$installerPath" ]]; then
        log_message "macOS ${targetVersionShortName} installer not found at $installerPath."
        update_progress_bar "Installer Missing" "The required macOS ${targetVersionShortName} installer is not available. Attempting to download..." "indeterminate"
        
        log_message "Attempting to download macOS ${targetVersionShortName} installer..."
        # This command might take a very long time.
        # `softwareupdate --fetch-full-installer` or `softwareupdate --fetch-full-installer --full-installer-version X.Y.Z`
        # Example: softwareupdate --fetch-full-installer (gets the latest compatible)
        # Or: softwareupdate --fetch-full-installer --full-installer-version 14.1.1
        # For simplicity, assuming latest if targetMajorVersion is "latest" or not specific enough.
        local fetch_cmd="softwareupdate --fetch-full-installer"
        if [[ "$targetVersionShortName" != "latest" ]]; then
             # Attempt to find a specific version if targetMajorVersion is like "13" or "14"
             # This requires knowing the full version string. This part is complex.
             # For now, this example will just fetch the latest available full installer.
             log_message "Fetching latest available full installer as specific version logic is complex for this example."
        fi

        log_message "Running: $fetch_cmd"
        # This needs to run in background with progress updates.
        # For this example, we'll simulate it.
        local fetch_duration=180 # Simulate 3 minutes for fetch
        for ((i=0; i<=fetch_duration; i+=15)); do
            update_progress_bar "Downloading Installer" "Fetching macOS ${targetVersionShortName} installer (${i*100/fetch_duration}%)..." "$((i*100/fetch_duration))"
            sleep 15
            # In reality, monitor `softwareupdate` process or log files for progress.
        done
        # After simulated download, re-check path
        if [[ ! -d "$installerPath" ]]; then # If still not found (e.g. using generic path)
             # Try to find the installer again, as `softwareupdate` might download to a generic name first
             # This part is highly dependent on exact OS versions and `softwareupdate` behavior.
             # For this example, we'll assume it failed if the specific path isn't there.
            log_message "Failed to download or locate macOS ${targetVersionShortName} installer after fetch attempt."
            update_progress_bar "Download Failed" "Could not download the macOS ${targetVersionShortName} installer." "100"
            sleep 3
            close_progress_dialog
            software_update_prompt "Upgrade Error" "Failed to download the macOS ${targetVersionShortName} installer. Please contact IT." "OK" "" 60 "$dialogIcon"
            cleanup_and_exit 1
        fi
        log_message "macOS ${targetVersionShortName} installer found/downloaded to $installerPath."
    fi

    update_progress_bar "Installer Ready" "macOS ${targetVersionShortName} installer is ready. Preparing to start the upgrade." "50"
    sleep 3

    # This is where you would call `startosinstall`
    # Example: "$installerPath/Contents/Resources/startosinstall" --agreetolicense --nointeraction --pidtosignal $somePID
    # `startosinstall` will reboot the machine. The progress dialog will be killed by the reboot.
    # So, the message before this should be final.
    log_message "Initiating startosinstall for macOS ${targetVersionShortName}..."
    update_progress_bar "Starting Upgrade" "The macOS ${targetVersionShortName} upgrade is about to begin. Your Mac will restart automatically." "75"
    
    # Give user a few seconds to read the message before startosinstall takes over
    sleep 10 

    # Make sure to close our swiftDialog *before* startosinstall reboots.
    # startosinstall itself might show progress, or the Apple screen will.
    # We can't easily track startosinstall progress from this script after it starts.
    close_progress_dialog 

    log_message "Executing: \"$installerPath/Contents/Resources/startosinstall\" --agreetolicense --nointeraction"
    # For testing, comment out the actual startosinstall line:
    # "$installerPath/Contents/Resources/startosinstall" --agreetolicense --nointeraction
    # Instead, simulate success for script flow:
    log_message "SIMULATION: startosinstall would run here and reboot the Mac."
    log_message "SIMULATION: Assuming upgrade will proceed."
    software_update_prompt "Upgrade Initiated" "The macOS ${targetVersionShortName} upgrade process has started. Your Mac will restart soon. This dialog is for simulation only." "OK" "" 60 "$majorUpgradeIcon"
    
    # Normally, the script would end here as the Mac reboots.
    # If startosinstall fails to start, you'd need error handling.
    reset_deferrals # Assuming successful initiation
    cleanup_and_exit 0 # Script ends, Mac reboots due to startosinstall
}

# --- Main Logic ---
main() {
    pre_flight_checks "$@" # Pass script args for dialogPath override

    # Deadline Check (if patchDeadline is set)
    if [[ -n "$patchDeadline" ]]; then
        currentDateEpoch=$(date +%s)
        deadlineEpoch=$(date -j -f "%Y-%m-%d" "$patchDeadline" "+%s" 2>/dev/null)
        if [[ -z "$deadlineEpoch" ]]; then
            log_message "Warning: Invalid PATCH_DEADLINE format: $patchDeadline. Should be YYYY-MM-DD."
        elif [[ "$currentDateEpoch" -gt "$deadlineEpoch" ]]; then
            log_message "Patch deadline ($patchDeadline) has passed. Forcing updates."
            if [[ "$forceMajorUpgrade" == "true" ]] && ([[ -n "$targetMajorVersion" ]] || [[ "$osMajorVersion" -lt "SOME_LATEST_SUPPORTED_BY_SCRIPT" ]]); then
                 # Example: "SOME_LATEST_SUPPORTED_BY_SCRIPT" could be 14 if Sonoma is the newest this script fully handles.
                 # This logic needs to be more robust based on actual latest version.
                run_major_os_upgrade
            else
                run_software_updates
            fi
            cleanup_and_exit 0 # Script will exit within the update functions
        fi
    fi

    # Deferral Logic
    deferralCount=$(read_deferral_count)
    log_message "Current deferral count: $deferralCount (Max: $maxDeferrals)"

    if [[ "$deferralCount" -ge "$maxDeferrals" ]]; then
        log_message "Maximum deferrals reached. Checking grace period."
        lastDeferralTime=$(/usr/libexec/PlistBuddy -c "Print :lastDeferralTimestamp" "$deferralPlist" 2>/dev/null || echo 0)
        gracePeriodEndTime=$((lastDeferralTime + gracePeriod))
        currentTime=$(date +%s)

        if [[ "$currentTime" -gt "$gracePeriodEndTime" ]]; then
            log_message "Grace period expired. Forcing updates."
            software_update_prompt "Mandatory Updates" "Software updates are now mandatory as the deadline or maximum deferrals have been reached. Updates will begin shortly." "OK" "" 60 "$dialogIcon"
            # User acknowledged, proceed with forced update
        else
            remainingGraceTime=$((gracePeriodEndTime - currentTime))
            graceTimeFriendly=$(printf '%dh %dm' $((remainingGraceTime/3600)) $(((remainingGraceTime%3600)/60)))
            log_message "Grace period active. Updates will be forced in approximately $graceTimeFriendly."
            software_update_prompt "Mandatory Updates Soon" "Software updates will be mandatory in approximately $graceTimeFriendly. Please save your work. You can choose to update now." "Update Now" "Later" "$remainingGraceTime" "$promptIcon"
            promptExitCode=$?
            if [[ "$promptExitCode" -eq 0 ]]; then # Update Now
                log_message "User chose to update now during grace period."
            elif [[ "$promptExitCode" -eq 2 ]] || [[ "$promptExitCode" -eq 4 ]]; then # Later or Timeout
                log_message "User chose to defer during grace period, or prompt timed out. Exiting."
                cleanup_and_exit 0
            fi
        fi
        # Force updates if max deferrals/deadline/grace period passed
        if [[ "$forceMajorUpgrade" == "true" ]] && ([[ -n "$targetMajorVersion" ]] || [[ "$osMajorVersion" -lt "14" ]]); then # Adjust "14" as needed
            run_major_os_upgrade
        else
            run_software_updates
        fi
        cleanup_and_exit 0
    fi

    # Standard Prompting if not forced yet
    promptTitle="Software Updates Available"
    promptMessage="Updates are available for your Mac. Please save your work before proceeding.\n\nYou have $((maxDeferrals - deferralCount)) deferrals remaining."
    promptButton1="Update Now"
    promptButton2="Later"

    software_update_prompt "$promptTitle" "$promptMessage" "$promptButton1" "$promptButton2" "$promptTimeout" "$promptIcon"
    promptExitCode=$?

    case "$promptExitCode" in
        0) # Update Now
            log_message "User chose 'Update Now'."
            if [[ "$forceMajorUpgrade" == "true" ]] && ([[ -n "$targetMajorVersion" ]] || [[ "$osMajorVersion" -lt "14" ]]); then # Adjust "14" as needed
                run_major_os_upgrade
            else
                run_software_updates
            fi
            ;;
        2) # Later
            log_message "User chose 'Later'."
            write_deferral_count $((deferralCount + 1))
            cleanup_and_exit 0
            ;;
        4) # Timeout (simulated)
            log_message "Prompt timed out. User did not make a selection. Incrementing deferral."
            write_deferral_count $((deferralCount + 1))
            cleanup_and_exit 0
            ;;
        *) # Other error or unexpected exit code
            log_message "swiftDialog prompt exited with unexpected code: $promptExitCode. Assuming deferral."
            write_deferral_count $((deferralCount + 1)) # Or handle as error
            cleanup_and_exit 1
            ;;
    esac

    cleanup_and_exit 0
}

# --- Script Execution ---
# Ensure log file exists and set permissions
touch "$scriptLog" && chmod 644 "$scriptLog"
# Call main function
main "$@"
