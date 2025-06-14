#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Copyright (c) 2023, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# This script was created by Kevin M. White for Jamf
#
# DESCRIPTION
#
# S.U.P.E.R.M.A.N. (or just 'super') is an open source script that provides administrators
# with a comprehensive solution to encourage and enforce macOS minor updates, macOS major
# upgrades, Jamf Pro Policies, or enforced system restarts.
#
# For more information, please visit: https://github.com/Macjutsu/super
#
# MODIFICATION FOR SWIFTDIALOG
#
# This version of the script has been modified to use 'swiftdialog' instead of IBM Notifier.
# - The 'validateDialog' function now checks for the 'dialog' binary.
# - The 'displayDialog' and 'displayNotification' functions have been rewritten to construct
#   and execute 'swiftdialog' commands.
# - Exit codes are mapped to ensure the script's logic remains consistent.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# S.U.P.E.R.M.A.N. Version
export superVersion="8.0.0"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# USER-DEFINED VARIABLES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Enter the full path to the Jamf Pro binary
jamfBinary="/usr/local/bin/jamf"

# Supported languages for dialog windows
supportedLanguages=( "en" "de" "es" "fi" "fr" "he" "ja" "nl" "pt" "sv" "zh-CN" "zh-TW" )

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# S.U.P.E.R.M.A.N. PRE-REQUISITES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Confirm S.U.P.E.R.M.A.N. script is running as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo "S.U.P.E.R.M.A.N. must be run as root.  Please use 'sudo'."
    exit 1
fi

# Set S.U.P.E.R.M.A.N.'s working directory
superDirectory="/Library/Application Support/JAMF/super"
if [[ ! -d "${superDirectory}" ]]; then
    /bin/mkdir -p "${superDirectory}"
fi

# Set log file path
logFile="${superDirectory}/super.log"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FUNCTIONS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Function to easily write to the log file
log() {
    echo "$(date +"%a %b %d %H:%M:%S") ${HOSTNAME} super[${superPID}]: ${1}" >> "${logFile}"
}

# Function to validate S.U.P.E.R.M.A.N. settings
validateSettings() {
    if [[ "${testMode}" != "true" ]]; then
        log "Test Mode is disabled"
    else
        log "Test Mode is enabled"
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SWIFTDIALOG MODIFICATION - START
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Function to validate and set the dialog application path
validateDialog() {
    log "Validating dialog agent"
    
    # We will use swiftDialog, typically located at /usr/local/bin/dialog
    dialogPath="/usr/local/bin/dialog"

    if [[ -x "${dialogPath}" ]]; then
        dialogVersion=$("${dialogPath}" --version)
        log "swiftDialog version ${dialogVersion} found at ${dialogPath}"
        dialogAgent="swiftDialog"
    else
        log "ERROR: swiftDialog not found at ${dialogPath}"
        log "Please install swiftDialog: https://github.com/swiftDialog/swiftDialog"
        exit 1
    fi
}

# Function to display a standard dialog window
displayDialog() {
    log "Displaying dialog"
    
    # Construct the swiftDialog command
    local dialogCMD=()
    dialogCMD+=("${dialogPath}")
    dialogCMD+=("--title" "${dialogTitle}")
    dialogCMD+=("--message" "${dialogMessage}")
    
    if [[ -n "${dialogIcon}" ]]; then
        dialogCMD+=("--icon" "${dialogIcon}")
    fi

    if [[ -n "${dialogButton1}" ]]; then
        dialogCMD+=("--button1text" "${dialogButton1}")
    fi
    
    if [[ -n "${dialogButton2}" ]]; then
        dialogCMD+=("--button2text" "${dialogButton2}")
    fi

    if [[ "${dialogTimeout}" -gt 0 ]]; then
        dialogCMD+=("--timer" "${dialogTimeout}")
    fi
    
    if [[ "${infobox}" == "true" ]]; then
        dialogCMD+=("--infobox")
    else
        dialogCMD+=("--height" "450") # Give standard dialogs some space
    fi
    
    # accessory_view in IBM Notifier is a web view. swiftDialog doesn't have a direct equivalent.
    # We can use markdown in the --message, or add an image with --image, or a button with an action.
    # For simplicity, we will log a warning if an accessory view is attempted.
    if [[ -n "${dialogAccessoryView}" ]]; then
        log "WARNING: 'accessory_view' is not directly supported by swiftDialog."
        log "Consider using markdown in the message or adding an info button with '--infobuttonaction'."
    fi

    # Execute the command
    log "swiftDialog command: ${dialogCMD[*]}"
    "${dialogCMD[@]}"
    dialogExitCode=$?
    log "swiftDialog exit code: ${dialogExitCode}"
}

# Function to display a notification
displayNotification() {
    log "Displaying notification"
    
    # Construct the swiftDialog notification command
    local notifyCMD=()
    notifyCMD+=("${dialogPath}")
    notifyCMD+=("--notification")
    notifyCMD+=("--title" "${dialogTitle}")
    notifyCMD+=("--message" "${dialogMessage}")
    
    if [[ -n "${dialogSubtitle}" ]]; then
        notifyCMD+=("--subtitle" "${dialogSubtitle}")
    fi

    if [[ -n "${dialogIcon}" ]]; then
        notifyCMD+=("--icon" "${dialogIcon}")
    fi
    
    # Execute the command
    log "swiftDialog command: ${notifyCMD[*]}"
    "${notifyCMD[@]}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# SWIFTDIALOG MODIFICATION - END
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#!/bin/bash
# S.U.P.E.R.M.A.N.
# Software Update/Upgrade Policy Enforcement (with) Recursive Messaging And Notification
# https://github.com/Macjutsu/super
# by Kevin M. White

# The next line disables specific ShellCheck codes (https://github.com/koalaman/shellcheck) for the entire script.
# shellcheck disable=SC2012,SC2024,SC2207

SUPER_VERSION="5.0.0"
readonly SUPER_VERSION
SUPER_DATE="2024/10/17"
readonly SUPER_DATE

# MARK: *** Documentation ***
################################################################################

# Show usage documentation.
show_usage() {
	echo "
  S.U.P.E.R.M.A.N.
  Software Update/Upgrade Policy Enforcement (with) Recursive
  Messaging And Notification
  
  Version ${SUPER_VERSION}
  ${SUPER_DATE}
  https://github.com/Macjutsu/super
  
  Usage:
  sudo ./super
  
  Installation Options:
  [--install-macos-major-upgrades]  [--install-macos-major-upgrades-off]
  [--install-macos-major-version-target=number]
  [--install-rapid-security-responses]  [--install-rapid-security-responses-off]
  [--install-non-system-updates-without-restarting]
  [--install-non-system-updates-without-restarting-off]
  [--install-jamf-policy-triggers=PolicyTrigger,PolicyTrigger,etc...]
  [--install-jamf-policy-triggers-without-restarting]
  [--install-jamf-policy-triggers-without-restarting-off]
  
  Workflow Options:
  [--workflow-install-now]  [--workflow-install-now-off]
  [--workflow-only-download]  [--workflow-only-download-off]
  [--workflow-restart-without-updates]  [--workflow-restart-without-updates-off]
  [--workflow-disable-update-check]  [--workflow-disable-update-check-off]
  [--workflow-disable-relaunch]  [--workflow-disable-relaunch-off]
  [--workflow-reset-super-after-completion]
  
  Deferral Timer Options:
  [--deferral-timer-default=minutes]
  [--deferral-timer-menu=minutes,minutes,etc...]
  [--deferral-timer-focus=minutes]  [--deferral-timer-error=minutes]
  [--deferral-timer-workflow-relaunch=minutes]  [--deferral-timer-reset-all]
  
  Scheduling Options:
  [--schedule-workflow-active=DAY:hh:mm-hh:mm,DAY:hh:mm-hh:mm,etc...]
  [--schedule-zero-date-release]  [--schedule-zero-date-release-off]
  [--schedule-zero-date-sofa-custom-url=URL]
  [--schedule-zero-date-manual=YYYY-MM-DD:hh:mm]
  [--scheduled-install-days=number]  [--scheduled-install-date=YYYY-MM-DD:hh:mm]
  [--scheduled-install-user-choice]  [--scheduled-install-user-choice-off]
  [--scheduled-install-reminder=minutes,minutes,etc...]
  [--scheduled-install-delete-all]
  
  Deadline COUNT Options:
  [--deadline-count-focus=number]  [--deadline-count-soft=number]
  [--deadline-count-hard=number]  [--deadline-count-restart-all]
  [--deadline-count-delete-all]
  
  Deadline DAYS Options:
  [--deadline-days-focus=number]  [--deadline-days-soft=number]
  [--deadline-days-hard=number]  [--deadline-days-restart-all]
  [--deadline-days-delete-all]
  
  Deadline DATE Options:
  [--deadline-date-focus=YYYY-MM-DD:hh:mm]
  [--deadline-date-soft=YYYY-MM-DD:hh:mm]
  [--deadline-date-hard=YYYY-MM-DD:hh:mm]  [--deadline-date-delete-all]
  
  Display Behavior Options:
  [--dialog-timeout-default=seconds]  [--dialog-timeout-user-auth=seconds]
  [--dialog-timeout-user-choice=seconds]
  [--dialog-timeout-user-schedule=seconds]
  [--dialog-timeout-soft-deadline=seconds]
  [--dialog-timeout-insufficient-storage=seconds]
  [--dialog-timeout-power-required=seconds]  [--dialog-timeout-delete-all]
  [--display-unmovable=ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR]
  [--display-hide-background=ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR]
  [--display-silently=ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR]
  [--display-hide-progress-bar=ALWAYS,DEADLINE,SCHEDULED,INSTALLNOW,ERROR]
  [--display-notifications-centered=ALWAYS,DEADLINE,SCHEDULED,INSTALLNOW,ERROR]
  
  Display Interface Options:
  [--display-icon-size=pixels]  [--display-icon-file=/local/path or URL]
  [--display-icon-light-file=/local/path or URL]
  [--display-icon-dark-file=/local/path or URL]
  [--display-accessory-type=TEXTBOX|HTMLBOX|HTML|IMAGE|VIDEO|VIDEOAUTO]
  [--display-accessory-default-file=/local/path or URL]
  [--display-accessory-macos-minor-update-file=/local/path or URL]
  [--display-accessory-macos-major-upgrade-file=/local/path or URL]
  [--display-accessory-non-system-updates-file=/local/path or URL]
  [--display-accessory-jamf-policy-triggers-file=/local/path or URL]
  [--display-accessory-restart-without-updates-file=/local/path or URL]
  [--display-help-button-string=plain text or URL]
  [--display-warning-button-string=plain text or URL]
  
  Apple Silicon Authentication Options:
  [--auth-ask-user-to-save-password]  [--auth-ask-user-to-save-password-off]
  [--auth-local-account=AccountName]  [--auth-local-password=Password]
  [--auth-service-add-via-admin-account=AccountName]
  [--auth-service-add-via-admin-password=Password]
  [--auth-service-account=AccountName]  [--auth-service-password=Password]
  [--auth-jamf-client=ClientID]  [--auth-jamf-secret=ClientSecret]
  [--auth-jamf-account=AccountName]  [--auth-jamf-password=Password]
  [--auth-jamf-custom-url=URL]  [--auth-delete-all]
  [--auth-credential-failover-to-user]  [--auth-credential-failover-to-user-off]
  [--auth-mdm-failover-to-user=ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR]
  
  Test Mode Options:
  [--test-mode]  [--test-mode-off]  [--test-mode-timeout=seconds]
  [--test-storage-update=gigabytes]  [--test-storage-upgrade=gigabytes]
  [--test-battery-level=percentage]
  
  Troubleshooting and Documentation Options:
  [--open-logs]  [--reset-super]  [--verbose-mode]  [--verbose-mode-off]
  [--usage]  [--help]
  
  ** Managed preferences override local options via domain: com.macjutsu.super
  
  <key>InstallMacOSMajorUpgrades</key> <true/> | <false/>
  <key>InstallMacOSMajorVersionTarget</key> <string>version</string>
  <key>InstallRapidSecurityResponses</key> <true/> | <false/>
  <key>InstallNonSystemUpdatesWithoutRestarting</key> <true/> | <false/>
  <key>InstallJamfPolicyTriggers</key>
  <string>PolicyTrigger,PolicyTrigger,etc...</string>
  <key>InstallJamfPolicyTriggersWithoutRestarting</key> <true/> | <false/>
  <key>WorkflowInstallNow</key> <true/> | <false/>
  <key>WorkflowOnlyDownload</key> <true/> | <false/>
  <key>WorkflowRestartWithoutUpdates</key> <true/> | <false/>
  <key>WorkflowDisableUpdateCheck</key> <true/> | <false/>
  <key>WorkflowDisableRelaunch</key> <true/> | <false/>
  <key>DeferralTimerDefault</key> <string>minutes</string>
  <key>DeferralTimerMenu</key> <string>minutes,minutes,etc...</string>
  <key>DeferralTimerFocus</key> <string>minutes</string>
  <key>DeferralTimerError</key> <string>minutes</string>
  <key>DeferralTimerWorkflowRelaunch</key> <string>minutes</string>
  <key>ScheduleWorkflowActive</key>
  <string>DAY:hh:mm-hh:mm,DAY:hh:mm-hh:mm,etc...</string>
  <key>ScheduleZeroDateRelease</key> <true/> | <false/>
  <key>ScheduleZeroDateSOFACustomURL</key> <string>URL</string>
  <key>ScheduleZeroDateManual</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>ScheduledInstallDays</key> <string>number</string>
  <key>ScheduledInstallDate</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>ScheduledInstallUserChoice</key> <true/> | <false/>
  <key>ScheduledInstallReminder</key> <string>minutes,minutes,etc...</string>
  <key>DeadlineCountFocus</key> <string>number</string>
  <key>DeadlineCountSoft</key> <string>number</string>
  <key>DeadlineCountHard</key> <string>number</string>
  <key>DeadlineDaysFocus</key> <string>number</string>
  <key>DeadlineDaysSoft</key> <string>number</string>
  <key>DeadlineDaysHard</key> <string>number</string>
  <key>DeadlineDateFocus</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>DeadlineDateSoft</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>DeadlineDateHard</key> <string>YYYY-MM-DD:hh:mm</string>
  <key>DialogTimeoutDefault</key> <string>seconds</string>
  <key>DialogTimeoutUserAuth</key> <string>seconds</string>
  <key>DialogTimeoutUserChoice</key> <string>seconds</string>
  <key>DialogTimeoutUserSchedule</key> <string>seconds</string>
  <key>DialogTimeoutSoftDeadline</key> <string>seconds</string>
  <key>DialogTimeoutInsufficientStorage</key> <string>seconds</string>
  <key>DialogTimeoutPowerRequired</key> <string>seconds</string>
  <key>DisplayUnmovable</key>
  <string>ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR</string>
  <key>DisplayHideBackground</key>
  <string>ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR</string>
  <key>DisplaySilently</key>
  <string>ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR</string>
  <key>DisplayHideProgressBar</key>
  <string>ALWAYS,DEADLINE,SCHEDULED,INSTALLNOW,ERROR</string>
  <key>DisplayNotificationsCentered</key>
  <string>ALWAYS,DEADLINE,SCHEDULED,INSTALLNOW,ERROR</string>
  <key>DisplayIconSize</key> <string>pixels</string>
  <key>DisplayIconFile</key> <string>path</string>
  <key>DisplayIconLightFile</key> <string>path</string>
  <key>DisplayIconDarkFile</key> <string>path</string>
  <key>DisplayAccessoryType</key>
  <string>TEXTBOX|HTMLBOX|HTML|IMAGE|VIDEO|VIDEOAUTO</string>
  <key>DisplayAccessoryDefaultFile</key> <string>path or URL</string>
  <key>DisplayAccessoryMacOSMinorUpdateFile</key> <string>path or URL</string>
  <key>DisplayAccessoryMacOSMajorUpgradeFile</key> <string>path or URL</string>
  <key>DisplayAccessoryNonSystemUpdatesFile</key> <string>path or URL</string>
  <key>DisplayAccessoryJamfPolicyTriggersFile</key> <string>path or URL</string>
  <key>DisplayAccessoryRestartWithoutUpdatesFile</key> <string>path or URL</string>
  <key>DisplayHelpButtonString</key> <string>plain text or URL</string>
  <key>DisplayWarningButtonString</key> <string>plain text or URL</string>
  <key>AuthAskUserToSavePassword</key> <true/> | <false/>
  <key>AuthJamfCustomURL</key> <string>URL</string>
  <key>AuthCredentialFailoverToUser</key> <true/> | <false/>
  <key>AuthMDMFailoverToUser</key>
  <string>ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR</string>
  <key>TestMode</key> <true/> | <false/>
  <key>TestModeTimeout</key> <string>seconds</string>
  <key>TestStorageUpdate</key> <string>gigabytes</string>
  <key>TestStorageUpgrade</key> <string>gigabytes</string>
  <key>TestBatteryLevel</key> <string>percentage</string>
  <key>VerboseMode</key> <true/> | <false/>
  
  ** For detailed documentation visit: https://github.com/Macjutsu/super/wiki
  ** Or use --help to automatically open the S.U.P.E.R.M.A.N. Wiki.
"
	
	# Error log any unrecognized options.
	if [[ -n "${unrecognized_options_array[*]}" ]]; then
		if [[ $(id -u) -eq 0 ]] && [[ -d "${SUPER_LOG_FOLDER}" ]]; then
			log_super "Parameter Error: Unrecognized Options: ${unrecognized_options_array[*]%%=*}"
			[[ "${parent_process_is_jamf}" == "TRUE" ]] && log_super "Warning: Note that each Jamf Pro Policy Parameter can only contain a single option."
			log_status "Inactive Error: Unrecognized Options: ${unrecognized_options_array[*]%%=*}"
		else # super is not running as root or not installed yet.
			log_echo "Parameter Error: Unrecognized Options: ${unrecognized_options_array[*]%%=*}"
			[[ "${parent_process_is_jamf}" == "TRUE" ]] && log_echo "Warning: Note that each Jamf Pro Policy Parameter can only contain a single option."
		fi
	fi
	log_echo "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - EXIT USAGE ****"
	exit 0
}

# If there is a real current user then open the S.U.P.E.R.M.A.N. Wiki, otherwise run the show_usage() function.
show_help() {
	check_current_user
	if [[ "${current_user_account_name}" != "FALSE" ]]; then
		log_echo "Status: Opening S.U.P.E.R.M.A.N. Wiki for user account: ${current_user_account_name}."
		sudo -u "${current_user_account_name}" open "https://github.com/Macjutsu/super/wiki" &
		log_echo "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - EXIT HELP ****"
	else # No current GUI user.
		log_echo "Warning: Unable to open S.U.P.E.R.M.A.N. Wiki because there is no GUI user."
		show_usage
	fi
	exit 0
}

# MARK: *** Parameters ***
################################################################################

# Set default parameters that are used throughout the script.
set_defaults() {
	# Path to the super working folder:
	SUPER_FOLDER="/Library/Management/super"
	readonly SUPER_FOLDER
	
	# Path to the super Symbolic link in default binary folder.
	SUPER_LINK="/usr/local/bin/super"
	readonly SUPER_LINK
	# IMPORTANT DETAIL: Changing this path provides no benefit as this is the default location for most non-system command line tools.
	
	# Path to the super PID file:
	SUPER_PID_FILE="/var/run/super.pid"
	readonly SUPER_PID_FILE
	# IMPORTANT DETAIL: Changing this path provides no benefit as this is the default location for PID files.
	
	# Label name for the super LaunchDaemon.
	SUPER_LAUNCH_DAEMON_LABEL="com.macjutsu.super" # No trailing ".plist"
	readonly SUPER_LAUNCH_DAEMON_LABEL
	
	# Path to the local property list file:
	SUPER_LOCAL_PLIST="${SUPER_FOLDER}/com.macjutsu.super" # No trailing ".plist"
	readonly SUPER_LOCAL_PLIST
	
	# Path to the managed property list file:
	SUPER_MANAGED_PLIST="/Library/Managed Preferences/com.macjutsu.super" # No trailing ".plist"
	readonly SUPER_MANAGED_PLIST
	# IMPORTANT DETAIL: While you can customize the identifier "com.macjutsu.super", you must keep the "/Library/Managed Preferences/" folder path intact.
	
	# Path to the super log folder:
	SUPER_LOG_FOLDER="${SUPER_FOLDER}/logs"
	readonly SUPER_LOG_FOLDER
	
	# Path to the super log archive folder:
	SUPER_LOG_ARCHIVE_FOLDER="${SUPER_FOLDER}/logs-archive"
	readonly SUPER_LOG_ARCHIVE_FOLDER
	
	# The maximum size (in KB) for any super log that triggers an archival of log files at startup:
	SUPER_LOG_ARCHIVE_SIZE=1000
	readonly SUPER_LOG_ARCHIVE_SIZE
	
	# Path to the log for the main super workflow:
	SUPER_LOG="${SUPER_LOG_FOLDER}/super.log"
	readonly SUPER_LOG
	
	# Path to the log for the current "mdmclient AvailableOSUpdates" command response:
	MDMCLIENT_LIST_LOG="${SUPER_LOG_FOLDER}/mdmclient-list.log"
	readonly MDMCLIENT_LIST_LOG
	
	# Path to the log for the current "mist list" command response:
	MACOS_INSTALLERS_LIST_LOG="${SUPER_LOG_FOLDER}/macos-installers-list.log"
	readonly MACOS_INSTALLERS_LIST_LOG
	
	# Path to the log for the current "softwareupdate --list" command response:
	MSU_LIST_LOG="${SUPER_LOG_FOLDER}/msu-list.log"
	readonly MSU_LIST_LOG
	
	# URL to the default SOFA macOS machine readable json feed:
	SOFA_MACOS_DEFAULT_URL="https://sofafeed.macadmins.io/v1/macos_data_feed.json"
	readonly SOFA_MACOS_DEFAULT_URL
	
	# Path to the local copy of the SOFA machine readable feed:
	SOFA_MACOS_JSON_CACHE="${SUPER_LOG_FOLDER}/sofa-macos-data-feed.json"
	readonly SOFA_MACOS_JSON_CACHE
	
	# Path to the local copy of the SOFA etag cache:
	SOFA_MACOS_JSON_ETAG_CACHE="${SUPER_LOG_FOLDER}/sofa-macos-data-feed-etag.txt"
	readonly SOFA_MACOS_JSON_ETAG_CACHE
	
	# Path to the log for all softwareupdate download/install workflows:
	MSU_WORKFLOW_LOG="${SUPER_LOG_FOLDER}/msu-workflow.log"
	readonly MSU_WORKFLOW_LOG
	
	# Path to the log for all macOS installer application download/install workflows:
	INSTALLER_WORKFLOW_LOG="${SUPER_LOG_FOLDER}/installer-workflow.log"
	readonly INSTALLER_WORKFLOW_LOG
	
	# Path to the log for filtered MDM client command progress:
	MDM_COMMAND_LOG="${SUPER_LOG_FOLDER}/mdm-command.log"
	readonly MDM_COMMAND_LOG
	
	# Path to the log for debug MDM client command progress:
	MDM_COMMAND_DEBUG_LOG="${SUPER_LOG_FOLDER}/mdm-command-debug.log"
	readonly MDM_COMMAND_DEBUG_LOG
	
	# Path to the log for filtered MDM update/upgrade workflow progress:
	MDM_WORKFLOW_LOG="${SUPER_LOG_FOLDER}/mdm-workflow.log"
	readonly MDM_WORKFLOW_LOG
	
	# Path to the log for debug MDM update/upgrade workflow progress:
	MDM_WORKFLOW_DEBUG_LOG="${SUPER_LOG_FOLDER}/mdm-workflow-debug.log"
	readonly MDM_WORKFLOW_DEBUG_LOG
	
	# Path to the jamf binary:
	JAMF_PRO_BINARY="/usr/local/bin/jamf"
	readonly JAMF_PRO_BINARY
	# IMPORTANT DETAIL: Changing this path provides no benefit as this is the default location for the jamf binary.
	
	# URL to the IBM Notifier.app download:
	IBM_NOTIFIER_DOWNLOAD_URL="https://github.com/IBM/mac-ibm-notifications/releases/download/v-3.2.1-b-127/IBM.Notifier.zip"
	readonly IBM_NOTIFIER_DOWNLOAD_URL
	
	# Target version for IBM Notifier.app:
	IBM_NOTIFIER_TARGET_VERSION="3.2.1"
	readonly IBM_NOTIFIER_TARGET_VERSION
	
	# Path to the local IBM Notifier.app:
	IBM_NOTIFIER_APP="${SUPER_FOLDER}/IBM Notifier.app"
	readonly IBM_NOTIFIER_APP
	# IMPORTANT DETAIL: super does not move the IBM Notifier.app to another custom location.
	# Changing this folder path to anything besides "${SUPER_FOLDER}/IBM Notifier.app" requires that you must also deploy the IBM Notifier.app to the custom location prior to using super.
	
	# Path to the local IBM Notifier.app binary:
	IBM_NOTIFIER_BINARY="${IBM_NOTIFIER_APP}/Contents/MacOS/IBM Notifier"
	readonly IBM_NOTIFIER_BINARY
	
	# URL to the mist-cli package installer:
	MIST_CLI_DOWNLOAD_URL="https://github.com/ninxsoft/mist-cli/releases/download/v2.1.1/mist-cli.2.1.1.pkg"
	readonly MIST_CLI_DOWNLOAD_URL
	
	# Target version for mist-cli:
	MIST_CLI_TARGET_VERSION="2.1.1"
	readonly MIST_CLI_TARGET_VERSION
	
	# Path to the local mist-cli binary:
	MIST_CLI_BINARY="/usr/local/bin/mist"
	readonly MIST_CLI_BINARY
	# IMPORTANT DETAIL: super does not move the mist-cli binary to another custom location.
	# Changing this folder path to anything besides "/usr/local/bin/mist" requires that you must also deploy the mist-cli binary to the custom location prior to using super.
	
	# Path to the local preference file that would contain any software update settings:
	MSU_LOCAL_PLIST="/Library/Preferences/com.apple.SoftwareUpdate" # No trailing ".plist"
	readonly MSU_LOCAL_PLIST
	# IMPORTANT DETAIL: Changing this path provides no benefit as this is the default location for the local software update settings property list file.
	
	# Path to the managed preference file that would contain any automatic software update settings:
	MSU_MANAGED_PLIST="/Library/Managed Preferences/com.apple.SoftwareUpdate" # No trailing ".plist"
	readonly MSU_MANAGED_PLIST
	# IMPORTANT DETAIL: Changing this path provides no benefit as this is the default location for the managed software update settings property list file.
	
	# Path to the managed preference file that would contain any software update deferral restrictions:
	APPLICATION_ACCESS_MANAGED_PLIST="/Library/Managed Preferences/com.apple.applicationaccess" # No trailing ".plist"
	readonly APPLICATION_ACCESS_MANAGED_PLIST
	# IMPORTANT DETAIL: Changing this path provides no benefit as this is the default location for the software update deferral restrictions property list file.
	
	# The default number of minutes to defer the super workflow (except for the relaunch workflow deferral timer).
	DEFERRAL_TIMER_DEFAULT_MINUTES=60
	readonly DEFERRAL_TIMER_DEFAULT_MINUTES
	
	# The default number of minutes to defer once the super workflow is complete (aka. automatically relaunch the super workflow).
	DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES=360
	readonly DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES
	
	# The default number of minutes to defer the super restart validation workflow if there is a workflow error.
	DEFERRAL_TIMER_RESTART_VALIDATION_ERROR_MINUTES=5
	readonly DEFERRAL_TIMER_RESTART_VALIDATION_ERROR_MINUTES
	
	# The the minimum number of minutes in the future a user can select a scheduled install.
	DIALOG_USER_SCHEDULE_MINIMUM_SELECTION_MINUTES=2
	readonly DIALOG_USER_SCHEDULE_MINIMUM_SELECTION_MINUTES
	
	# Default icon size for dialogs and notifications.
	DISPLAY_ICON_DEFAULT_SIZE=96
	readonly DISPLAY_ICON_DEFAULT_SIZE
	
	# Path to for the local cached light mode display icon (the file type must be set to .png):
	DISPLAY_ICON_LIGHT_FILE_CACHE="${SUPER_FOLDER}/icon-light.png"
	readonly DISPLAY_ICON_LIGHT_FILE_CACHE
	
	# Path to for the local cached dark mode display icon (the file type must be set to .png):
	DISPLAY_ICON_DARK_FILE_CACHE="${SUPER_FOLDER}/icon-dark.png"
	readonly DISPLAY_ICON_DARK_FILE_CACHE
	
	# The default icon in the if no ${display_icon_light_file_path} or ${display_icon_dark_file_path} is specified or found.
	DISPLAY_ICON_DEFAULT_FILE="/System/Library/PrivateFrameworks/SoftwareUpdate.framework/Versions/Current/Resources/SoftwareUpdate.icns"
	readonly DISPLAY_ICON_DEFAULT_FILE
	
	# Deadline date display format.
	DISPLAY_STRING_FORMAT_DATE="%a %b %d" # Formatting options can be found in the man page for the date command.
	readonly DISPLAY_STRING_FORMAT_DATE
	
	# Deadline date/time separator display string.
	DISPLAY_STRING_FORMAT_DATE_TIME_SEPARATOR=" "
	readonly DISPLAY_STRING_FORMAT_DATE_TIME_SEPARATOR
	
	# Deadline time display format.
	DISPLAY_STRING_FORMAT_TIME="%l:%M %p" # Formatting options can be found in the man page for the date command.
	readonly DISPLAY_STRING_FORMAT_TIME
	
	# The default minium storage space in gigabytes required for a macOS minor update.
	STORAGE_REQUIRED_UPDATE_DEFAULT_GB=15
	readonly STORAGE_REQUIRED_UPDATE_DEFAULT_GB
	
	# The default minium storage space in gigabytes required for a macOS major upgrade.
	STORAGE_REQUIRED_UPGRADE_DEFAULT_GB=25
	readonly STORAGE_REQUIRED_UPGRADE_DEFAULT_GB
	
	# The number of seconds between storage checks when displaying the insufficient storage notification via the dialog_insufficient_storage() function.
	STORAGE_REQUIRED_RECHECK_SECONDS=5
	readonly STORAGE_REQUIRED_RECHECK_SECONDS
	
	# The default battery level percentage required for a macOS software update/upgrade on Mac computers with Apple Silicon.
	POWER_REQUIRED_BATTERY_APPLE_SILICON_PERCENT=20
	readonly POWER_REQUIRED_BATTERY_APPLE_SILICON_PERCENT
	
	# The default battery level percentage required for a macOS software update/upgrade on Mac computers with Intel.
	POWER_REQUIRED_BATTERY_INTEL_PERCENT=50
	readonly POWER_REQUIRED_BATTERY_INTEL_PERCENT
	
	# The number of seconds between AC power checks when displaying the insufficient battery notification via the dialog_insufficient_storage() function.
	POWER_REQUIRED_RECHECK_SECONDS=1
	readonly POWER_REQUIRED_RECHECK_SECONDS
	
	# The number of seconds to timeout various workflow startup processes if no progress is reported.
	TIMEOUT_START_SECONDS=120
	readonly TIMEOUT_START_SECONDS
	
	# The number of seconds to timeout the macOS 11+ softwareupdate download/prepare workflow if no progress is reported.
	TIMEOUT_MSU_SYSTEM_SECONDS=1200
	readonly TIMEOUT_MSU_SYSTEM_SECONDS
	
	# The number of seconds to timeout the softwareupdate non-system update workflow if no progress is reported.
	TIMEOUT_non_system_msu_SECONDS=600
	readonly TIMEOUT_non_system_msu_SECONDS
	
	# The number of seconds to timeout the macOS installer download workflow if no progress is reported.
	TIMEOUT_INSTALLER_DOWNLOAD_SECONDS=300
	readonly TIMEOUT_INSTALLER_DOWNLOAD_SECONDS
	
	# The number of seconds to timeout the macOS installation workflow if no progress is reported.
	TIMEOUT_INSTALLER_WORKFLOW_SECONDS=600
	readonly TIMEOUT_INSTALLER_DOWNLOAD_SECONDS
	
	# The number of seconds to timeout MDM commands if no response is reported.
	TIMEOUT_MDM_COMMAND_SECONDS=300
	readonly TIMEOUT_MDM_COMMAND_SECONDS
	
	# The number of seconds to timeout the MDM download/prepare workflow if no progress is reported.
	TIMEOUT_MDM_WORKFLOW_SECONDS=600
	readonly TIMEOUT_MDM_WORKFLOW_SECONDS
	
	# The default amount of time in seconds to leave test notifications and dialogs open before moving on with the test mode workflow.
	TEST_MODE_DEFAULT_TIMEOUT=10
	readonly TEST_MODE_DEFAULT_TIMEOUT
	
	# Various regular expressions used for parameter validation.
	REGEX_MACOS_MAJOR_VERSION="^([1][1-9])$"
	readonly REGEX_MACOS_MAJOR_VERSION
	REGEX_ANY_WHOLE_NUMBER="^[0-9]+$"
	readonly REGEX_ANY_WHOLE_NUMBER
	REGEX_CSV_WHOLE_NUMBERS="^[0-9*,]+$"
	readonly REGEX_CSV_WHOLE_NUMBERS
	REGEX_HOURS_MINUTES="^(2[0-3]|[01][0-9]):[0-5][0-9]$"
	readonly REGEX_HOURS_MINUTES
	REGEX_DATE_HOURS_MINUTES="^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]):(2[0-3]|[01][0-9]):[0-5][0-9]$"
	readonly REGEX_DATE_HOURS_MINUTES
	REGEX_DATE_HOURS_MINUTES_SECONDS="^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]):(2[0-3]|[01][0-9]):[0-5][0-9]:[0-5][0-9]$"
	readonly REGEX_DATE_HOURS_MINUTES_SECONDS
	REGEX_DATE="^[0-9][0-9][0-9][0-9]-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$"
	readonly REGEX_DATE
	REGEX_WEEKDAY="^(MON|TUE|WED|THU|FRI|SAT|SUN)$"
	readonly REGEX_WEEKDAY
	REGEX_HOURS_MINUTES_RANGE="^(2[0-3]|[01][0-9]):[0-5][0-9]-(2[0-3]|[01][0-9]):[0-5][0-9]$"
	readonly REGEX_HOURS_MINUTES_RANGE
	REGEX_schedule_workflow_active_time_frame="^(MON|TUE|WED|THU|FRI|SAT|SUN):(2[0-3]|[01][0-9]):[0-5][0-9]-(2[0-3]|[01][0-9]):[0-5][0-9]$"
	readonly REGEX_schedule_workflow_active_time_frame
	REGEX_HTML_URL="^http:\/\/|^https:\/\/"
	readonly REGEX_HTML_URL
	REGEX_HTTPS="^https:\/\/.*"
	readonly REGEX_HTTPS
	REGEX_WORKFLOW_OPTIONS="^ALWAYS$|^DIALOG$|^DEADLINE$|^SCHEDULED$|^INSTALLNOW$|^ERROR$"
	readonly REGEX_WORKFLOW_OPTIONS
}

# Collect input options and set associated parameters.
get_options() {
	# If super is running via Jamf Pro Policy installation then the first 3 input parameters are skipped.
	if [[ "$1" == "/" ]] || [[ $(ps -p "${PPID}" | grep -c -e 'bin/jamf' -e 'jamf/bin' -e '\sjamf\s') -gt 0 ]]; then
		shift 3
		parent_process_is_jamf="TRUE"
	fi
	
	# get_options debug mode.
	# log_super "Debug Mode: Function ${FUNCNAME[0]}: @ is:\n$@"
	
	# This is a standard while/case loop to collect all the input parameters.
	while [[ -n "$1" ]]; do
		case "$1" in
		-u | -U | --usage)
			show_usage
			;;
		-h | -H | --help)
			show_help
			;;
		--install-macos-major-upgrades)
			install_macos_major_upgrades="TRUE"
			;;
		--install-macos-major-upgrades-off)
			install_macos_major_upgrades="FALSE"
			;;
		--install-macos-major-version-target=*)
			install_macos_major_version_target_option="${1##*=}"
			;;
		--install-rapid-security-responses)
			install_rapid_security_responses_option="TRUE"
			;;
		--install-rapid-security-responses-off)
			install_rapid_security_responses_option="FALSE"
			;;
		--install-non-system-updates-without-restarting)
			install_non_system_updates_without_restarting_option="TRUE"
			;;
		--install-non-system-updates-without-restarting-off)
			install_non_system_updates_without_restarting_option="FALSE"
			;;
		--install-jamf-policy-triggers=*)
			install_jamf_policy_triggers_option="${1##*=}"
			;;
		--install-jamf-policy-triggers-without-restarting)
			install_jamf_policy_triggers_without_restarting_option="TRUE"
			;;
		--install-jamf-policy-triggers-without-restarting-off)
			install_jamf_policy_triggers_without_restarting_option="FALSE"
			;;
		--workflow-install-now)
			workflow_install_now_option="TRUE"
			;;
		--workflow-install-now-off)
			workflow_install_now_option="FALSE"
			;;
		--workflow-only-download)
			workflow_only_download_option="TRUE"
			;;
		--workflow-only-download-off)
			workflow_only_download_option="FALSE"
			;;
		--workflow-restart-without-updates)
			workflow_restart_without_updates_option="TRUE"
			;;
		--workflow-restart-without-updates-off)
			workflow_restart_without_updates_option="FALSE"
			;;
		--workflow-disable-update-check)
			workflow_disable_update_check_option="TRUE"
			;;
		--workflow-disable-update-check-off)
			workflow_disable_update_check_option="FALSE"
			;;
		--workflow-disable-relaunch)
			workflow_disable_relaunch_option="TRUE"
			;;
		--workflow-disable-relaunch-off)
			workflow_disable_relaunch_option="FALSE"
			;;
		--workflow-reset-super-after-completion)
			workflow_reset_super_after_completion_active="TRUE"
			;;
		--deferral-timer-default=*)
			deferral_timer_default_option="${1##*=}"
			;;
		--deferral-timer-menu=*)
			deferral_timer_menu_option="${1##*=}"
			;;
		--deferral-timer-focus=*)
			deferral_timer_focus_option="${1##*=}"
			;;
		--deferral-timer-error=*)
			deferral_timer_error_option="${1##*=}"
			;;
		--deferral-timer-workflow-relaunch=*)
			deferral_timer_workflow_relaunch_option="${1##*=}"
			;;
		--deferral-timer-reset-all)
			deferral_timer_reset_all_option="TRUE"
			;;
		--schedule-workflow-active=*)
			schedule_workflow_active_option="${1##*=}"
			;;
		--schedule-zero-date-release)
			schedule_zero_date_release_option="TRUE"
			;;
		--schedule-zero-date-release-off)
			schedule_zero_date_release_option="FALSE"
			;;
		--schedule-zero-date-sofa-custom-url=*)
			schedule_zero_date_sofa_custom_url_option="${1##*=}"
			;;
		--schedule-zero-date-manual=*)
			schedule_zero_date_manual_option="${1##*=}"
			;;
		--scheduled-install-days=*)
			scheduled_install_days_option="${1##*=}"
			;;
		--scheduled-install-date=*)
			scheduled_install_date_option="${1##*=}"
			;;
		--scheduled-install-user-choice)
			scheduled_install_user_choice_option="TRUE"
			;;
		--scheduled-install-user-choice-off)
			scheduled_install_user_choice_option="FALSE"
			;;
		--scheduled-install-reminder=*)
			scheduled_install_reminder_option="${1##*=}"
			;;
		--scheduled-install-delete-all)
			scheduled_install_delete_all_option="TRUE"
			;;
		--deadline-count-focus=*)
			deadline_count_focus_option="${1##*=}"
			;;
		--deadline-count-soft=*)
			deadline_count_soft_option="${1##*=}"
			;;
		--deadline-count-hard=*)
			deadline_count_hard_option="${1##*=}"
			;;
		--deadline-count-restart-all)
			deadline_count_restart_all_option="TRUE"
			;;
		--deadline-count-delete-all)
			deadline_count_delete_all_option="TRUE"
			;;
		--deadline-days-focus=*)
			deadline_days_focus_option="${1##*=}"
			;;
		--deadline-days-soft=*)
			deadline_days_soft_option="${1##*=}"
			;;
		--deadline-days-hard=*)
			deadline_days_hard_option="${1##*=}"
			;;
		--deadline-days-restart-all)
			deadline_days_restart_all_option="TRUE"
			;;
		--deadline-days-delete-all)
			deadline_days_delete_all_option="TRUE"
			;;
		--deadline-date-focus=*)
			deadline_date_focus_option="${1##*=}"
			;;
		--deadline-date-soft=*)
			deadline_date_soft_option="${1##*=}"
			;;
		--deadline-date-hard=*)
			deadline_date_hard_option="${1##*=}"
			;;
		--deadline-date-delete-all)
			deadline_date_delete_all_option="TRUE"
			;;
		--dialog-timeout-default=*)
			dialog_timeout_default_option="${1##*=}"
			;;
		--dialog-timeout-user-auth=*)
			dialog_timeout_user_auth_option="${1##*=}"
			;;
		--dialog-timeout-user-choice=*)
			dialog_timeout_user_choice_option="${1##*=}"
			;;
		--dialog-timeout-user-schedule=*)
			dialog_timeout_user_schedule_option="${1##*=}"
			;;
		--dialog-timeout-soft-deadline=*)
			dialog_timeout_soft_deadline_option="${1##*=}"
			;;
		--dialog-timeout-insufficient-storage=*)
			dialog_timeout_insufficient_storage_option="${1##*=}"
			;;
		--dialog-timeout-power-required=*)
			dialog_timeout_power_required_option="${1##*=}"
			;;
		--dialog-timeout-delete-all)
			dialog_timeout_delete_all_option="TRUE"
			;;
		--display-unmovable=*)
			display_unmovable_option="${1##*=}"
			;;
		--display-hide-background=*)
			display_hide_background_option="${1##*=}"
			;;
		--display-silently=*)
			display_silently_option="${1##*=}"
			;;
		--display-hide-progress-bar=*)
			display_hide_progress_bar_option="${1##*=}"
			;;
		--display-notifications-centered=*)
			display_notifications_centered_option="${1##*=}"
			;;
		--display-icon-size=*)
			display_icon_size_option="${1##*=}"
			;;
		--display-icon-file=*)
			display_icon_file_option="${1##*=}"
			;;
		--display-icon-light-file=*)
			display_icon_light_file_option="${1##*=}"
			;;
		--display-icon-dark-file=*)
			display_icon_dark_file_option="${1##*=}"
			;;
		--display-accessory-type=*)
			display_accessory_type_option="${1##*=}"
			;;
		--display-accessory-default-file=*)
			display_accessory_default_file_option="${1##*=}"
			;;
		--display-accessory-macos-minor-update-file=*)
			display_accessory_macos_minor_update_file_option="${1##*=}"
			;;
		--display-accessory-macos-major-upgrade-file=*)
			display_accessory_macos_major_upgrade_file_option="${1##*=}"
			;;
		--display-accessory-non-system-updates-file=*)
			display_accessory_non_system_updates_file_option="${1##*=}"
			;;
		--display-accessory-jamf-policy-triggers-file=*)
			display_accessory_jamf_policy_triggers_file_option="${1##*=}"
			;;
		--display-accessory-restart-without-updates-file=*)
			display_accessory_restart_without_updates_file_option="${1##*=}"
			;;
		--display-help-button-string=*)
			display_help_button_string_option="${1##*=}"
			;;
		--display-warning-button-string=*)
			display_warning_button_string_option="${1##*=}"
			;;
		--auth-ask-user-to-save-password)
			auth_ask_user_to_save_password="TRUE"
			;;
		--auth-ask-user-to-save-password-off)
			auth_ask_user_to_save_password="FALSE"
			;;
		--auth-local-account=*)
			auth_local_account_option="${1##*=}"
			;;
		--auth-local-password=*)
			auth_local_password_option="${1##*=}"
			;;
		--auth-service-add-via-admin-account=*)
			auth_service_add_via_admin_account_option="${1##*=}"
			;;
		--auth-service-add-via-admin-password=*)
			auth_service_add_via_admin_password_option="${1##*=}"
			;;
		--auth-service-account=*)
			auth_service_account_option="${1##*=}"
			;;
		--auth-service-password=*)
			auth_service_password_option="${1##*=}"
			;;
		--auth-jamf-client=*)
			auth_jamf_client_option="${1##*=}"
			;;
		--auth-jamf-secret=*)
			auth_jamf_secret_option="${1##*=}"
			;;
		--auth-jamf-account=*)
			auth_jamf_account_option="${1##*=}"
			;;
		--auth-jamf-password=*)
			auth_jamf_password_option="${1##*=}"
			;;
		--auth-delete-all)
			auth_delete_all_option="TRUE"
			;;
		--auth-jamf-custom-url=*)
			auth_jamf_custom_url_option="${1##*=}"
			;;
		--auth-credential-failover-to-user)
			auth_credential_failover_to_user_option="TRUE"
			;;
		--auth-credential-failover-to-user-off)
			auth_credential_failover_to_user_option="FALSE"
			;;
		--auth-mdm-failover-to-user=*)
			auth_mdm_failover_to_user_option="${1##*=}"
			;;
		-T | --test-mode)
			test_mode_option="TRUE"
			;;
		-t | --test-mode-off)
			test_mode_option="FALSE"
			;;
		--test-mode-timeout=*)
			test_mode_timeout_option="${1##*=}"
			;;
		--test-storage-update=*)
			test_storage_update_option="${1##*=}"
			;;
		--test-storage-upgrade=*)
			test_storage_upgrade_option="${1##*=}"
			;;
		--test-battery-level=*)
			test_battery_level_option="${1##*=}"
			;;
		-l | -L | --open-logs)
			open_logs_option="TRUE"
			;;
		-x | -X | --reset-super)
			reset_super_option="TRUE"
			;;
		-V | --verbose-mode)
			verbose_mode_option="TRUE"
			;;
		-v | --verbose-mode-off)
			verbose_mode_option="FALSE"
			;;
		*)
			unrecognized_options_array+=("$1")
			;;
		esac
		shift
	done
	
	# Error log any unrecognized options.
	[[ -n "${unrecognized_options_array[*]}" ]] && show_usage
}

# Collect any parameters stored in ${SUPER_MANAGED_PLIST} and/or ${SUPER_LOCAL_PLIST}.
get_preferences() {
	# First handle any preference deletion requests.
	local workflow_reset_super_after_completion_now_local
	workflow_reset_super_after_completion_now_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletionNow 2>/dev/null)
	if [[ "${reset_super_option}" == "TRUE" ]] || [[ "${workflow_reset_super_after_completion_now_local}" -eq 1 ]]; then
		log_super "Status: Deleting all local (non-managed and non-authentication) preferences."
		
		# Backup any preferences made before this function and saved authentication preferences first.
		local auth_ask_user_to_save_password_backup
		auth_ask_user_to_save_password_backup=$(defaults read "${SUPER_LOCAL_PLIST}" AuthAskUserToSavePassword 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_ask_user_to_save_password_backup: ${auth_ask_user_to_save_password_backup}"
		local auth_local_account_backup
		auth_local_account_backup=$(defaults read "${SUPER_LOCAL_PLIST}" AuthLocalAccount 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_backup: ${auth_local_account_backup}"
		local auth_service_account_backup
		auth_service_account_backup=$(defaults read "${SUPER_LOCAL_PLIST}" AuthServiceAccount 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_backup: ${auth_service_account_backup}"
		local auth_jamf_client_backup
		auth_jamf_client_backup=$(defaults read "${SUPER_LOCAL_PLIST}" AuthJamfClient 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_backup: ${auth_jamf_client_backup}"
		local auth_jamf_account_backup
		auth_jamf_account_backup=$(defaults read "${SUPER_LOCAL_PLIST}" AuthJamfAccount 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_backup: ${auth_jamf_account_backup}"
		local auth_legacy_local_account_backup
		auth_legacy_local_account_backup=$(defaults read "${SUPER_LOCAL_PLIST}" LocalAccount 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_legacy_local_account_backup: ${auth_legacy_local_account_backup}"
		local auth_legacy_super_account_backup
		auth_legacy_super_account_backup=$(defaults read "${SUPER_LOCAL_PLIST}" SuperAccount 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_legacy_super_account_backup: ${auth_legacy_super_account_backup}"
		local auth_legacy_jamf_account_backup
		auth_legacy_jamf_account_backup=$(defaults read "${SUPER_LOCAL_PLIST}" JamfAccount 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_legacy_jamf_account_backup: ${auth_legacy_jamf_account_backup}"
	
		# Delete and/or reset locally saved items.
		defaults delete "${SUPER_LOCAL_PLIST}"
		rm -f "${SUPER_FOLDER}/.WorkflowInstallNow" 2>/dev/null # This is cleaning up a legacy item.
		rm -f "${SUPER_FOLDER}/.WorkflowRestartValidate" 2>/dev/null # This is cleaning up a legacy item.
		rm -r "${SUPER_FOLDER}/icon.png" 2>/dev/null # This is cleaning up a legacy item.
		rm -r "${DISPLAY_ICON_LIGHT_FILE_CACHE}" 2>/dev/null
		rm -r "${DISPLAY_ICON_DARK_FILE_CACHE}" 2>/dev/null
		check_software_status_required="TRUE" # This will trigger the reset_software_update_status() function.
		rm -f "${SOFA_MACOS_JSON_ETAG_CACHE}" 2>/dev/null
		rm -f "${SOFA_MACOS_JSON_CACHE}" 2>/dev/null
		defaults write "${SUPER_LOCAL_PLIST}" SuperVersion -string "${SUPER_VERSION}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" VerboseMode -bool true
	
		# Restore any saved preferences from backup.
		[[ "${auth_ask_user_to_save_password_backup}" -eq 1 ]] && defaults write "${SUPER_LOCAL_PLIST}" AuthAskUserToSavePassword -bool true
		[[ "${auth_local_account_backup}" -eq 1 ]] && defaults write "${SUPER_LOCAL_PLIST}" AuthLocalAccount -bool true
		[[ "${auth_service_account_backup}" -eq 1 ]] && defaults write "${SUPER_LOCAL_PLIST}" AuthServiceAccount -bool true
		[[ "${auth_jamf_client_backup}" -eq 1 ]] && defaults write "${SUPER_LOCAL_PLIST}" AuthJamfClient -bool true
		[[ "${auth_jamf_account_backup}" -eq 1 ]] && defaults write "${SUPER_LOCAL_PLIST}" AuthJamfAccount -bool true
		[[ -n "${auth_legacy_local_account_backup}" ]] && defaults write "${SUPER_LOCAL_PLIST}" LocalAccount -string "${auth_legacy_local_account_backup}"
		[[ -n "${auth_legacy_super_account_backup}" ]] && defaults write "${SUPER_LOCAL_PLIST}" SuperAccount -string "${auth_legacy_super_account_backup}"
		[[ -n "${auth_legacy_jamf_account_backup}" ]] && defaults write "${SUPER_LOCAL_PLIST}" JamfAccount -string "${auth_legacy_jamf_account_backup}"
	else # Lesser delete/reset options.
		if [[ "${deferral_timer_reset_all_option}" == "TRUE" ]]; then
			log_super "Status: Resetting all local deferral timer preferences."
			defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerDefault 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerMenu 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerFocus 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerError 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null
		fi
		if [[ "${scheduled_install_delete_all_option}" == "TRUE" ]]; then
			log_super "Status: Deleting all scheduled installation preferences."
			defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallDays 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallDate 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallUserChoice 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallReminder 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
		fi
		if [[ "${deadline_count_delete_all_option}" == "TRUE" ]]; then
			log_super "Status: Deleting all local deadline count preferences."
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCountFocus 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCountSoft 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCountHard 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCounterFocus 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCounterSoft 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCounterHard 2>/dev/null
		fi
		if [[ "${deadline_days_delete_all_option}" == "TRUE" ]]; then
			log_super "Status: Deleting all local deadline days preferences."
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysFocus 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysSoft 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysHard 2>/dev/null
		fi
		if [[ "${deadline_date_delete_all_option}" == "TRUE" ]]; then
			log_super "Status: Deleting all local deadline date preferences."
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDateFocus 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDateSoft 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDateHard 2>/dev/null
		fi
		if [[ "${dialog_timeout_delete_all_option}" == "TRUE" ]]; then
			log_super "Status: Deleting all local dialog timeout preferences."
			defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutDefault 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutUserChoice 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutSoftDeadline 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutUserAuth 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutInsufficientStorage 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutPowerRequired 2>/dev/null
		fi
	fi
	
	# Collect any managed preferences from ${SUPER_MANAGED_PLIST}.
	if [[ -f "${SUPER_MANAGED_PLIST}.plist" ]]; then
		local install_macos_major_upgrades_managed
		install_macos_major_upgrades_managed=$(defaults read "${SUPER_MANAGED_PLIST}" InstallMacOSMajorUpgrades 2>/dev/null)
		local install_macos_major_version_target_managed
		install_macos_major_version_target_managed=$(defaults read "${SUPER_MANAGED_PLIST}" InstallMacOSMajorVersionTarget 2>/dev/null)
		local install_rapid_security_responses_managed
		install_rapid_security_responses_managed=$(defaults read "${SUPER_MANAGED_PLIST}" InstallRapidSecurityResponses 2>/dev/null)
		local install_non_system_updates_without_restarting_managed
		install_non_system_updates_without_restarting_managed=$(defaults read "${SUPER_MANAGED_PLIST}" InstallNonSystemUpdatesWithoutRestarting 2>/dev/null)
		local install_jamf_policy_triggers_managed
		install_jamf_policy_triggers_managed=$(defaults read "${SUPER_MANAGED_PLIST}" InstallJamfPolicyTriggers 2>/dev/null)
		local install_jamf_policy_triggers_without_restarting_managed
		install_jamf_policy_triggers_without_restarting_managed=$(defaults read "${SUPER_MANAGED_PLIST}" InstallJamfPolicyTriggersWithoutRestarting 2>/dev/null)
		local workflow_install_now_managed
		workflow_install_now_managed=$(defaults read "${SUPER_MANAGED_PLIST}" WorkflowInstallNow 2>/dev/null)
		local workflow_only_download_managed
		workflow_only_download_managed=$(defaults read "${SUPER_MANAGED_PLIST}" WorkflowOnlyDownload 2>/dev/null)
		local workflow_restart_without_updates_managed
		workflow_restart_without_updates_managed=$(defaults read "${SUPER_MANAGED_PLIST}" WorkflowRestartWithoutUpdates 2>/dev/null)
		local workflow_disable_update_check_managed
		workflow_disable_update_check_managed=$(defaults read "${SUPER_MANAGED_PLIST}" WorkflowDisableUpdateCheck 2>/dev/null)
		local workflow_disable_relaunch_managed
		workflow_disable_relaunch_managed=$(defaults read "${SUPER_MANAGED_PLIST}" WorkflowDisableRelaunch 2>/dev/null)
		local deferral_timer_default_managed
		deferral_timer_default_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeferralTimerDefault 2>/dev/null)
		local deferral_timer_menu_managed
		deferral_timer_menu_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeferralTimerMenu 2>/dev/null)
		local deferral_timer_focus_managed
		deferral_timer_focus_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeferralTimerFocus 2>/dev/null)
		local deferral_timer_error_managed
		deferral_timer_error_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeferralTimerError 2>/dev/null)
		local deferral_timer_workflow_relaunch_managed
		deferral_timer_workflow_relaunch_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null)
		local schedule_workflow_active_managed
		schedule_workflow_active_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduleWorkflowActive 2>/dev/null)
		local schedule_zero_date_release_managed
		schedule_zero_date_release_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduleZeroDateRelease 2>/dev/null)
		local schedule_zero_date_sofa_custom_url_managed
		schedule_zero_date_sofa_custom_url_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduleZeroDateSOFACustomURL 2>/dev/null)
		local schedule_zero_date_manual_managed
		schedule_zero_date_manual_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduleZeroDateManual 2>/dev/null)
		local scheduled_install_days_managed
		scheduled_install_days_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduledInstallDays 2>/dev/null)
		local scheduled_install_date_managed
		scheduled_install_date_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduledInstallDate 2>/dev/null)
		local scheduled_install_user_choice_managed
		scheduled_install_user_choice_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduledInstallUserChoice 2>/dev/null)
		local scheduled_install_reminder_managed
		scheduled_install_reminder_managed=$(defaults read "${SUPER_MANAGED_PLIST}" ScheduledInstallReminder 2>/dev/null)
		local deadline_count_focus_managed
		deadline_count_focus_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineCountFocus 2>/dev/null)
		local deadline_count_soft_managed
		deadline_count_soft_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineCountSoft 2>/dev/null)
		local deadline_count_hard_managed
		deadline_count_hard_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineCountHard 2>/dev/null)
		local deadline_days_focus_managed
		deadline_days_focus_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineDaysFocus 2>/dev/null)
		local deadline_days_soft_managed
		deadline_days_soft_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineDaysSoft 2>/dev/null)
		local deadline_days_hard_managed
		deadline_days_hard_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineDaysHard 2>/dev/null)
		local deadline_date_focus_managed
		deadline_date_focus_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineDateFocus 2>/dev/null)
		local deadline_date_soft_managed
		deadline_date_soft_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineDateSoft 2>/dev/null)
		local deadline_date_hard_managed
		deadline_date_hard_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DeadlineDateHard 2>/dev/null)
		local dialog_timeout_default_managed
		dialog_timeout_default_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutDefault 2>/dev/null)
		local dialog_timeout_user_auth_managed
		dialog_timeout_user_auth_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutUserAuth 2>/dev/null)
		local dialog_timeout_user_choice_managed
		dialog_timeout_user_choice_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutUserChoice 2>/dev/null)
		local dialog_timeout_user_schedule_managed
		dialog_timeout_user_schedule_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutUserSchedule 2>/dev/null)
		local dialog_timeout_soft_deadline_managed
		dialog_timeout_soft_deadline_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutSoftDeadline 2>/dev/null)
		local dialog_timeout_insufficient_storage_managed
		dialog_timeout_insufficient_storage_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutInsufficientStorage 2>/dev/null)
		local dialog_timeout_power_required_managed
		dialog_timeout_power_required_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DialogTimeoutPowerRequired 2>/dev/null)
		local display_unmovable_managed
		display_unmovable_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayUnmovable 2>/dev/null)
		local display_hide_background_managed
		display_hide_background_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayHideBackground 2>/dev/null)
		local display_silently_managed
		display_silently_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplaySilently 2>/dev/null)
		local display_hide_progress_bar_managed
		display_hide_progress_bar_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayHideProgressBar 2>/dev/null)
		local display_notifications_centered_managed
		display_notifications_centered_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayNotificationsCentered 2>/dev/null)
		local display_icon_size_managed
		display_icon_size_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayIconSize 2>/dev/null)
		local display_icon_file_managed
		display_icon_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayIconFile 2>/dev/null)
		local display_icon_light_file_managed
		display_icon_light_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayIconLightFile 2>/dev/null)
		local display_icon_dark_file_managed
		display_icon_dark_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayIconDarkFile 2>/dev/null)
		local display_accessory_type_managed
		display_accessory_type_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryType 2>/dev/null)
		local display_accessory_default_file_managed
		display_accessory_default_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryDefaultFile 2>/dev/null)
		local display_accessory_macos_minor_update_file_managed
		display_accessory_macos_minor_update_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryMacOSMinorUpdateFile 2>/dev/null)
		local display_accessory_macos_minor_update_file_managed
		display_accessory_macos_major_upgrade_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryMacOSMajorUpgradeFile 2>/dev/null)
		local display_accessory_non_system_updates_file_managed
		display_accessory_non_system_updates_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryNonSystemUpdatesFile 2>/dev/null)
		local display_accessory_jamf_policy_triggers_file_managed
		display_accessory_jamf_policy_triggers_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryJamfPolicyTriggersFile 2>/dev/null)
		local display_accessory_restart_without_updates_file_managed
		display_accessory_restart_without_updates_file_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayAccessoryRestartWithoutUpdatesFile 2>/dev/null)
		local display_help_button_string_managed
		display_help_button_string_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayHelpButtonString 2>/dev/null)
		local display_warning_button_string_managed
		display_warning_button_string_managed=$(defaults read "${SUPER_MANAGED_PLIST}" DisplayWarningButtonString 2>/dev/null)
		local auth_user_save_password_managed
		auth_user_save_password_managed=$(defaults read "${SUPER_MANAGED_PLIST}" AuthAskUserToSavePassword 2>/dev/null)
		local auth_jamf_computer_id_managed
		auth_jamf_computer_id_managed=$(defaults read "${SUPER_MANAGED_PLIST}" AuthJamfComputerID 2>/dev/null)
		local auth_jamf_custom_url_managed
		auth_jamf_custom_url_managed=$(defaults read "${SUPER_MANAGED_PLIST}" AuthJamfCustomURL 2>/dev/null)
		local auth_credential_failover_to_user_managed
		auth_credential_failover_to_user_managed=$(defaults read "${SUPER_MANAGED_PLIST}" AuthCredentialFailoverToUser 2>/dev/null)
		local auth_mdm_failover_to_user_managed
		auth_mdm_failover_to_user_managed=$(defaults read "${SUPER_MANAGED_PLIST}" AuthMDMFailoverToUser 2>/dev/null)
		local test_mode_managed
		test_mode_managed=$(defaults read "${SUPER_MANAGED_PLIST}" TestMode 2>/dev/null)
		local test_mode_timeout_managed
		test_mode_timeout_managed=$(defaults read "${SUPER_MANAGED_PLIST}" TestModeTimeout 2>/dev/null)
		local test_storage_update_managed
		test_storage_update_managed=$(defaults read "${SUPER_MANAGED_PLIST}" TestStorageUpdate 2>/dev/null)
		local test_storage_upgrade_managed
		test_storage_upgrade_managed=$(defaults read "${SUPER_MANAGED_PLIST}" TestStorageUpgrade 2>/dev/null)
		local test_battery_level_managed
		test_battery_level_managed=$(defaults read "${SUPER_MANAGED_PLIST}" TestBatteryLevel 2>/dev/null)
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Managed preference file: ${SUPER_MANAGED_PLIST}:\n$(defaults read "${SUPER_MANAGED_PLIST}" 2>/dev/null)"
	
	# Collect any local preferences from ${SUPER_LOCAL_PLIST}.
	if [[ -f "${SUPER_LOCAL_PLIST}.plist" ]]; then
		local install_macos_major_upgrades_local
		install_macos_major_upgrades_local=$(defaults read "${SUPER_LOCAL_PLIST}" InstallMacOSMajorUpgrades 2>/dev/null)
		local install_macos_major_version_target_local
		install_macos_major_version_target_local=$(defaults read "${SUPER_LOCAL_PLIST}" InstallMacOSMajorVersionTarget 2>/dev/null)
		local install_rapid_security_responses_local
		install_rapid_security_responses_local=$(defaults read "${SUPER_LOCAL_PLIST}" InstallRapidSecurityResponses 2>/dev/null)
		local install_non_system_updates_without_restarting_local
		install_non_system_updates_without_restarting_local=$(defaults read "${SUPER_LOCAL_PLIST}" InstallNonSystemUpdatesWithoutRestarting 2>/dev/null)
		local install_jamf_policy_triggers_local
		install_jamf_policy_triggers_local=$(defaults read "${SUPER_LOCAL_PLIST}" InstallJamfPolicyTriggers 2>/dev/null)
		local install_jamf_policy_triggers_without_restarting_local
		install_jamf_policy_triggers_without_restarting_local=$(defaults read "${SUPER_LOCAL_PLIST}" InstallJamfPolicyTriggersWithoutRestarting 2>/dev/null)
		local workflow_install_now_local
		workflow_install_now_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowInstallNow 2>/dev/null)
		local workflow_only_download_local
		workflow_only_download_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowOnlyDownload 2>/dev/null)
		local workflow_restart_without_updates_local
		workflow_restart_without_updates_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowRestartWithoutUpdates 2>/dev/null)
		local workflow_disable_update_check_local
		workflow_disable_update_check_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowDisableUpdateCheck 2>/dev/null)
		local workflow_disable_relaunch_local
		workflow_disable_relaunch_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowDisableRelaunch 2>/dev/null)
		local deferral_timer_default_local
		deferral_timer_default_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralTimerDefault 2>/dev/null)
		local deferral_timer_menu_local
		deferral_timer_menu_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralTimerMenu 2>/dev/null)
		local deferral_timer_focus_local
		deferral_timer_focus_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralTimerFocus 2>/dev/null)
		local deferral_timer_error_local
		deferral_timer_error_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralTimerError 2>/dev/null)
		local deferral_timer_workflow_relaunch_local
		deferral_timer_workflow_relaunch_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null)
		local schedule_workflow_active_local
		schedule_workflow_active_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleWorkflowActive 2>/dev/null)
		local schedule_zero_date_release_local
		schedule_zero_date_release_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleZeroDateRelease 2>/dev/null)
		local schedule_zero_date_sofa_custom_url_local
		schedule_zero_date_sofa_custom_url_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleZeroDateSOFACustomURL 2>/dev/null)
		local schedule_zero_date_manual_local
		schedule_zero_date_manual_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleZeroDateManual 2>/dev/null)
		local scheduled_install_days_local
		scheduled_install_days_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduledInstallDays 2>/dev/null)
		local scheduled_install_date_local
		scheduled_install_date_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduledInstallDate 2>/dev/null)
		local scheduled_install_user_choice_local
		scheduled_install_user_choice_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduledInstallUserChoice 2>/dev/null)
		local scheduled_install_reminder_local
		scheduled_install_reminder_local=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduledInstallReminder 2>/dev/null)
		local deadline_count_focus_local
		deadline_count_focus_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineCountFocus 2>/dev/null)
		local deadline_count_soft_local
		deadline_count_soft_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineCountSoft 2>/dev/null)
		local deadline_count_hard_local
		deadline_count_hard_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineCountHard 2>/dev/null)
		local deadline_days_focus_local
		deadline_days_focus_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineDaysFocus 2>/dev/null)
		local deadline_days_soft_local
		deadline_days_soft_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineDaysSoft 2>/dev/null)
		local deadline_days_hard_local
		deadline_days_hard_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineDaysHard 2>/dev/null)
		local deadline_date_focus_local
		deadline_date_focus_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineDateFocus 2>/dev/null)
		local deadline_date_soft_local
		deadline_date_soft_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineDateSoft 2>/dev/null)
		local deadline_date_hard_local
		deadline_date_hard_local=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineDateHard 2>/dev/null)
		local dialog_timeout_default_local
		dialog_timeout_default_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutDefault 2>/dev/null)
		local dialog_timeout_user_auth_local
		dialog_timeout_user_auth_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutUserAuth 2>/dev/null)
		local dialog_timeout_user_choice_local
		dialog_timeout_user_choice_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutUserChoice 2>/dev/null)
		local dialog_timeout_user_schedule_local
		dialog_timeout_user_schedule_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutUserSchedule 2>/dev/null)
		local dialog_timeout_soft_deadline_local
		dialog_timeout_soft_deadline_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutSoftDeadline 2>/dev/null)
		local dialog_timeout_insufficient_storage_local
		dialog_timeout_insufficient_storage_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutInsufficientStorage 2>/dev/null)
		local dialog_timeout_power_required_local
		dialog_timeout_power_required_local=$(defaults read "${SUPER_LOCAL_PLIST}" DialogTimeoutPowerRequired 2>/dev/null)
		local display_unmovable_local
		display_unmovable_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayUnmovable 2>/dev/null)
		local display_hide_background_local
		display_hide_background_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayHideBackground 2>/dev/null)
		local display_silently_local
		display_silently_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplaySilently 2>/dev/null)
		local display_hide_progress_bar_local
		display_hide_progress_bar_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayHideProgressBar 2>/dev/null)
		local display_notifications_centered_local
		display_notifications_centered_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayNotificationsCentered 2>/dev/null)
		local display_icon_size_local
		display_icon_size_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayIconSize 2>/dev/null)
		local display_icon_file_local
		display_icon_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayIconFile 2>/dev/null)
		local display_icon_light_file_local
		display_icon_light_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayIconLightFile 2>/dev/null)
		local display_icon_dark_file_local
		display_icon_dark_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayIconDarkFile 2>/dev/null)
		local display_accessory_type_local
		display_accessory_type_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryType 2>/dev/null)
		local display_accessory_default_file_local
		display_accessory_default_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryDefaultFile 2>/dev/null)
		local display_accessory_macos_minor_update_file_local
		display_accessory_macos_minor_update_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryMacOSMinorUpdateFile 2>/dev/null)
		local display_accessory_macos_minor_update_file_local
		display_accessory_macos_major_upgrade_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryMacOSMajorUpgradeFile 2>/dev/null)
		local display_accessory_non_system_updates_file_local
		display_accessory_non_system_updates_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryNonSystemUpdatesFile 2>/dev/null)
		local display_accessory_jamf_policy_triggers_file_local
		display_accessory_jamf_policy_triggers_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryJamfPolicyTriggersFile 2>/dev/null)
		local display_accessory_restart_without_updates_file_local
		display_accessory_restart_without_updates_file_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayAccessoryRestartWithoutUpdatesFile 2>/dev/null)
		local display_help_button_string_local
		display_help_button_string_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayHelpButtonString 2>/dev/null)
		local display_warning_button_string_local
		display_warning_button_string_local=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayWarningButtonString 2>/dev/null)
		local auth_user_save_password_local
		auth_user_save_password_local=$(defaults read "${SUPER_LOCAL_PLIST}" AuthAskUserToSavePassword 2>/dev/null)
		local auth_jamf_computer_id_local
		auth_jamf_computer_id_local=$(defaults read "${SUPER_LOCAL_PLIST}" AuthJamfComputerID 2>/dev/null)
		local auth_jamf_custom_url_local
		auth_jamf_custom_url_local=$(defaults read "${SUPER_LOCAL_PLIST}" AuthJamfCustomURL 2>/dev/null)
		local auth_credential_failover_to_user_local
		auth_credential_failover_to_user_local=$(defaults read "${SUPER_LOCAL_PLIST}" AuthCredentialFailoverToUser 2>/dev/null)
		local auth_mdm_failover_to_user_local
		auth_mdm_failover_to_user_local=$(defaults read "${SUPER_LOCAL_PLIST}" AuthMDMFailoverToUser 2>/dev/null)
		local test_mode_local
		test_mode_local=$(defaults read "${SUPER_LOCAL_PLIST}" TestMode 2>/dev/null)
		local test_mode_timeout_local
		test_mode_timeout_local=$(defaults read "${SUPER_LOCAL_PLIST}" TestModeTimeout 2>/dev/null)
		local test_storage_update_local
		test_storage_update_local=$(defaults read "${SUPER_LOCAL_PLIST}" TestStorageUpdate 2>/dev/null)
		local test_storage_upgrade_local
		test_storage_upgrade_local=$(defaults read "${SUPER_LOCAL_PLIST}" TestStorageUpgrade 2>/dev/null)
		local test_battery_level_local
		test_battery_level_local=$(defaults read "${SUPER_LOCAL_PLIST}" TestBatteryLevel 2>/dev/null)
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file before startup validation: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
	
	# This logic ensures the priority order of managed preference overrides the new input option which overrides the saved local preference.
	[[ -n "${install_macos_major_upgrades_managed}" ]] && install_macos_major_upgrades="${install_macos_major_upgrades_managed}"
	{ [[ -z "${install_macos_major_upgrades_managed}" ]] && [[ -z "${install_macos_major_upgrades}" ]] && [[ -n "${install_macos_major_upgrades_local}" ]]; } && install_macos_major_upgrades="${install_macos_major_upgrades_local}"
	[[ -n "${install_macos_major_version_target_managed}" ]] && install_macos_major_version_target_option="${install_macos_major_version_target_managed}"
	{ [[ -z "${install_macos_major_version_target_managed}" ]] && [[ -z "${install_macos_major_version_target_option}" ]] && [[ -n "${install_macos_major_version_target_local}" ]]; } && install_macos_major_version_target_option="${install_macos_major_version_target_local}"
	[[ -n "${install_rapid_security_responses_managed}" ]] && install_rapid_security_responses_option="${install_rapid_security_responses_managed}"
	{ [[ -z "${install_rapid_security_responses_managed}" ]] && [[ -z "${install_rapid_security_responses_option}" ]] && [[ -n "${install_rapid_security_responses_local}" ]]; } && install_rapid_security_responses_option="${install_rapid_security_responses_local}"
	[[ -n "${install_non_system_updates_without_restarting_managed}" ]] && install_non_system_updates_without_restarting_option="${install_non_system_updates_without_restarting_managed}"
	{ [[ -z "${install_non_system_updates_without_restarting_managed}" ]] && [[ -z "${install_non_system_updates_without_restarting_option}" ]] && [[ -n "${install_non_system_updates_without_restarting_local}" ]]; } && install_non_system_updates_without_restarting_option="${install_non_system_updates_without_restarting_local}"
	[[ -n "${install_jamf_policy_triggers_managed}" ]] && install_jamf_policy_triggers_option="${install_jamf_policy_triggers_managed}"
	{ [[ -z "${install_jamf_policy_triggers_managed}" ]] && [[ -z "${install_jamf_policy_triggers_option}" ]] && [[ -n "${install_jamf_policy_triggers_local}" ]]; } && install_jamf_policy_triggers_option="${install_jamf_policy_triggers_local}"
	[[ -n "${install_jamf_policy_triggers_without_restarting_managed}" ]] && install_jamf_policy_triggers_without_restarting_option="${install_jamf_policy_triggers_without_restarting_managed}"
	{ [[ -z "${install_jamf_policy_triggers_without_restarting_managed}" ]] && [[ -z "${install_jamf_policy_triggers_without_restarting_option}" ]] && [[ -n "${install_jamf_policy_triggers_without_restarting_local}" ]]; } && install_jamf_policy_triggers_without_restarting_option="${install_jamf_policy_triggers_without_restarting_local}"
	[[ -n "${workflow_install_now_managed}" ]] && workflow_install_now_option="${workflow_install_now_managed}"
	{ [[ -z "${workflow_install_now_managed}" ]] && [[ -z "${workflow_install_now_option}" ]] && [[ -n "${workflow_install_now_local}" ]]; } && workflow_install_now_option="${workflow_install_now_local}"
	[[ -n "${workflow_only_download_managed}" ]] && workflow_only_download_option="${workflow_only_download_managed}"
	{ [[ -z "${workflow_only_download_managed}" ]] && [[ -z "${workflow_only_download_option}" ]] && [[ -n "${workflow_only_download_local}" ]]; } && workflow_only_download_option="${workflow_only_download_local}"
	[[ -n "${workflow_restart_without_updates_managed}" ]] && workflow_restart_without_updates_option="${workflow_restart_without_updates_managed}"
	{ [[ -z "${workflow_restart_without_updates_managed}" ]] && [[ -z "${workflow_restart_without_updates_option}" ]] && [[ -n "${workflow_restart_without_updates_local}" ]]; } && workflow_restart_without_updates_option="${workflow_restart_without_updates_local}"
	[[ -n "${workflow_disable_update_check_managed}" ]] && workflow_disable_update_check_option="${workflow_disable_update_check_managed}"
	{ [[ -z "${workflow_disable_update_check_managed}" ]] && [[ -z "${workflow_disable_update_check_option}" ]] && [[ -n "${workflow_disable_update_check_local}" ]]; } && workflow_disable_update_check_option="${workflow_disable_update_check_local}"
	[[ -n "${workflow_disable_relaunch_managed}" ]] && workflow_disable_relaunch_option="${workflow_disable_relaunch_managed}"
	{ [[ -z "${workflow_disable_relaunch_managed}" ]] && [[ -z "${workflow_disable_relaunch_option}" ]] && [[ -n "${workflow_disable_relaunch_local}" ]]; } && workflow_disable_relaunch_option="${workflow_disable_relaunch_local}"
	[[ -n "${deferral_timer_default_managed}" ]] && deferral_timer_default_option="${deferral_timer_default_managed}"
	{ [[ -z "${deferral_timer_default_managed}" ]] && [[ -z "${deferral_timer_default_option}" ]] && [[ -n "${deferral_timer_default_local}" ]]; } && deferral_timer_default_option="${deferral_timer_default_local}"
	[[ -n "${deferral_timer_menu_managed}" ]] && deferral_timer_menu_option="${deferral_timer_menu_managed}"
	{ [[ -z "${deferral_timer_menu_managed}" ]] && [[ -z "${deferral_timer_menu_option}" ]] && [[ -n "${deferral_timer_menu_local}" ]]; } && deferral_timer_menu_option="${deferral_timer_menu_local}"
	[[ -n "${deferral_timer_focus_managed}" ]] && deferral_timer_focus_option="${deferral_timer_focus_managed}"
	{ [[ -z "${deferral_timer_focus_managed}" ]] && [[ -z "${deferral_timer_focus_option}" ]] && [[ -n "${deferral_timer_focus_local}" ]]; } && deferral_timer_focus_option="${deferral_timer_focus_local}"
	[[ -n "${deferral_timer_error_managed}" ]] && deferral_timer_error_option="${deferral_timer_error_managed}"
	{ [[ -z "${deferral_timer_error_managed}" ]] && [[ -z "${deferral_timer_error_option}" ]] && [[ -n "${deferral_timer_error_local}" ]]; } && deferral_timer_error_option="${deferral_timer_error_local}"
	[[ -n "${deferral_timer_workflow_relaunch_managed}" ]] && deferral_timer_workflow_relaunch_option="${deferral_timer_workflow_relaunch_managed}"
	{ [[ -z "${deferral_timer_workflow_relaunch_managed}" ]] && [[ -z "${deferral_timer_workflow_relaunch_option}" ]] && [[ -n "${deferral_timer_workflow_relaunch_local}" ]]; } && deferral_timer_workflow_relaunch_option="${deferral_timer_workflow_relaunch_local}"
	[[ -n "${schedule_workflow_active_managed}" ]] && schedule_workflow_active_option="${schedule_workflow_active_managed}"
	{ [[ -z "${schedule_workflow_active_managed}" ]] && [[ -z "${schedule_workflow_active_option}" ]] && [[ -n "${schedule_workflow_active_local}" ]]; } && schedule_workflow_active_option="${schedule_workflow_active_local}"
	[[ -n "${schedule_zero_date_release_managed}" ]] && schedule_zero_date_release_option="${schedule_zero_date_release_managed}"
	{ [[ -z "${schedule_zero_date_release_managed}" ]] && [[ -z "${schedule_zero_date_release_option}" ]] && [[ -n "${schedule_zero_date_release_local}" ]]; } && schedule_zero_date_release_option="${schedule_zero_date_release_local}"
	[[ -n "${schedule_zero_date_sofa_custom_url_managed}" ]] && schedule_zero_date_sofa_custom_url_option="${schedule_zero_date_sofa_custom_url_managed}"
	{ [[ -z "${schedule_zero_date_sofa_custom_url_managed}" ]] && [[ -z "${schedule_zero_date_sofa_custom_url_option}" ]] && [[ -n "${schedule_zero_date_sofa_custom_url_local}" ]]; } && schedule_zero_date_sofa_custom_url_option="${schedule_zero_date_sofa_custom_url_local}"
	[[ -n "${schedule_zero_date_manual_managed}" ]] && schedule_zero_date_manual_option="${schedule_zero_date_manual_managed}"
	{ [[ -z "${schedule_zero_date_manual_managed}" ]] && [[ -z "${schedule_zero_date_manual_option}" ]] && [[ -n "${schedule_zero_date_manual_local}" ]]; } && schedule_zero_date_manual_option="${schedule_zero_date_manual_local}"
	[[ -n "${scheduled_install_days_managed}" ]] && scheduled_install_days_option="${scheduled_install_days_managed}"
	{ [[ -z "${scheduled_install_days_managed}" ]] && [[ -z "${scheduled_install_days_option}" ]] && [[ -n "${scheduled_install_days_local}" ]]; } && scheduled_install_days_option="${scheduled_install_days_local}"
	[[ -n "${scheduled_install_date_managed}" ]] && scheduled_install_date_option="${scheduled_install_date_managed}"
	{ [[ -z "${scheduled_install_date_managed}" ]] && [[ -z "${scheduled_install_date_option}" ]] && [[ -n "${scheduled_install_date_local}" ]]; } && scheduled_install_date_option="${scheduled_install_date_local}"
	[[ -n "${scheduled_install_user_choice_managed}" ]] && scheduled_install_user_choice_option="${scheduled_install_user_choice_managed}"
	{ [[ -z "${scheduled_install_user_choice_managed}" ]] && [[ -z "${scheduled_install_user_choice_option}" ]] && [[ -n "${scheduled_install_user_choice_local}" ]]; } && scheduled_install_user_choice_option="${scheduled_install_user_choice_local}"
	[[ -n "${scheduled_install_reminder_managed}" ]] && scheduled_install_reminder_option="${scheduled_install_reminder_managed}"
	{ [[ -z "${scheduled_install_reminder_managed}" ]] && [[ -z "${scheduled_install_reminder_option}" ]] && [[ -n "${scheduled_install_reminder_local}" ]]; } && scheduled_install_reminder_option="${scheduled_install_reminder_local}"
	[[ -n "${deadline_count_focus_managed}" ]] && deadline_count_focus_option="${deadline_count_focus_managed}"
	{ [[ -z "${deadline_count_focus_managed}" ]] && [[ -z "${deadline_count_focus_option}" ]] && [[ -n "${deadline_count_focus_local}" ]]; } && deadline_count_focus_option="${deadline_count_focus_local}"
	[[ -n "${deadline_count_soft_managed}" ]] && deadline_count_soft_option="${deadline_count_soft_managed}"
	{ [[ -z "${deadline_count_soft_managed}" ]] && [[ -z "${deadline_count_soft_option}" ]] && [[ -n "${deadline_count_soft_local}" ]]; } && deadline_count_soft_option="${deadline_count_soft_local}"
	[[ -n "${deadline_count_hard_managed}" ]] && deadline_count_hard_option="${deadline_count_hard_managed}"
	{ [[ -z "${deadline_count_hard_managed}" ]] && [[ -z "${deadline_count_hard_option}" ]] && [[ -n "${deadline_count_hard_local}" ]]; } && deadline_count_hard_option="${deadline_count_hard_local}"
	[[ -n "${deadline_days_focus_managed}" ]] && deadline_days_focus_option="${deadline_days_focus_managed}"
	{ [[ -z "${deadline_days_focus_managed}" ]] && [[ -z "${deadline_days_focus_option}" ]] && [[ -n "${deadline_days_focus_local}" ]]; } && deadline_days_focus_option="${deadline_days_focus_local}"
	[[ -n "${deadline_days_soft_managed}" ]] && deadline_days_soft_option="${deadline_days_soft_managed}"
	{ [[ -z "${deadline_days_soft_managed}" ]] && [[ -z "${deadline_days_soft_option}" ]] && [[ -n "${deadline_days_soft_local}" ]]; } && deadline_days_soft_option="${deadline_days_soft_local}"
	[[ -n "${deadline_days_hard_managed}" ]] && deadline_days_hard_option="${deadline_days_hard_managed}"
	{ [[ -z "${deadline_days_hard_managed}" ]] && [[ -z "${deadline_days_hard_option}" ]] && [[ -n "${deadline_days_hard_local}" ]]; } && deadline_days_hard_option="${deadline_days_hard_local}"
	[[ -n "${deadline_date_focus_managed}" ]] && deadline_date_focus_option="${deadline_date_focus_managed}"
	{ [[ -z "${deadline_date_focus_managed}" ]] && [[ -z "${deadline_date_focus_option}" ]] && [[ -n "${deadline_date_focus_local}" ]]; } && deadline_date_focus_option="${deadline_date_focus_local}"
	[[ -n "${deadline_date_soft_managed}" ]] && deadline_date_soft_option="${deadline_date_soft_managed}"
	{ [[ -z "${deadline_date_soft_managed}" ]] && [[ -z "${deadline_date_soft_option}" ]] && [[ -n "${deadline_date_soft_local}" ]]; } && deadline_date_soft_option="${deadline_date_soft_local}"
	[[ -n "${deadline_date_hard_managed}" ]] && deadline_date_hard_option="${deadline_date_hard_managed}"
	{ [[ -z "${deadline_date_hard_managed}" ]] && [[ -z "${deadline_date_hard_option}" ]] && [[ -n "${deadline_date_hard_local}" ]]; } && deadline_date_hard_option="${deadline_date_hard_local}"
	[[ -n "${dialog_timeout_default_managed}" ]] && dialog_timeout_default_option="${dialog_timeout_default_managed}"
	{ [[ -z "${dialog_timeout_default_managed}" ]] && [[ -z "${dialog_timeout_default_option}" ]] && [[ -n "${dialog_timeout_default_local}" ]]; } && dialog_timeout_default_option="${dialog_timeout_default_local}"
	[[ -n "${dialog_timeout_user_auth_managed}" ]] && dialog_timeout_user_auth_option="${dialog_timeout_user_auth_managed}"
	{ [[ -z "${dialog_timeout_user_auth_managed}" ]] && [[ -z "${dialog_timeout_user_auth_option}" ]] && [[ -n "${dialog_timeout_user_auth_local}" ]]; } && dialog_timeout_user_auth_option="${dialog_timeout_user_auth_local}"
	[[ -n "${dialog_timeout_user_choice_managed}" ]] && dialog_timeout_user_choice_option="${dialog_timeout_user_choice_managed}"
	{ [[ -z "${dialog_timeout_user_choice_managed}" ]] && [[ -z "${dialog_timeout_user_choice_option}" ]] && [[ -n "${dialog_timeout_user_choice_local}" ]]; } && dialog_timeout_user_choice_option="${dialog_timeout_user_choice_local}"
	[[ -n "${dialog_timeout_user_schedule_managed}" ]] && dialog_timeout_user_schedule_option="${dialog_timeout_user_schedule_managed}"
	{ [[ -z "${dialog_timeout_user_schedule_managed}" ]] && [[ -z "${dialog_timeout_user_schedule_option}" ]] && [[ -n "${dialog_timeout_user_schedule_local}" ]]; } && dialog_timeout_user_schedule_option="${dialog_timeout_user_schedule_local}"
	[[ -n "${dialog_timeout_soft_deadline_managed}" ]] && dialog_timeout_soft_deadline_option="${dialog_timeout_soft_deadline_managed}"
	{ [[ -z "${dialog_timeout_soft_deadline_managed}" ]] && [[ -z "${dialog_timeout_soft_deadline_option}" ]] && [[ -n "${dialog_timeout_soft_deadline_local}" ]]; } && dialog_timeout_soft_deadline_option="${dialog_timeout_soft_deadline_local}"
	[[ -n "${dialog_timeout_insufficient_storage_managed}" ]] && dialog_timeout_insufficient_storage_option="${dialog_timeout_insufficient_storage_managed}"
	{ [[ -z "${dialog_timeout_insufficient_storage_managed}" ]] && [[ -z "${dialog_timeout_insufficient_storage_option}" ]] && [[ -n "${dialog_timeout_insufficient_storage_local}" ]]; } && dialog_timeout_insufficient_storage_option="${dialog_timeout_insufficient_storage_local}"
	[[ -n "${dialog_timeout_power_required_managed}" ]] && dialog_timeout_power_required_option="${dialog_timeout_power_required_managed}"
	{ [[ -z "${dialog_timeout_power_required_managed}" ]] && [[ -z "${dialog_timeout_power_required_option}" ]] && [[ -n "${dialog_timeout_power_required_local}" ]]; } && dialog_timeout_power_required_option="${dialog_timeout_power_required_local}"
	[[ -n "${display_unmovable_managed}" ]] && display_unmovable_option="${display_unmovable_managed}"
	{ [[ -z "${display_unmovable_managed}" ]] && [[ -z "${display_unmovable_option}" ]] && [[ -n "${display_unmovable_local}" ]]; } && display_unmovable_option="${display_unmovable_local}"
	[[ -n "${display_hide_background_managed}" ]] && display_hide_background_option="${display_hide_background_managed}"
	{ [[ -z "${display_hide_background_managed}" ]] && [[ -z "${display_hide_background_option}" ]] && [[ -n "${display_hide_background_local}" ]]; } && display_hide_background_option="${display_hide_background_local}"
	[[ -n "${display_silently_managed}" ]] && display_silently_option="${display_silently_managed}"
	{ [[ -z "${display_silently_managed}" ]] && [[ -z "${display_silently_option}" ]] && [[ -n "${display_silently_local}" ]]; } && display_silently_option="${display_silently_local}"
	[[ -n "${display_hide_progress_bar_managed}" ]] && display_hide_progress_bar_option="${display_hide_progress_bar_managed}"
	{ [[ -z "${display_hide_progress_bar_managed}" ]] && [[ -z "${display_hide_progress_bar_option}" ]] && [[ -n "${display_hide_progress_bar_local}" ]]; } && display_hide_progress_bar_option="${display_hide_progress_bar_local}"
	[[ -n "${display_notifications_centered_managed}" ]] && display_notifications_centered_option="${display_notifications_centered_managed}"
	{ [[ -z "${display_notifications_centered_managed}" ]] && [[ -z "${display_notifications_centered_option}" ]] && [[ -n "${display_notifications_centered_local}" ]]; } && display_notifications_centered_option="${display_notifications_centered_local}"
	[[ -n "${display_icon_size_managed}" ]] && display_icon_size_option="${display_icon_size_managed}"
	{ [[ -z "${display_icon_size_managed}" ]] && [[ -z "${display_icon_size_option}" ]] && [[ -n "${display_icon_size_local}" ]]; } && display_icon_size_option="${display_icon_size_local}"
	[[ -n "${display_icon_file_managed}" ]] && display_icon_file_option="${display_icon_file_managed}"
	{ [[ -z "${display_icon_file_managed}" ]] && [[ -z "${display_icon_file_option}" ]] && [[ -n "${display_icon_file_local}" ]]; } && display_icon_file_option="${display_icon_file_local}"
	[[ -n "${display_icon_light_file_managed}" ]] && display_icon_light_file_option="${display_icon_light_file_managed}"
	{ [[ -z "${display_icon_light_file_managed}" ]] && [[ -z "${display_icon_light_file_option}" ]] && [[ -n "${display_icon_light_file_local}" ]]; } && display_icon_light_file_option="${display_icon_light_file_local}"
	[[ -n "${display_icon_dark_file_managed}" ]] && display_icon_dark_file_option="${display_icon_dark_file_managed}"
	{ [[ -z "${display_icon_dark_file_managed}" ]] && [[ -z "${display_icon_dark_file_option}" ]] && [[ -n "${display_icon_dark_file_local}" ]]; } && display_icon_dark_file_option="${display_icon_dark_file_local}"
	[[ -n "${display_accessory_type_managed}" ]] && display_accessory_type_option="${display_accessory_type_managed}"
	{ [[ -z "${display_accessory_type_managed}" ]] && [[ -z "${display_accessory_type_option}" ]] && [[ -n "${display_accessory_type_local}" ]]; } && display_accessory_type_option="${display_accessory_type_local}"
	[[ -n "${display_accessory_default_file_managed}" ]] && display_accessory_default_file_option="${display_accessory_default_file_managed}"
	{ [[ -z "${display_accessory_default_file_managed}" ]] && [[ -z "${display_accessory_default_file_option}" ]] && [[ -n "${display_accessory_default_file_local}" ]]; } && display_accessory_default_file_option="${display_accessory_default_file_local}"
	[[ -n "${display_accessory_macos_minor_update_file_managed}" ]] && display_accessory_macos_minor_update_file_option="${display_accessory_macos_minor_update_file_managed}"
	{ [[ -z "${display_accessory_macos_minor_update_file_managed}" ]] && [[ -z "${display_accessory_macos_minor_update_file_option}" ]] && [[ -n "${display_accessory_macos_minor_update_file_local}" ]]; } && display_accessory_macos_minor_update_file_option="${display_accessory_macos_minor_update_file_local}"
	[[ -n "${display_accessory_macos_major_upgrade_file_managed}" ]] && display_accessory_macos_major_upgrade_file_option="${display_accessory_macos_major_upgrade_file_managed}"
	{ [[ -z "${display_accessory_macos_major_upgrade_file_managed}" ]] && [[ -z "${display_accessory_macos_major_upgrade_file_option}" ]] && [[ -n "${display_accessory_macos_major_upgrade_file_local}" ]]; } && display_accessory_macos_major_upgrade_file_option="${display_accessory_macos_major_upgrade_file_local}"
	[[ -n "${display_accessory_non_system_updates_file_managed}" ]] && display_accessory_non_system_updates_file_option="${display_accessory_non_system_updates_file_managed}"
	{ [[ -z "${display_accessory_non_system_updates_file_managed}" ]] && [[ -z "${display_accessory_non_system_updates_file_option}" ]] && [[ -n "${display_accessory_non_system_updates_file_local}" ]]; } && display_accessory_non_system_updates_file_option="${display_accessory_non_system_updates_file_local}"
	[[ -n "${display_accessory_jamf_policy_triggers_file_managed}" ]] && display_accessory_jamf_policy_triggers_file_option="${display_accessory_jamf_policy_triggers_file_managed}"
	{ [[ -z "${display_accessory_jamf_policy_triggers_file_managed}" ]] && [[ -z "${display_accessory_jamf_policy_triggers_file_option}" ]] && [[ -n "${display_accessory_jamf_policy_triggers_file_local}" ]]; } && display_accessory_jamf_policy_triggers_file_option="${display_accessory_jamf_policy_triggers_file_local}"
	[[ -n "${display_accessory_restart_without_updates_file_managed}" ]] && display_accessory_restart_without_updates_file_option="${display_accessory_restart_without_updates_file_managed}"
	{ [[ -z "${display_accessory_restart_without_updates_file_managed}" ]] && [[ -z "${display_accessory_restart_without_updates_file_option}" ]] && [[ -n "${display_accessory_restart_without_updates_file_local}" ]]; } && display_accessory_restart_without_updates_file_option="${display_accessory_restart_without_updates_file_local}"
	[[ -n "${display_help_button_string_managed}" ]] && display_help_button_string_option="${display_help_button_string_managed}"
	{ [[ -z "${display_help_button_string_managed}" ]] && [[ -z "${display_help_button_string_option}" ]] && [[ -n "${display_help_button_string_local}" ]]; } && display_help_button_string_option="${display_help_button_string_local}"
	[[ -n "${display_warning_button_string_managed}" ]] && display_warning_button_string_option="${display_warning_button_string_managed}"
	{ [[ -z "${display_warning_button_string_managed}" ]] && [[ -z "${display_warning_button_string_option}" ]] && [[ -n "${display_warning_button_string_local}" ]]; } && display_warning_button_string_option="${display_warning_button_string_local}"
	[[ -n "${auth_user_save_password_managed}" ]] && auth_ask_user_to_save_password="${auth_user_save_password_managed}"
	{ [[ -z "${auth_user_save_password_managed}" ]] && [[ -z "${auth_ask_user_to_save_password}" ]] && [[ -n "${auth_user_save_password_local}" ]]; } && auth_ask_user_to_save_password="${auth_user_save_password_local}"
	[[ -n "${auth_jamf_computer_id_managed}" ]] && auth_jamf_computer_id_option="${auth_jamf_computer_id_managed}"
	{ [[ -z "${auth_jamf_computer_id_managed}" ]] && [[ -z "${auth_jamf_computer_id_option}" ]] && [[ -n "${auth_jamf_computer_id_local}" ]]; } && auth_jamf_computer_id_option="${auth_jamf_computer_id_local}"
	[[ -n "${auth_jamf_custom_url_managed}" ]] && auth_jamf_custom_url_option="${auth_jamf_custom_url_managed}"
	{ [[ -z "${auth_jamf_custom_url_managed}" ]] && [[ -z "${auth_jamf_custom_url_option}" ]] && [[ -n "${auth_jamf_custom_url_local}" ]]; } && auth_jamf_custom_url_option="${auth_jamf_custom_url_local}"
	[[ -n "${auth_credential_failover_to_user_managed}" ]] && auth_credential_failover_to_user_option="${auth_credential_failover_to_user_managed}"
	{ [[ -z "${auth_credential_failover_to_user_managed}" ]] && [[ -z "${auth_credential_failover_to_user_option}" ]] && [[ -n "${auth_credential_failover_to_user_local}" ]]; } && auth_credential_failover_to_user_option="${auth_credential_failover_to_user_local}"
	[[ -n "${auth_mdm_failover_to_user_managed}" ]] && auth_mdm_failover_to_user_option="${auth_mdm_failover_to_user_managed}"
	{ [[ -z "${auth_mdm_failover_to_user_managed}" ]] && [[ -z "${auth_mdm_failover_to_user_option}" ]] && [[ -n "${auth_mdm_failover_to_user_local}" ]]; } && auth_mdm_failover_to_user_option="${auth_mdm_failover_to_user_local}"
	[[ -n "${test_mode_managed}" ]] && test_mode_option="${test_mode_managed}"
	{ [[ -z "${test_mode_managed}" ]] && [[ -z "${test_mode_option}" ]] && [[ -n "${test_mode_local}" ]]; } && test_mode_option="${test_mode_local}"
	[[ -n "${test_mode_timeout_managed}" ]] && test_mode_timeout_option="${test_mode_timeout_managed}"
	{ [[ -z "${test_mode_timeout_managed}" ]] && [[ -z "${test_mode_timeout_option}" ]] && [[ -n "${test_mode_timeout_local}" ]]; } && test_mode_timeout_option="${test_mode_timeout_local}"
	[[ -n "${test_storage_update_managed}" ]] && test_storage_update_option="${test_storage_update_managed}"
	{ [[ -z "${test_storage_update_managed}" ]] && [[ -z "${test_storage_update_option}" ]] && [[ -n "${test_storage_update_local}" ]]; } && test_storage_update_option="${test_storage_update_local}"
	[[ -n "${test_storage_upgrade_managed}" ]] && test_storage_upgrade_option="${test_storage_upgrade_managed}"
	{ [[ -z "${test_storage_upgrade_managed}" ]] && [[ -z "${test_storage_upgrade_option}" ]] && [[ -n "${test_storage_upgrade_local}" ]]; } && test_storage_upgrade_option="${test_storage_upgrade_local}"
	[[ -n "${test_battery_level_managed}" ]] && test_battery_level_option="${test_battery_level_managed}"
	{ [[ -z "${test_battery_level_managed}" ]] && [[ -z "${test_battery_level_option}" ]] && [[ -n "${test_battery_level_local}" ]]; } && test_battery_level_option="${test_battery_level_local}"
}

# Validate non-authentication parameters and manage ${SUPER_LOCAL_PLIST}. Any errors set ${option_error}.
manage_parameter_options() {
	option_error="FALSE"
	
	# Manage ${install_macos_major_upgrades} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${install_macos_major_upgrades}" -eq 1 ]] || [[ "${install_macos_major_upgrades}" == "TRUE" ]]; then
		install_macos_major_upgrades="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" InstallMacOSMajorUpgrades -bool true
	else
		install_macos_major_upgrades="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" InstallMacOSMajorUpgrades 2>/dev/null
	fi
	
	# Validate ${install_macos_major_version_target_option} and if a valid set ${install_macos_major_upgrades_target} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${install_macos_major_version_target_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --install-macos-major-version-target option, defaulting to the newest compatible major macOS version."
		defaults delete "${SUPER_LOCAL_PLIST}" InstallMacOSMajorVersionTarget 2>/dev/null
		unset install_macos_major_version_target_option
	elif [[ -n "${install_macos_major_version_target_option}" ]] && ! [[ "${install_macos_major_version_target_option}" =~ ${REGEX_MACOS_MAJOR_VERSION} ]]; then
		log_super "Parameter Error: The --install-macos-major-version-target=number value must be a contemporary macOS major version number (12,13,etc.)."
		option_error="TRUE"
	elif [[ -n "${install_macos_major_version_target_option}" ]] && [[ "${install_macos_major_version_target_option}" =~ ${REGEX_MACOS_MAJOR_VERSION} ]]; then
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]]; then
			install_macos_major_upgrades_target="${install_macos_major_version_target_option}"
			defaults write "${SUPER_LOCAL_PLIST}" InstallMacOSMajorVersionTarget -string "${install_macos_major_upgrades_target}"
		else
			log_super "Parameter Error: To use the --install-macos-major-version-target option you must also use the --install-macos-major-upgrades option."
			option_error="TRUE"
			defaults delete "${SUPER_LOCAL_PLIST}" InstallMacOSMajorVersionTarget 2>/dev/null
		fi
	fi
	
	# Manage the ${install_macos_major_upgrades} and ${install_macos_major_upgrades_target} if it's less than or the same as the current macOS ${macos_version_major}.
	if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ -n "${install_macos_major_upgrades_target}" ]] && [[ "${install_macos_major_upgrades_target}" -le "${macos_version_major}" ]]; then
		[[ "${install_macos_major_upgrades_target}" -lt "${macos_version_major}" ]] && log_super "Parameter Warning: The --install-macos-major-version-target=${install_macos_major_upgrades_target} option is less than current macOS ${macos_version_major}. Disabling macOS major upgrade workflow."
		[[ "${install_macos_major_upgrades_target}" -eq "${macos_version_major}" ]] && log_super "Status: The --install-macos-major-version-target=${install_macos_major_upgrades_target} option is the same as current macOS ${macos_version_major}. Disabling macOS major upgrade workflow."
		install_macos_major_upgrades="FALSE"
		unset install_macos_major_upgrades_target
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_major_upgrades is: ${install_macos_major_upgrades}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_major_upgrades_target is: ${install_macos_major_upgrades_target}"
	
	# Manage ${install_rapid_security_responses_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${install_rapid_security_responses_option}" -eq 1 ]] || [[ "${install_rapid_security_responses_option}" == "TRUE" ]]; then
		install_rapid_security_responses_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" InstallRapidSecurityResponses -bool true
	else
		install_rapid_security_responses_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" InstallRapidSecurityResponses 2>/dev/null
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${install_rapid_security_responses_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_rapid_security_responses_option is: ${install_rapid_security_responses_option}"
	
	# Manage ${install_non_system_updates_without_restarting_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${install_non_system_updates_without_restarting_option}" -eq 1 ]] || [[ "${install_non_system_updates_without_restarting_option}" == "TRUE" ]]; then
		install_non_system_updates_without_restarting_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" InstallNonSystemUpdatesWithoutRestarting -bool true
	else
		install_non_system_updates_without_restarting_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" InstallNonSystemUpdatesWithoutRestarting 2>/dev/null
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${install_non_system_updates_without_restarting_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_non_system_updates_without_restarting_option is: ${install_non_system_updates_without_restarting_option}"
	
	# Validate ${install_jamf_policy_triggers_option} input and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${install_jamf_policy_triggers_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --install-jamf-policy-triggers option."
		defaults delete "${SUPER_LOCAL_PLIST}" InstallJamfPolicyTriggers 2>/dev/null
		unset install_jamf_policy_triggers_option
	elif [[ -n "${install_jamf_policy_triggers_option}" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" InstallJamfPolicyTriggers -string "${install_jamf_policy_triggers_option}"
	fi
	if [[ ! -f "${JAMF_PRO_BINARY}" ]] && [[ -n "${install_jamf_policy_triggers_option}" ]]; then
		log_super "Parameter Error: Unable to use the --install-jamf-policy-triggers option due to missing Jamf binary."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${install_jamf_policy_triggers_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_jamf_policy_triggers_option is: ${install_jamf_policy_triggers_option}"
	
	# Manage ${install_jamf_policy_triggers_without_restarting_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${install_jamf_policy_triggers_without_restarting_option}" -eq 1 ]] || [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]]; then
		install_jamf_policy_triggers_without_restarting_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" InstallJamfPolicyTriggersWithoutRestarting -bool true
	else
		install_jamf_policy_triggers_without_restarting_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" InstallJamfPolicyTriggersWithoutRestarting 2>/dev/null
	fi
	if [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]] && [[ -z "${install_jamf_policy_triggers_option}" ]]; then
		log_super "Parameter Parameter Warning: The --install-jamf-policy-triggers-without-restarting only works if you also set the --install-jamf-policy-triggers option."
		install_jamf_policy_triggers_without_restarting_option="FALSE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${install_jamf_policy_triggers_without_restarting_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_jamf_policy_triggers_without_restarting_option is: ${install_jamf_policy_triggers_without_restarting_option}"
	
	# Manage ${workflow_install_now_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${workflow_install_now_option}" -eq 1 ]] || [[ "${workflow_install_now_option}" == "TRUE" ]]; then
		workflow_install_now_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowInstallNow -bool true
	else
		workflow_install_now_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowInstallNow 2>/dev/null
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_install_now_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_now_option is: ${workflow_install_now_option}"
	
	# Manage ${workflow_only_download_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${workflow_only_download_option}" -eq 1 ]] || [[ "${workflow_only_download_option}" == "TRUE" ]]; then
		workflow_only_download_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowOnlyDownload -bool true
	else
		workflow_only_download_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowOnlyDownload 2>/dev/null
	fi
	if [[ "${workflow_install_now_option}" == "TRUE" ]] && [[ "${workflow_only_download_option}" == "TRUE" ]]; then
		log_super "Parameter Warning: When both the --workflow-install-now and the --workflow-only-download options are enabled the --workflow-install-now option takes priority."
		workflow_only_download_option="FALSE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_only_download_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_only_download_option is: ${workflow_only_download_option}"
	
	# Manage ${workflow_restart_without_updates_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${workflow_restart_without_updates_option}" -eq 1 ]] || [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then
		workflow_restart_without_updates_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowRestartWithoutUpdates -bool true
	else
		workflow_restart_without_updates_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowRestartWithoutUpdates 2>/dev/null
	fi
	if [[ "${workflow_only_download_option}" == "TRUE" ]] && [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then
		log_super "Parameter Error: The --workflow-restart-without-updates option can not be used with the --only-download option."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_restart_without_updates_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_restart_without_updates_option is: ${workflow_restart_without_updates_option}"
	
	# Manage ${workflow_disable_update_check_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${workflow_disable_update_check_option}" -eq 1 ]] || [[ "${workflow_disable_update_check_option}" == "TRUE" ]]; then
		workflow_disable_update_check_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowDisableUpdateCheck -bool true
	else
		workflow_disable_update_check_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDisableUpdateCheck 2>/dev/null
	fi
	if [[ "${workflow_only_download_option}" == "TRUE" ]] && [[ "${workflow_disable_update_check_option}" == "TRUE" ]]; then
		log_super "Parameter Error: The --workflow-disable-update-check option can not be used with the --only-download option."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_disable_update_check_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_disable_update_check_option is: ${workflow_disable_update_check_option}"
	
	# Manage ${workflow_disable_relaunch_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${workflow_disable_relaunch_option}" -eq 1 ]] || [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
		workflow_disable_relaunch_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowDisableRelaunch -bool true
	else
		workflow_disable_relaunch_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDisableRelaunch 2>/dev/null
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_disable_relaunch_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_disable_relaunch_option is: ${workflow_disable_relaunch_option}"
	
	# Validate ${deferral_timer_default_option} input and if valid set ${deferral_timer_minutes} and save to ${SUPER_LOCAL_PLIST}. If there is no ${deferral_timer_minutes} then set it to ${DEFERRAL_TIMER_DEFAULT_MINUTES}.
	if [[ "${deferral_timer_default_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deferral-timer-default option, defaulting to ${DEFERRAL_TIMER_DEFAULT_MINUTES} minutes."
		defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerDefault 2>/dev/null
		unset deferral_timer_default_option
	elif [[ -n "${deferral_timer_default_option}" ]] && [[ "${deferral_timer_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${deferral_timer_default_option}" -lt 2 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-default=minutes value of ${deferral_timer_default_option} is too low, rounding up to 2 minutes."
			deferral_timer_minutes=2
		elif [[ "${deferral_timer_default_option}" -gt 10080 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-default=minutes value of ${deferral_timer_default_option} is too high, rounding down to 10080 minutes (1 week)."
			deferral_timer_minutes=10080
		else
			deferral_timer_minutes="${deferral_timer_default_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DeferralTimerDefault -string "${deferral_timer_minutes}"
	elif [[ -n "${deferral_timer_default_option}" ]] && ! [[ "${deferral_timer_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deferral-timer-default=minutes value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${deferral_timer_minutes}" ]] && deferral_timer_minutes="${DEFERRAL_TIMER_DEFAULT_MINUTES}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_minutes is: ${deferral_timer_minutes}"
	
	# Validate ${deferral_timer_menu_option} input and if valid set ${deferral_timer_menu_minutes} and save to ${SUPER_LOCAL_PLIST}.
	local previous_ifs
	if [[ "${deferral_timer_menu_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deferral-timer-menu option, defaulting to ${deferral_timer_minutes} minutes."
		defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerMenu 2>/dev/null
		unset deferral_timer_menu_option
	elif [[ -n "${deferral_timer_menu_option}" ]] && [[ "${deferral_timer_menu_option}" =~ ${REGEX_CSV_WHOLE_NUMBERS} ]]; then
		previous_ifs="${IFS}"
		IFS=','
		local deferral_timer_menu_option_array
		read -r -a deferral_timer_menu_option_array <<<"${deferral_timer_menu_option}"
		for array_index in "${!deferral_timer_menu_option_array[@]}"; do
			if [[ "${deferral_timer_menu_option_array[array_index]}" -lt 2 ]]; then
				log_super "Parameter Warning: Specified --deferral-timer-menu=minutes value of ${deferral_timer_menu_option_array[array_index]} minutes is too low, rounding up to 2 minutes."
				deferral_timer_menu_option_array[array_index]=2
			elif [[ "${deferral_timer_menu_option_array[array_index]}" -gt 10080 ]]; then
				log_super "Parameter Warning: Specified --deferral-timer-menu=minutes value of ${deferral_timer_menu_option_array[array_index]} minutes is too high, rounding down to 10080 minutes (1 week)."
				deferral_timer_menu_option_array[array_index]=10080
			fi
		done
		deferral_timer_menu_minutes="${deferral_timer_menu_option_array[*]}"
		defaults write "${SUPER_LOCAL_PLIST}" DeferralTimerMenu -string "${deferral_timer_menu_minutes}"
		IFS="${previous_ifs}"
	elif [[ -n "${deferral_timer_menu_option}" ]] && ! [[ "${deferral_timer_menu_option}" =~ ${REGEX_CSV_WHOLE_NUMBERS} ]]; then
		log_super "Parameter Error: The --deferral-timer-menu=minutes,minutes,etc... value must only contain numbers and commas (no spaces)."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deferral_timer_menu_minutes}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_menu_minutes is: ${deferral_timer_menu_minutes}"
	
	# Validate ${deferral_timer_focus_option} input and if valid set ${deferral_timer_focus_minutes} and save to ${SUPER_LOCAL_PLIST}. If there is no ${deferral_timer_focus_minutes} then set it to ${deferral_timer_minutes}.
	if [[ "${deferral_timer_focus_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deferral-timer-focus option, defaulting to ${deferral_timer_minutes} minutes."
		defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerFocus 2>/dev/null
		unset deferral_timer_focus_option
	elif [[ -n "${deferral_timer_focus_option}" ]] && [[ "${deferral_timer_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${deferral_timer_focus_option}" -lt 2 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-focus=minutes value of ${deferral_timer_focus_option} minutes is too low, rounding up to 2 minutes."
			deferral_timer_focus_minutes=2
		elif [[ "${deferral_timer_focus_option}" -gt 10080 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-focus=minutes value of ${deferral_timer_focus_option} minutes is too high, rounding down to 1440 minutes (1 week)."
			deferral_timer_focus_minutes=10080
		else
			deferral_timer_focus_minutes="${deferral_timer_focus_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DeferralTimerFocus -string "${deferral_timer_focus_minutes}"
	elif [[ -n "${deferral_timer_focus_option}" ]] && ! [[ "${deferral_timer_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deferral-timer-focus=minutes value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${deferral_timer_focus_minutes}" ]] && deferral_timer_focus_minutes="${deferral_timer_minutes}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_focus_minutes is: ${deferral_timer_focus_minutes}"
	
	# Validate ${deferral_timer_error_option} input and if valid set ${deferral_timer_error_minutes} and save to ${SUPER_LOCAL_PLIST}. If there is no ${deferral_timer_error_minutes} then set it to ${deferral_timer_minutes}.
	if [[ "${deferral_timer_error_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deferral-timer-error option, defaulting to ${deferral_timer_minutes} minutes."
		defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerError 2>/dev/null
		unset deferral_timer_error_option
	elif [[ -n "${deferral_timer_error_option}" ]] && [[ "${deferral_timer_error_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${deferral_timer_error_option}" -lt 2 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-error=minutes value of ${deferral_timer_error_option} minutes is too low, rounding up to 2 minutes."
			deferral_timer_error_minutes=2
		elif [[ "${deferral_timer_error_option}" -gt 10080 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-error=minutes value of ${deferral_timer_error_option} minutes is too high, rounding down to 1440 minutes (1 week)."
			deferral_timer_error_minutes=10080
		else
			deferral_timer_error_minutes="${deferral_timer_error_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DeferralTimerError -string "${deferral_timer_error_minutes}"
	elif [[ -n "${deferral_timer_error_option}" ]] && ! [[ "${deferral_timer_error_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deferral-timer-error=minutes value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${deferral_timer_error_minutes}" ]] && deferral_timer_error_minutes="${deferral_timer_minutes}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_error_minutes is: ${deferral_timer_error_minutes}"
	
	# Validate ${deferral_timer_workflow_relaunch_option} input and if valid set ${deferral_timer_workflow_relaunch_minutes} and save to ${SUPER_LOCAL_PLIST}. If there is no ${deferral_timer_workflow_relaunch_minutes} then set it to ${DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES}.
	if [[ "${deferral_timer_workflow_relaunch_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deferral-timer-workflow-relaunch option, defaulting to ${DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES} minutes."
		defaults delete "${SUPER_LOCAL_PLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null
		unset deferral_timer_workflow_relaunch_option
	elif [[ -n "${deferral_timer_workflow_relaunch_option}" ]] && [[ "${deferral_timer_workflow_relaunch_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${deferral_timer_workflow_relaunch_option}" -lt 2 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-workflow-relaunch=minutes value of ${deferral_timer_workflow_relaunch_option} minutes is too low, rounding up to 2 minutes."
			deferral_timer_workflow_relaunch_minutes=2
		elif [[ "${deferral_timer_workflow_relaunch_option}" -gt 43200 ]]; then
			log_super "Parameter Warning: Specified --deferral-timer-workflow-relaunch=minutes value of ${deferral_timer_workflow_relaunch_option} minutes is too high, rounding down to 43200 minutes (30 days)."
			deferral_timer_workflow_relaunch_minutes=43200
		else
			deferral_timer_workflow_relaunch_minutes="${deferral_timer_workflow_relaunch_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DeferralTimerWorkflowRelaunch -string "${deferral_timer_workflow_relaunch_minutes}"
	elif [[ -n "${deferral_timer_workflow_relaunch_option}" ]] && ! [[ "${deferral_timer_workflow_relaunch_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deferral-timer-workflow-relaunch=minutes value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${deferral_timer_workflow_relaunch_minutes}" ]] && deferral_timer_workflow_relaunch_minutes="${DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_workflow_relaunch_minutes is: ${deferral_timer_workflow_relaunch_minutes}"
	
	# Manage ${schedule_workflow_active_option} and save to ${SUPER_LOCAL_PLIST}.
	local extract_weekday
	local extract_time
	if [[ "${schedule_workflow_active_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --schedule-workflow-active option, defaulting to workflow is always active."
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduleWorkflowActive 2>/dev/null
		unset schedule_workflow_active_option
	elif [[ -n "${schedule_workflow_active_option}" ]]; then
		previous_ifs="${IFS}"
		IFS=','
		read -r -a schedule_workflow_active_array <<<"${schedule_workflow_active_option}"
		for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
			extract_weekday="${schedule_workflow_active_time_frame:0:3}"
			if ! [[ "${extract_weekday}" =~ ${REGEX_WEEKDAY} ]]; then
				log_super "Parameter Error: Unrecognized --schedule-workflow-active weekday of ${extract_weekday}. The weekdays must be specified as MON|TUE|WED|THU|FRI|SAT|SUN."
				option_error="TRUE"
			fi
			extract_time="${schedule_workflow_active_time_frame:4:11}"
			if ! [[ "${extract_time}" =~ ${REGEX_HOURS_MINUTES_RANGE} ]]; then
				log_super "Parameter Error: Each --schedule-workflow-active time frame value must be formated in 24-hour time as hh:mm-hh:mm."
				option_error="TRUE"
			fi
			if ! [[ "${schedule_workflow_active_time_frame}" =~ ${REGEX_schedule_workflow_active_time_frame} ]]; then
				log_super "Parameter Error: Each --schedule-workflow-active weekday and time frame must be formated as DAY:hh:mm-hh:mm."
				option_error="TRUE"
			fi
		done
		IFS="${previous_ifs}"
		if [[ "${option_error}" != "TRUE" ]]; then
			defaults write "${SUPER_LOCAL_PLIST}" ScheduleWorkflowActive -string "${schedule_workflow_active_option}"
		else
			unset schedule_workflow_active_option
		fi
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${schedule_workflow_active_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_option is: ${schedule_workflow_active_option}"
	
	# Manage ${schedule_zero_date_release_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${schedule_zero_date_release_option}" -eq 1 ]] || [[ "${schedule_zero_date_release_option}" == "TRUE" ]]; then
		schedule_zero_date_release_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" ScheduleZeroDateRelease -bool true
	else
		schedule_zero_date_release_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateRelease 2>/dev/null
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${schedule_zero_date_release_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_release_option is: ${schedule_zero_date_release_option}"
	
	# Validate ${schedule_zero_date_sofa_custom_url_option} input and save to ${SUPER_LOCAL_PLIST}. This also sets ${sofa_macos_url}.
	if [[ "${schedule_zero_date_sofa_custom_url_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --schedule-zero-date-sofa-custom-url option, now usign the default SOFA macOS releases feed at ${SOFA_MACOS_DEFAULT_URL}."
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateSOFACustomURL 2>/dev/null
		unset schedule_zero_date_sofa_custom_url_option
	elif [[ -n "${schedule_zero_date_sofa_custom_url_option}" ]] && ! [[ "${schedule_zero_date_sofa_custom_url_option}" =~ ${REGEX_HTTPS} ]]; then
		log_super "Parameter Error: Invalid ---schedule-zero-date-sofa-custom-url VALUE must start with 'https://': ${schedule_zero_date_sofa_custom_url_option}"
		option_error="TRUE"
	elif [[ -n "${schedule_zero_date_sofa_custom_url_option}" ]] && [[ "${schedule_zero_date_sofa_custom_url_option}" =~ ${REGEX_HTTPS} ]]; then
		if [[ "${schedule_zero_date_release_option}" == "TRUE" ]]; then
			defaults write "${SUPER_LOCAL_PLIST}" ScheduleZeroDateSOFACustomURL -string "${schedule_zero_date_sofa_custom_url_option}"
			sofa_macos_url="${schedule_zero_date_sofa_custom_url_option}"
		else
			log_super "Parameter Error: To use the --schedule-zero-date-sofa-custom-url option you must also use the --schedule-zero-date-release option."
			option_error="TRUE"
			defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateSOFACustomURL 2>/dev/null
		fi
	fi
	[[ -z "${sofa_macos_url}" ]] && sofa_macos_url="${SOFA_MACOS_DEFAULT_URL}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${sofa_macos_url}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: sofa_macos_url is: ${sofa_macos_url}"
	
	# Validate ${schedule_zero_date_manual_option} and if valid set ${schedule_zero_date_manual} and save to ${SUPER_LOCAL_PLIST}.
	local extract_date
	local sanitized_date
	local extract_hours
	local extract_minutes
	if [[ "${schedule_zero_date_manual_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --schedule-zero-date-manual option, defaulting to an automatic zero date."
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateManual 2>/dev/null
		unset schedule_zero_date_manual_option
	elif [[ -n "${schedule_zero_date_manual_option}" ]]; then
		extract_date="${schedule_zero_date_manual_option:0:10}"
		if [[ "${extract_date}" =~ ${REGEX_DATE} ]]; then
			extract_time="${schedule_zero_date_manual_option:11:5}"
			if [[ -n "${extract_time}" ]]; then
				extract_hours="${extract_time:0:2}"
				[[ -z "${extract_hours}" ]] && extract_hours="00"
				extract_minutes="${extract_time:3:2}"
				[[ -z "${extract_minutes}" ]] && extract_minutes="00"
				extract_time="${extract_hours}:${extract_minutes}"
			else
				extract_time="00:00"
			fi
			if [[ "${extract_time}" =~ ${REGEX_HOURS_MINUTES} ]]; then
				sanitized_date="${extract_date}:${extract_time}"
			else
				log_super "Parameter Error: The --schedule-zero-date-manual value for time must be formated in 24-hour time as hh:mm."
				option_error="TRUE"
			fi
		else
			log_super "Parameter Error: The --schedule-zero-date-manual value for date must be formated as YYYY-MM-DD."
			option_error="TRUE"
		fi
		if [[ "${sanitized_date}" =~ ${REGEX_DATE_HOURS_MINUTES} ]]; then
			schedule_zero_date_manual="${sanitized_date}"
			defaults write "${SUPER_LOCAL_PLIST}" ScheduleZeroDateManual -string "${schedule_zero_date_manual}"
		else
			log_super "Parameter Error: The --schedule-zero-date-manual value must be formatted as YYYY-MM-DD:hh:mm."
			option_error="TRUE"
		fi
	fi
	if [[ -n "${schedule_zero_date_manual}" ]] && [[ "${schedule_zero_date_release_option}" == "TRUE" ]]; then
		log_super "Parameter Warning: When both the --schedule-zero-date-manual and the --schedule-zero-date-release options are enabled the --schedule-zero-date-manual option takes priority."
		schedule_zero_date_release_option="FALSE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${schedule_zero_date_manual}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_manual is: ${schedule_zero_date_manual}"
	
	# Validate ${scheduled_install_days_option} input and if valid set ${scheduled_install_days}.
	if [[ "${scheduled_install_days_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --scheduled-install-days option."
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallDays 2>/dev/null
		unset scheduled_install_days_option
	elif [[ -n "${scheduled_install_days_option}" ]] && [[ "${scheduled_install_days_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		scheduled_install_days="${scheduled_install_days_option}"
	elif [[ -n "${scheduled_install_days_option}" ]] && ! [[ "${scheduled_install_days_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --scheduled-install-days=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validate ${scheduled_install_date_option}, if valid set ${scheduled_install_date} and ${scheduled_install_date_epoch}.
	if [[ "${scheduled_install_date_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --scheduled-install-date option."
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallDate 2>/dev/null
		unset scheduled_install_date_option
	elif [[ -n "${scheduled_install_date_option}" ]]; then
		extract_date="${scheduled_install_date_option:0:10}"
		if [[ "${extract_date}" =~ ${REGEX_DATE} ]]; then
			extract_time="${scheduled_install_date_option:11:5}"
			if [[ -n "${extract_time}" ]]; then
				extract_hours="${extract_time:0:2}"
				[[ -z "${extract_hours}" ]] && extract_hours="00"
				extract_minutes="${extract_time:3:2}"
				[[ -z "${extract_minutes}" ]] && extract_minutes="00"
				extract_time="${extract_hours}:${extract_minutes}"
			else
				extract_time="00:00"
			fi
			if [[ "${extract_time}" =~ ${REGEX_HOURS_MINUTES} ]]; then
				sanitized_date="${extract_date}:${extract_time}"
			else
				log_super "Parameter Error: The --scheduled-install-date value for time must be formated in 24-hour time as hh:mm."
				option_error="TRUE"
			fi
		else
			log_super "Parameter Error: The --scheduled-install-date value for date must be formated as YYYY-MM-DD."
			option_error="TRUE"
		fi
		if [[ "${sanitized_date}" =~ ${REGEX_DATE_HOURS_MINUTES} ]]; then
			scheduled_install_date="${sanitized_date}"
		else
			log_super "Parameter Error: The --scheduled-install-date value must be formatted as YYYY-MM-DD:hh:mm."
			option_error="TRUE"
		fi
	fi
	
	# Manage ${scheduled_install_user_choice_option}.
	if [[ "${scheduled_install_user_choice_option}" -eq 1 ]] || [[ "${scheduled_install_user_choice_option}" == "TRUE" ]]; then
		scheduled_install_user_choice_option="TRUE"
	else
		scheduled_install_user_choice_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallUserChoice 2>/dev/null
	fi
	
	# Validated that ${scheduled_install_days}, ${scheduled_install_date}, and ${scheduled_install_user_choice_option} are not simultaneously active, if not then save the active scheduled restart to ${SUPER_LOCAL_PLIST}.
	local scheduled_install_option_counter
	scheduled_install_option_counter=0
	[[ -n "${scheduled_install_days}" ]] && ((scheduled_install_option_counter++))
	[[ -n "${scheduled_install_date}" ]] && ((scheduled_install_option_counter++))
	[[ "${scheduled_install_user_choice_option}" == "TRUE" ]] && ((scheduled_install_option_counter++))
	if [[ "${scheduled_install_option_counter}" -eq 1 ]]; then
		[[ -n "${scheduled_install_days}" ]] && defaults write "${SUPER_LOCAL_PLIST}" ScheduledInstallDays -string "${scheduled_install_days}"
		[[ -n "${scheduled_install_date}" ]] && defaults write "${SUPER_LOCAL_PLIST}" ScheduledInstallDate -string "${scheduled_install_date}"
		[[ "${scheduled_install_user_choice_option}" == "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" ScheduledInstallUserChoice -bool true
	elif [[ "${scheduled_install_option_counter}" -gt 1 ]]; then
		log_super "Parameter Error: You can only use one of the following scheduled restart options at a time: --scheduled-install-days, --scheduled-install-date, or --scheduled-install-user-choice."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${scheduled_install_option_counter}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_option_counter is: ${scheduled_install_option_counter}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${scheduled_install_days}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_days is: ${scheduled_install_days}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${scheduled_install_date}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_date is: ${scheduled_install_date}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${scheduled_install_user_choice_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_option is: ${scheduled_install_user_choice_option}"
	
	# Validate ${scheduled_install_reminder_option} input and if valid set ${scheduled_install_reminder_minutes} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${scheduled_install_reminder_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --scheduled-install-reminder option, defaulting to no warning prior to a scheduled restart."
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduledInstallReminder 2>/dev/null
		unset scheduled_install_reminder_option
	elif [[ -n "${scheduled_install_reminder_option}" ]] && [[ "${scheduled_install_reminder_option}" =~ ${REGEX_CSV_WHOLE_NUMBERS} ]]; then
		if [[ "${scheduled_install_option_counter}" -eq 0 ]]; then
			log_super "Parameter Error: The --scheduled-install-reminder=minutes option requires that you also set one of the following options: --scheduled-install-days, --scheduled-install-date, or --scheduled-install-user-choice."
			option_error="TRUE"
		else
			previous_ifs="${IFS}"
			IFS=','
			local scheduled_install_reminder_array
			read -r -a scheduled_install_reminder_array <<<"${scheduled_install_reminder_option}"
			for array_index in "${!scheduled_install_reminder_array[@]}"; do
				if [[ "${scheduled_install_reminder_array[array_index]}" -lt 2 ]]; then
					log_super "Parameter Warning: Specified --scheduled-install-reminder=minutes value of ${scheduled_install_reminder_array[array_index]} minutes is too low, rounding up to 2 minutes."
					scheduled_install_reminder_array[array_index]=2
				elif [[ "${scheduled_install_reminder_array[array_index]}" -gt 10080 ]]; then
					log_super "Parameter Warning: Specified --scheduled-install-reminder=minutes value of ${scheduled_install_reminder_array[array_index]} minutes is too high, rounding down to 10080 minutes (1 week)."
					scheduled_install_reminder_array[array_index]=10080
				fi
			done
			scheduled_install_reminder_minutes=$(echo "${scheduled_install_reminder_array[*]}" | sed -e $'s/,/\\\n/g' | sort -n -r | tr '\n' ',' | sed 's/.$//')
			defaults write "${SUPER_LOCAL_PLIST}" ScheduledInstallReminder -string "${scheduled_install_reminder_minutes}"
			IFS="${previous_ifs}"
		fi
	elif [[ -n "${scheduled_install_reminder_option}" ]] && ! [[ "${scheduled_install_reminder_option}" =~ ${REGEX_CSV_WHOLE_NUMBERS} ]]; then
		log_super "Parameter Error: The --scheduled-install-reminder=minutes,minutes,etc... value must only contain numbers and commas (no spaces)."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${scheduled_install_reminder_minutes}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_reminder_minutes is: ${scheduled_install_reminder_minutes}"
	
	# Validate ${deadline_count_focus_option} input and if valid set ${deadline_count_focus} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${deadline_count_focus_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-count-focus option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCountFocus 2>/dev/null
		unset deadline_count_focus_option
	elif [[ -n "${deadline_count_focus_option}" ]] && [[ "${deadline_count_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		deadline_count_focus="${deadline_count_focus_option}"
		defaults write "${SUPER_LOCAL_PLIST}" DeadlineCountFocus -string "${deadline_count_focus}"
	elif [[ -n "${deadline_count_focus_option}" ]] && ! [[ "${deadline_count_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deadline-count-focus=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validate ${deadline_count_soft_option} input and if valid set ${deadline_count_soft}.
	if [[ "${deadline_count_soft_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-count-soft option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCountSoft 2>/dev/null
		unset deadline_count_soft_option
	elif [[ -n "${deadline_count_soft_option}" ]] && [[ "${deadline_count_soft_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		deadline_count_soft="${deadline_count_soft_option}"
	elif [[ -n "${deadline_count_soft_option}" ]] && ! [[ "${deadline_count_soft_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deadline-count-soft=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validate ${deadline_count_hard_option} input and if valid set ${deadline_count_hard}.
	if [[ "${deadline_count_hard_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-count-hard option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCountHard 2>/dev/null
		unset deadline_count_hard_option
	elif [[ -n "${deadline_count_hard_option}" ]] && [[ "${deadline_count_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		deadline_count_hard="${deadline_count_hard_option}"
	elif [[ -n "${deadline_count_hard_option}" ]] && ! [[ "${deadline_count_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deadline-count-hard=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validated that ${deadline_count_soft} and ${deadline_count_hard} are not both active, if not then save ${deadline_count_soft} or ${deadline_count_hard} to ${SUPER_LOCAL_PLIST}.
	if [[ -n "${deadline_count_soft}" ]] && [[ -n "${deadline_count_hard}" ]]; then
		log_super "Parameter Error: You can not use both the --deadline-count-soft and --deadline-count-hard options at the same time. You must pick one deadline count behavior."
		option_error="TRUE"
	else
		[[ -n "${deadline_count_soft}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineCountSoft -string "${deadline_count_soft}"
		[[ -n "${deadline_count_hard}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineCountHard -string "${deadline_count_hard}"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_count_focus}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_count_focus is: ${deadline_count_focus}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_count_soft}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_count_soft is: ${deadline_count_soft}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_count_hard}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_count_hard is: ${deadline_count_hard}"
	
	# Validate ${deadline_days_focus_option} input and if valid set ${deadline_days_focus}.
	if [[ "${deadline_days_focus_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-days-focus option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysFocus 2>/dev/null
		unset deadline_days_focus_option
	elif [[ -n "${deadline_days_focus_option}" ]] && [[ "${deadline_days_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		deadline_days_focus="${deadline_days_focus_option}"
	elif [[ -n "${deadline_days_focus_option}" ]] && ! [[ "${deadline_days_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deadline-days-focus=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validate ${deadline_days_soft_option} input and if valid set ${deadline_days_soft}.
	if [[ "${deadline_days_soft_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-days-soft option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysSoft 2>/dev/null
		unset deadline_days_soft_option
	elif [[ -n "${deadline_days_soft_option}" ]] && [[ "${deadline_days_soft_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		deadline_days_soft="${deadline_days_soft_option}"
	elif [[ -n "${deadline_days_soft_option}" ]] && ! [[ "${deadline_days_soft_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deadline-days-soft=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validate ${deadline_days_hard_option} input and if valid set ${deadline_days_hard}.
	if [[ "${deadline_days_hard_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-days-hard option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysHard 2>/dev/null
		unset deadline_days_hard_option
	elif [[ -n "${deadline_days_hard_option}" ]] && [[ "${deadline_days_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		deadline_days_hard="${deadline_days_hard_option}"
	elif [[ -n "${deadline_days_hard_option}" ]] && ! [[ "${deadline_days_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --deadline-days-hard=number value must only be a number."
		option_error="TRUE"
	fi
	
	# Validate ${deadline_days_focus}, ${deadline_days_soft}, and ${deadline_days_hard} in relation to each other, and if valid save to ${SUPER_LOCAL_PLIST}.
	if [[ -n "${deadline_days_hard}" ]] && [[ -n "${deadline_days_soft}" ]] && [[ "${deadline_days_hard}" -le "${deadline_days_soft}" ]]; then
		log_super "Parameter Error: The --deadline-days-hard=number value of ${deadline_days_hard} day(s) must be more than the --deadline-days-soft=number value of ${deadline_days_soft} day(s)."
		option_error="TRUE"
	fi
	if [[ -n "${deadline_days_hard}" ]] && [[ -n "${deadline_days_focus}" ]] && [[ "${deadline_days_hard}" -le "${deadline_days_focus}" ]]; then
		log_super "Parameter Error: The --deadline-days-hard=number value of ${deadline_days_hard} day(s) must be more than the --deadline-days-focus=number value of ${deadline_days_focus} day(s)."
		option_error="TRUE"
	fi
	if [[ -n "${deadline_days_soft}" ]] && [[ -n "${deadline_days_focus}" ]] && [[ "${deadline_days_soft}" -le "${deadline_days_focus}" ]]; then
		log_super "Parameter Error: The --deadline-days-soft=number value of ${deadline_days_soft} day(s) must be more than the --deadline-days-focus=number value of ${deadline_days_focus} day(s)."
		option_error="TRUE"
	fi
	if [[ "${option_error}" != "TRUE" ]]; then
		[[ -n "${deadline_days_focus}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineDaysFocus -string "${deadline_days_focus}"
		[[ -n "${deadline_days_soft}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineDaysSoft -string "${deadline_days_soft}"
		[[ -n "${deadline_days_hard}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineDaysHard -string "${deadline_days_hard}"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_days_focus}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_focus is: ${deadline_days_focus}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_days_soft}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_soft is: ${deadline_days_soft}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_days_hard}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_hard is: ${deadline_days_hard}"
	
	# Validate ${deadline_date_focus_option}, if valid set ${deadline_date_focus} and ${deadline_date_focus_epoch}.
	if [[ "${deadline_date_focus_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-date-focus option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDateFocus 2>/dev/null
		unset deadline_date_focus_option
	elif [[ -n "${deadline_date_focus_option}" ]]; then
		extract_date="${deadline_date_focus_option:0:10}"
		if [[ "${extract_date}" =~ ${REGEX_DATE} ]]; then
			extract_time="${deadline_date_focus_option:11:5}"
			if [[ -n "${extract_time}" ]]; then
				extract_hours="${extract_time:0:2}"
				[[ -z "${extract_hours}" ]] && extract_hours="00"
				extract_minutes="${extract_time:3:2}"
				[[ -z "${extract_minutes}" ]] && extract_minutes="00"
				extract_time="${extract_hours}:${extract_minutes}"
			else
				extract_time="00:00"
			fi
			if [[ "${extract_time}" =~ ${REGEX_HOURS_MINUTES} ]]; then
				sanitized_date="${extract_date}:${extract_time}"
			else
				log_super "Parameter Error: The --deadline-date-focus value for time must be formated in 24-hour time as hh:mm."
				option_error="TRUE"
			fi
		else
			log_super "Parameter Error: The --deadline-date-focus value for date must be formated as YYYY-MM-DD."
			option_error="TRUE"
		fi
		if [[ "${sanitized_date}" =~ ${REGEX_DATE_HOURS_MINUTES} ]]; then
			deadline_date_focus="${sanitized_date}"
			deadline_date_focus_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${sanitized_date}:00" +%s)
		else
			log_super "Parameter Error: The --deadline-date-focus value must be formatted as YYYY-MM-DD:hh:mm."
			option_error="TRUE"
		fi
	fi
	
	# Validate ${deadline_date_soft_option}, if valid set ${deadline_date_soft} and ${deadline_date_soft_epoch}.
	if [[ "${deadline_date_soft_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-date-soft option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDateSoft 2>/dev/null
		unset deadline_date_soft_option
	elif [[ -n "${deadline_date_soft_option}" ]]; then
		extract_date="${deadline_date_soft_option:0:10}"
		if [[ "${extract_date}" =~ ${REGEX_DATE} ]]; then
			extract_time="${deadline_date_soft_option:11:5}"
			if [[ -n "${extract_time}" ]]; then
				extract_hours="${extract_time:0:2}"
				[[ -z "${extract_hours}" ]] && extract_hours="00"
				extract_minutes="${extract_time:3:2}"
				[[ -z "${extract_minutes}" ]] && extract_minutes="00"
				extract_time="${extract_hours}:${extract_minutes}"
			else
				extract_time="00:00"
			fi
			if [[ "${extract_time}" =~ ${REGEX_HOURS_MINUTES} ]]; then
				sanitized_date="${extract_date}:${extract_time}"
			else
				log_super "Parameter Error: The --deadline-date-soft value for time must be formated in 24-hour time as hh:mm."
				option_error="TRUE"
			fi
		else
			log_super "Parameter Error: The --deadline-date-soft value for date must be formated as YYYY-MM-DD."
			option_error="TRUE"
		fi
		if [[ "${sanitized_date}" =~ ${REGEX_DATE_HOURS_MINUTES} ]]; then
			deadline_date_soft="${sanitized_date}"
			deadline_date_soft_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${sanitized_date}:00" +%s)
		else
			log_super "Parameter Error: The --deadline-date-soft value must be formatted as YYYY-MM-DD:hh:mm."
			option_error="TRUE"
		fi
	fi
	
	# Validate ${deadline_date_hard_option}, if valid set ${deadline_date_hard} and ${deadline_date_hard_epoch}.
	if [[ "${deadline_date_hard_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --deadline-date-hard option."
		defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDateHard 2>/dev/null
		unset deadline_date_hard_option
	elif [[ -n "${deadline_date_hard_option}" ]]; then
		extract_date="${deadline_date_hard_option:0:10}"
		if [[ "${extract_date}" =~ ${REGEX_DATE} ]]; then
			extract_time="${deadline_date_hard_option:11:5}"
			if [[ -n "${extract_time}" ]]; then
				extract_hours="${extract_time:0:2}"
				[[ -z "${extract_hours}" ]] && extract_hours="00"
				extract_minutes="${extract_time:3:2}"
				[[ -z "${extract_minutes}" ]] && extract_minutes="00"
				extract_time="${extract_hours}:${extract_minutes}"
			else
				extract_time="00:00"
			fi
			if [[ "${extract_time}" =~ ${REGEX_HOURS_MINUTES} ]]; then
				sanitized_date="${extract_date}:${extract_time}"
			else
				log_super "Parameter Error: The --deadline-date-hard value for time must be formated in 24-hour time as hh:mm."
				option_error="TRUE"
			fi
		else
			log_super "Parameter Error: The --deadline-date-hard value for date must be formated as YYYY-MM-DD."
			option_error="TRUE"
		fi
		if [[ "${sanitized_date}" =~ ${REGEX_DATE_HOURS_MINUTES} ]]; then
			deadline_date_hard="${sanitized_date}"
			deadline_date_hard_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${sanitized_date}:00" +%s)
		else
			log_super "Parameter Error: The --deadline-date-hard value must be formatted as YYYY-MM-DD:hh:mm."
			option_error="TRUE"
		fi
	fi
	
	# Validate ${deadline_date_focus_epoch}, ${deadline_date_soft_epoch}, and ${deadline_date_hard_epoch} in relation to each other. If valid then save date deadlines to ${SUPER_LOCAL_PLIST}.
	if [[ -n "${deadline_date_hard_epoch}" ]] && [[ -n "${deadline_date_soft_epoch}" ]] && [[ "${deadline_date_hard_epoch}" -le "${deadline_date_soft_epoch}" ]]; then
		log_super "Parameter Error: The --deadline-date-hard value of ${deadline_date_hard} must be later than the --deadline-date-soft value of ${deadline_date_soft}."
		option_error="TRUE"
	fi
	if [[ -n "${deadline_date_hard_epoch}" ]] && [[ -n "${deadline_date_focus_epoch}" ]] && [[ "${deadline_date_hard_epoch}" -le "${deadline_date_focus_epoch}" ]]; then
		log_super "Parameter Error: The --deadline-date-hard value of ${deadline_date_hard} must be later than --deadline-date-focus value of ${deadline_date_focus}."
		option_error="TRUE"
	fi
	if [[ -n "${deadline_date_soft_epoch}" ]] && [[ -n "${deadline_date_focus_epoch}" ]] && [[ "${deadline_date_soft_epoch}" -le "${deadline_date_focus_epoch}" ]]; then
		log_super "Parameter Error: The --deadline-date-soft value of ${deadline_date_soft} must be later than than --deadline-date-focus value of ${deadline_date_focus}."
		option_error="TRUE"
	fi
	if [[ "${option_error}" != "TRUE" ]]; then
		[[ -n "${deadline_date_focus}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineDateFocus -string "${deadline_date_focus}"
		[[ -n "${deadline_date_soft}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineDateSoft -string "${deadline_date_soft}"
		[[ -n "${deadline_date_hard}" ]] && defaults write "${SUPER_LOCAL_PLIST}" DeadlineDateHard -string "${deadline_date_hard}"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_date_focus}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_focus is: ${deadline_date_focus}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_date_soft}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_soft is: ${deadline_date_soft}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_date_hard}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_hard is: ${deadline_date_hard}"
	
	# Some validation and logging for the focus deferral timer option.
	if [[ -n "${deferral_timer_focus_option}" ]] && { [[ -z "${deadline_count_focus}" ]] && [[ -z "${deadline_days_focus}" ]] && [[ -z "${deadline_date_focus}" ]]; }; then
		log_super "Parameter Error: The --deferral-timer-focus option requires that you also specify at least one focus deadline option."
		option_error="TRUE"
	fi
	
	# Validate ${dialog_timeout_default_option} and if valid set ${dialog_timeout_default_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_default_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-default option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutDefault 2>/dev/null
		unset dialog_timeout_default_option
	elif [[ -n "${dialog_timeout_default_option}" ]] && [[ "${dialog_timeout_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_default_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-default=seconds value of ${dialog_timeout_default_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_default_seconds=60
		elif [[ "${dialog_timeout_default_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-default=seconds value of ${dialog_timeout_default_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_default_seconds=86400
		else
			dialog_timeout_default_seconds="${dialog_timeout_default_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutDefault -string "${dialog_timeout_default_seconds}"
	elif [[ -n "${dialog_timeout_default_option}" ]] && ! [[ "${dialog_timeout_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-default=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_default_seconds is: ${dialog_timeout_default_seconds}"
	
	# Validate ${dialog_timeout_user_auth_option} and if valid set ${dialog_timeout_user_auth_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_user_auth_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-user-auth option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutUserAuth 2>/dev/null
		unset dialog_timeout_user_auth_option
	elif [[ -n "${dialog_timeout_user_auth_option}" ]] && [[ "${dialog_timeout_user_auth_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_user_auth_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-user-auth=seconds value of ${dialog_timeout_user_auth_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_user_auth_seconds=60
		elif [[ "${dialog_timeout_user_auth_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-user-auth=seconds value of ${dialog_timeout_user_auth_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_user_auth_seconds=86400
		else
			dialog_timeout_user_auth_seconds="${dialog_timeout_user_auth_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutUserAuth -string "${dialog_timeout_user_auth_seconds}"
	elif [[ -n "${dialog_timeout_user_auth_option}" ]] && ! [[ "${dialog_timeout_user_auth_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-user-auth=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_user_auth_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_user_auth_seconds is: ${dialog_timeout_user_auth_seconds}"
	
	# Validate ${dialog_timeout_user_choice_option} and if valid set ${dialog_timeout_user_choice_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_user_choice_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-user-choice option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutUserChoice 2>/dev/null
		unset dialog_timeout_user_choice_option
	elif [[ -n "${dialog_timeout_user_choice_option}" ]] && [[ "${dialog_timeout_user_choice_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_user_choice_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-user-choice=seconds value of ${dialog_timeout_user_choice_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_user_choice_seconds=60
		elif [[ "${dialog_timeout_user_choice_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-user-choice=seconds value of ${dialog_timeout_user_choice_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_user_choice_seconds=86400
		else
			dialog_timeout_user_choice_seconds="${dialog_timeout_user_choice_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutUserChoice -string "${dialog_timeout_user_choice_seconds}"
	elif [[ -n "${dialog_timeout_user_choice_option}" ]] && ! [[ "${dialog_timeout_user_choice_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-user-choice=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_user_choice_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_user_choice_seconds is: ${dialog_timeout_user_choice_seconds}"
	
	# Validate ${dialog_timeout_user_schedule_option} and if valid set ${dialog_timeout_user_schedule_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_user_schedule_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-user-schedule option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutUserSchedule 2>/dev/null
		unset dialog_timeout_user_schedule_option
	elif [[ -n "${dialog_timeout_user_schedule_option}" ]] && [[ "${dialog_timeout_user_schedule_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_user_schedule_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-user-schedule=seconds value of ${dialog_timeout_user_schedule_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_user_schedule_seconds=60
		elif [[ "${dialog_timeout_user_schedule_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-user-schedule=seconds value of ${dialog_timeout_user_schedule_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_user_schedule_seconds=86400
		else
			dialog_timeout_user_schedule_seconds="${dialog_timeout_user_schedule_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutUserSchedule -string "${dialog_timeout_user_schedule_seconds}"
	elif [[ -n "${dialog_timeout_user_schedule_option}" ]] && ! [[ "${dialog_timeout_user_schedule_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-user-schedule=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_user_schedule_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_user_schedule_seconds is: ${dialog_timeout_user_schedule_seconds}"
	
	# Validate ${dialog_timeout_soft_deadline_option} and if valid set ${dialog_timeout_soft_deadline_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_soft_deadline_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-soft-deadline option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutSoftDeadline 2>/dev/null
		unset dialog_timeout_soft_deadline_option
	elif [[ -n "${dialog_timeout_soft_deadline_option}" ]] && [[ "${dialog_timeout_soft_deadline_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_soft_deadline_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-soft-deadline=seconds value of ${dialog_timeout_soft_deadline_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_soft_deadline_seconds=60
		elif [[ "${dialog_timeout_soft_deadline_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-soft-deadline=seconds value of ${dialog_timeout_soft_deadline_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_soft_deadline_seconds=86400
		else
			dialog_timeout_soft_deadline_seconds="${dialog_timeout_soft_deadline_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutSoftDeadline -string "${dialog_timeout_soft_deadline_seconds}"
	elif [[ -n "${dialog_timeout_soft_deadline_option}" ]] && ! [[ "${dialog_timeout_soft_deadline_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-soft-deadline=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_soft_deadline_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_soft_deadline_seconds is: ${dialog_timeout_soft_deadline_seconds}"
	
	# Validate ${dialog_timeout_insufficient_storage_option} and if valid set ${dialog_timeout_insufficient_storage_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_insufficient_storage_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-insufficient-storage option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutInsufficientStorage 2>/dev/null
		unset dialog_timeout_insufficient_storage_option
	elif [[ -n "${dialog_timeout_insufficient_storage_option}" ]] && [[ "${dialog_timeout_insufficient_storage_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_insufficient_storage_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-insufficient-storage=seconds value of ${dialog_timeout_insufficient_storage_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_insufficient_storage_seconds=60
		elif [[ "${dialog_timeout_insufficient_storage_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-insufficient-storage=seconds value of ${dialog_timeout_insufficient_storage_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_insufficient_storage_seconds=86400
		else
			dialog_timeout_insufficient_storage_seconds="${dialog_timeout_insufficient_storage_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutInsufficientStorage -string "${dialog_timeout_insufficient_storage_seconds}"
	elif [[ -n "${dialog_timeout_insufficient_storage_option}" ]] && ! [[ "${dialog_timeout_insufficient_storage_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-insufficient-storage=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_insufficient_storage_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_insufficient_storage_seconds is: ${dialog_timeout_insufficient_storage_seconds}"
	
	# Validate ${dialog_timeout_power_required_option} and if valid set ${dialog_timeout_power_required_seconds} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${dialog_timeout_power_required_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --dialog-timeout-power-required option."
		defaults delete "${SUPER_LOCAL_PLIST}" DialogTimeoutPowerRequired 2>/dev/null
		unset dialog_timeout_insufficient_storage_option
	elif [[ -n "${dialog_timeout_power_required_option}" ]] && [[ "${dialog_timeout_power_required_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${dialog_timeout_power_required_option}" -lt 60 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-power-required=seconds value of ${dialog_timeout_power_required_option} seconds is too low, rounding up to 60 seconds."
			dialog_timeout_power_required_seconds=60
		elif [[ "${dialog_timeout_power_required_option}" -gt 86400 ]]; then
			log_super "Parameter Warning: Specified --dialog-timeout-power-required=seconds value of ${dialog_timeout_power_required_option} seconds is too high, rounding down to 86400 seconds (1 day)."
			dialog_timeout_power_required_seconds=86400
		else
			dialog_timeout_power_required_seconds="${dialog_timeout_power_required_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DialogTimeoutPowerRequired -string "${dialog_timeout_power_required_seconds}"
	elif [[ -n "${dialog_timeout_power_required_option}" ]] && ! [[ "${dialog_timeout_power_required_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --dialog-timeout-power-required=seconds value must only be a number."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${dialog_timeout_power_required_seconds}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_timeout_power_required_seconds is: ${dialog_timeout_power_required_seconds}"
	
	# Validate ${display_unmovable_option} and if valid save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_unmovable_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-unmovable option, defaulting to movable dialogs and notifications."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayUnmovable 2>/dev/null
		unset display_unmovable_option
	elif [[ -n "${display_unmovable_option}" ]]; then
		previous_ifs="${IFS}"
		IFS=','
		local display_unmovable_array
		read -r -a display_unmovable_array <<<"${display_unmovable_option}"
		for option_type in "${display_unmovable_array[@]}"; do
			if ! [[ "${option_type}" =~ ${REGEX_WORKFLOW_OPTIONS} ]]; then
				log_super "Parameter Error: Unrecognized --display-unmovable type of ${option_type}. You can only specify the following types separated by commas (no spaces): ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR"
				option_error="TRUE"
			fi
		done
		IFS="${previous_ifs}"
		[[ "${option_error}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" DisplayUnmovable -string "${display_unmovable_option}"
		[[ $(echo "${display_unmovable_option}" | grep -c 'ALWAYS') -gt 0 ]] && display_unmovable_status="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_unmovable_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_unmovable_option is: ${display_unmovable_option}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_unmovable_status}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_unmovable_status is: ${display_unmovable_status}"
	
	# Validate ${display_hide_background_option} and if valid save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_hide_background_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-hide-background option, defaulting to visible background behind dialogs and notifications."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayHideBackground 2>/dev/null
		unset display_hide_background_option
	elif [[ -n "${display_hide_background_option}" ]]; then
		previous_ifs="${IFS}"
		IFS=','
		local display_hide_background_array
		read -r -a display_hide_background_array <<<"${display_hide_background_option}"
		for option_type in "${display_hide_background_array[@]}"; do
			if ! [[ "${option_type}" =~ ${REGEX_WORKFLOW_OPTIONS} ]]; then
				log_super "Parameter Error: Unrecognized --display-hide-background type of ${option_type}. You can only specify the following types separated by commas (no spaces): ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR"
				option_error="TRUE"
			fi
		done
		IFS="${previous_ifs}"
		[[ "${option_error}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" DisplayHideBackground -string "${display_hide_background_option}"
		[[ $(echo "${display_hide_background_option}" | grep -c 'ALWAYS') -gt 0 ]] && display_hide_background_status="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_hide_background_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_hide_background_option is: ${display_hide_background_option}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_hide_background_status}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_hide_background_status is: ${display_hide_background_status}"
	
	# Validate ${display_silently_option} and if valid save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_silently_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-silently option, defaulting to audible alert for dialogs and notifications."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplaySilently 2>/dev/null
		unset display_silently_option
	elif [[ -n "${display_silently_option}" ]]; then
		previous_ifs="${IFS}"
		IFS=','
		local display_silently_array
		read -r -a display_silently_array <<<"${display_silently_option}"
		for option_type in "${display_silently_array[@]}"; do
			if ! [[ "${option_type}" =~ ${REGEX_WORKFLOW_OPTIONS} ]]; then
				log_super "Parameter Error: Unrecognized --display-silently type of ${option_type}. You can only specify the following types separated by commas (no spaces): ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR"
				option_error="TRUE"
			fi
		done
		IFS="${previous_ifs}"
		[[ "${option_error}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" DisplaySilently -string "${display_silently_option}"
		[[ $(echo "${display_silently_option}" | grep -c 'ALWAYS') -gt 0 ]] && display_silently_status="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_silently_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_silently_option is: ${display_silently_option}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_silently_status}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_silently_status is: ${display_silently_status}"
	
	# Validate ${display_hide_progress_bar_option} and if valid save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_hide_progress_bar_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-hide-progress-bar option, defaulting to all notifications are shown a progress bar."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayHideProgressBar 2>/dev/null
		unset display_hide_progress_bar_option
	elif [[ -n "${display_hide_progress_bar_option}" ]]; then
		previous_ifs="${IFS}"
		IFS=','
		local display_hide_progress_bar_array
		read -r -a display_hide_progress_bar_array <<<"${display_hide_progress_bar_option}"
		for option_type in "${display_hide_progress_bar_array[@]}"; do
			if ! [[ "${option_type}" =~ ${REGEX_WORKFLOW_OPTIONS} ]]; then
				log_super "Parameter Error: Unrecognized --display-hide-progress-bar type of ${option_type}. You can only specify the following types separated by commas (no spaces): ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR"
				option_error="TRUE"
			fi
			[[ "${option_type}" == "DIALOG" ]] && log_super "Parameter Warning: The --display-hide-progress-bar type of DIALOG is ignored because interactive dialogs don't have progress bars'."
		done
		IFS="${previous_ifs}"
		[[ "${option_error}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" DisplayHideProgressBar -string "${display_hide_progress_bar_option}"
		[[ $(echo "${display_hide_progress_bar_option}" | grep -c 'ALWAYS') -gt 0 ]] && display_hide_progress_bar_status="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_hide_progress_bar_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_hide_progress_bar_option is: ${display_hide_progress_bar_option}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_hide_progress_bar_status}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_hide_progress_bar_status is: ${display_hide_progress_bar_status}"
	
	# Validate ${display_notifications_centered_option} and if valid save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_notifications_centered_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-notifications-centered option, defaulting to all notifications are shown in top right corner."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayNotificationsCentered 2>/dev/null
	elif [[ -n "${display_notifications_centered_option}" ]]; then
		previous_ifs="${IFS}"
		IFS=','
		local display_notifications_centered_array
		read -r -a display_notifications_centered_array <<<"${display_notifications_centered_option}"
		for option_type in "${display_notifications_centered_array[@]}"; do
			if ! [[ "${option_type}" =~ ${REGEX_WORKFLOW_OPTIONS} ]]; then
				log_super "Parameter Error: Unrecognized --display-notifications-centered type of ${option_type}. You can only specify the following types separated by commas (no spaces): ALWAYS,DEADLINE,SCHEDULED,INSTALLNOW,ERROR"
				option_error="TRUE"
			fi
			[[ "${option_type}" == "DIALOG" ]] && log_super "Parameter Warning: The --display-notifications-centered type of DIALOG is ignored because dialogs are not notifcations."
		done
		IFS="${previous_ifs}"
		[[ "${option_error}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" DisplayNotificationsCentered -string "${display_notifications_centered_option}"
		[[ $(echo "${display_notifications_centered_option}" | grep -c 'ALWAYS') -gt 0 ]] && display_notifications_centered_status="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_notifications_centered_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_notifications_centered_option is: ${display_notifications_centered_option}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_notifications_centered_status}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_notifications_centered_status is: ${display_notifications_centered_status}"
	
	# Validate ${display_icon_size_option} input and if valid override default ${display_icon_size} parameter and save to ${SUPER_LOCAL_PLIST}. If there is no ${display_icon_size} then set it to ${DISPLAY_ICON_DEFAULT_SIZE}.
	if [[ "${display_icon_size_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-icon-size option, defaulting to ${DISPLAY_ICON_DEFAULT_SIZE} pixels."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconSize 2>/dev/null
		unset display_icon_size_option
	elif [[ -n "${display_icon_size_option}" ]] && [[ "${display_icon_size_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${display_icon_size_option}" -lt 32 ]]; then
			log_super "Parameter Warning: Specified --display-icon-size=pixels value of ${display_icon_size_option} pixels is too low, rounding up to 32 pixels."
			display_icon_size=32
		elif [[ "${display_icon_size_option}" -gt 150 ]]; then
			log_super "Parameter Warning: Specified --display-icon-size=pixels value of ${display_icon_size_option} pixels is too high, rounding down to 150 pixels."
			display_icon_size=150
		else
			display_icon_size="${display_icon_size_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" DisplayIconSize -string "${display_icon_size}"
	elif [[ -n "${display_icon_size_option}" ]] && ! [[ "${display_icon_size_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --display-icon-size=pixels value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${display_icon_size}" ]] && display_icon_size="${DISPLAY_ICON_DEFAULT_SIZE}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_size is: ${display_icon_size}"
	
	# Initial validation for the ${display_icon_file_option}, ${display_icon_light_file_option}, and ${display_icon_dark_file_option} to set ${display_icon_light_file_path} and ${display_icon_dark_file_path}. Handling of the actual display icon files themselves is in the manage_helpers() function.
	display_icon_light_file_path="FALSE"
	display_icon_dark_file_path="FALSE"
	if [[ "${display_icon_light_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-icon-light-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconLightFile 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconLightFileCachedOrigin 2>/dev/null
		unset display_icon_light_file_option
		[[ -f "${DISPLAY_ICON_LIGHT_FILE_CACHE}" ]] && rm -f "${DISPLAY_ICON_LIGHT_FILE_CACHE}" 2>/dev/null
	elif [[ -n "${display_icon_light_file_option}" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" DisplayIconLightFile -string "${display_icon_light_file_option}"
		display_icon_light_file_path="${display_icon_light_file_option}"
	fi
	if [[ "${display_icon_dark_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-icon-dark-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconDarkFile 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconDarkFileCachedOrigin 2>/dev/null
		unset display_icon_dark_file_option
		[[ -f "${DISPLAY_ICON_DARK_FILE_CACHE}" ]] && rm -f "${DISPLAY_ICON_DARK_FILE_CACHE}" 2>/dev/null
	elif [[ -n "${display_icon_dark_file_option}" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" DisplayIconDarkFile -string "${display_icon_dark_file_option}"
		display_icon_dark_file_path="${display_icon_dark_file_option}"
	fi
	if [[ "${display_icon_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-icon-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconFile 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconFileCachedOrigin 2>/dev/null
		unset display_icon_file_option
	elif [[ -n "${display_icon_file_option}" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" DisplayIconFile -string "${display_icon_file_option}"
		[[ "${display_icon_light_file_path}" == "FALSE" ]] && display_icon_light_file_path="${display_icon_file_option}"
		[[ "${display_icon_dark_file_path}" == "FALSE" ]] && display_icon_dark_file_path="${display_icon_file_option}"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_light_file_path is: ${display_icon_light_file_path}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_dark_file_path is: ${display_icon_dark_file_path}"
	
	# Validate ${display_accessory_type_option}, ${display_accessory_default_file_option}, ${display_accessory_macos_minor_update_file_option}, ${display_accessory_macos_major_upgrade_file_option}, ${display_accessory_non_system_updates_file_option}, ${display_accessory_jamf_policy_triggers_file_option}, and ${display_accessory_restart_without_updates_file_option}.
	if [[ "${display_accessory_type_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-type option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryType 2>/dev/null
		unset display_accessory_type_option
	fi
	if [[ "${display_accessory_default_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-default-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryDefaultFile 2>/dev/null
		unset display_accessory_default_file_option
	fi
	if [[ "${display_accessory_macos_minor_update_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-macos-minor-update-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryMacOSMinorUpdateFile 2>/dev/null
		unset display_accessory_macos_minor_update_file_option
	fi
	if [[ "${display_accessory_macos_major_upgrade_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-macos-major-upgrade-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryMacOSMajorUpgradeFile 2>/dev/null
		unset display_accessory_macos_major_upgrade_file_option
	fi
	if [[ "${display_accessory_non_system_updates_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-non-system-updates-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryNonSystemUpdatesFile 2>/dev/null
		unset display_accessory_non_system_updates_file_option
	fi
	if [[ "${display_accessory_jamf_policy_triggers_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-jamf-policy-triggers-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryJamfPolicyTriggersFile 2>/dev/null
		unset display_accessory_jamf_policy_triggers_file_option
	fi
	if [[ "${display_accessory_restart_without_updates_file_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-accessory-restart-without-updates-file option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayAccessoryRestartWithoutUpdatesFile 2>/dev/null
		unset display_accessory_restart_without_updates_file_option
	fi
	if [[ -n "${display_accessory_type_option}" ]] && [[ -z "${display_accessory_default_file_option}" ]] && [[ -z "${display_accessory_macos_minor_update_file_option}" ]] && [[ -z "${display_accessory_macos_major_upgrade_file_option}" ]] && [[ -z "${display_accessory_non_system_updates_file_option}" ]] && [[ -z "${display_accessory_jamf_policy_triggers_file_option}" ]] && [[ -z "${display_accessory_restart_without_updates_file_option}" ]]; then
		log_super "Parameter Error: To use the --display-accessory-type option you must also specify one of the display accessory file options."
		option_error="TRUE"
	fi
	if [[ -z "${display_accessory_type_option}" ]] && { [[ -n "${display_accessory_default_file_option}" ]] || [[ -n "${display_accessory_macos_minor_update_file_option}" ]] || [[ -n "${display_accessory_macos_major_upgrade_file_option}" ]] || [[ -n "${display_accessory_non_system_updates_file_option}" ]] || [[ -n "${display_accessory_jamf_policy_triggers_file_option}" ]] || [[ -n "${display_accessory_restart_without_updates_file_option}" ]]; }; then
		log_super "Parameter Error: To use any of the display accessory file options you must also specify the --display-accessory-type option."
		option_error="TRUE"
	fi
	if [[ "${option_error}" != "TRUE" ]] && [[ -n "${display_accessory_type_option}" ]]; then
		if [[ "${display_accessory_type_option}" =~ ^TEXTBOX$|^HTMLBOX$|^HTML$|^IMAGE$|^VIDEO$|^VIDEOAUTO$ ]]; then
			display_accessory_type="${display_accessory_type_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryType -string "${display_accessory_type_option}"
		else
			log_super "Parameter Error: Unrecognized --display-accessory-type value of ${display_accessory_type_option}. You must specify one of the following; TEXTBOX, HTMLBOX, HTML, IMAGE, VIDEO, or VIDEOAUTO."
			option_error="TRUE"
		fi
	fi
	if [[ "${option_error}" != "TRUE" ]] && { [[ -n "${display_accessory_default_file_option}" ]] || [[ -n "${display_accessory_macos_minor_update_file_option}" ]] || [[ -n "${display_accessory_macos_major_upgrade_file_option}" ]] || [[ -n "${display_accessory_non_system_updates_file_option}" ]] || [[ -n "${display_accessory_jamf_policy_triggers_file_option}" ]] || [[ -n "${display_accessory_restart_without_updates_file_option}" ]]; }; then
		if [[ -n "${display_accessory_default_file_option}" ]]; then
			display_accessory_default="${display_accessory_default_file_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryDefaultFile -string "${display_accessory_default_file_option}"
		fi
		if [[ -n "${display_accessory_macos_minor_update_file_option}" ]]; then
			display_accessory_macos_minor_update="${display_accessory_macos_minor_update_file_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryMacOSMinorUpdateFile -string "${display_accessory_macos_minor_update_file_option}"
		fi
		if [[ -n "${display_accessory_macos_major_upgrade_file_option}" ]]; then
			display_accessory_macos_major_upgrade="${display_accessory_macos_major_upgrade_file_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryMacOSMajorUpgradeFile -string "${display_accessory_macos_major_upgrade_file_option}"
		fi
		if [[ -n "${display_accessory_non_system_updates_file_option}" ]]; then
			display_accessory_non_system_updates="${display_accessory_non_system_updates_file_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryNonSystemUpdatesFile -string "${display_accessory_non_system_updates_file_option}"
		fi
		if [[ -n "${display_accessory_jamf_policy_triggers_file_option}" ]]; then
			display_accessory_jamf_policy_triggers="${display_accessory_jamf_policy_triggers_file_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryJamfPolicyTriggersFile -string "${display_accessory_jamf_policy_triggers_file_option}"
		fi
		if [[ -n "${display_accessory_restart_without_updates_file_option}" ]]; then
			display_accessory_restart_without_updates="${display_accessory_restart_without_updates_file_option}"
			defaults write "${SUPER_LOCAL_PLIST}" DisplayAccessoryRestartWithoutUpdatesFile -string "${display_accessory_restart_without_updates_file_option}"
		fi
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_type}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_type is: ${display_accessory_type}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_default}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_default is: ${display_accessory_default}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_macos_major_upgrade}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_macos_major_upgrade is: ${display_accessory_macos_major_upgrade}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_macos_major_upgrade_file_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_macos_major_upgrade_file_option is: ${display_accessory_macos_major_upgrade_file_option}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_non_system_updates}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_non_system_updates is: ${display_accessory_non_system_updates}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_jamf_policy_triggers}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_jamf_policy_triggers is: ${display_accessory_jamf_policy_triggers}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_accessory_restart_without_updates}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_restart_without_updates is: ${display_accessory_restart_without_updates}"
	
	# Validate ${display_help_button_string_option} and set ${display_help_button_string} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_help_button_string_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-help-button-string option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayHelpButtonString 2>/dev/null
		unset display_help_button_string_option
	elif [[ -n "${display_help_button_string_option}" ]]; then
		display_help_button_string="${display_help_button_string_option}"
		defaults write "${SUPER_LOCAL_PLIST}" DisplayHelpButtonString -string "${display_help_button_string_option}"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_help_button_string}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_help_button_string is: ${display_help_button_string}"
	
	# Validate ${display_warning_button_string_option} and set ${display_warning_button_string} and save to ${SUPER_LOCAL_PLIST}.
	if [[ "${display_warning_button_string_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --display-warning-button-string option."
		defaults delete "${SUPER_LOCAL_PLIST}" DisplayWarningButtonString 2>/dev/null
		unset display_warning_button_string_option
	elif [[ -n "${display_warning_button_string_option}" ]]; then
		display_warning_button_string="${display_warning_button_string_option}"
		defaults write "${SUPER_LOCAL_PLIST}" DisplayWarningButtonString -string "${display_warning_button_string_option}"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${display_warning_button_string}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_warning_button_string is: ${display_warning_button_string}"
	
	# This initial round of authentication option validation simply checks to make sure the user entered logically correct option combinations.
	# Additional authentication validation is handled by the manage_authentication_options() function.
	if [[ "${mac_cpu_architecture}" == "arm64" ]]; then
		if [[ "${auth_ask_user_to_save_password}" -eq 1 ]] || [[ "${auth_ask_user_to_save_password}" == "TRUE" ]] && [[ "${auth_delete_all_option}" != "TRUE" ]]; then
			auth_ask_user_to_save_password="TRUE"
			defaults write "${SUPER_LOCAL_PLIST}" AuthAskUserToSavePassword -bool true
		else
			auth_ask_user_to_save_password="FALSE"
			defaults delete "${SUPER_LOCAL_PLIST}" AuthAskUserToSavePassword 2>/dev/null
		fi
		
		if [[ -n "${auth_local_account_option}" ]] && [[ -z "${auth_local_password_option}" ]]; then
			log_super "Auth Error: The --auth-local-account option requires that you also use the --auth-local-password option."
			option_error="TRUE"
		fi
		if [[ -z "${auth_local_account_option}" ]] && [[ -n "${auth_local_password_option}" ]]; then
			log_super "Auth Error: The --auth-local-password option requires that you also set the --auth-local-account option."
			option_error="TRUE"
		fi
		
		if [[ -n "${auth_service_add_via_admin_account_option}" ]] && [[ -z "${auth_service_add_via_admin_password_option}" ]]; then
			log_super "Auth Error: The --auth-service_add_via_admin-account option requires that you also use the --auth-service_add_via_admin-password option."
			option_error="TRUE"
		fi
		if [[ -z "${auth_service_add_via_admin_account_option}" ]] && [[ -n "${auth_service_add_via_admin_password_option}" ]]; then
			log_super "Auth Error: The --auth-service_add_via_admin-password option requires that you also set the --auth-service_add_via_admin-account option."
			option_error="TRUE"
		fi
		
		if [[ -n "${auth_service_account_option}" ]] && { [[ -z "${auth_service_add_via_admin_account_option}" ]] || [[ -z "${auth_service_add_via_admin_password_option}" ]]; }; then
			log_super "Auth Error: The --auth-service-account option requires that you also set the ---auth-service-add-via-admin-account and --auth-service-add-via-admin-password options."
			option_error="TRUE"
		fi
		if [[ -n "${auth_service_password_option}" ]] && { [[ -z "${auth_service_add_via_admin_account_option}" ]] || [[ -z "${auth_service_add_via_admin_password_option}" ]]; }; then
			log_super "Auth Error: The --auth-service-password option requires that you also set the ---auth-service-add-via-admin-account and --auth-service-add-via-admin-password options."
			option_error="TRUE"
		fi
		
		if [[ -n "${auth_jamf_client_option}" ]] && [[ -z "${auth_jamf_secret_option}" ]]; then
			log_super "Auth Error: The --auth-jamf-client option requires that you also set the --auth-jamf-secret option."
			option_error="TRUE"
		fi
		if [[ -z "${auth_jamf_client_option}" ]] && [[ -n "${auth_jamf_secret_option}" ]]; then
			log_super "Auth Error: The --auth-jamf-secret option requires that you also set the --auth-jamf-client."
			option_error="TRUE"
		fi
		if [[ -n "${auth_jamf_client_option}" ]] && [[ "${jamf_version_number}" -lt 1049 ]]; then
			log_super "Auth Error: The --auth-jamf-client option requires Jamf Pro version 10.49 or later, the currently installed version of Jamf Pro ${jamf_version_number_major}.${jamf_version_number_minor} does not support this option."
			option_error="TRUE"
		fi
		
		if [[ -n "${auth_jamf_account_option}" ]] && [[ -z "${auth_jamf_password_option}" ]]; then
			log_super "Auth Error: The --auth-jamf-account option requires that you also set the --auth-jamf-password option."
			option_error="TRUE"
		fi
		if [[ -z "${auth_jamf_account_option}" ]] && [[ -n "${auth_jamf_password_option}" ]]; then
			log_super "Auth Error: The --auth-jamf-password option requires that you also set the --auth-jamf-account."
			option_error="TRUE"
		fi
		if [[ -n "${auth_jamf_account_option}" ]] && [[ "${jamf_version_number}" -ge 1049 ]]; then
			log_super "Parameter Warning: The --auth-jamf-account option is not recommended for Jamf Pro version 10.49 or later. The recommended implementation is the more secure --auth-jamf-client option."
		fi
		
		# Validate ${auth_jamf_custom_url_option} input and save to ${SUPER_LOCAL_PLIST}.
		if [[ "${auth_jamf_custom_url_option}" == "X" ]]; then
			log_super "Status: Deleting local preference for the --auth-jamf-custom-url option, defaulting to Jamf Pro management URL."
			defaults delete "${SUPER_LOCAL_PLIST}" AuthJamfCustomURL 2>/dev/null
			unset auth_jamf_custom_url_option
		elif [[ -n "${auth_jamf_custom_url_option}" ]] && [[ "${auth_jamf_custom_url_option}" =~ ${REGEX_HTTPS} ]]; then
			if ! [[ "${auth_jamf_custom_url_option}" =~ .*\/$ ]]; then
				auth_jamf_custom_url_option="${auth_jamf_custom_url_option}/"
				log_super "Parameter Warning: Adding a trailing slash to the --auth-jamf-custom-url value: ${auth_jamf_custom_url_option}"
			fi
			defaults write "${SUPER_LOCAL_PLIST}" AuthJamfCustomURL -string "${auth_jamf_custom_url_option}"
			auth_jamf_custom_url="${auth_jamf_custom_url_option}"
		elif [[ -n "${auth_jamf_custom_url_option}" ]] && ! [[ "${auth_jamf_custom_url_option}" =~ ${REGEX_HTTPS} ]]; then
			log_super "Parameter Error: Invalid --auth-jamf-custom-url=URL VALUE must start with 'https://': ${auth_jamf_custom_url_option}"
			option_error="TRUE"
		fi
		{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${auth_jamf_custom_url}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_custom_url is: ${auth_jamf_custom_url}"
		
		# Manage ${auth_credential_failover_to_user_option} and save to ${SUPER_LOCAL_PLIST}.
		if [[ "${auth_credential_failover_to_user_option}" -eq 1 ]] || [[ "${auth_credential_failover_to_user_option}" == "TRUE" ]]; then
			auth_credential_failover_to_user_option="TRUE"
			defaults write "${SUPER_LOCAL_PLIST}" AuthCredentialFailoverToUser -bool true
		else
			auth_credential_failover_to_user_option="FALSE"
			defaults delete "${SUPER_LOCAL_PLIST}" AuthCredentialFailoverToUser 2>/dev/null
		fi
		{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${auth_credential_failover_to_user_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_credential_failover_to_user_option is: ${auth_credential_failover_to_user_option}"
		
		# Validate ${auth_mdm_failover_to_user_option} and set initial various ${auth_mdm_failover_*} parameters.
		if [[ "${auth_mdm_failover_to_user_option}" == "X" ]]; then
			log_super "Status: Deleting local preference for the --auth-mdm-failover-to-user option, defaulting to error deferral for any MDM failure."
			defaults delete "${SUPER_LOCAL_PLIST}" AuthMDMFailoverToUser 2>/dev/null
			unset auth_mdm_failover_to_user_option
		elif [[ -n "${auth_mdm_failover_to_user_option}" ]]; then
			previous_ifs="${IFS}"
			IFS=','
			local auth_mdm_failover_to_user_array
			read -r -a auth_mdm_failover_to_user_array <<<"${auth_mdm_failover_to_user_option}"
			for option_type in "${auth_mdm_failover_to_user_array[@]}"; do
				if ! [[ "${option_type}" =~ ${REGEX_WORKFLOW_OPTIONS} ]]; then
					log_super "Parameter Error: Unrecognized --auth-mdm-failover-to-user type of ${option_type}. You can only specify the following types separated by commas (no spaces): ALWAYS,DIALOG,DEADLINE,SCHEDULED,INSTALLNOW,ERROR"
					option_error="TRUE"
				fi
			done
			IFS="${previous_ifs}"
			[[ "${option_error}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" AuthMDMFailoverToUser -string "${auth_mdm_failover_to_user_option}"
			[[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ALWAYS') -gt 0 ]] && auth_mdm_failover_to_user_status="TRUE"
		fi
		{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${auth_mdm_failover_to_user_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_mdm_failover_to_user_option is: ${auth_mdm_failover_to_user_option}"
		{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${auth_mdm_failover_to_user_status}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_mdm_failover_to_user_status is: ${auth_mdm_failover_to_user_status}"
	else # Mac computer with Intel.
		[[ -n "${auth_ask_user_to_save_password}" ]] && log_super "Parameter Warning: The --auth-ask-user-to-save-password option is ignored on Mac computers with Intel."
		[[ -n "${auth_local_account_option}" ]] && log_super "Parameter Warning: The --auth-local-account option is ignored on Mac computers with Intel."
		[[ -n "${auth_service_add_via_admin_account_option}" ]] && log_super "Parameter Warning: The --auth-service-add-via-admin-account option is ignored on Mac computers with Intel."
		[[ -n "${auth_service_account_option}" ]] && log_super "Parameter Warning: The --auth-service-account option is ignored on Mac computers with Intel."
		[[ -n "${auth_jamf_client_option}" ]] && log_super "Parameter Warning: The --auth-jamf-client option is ignored on Mac computers with Intel."
		[[ -n "${auth_jamf_account_option}" ]] && log_super "Parameter Warning: The --auth-jamf-account option is ignored on Mac computers with Intel."
		[[ -n "${auth_jamf_custom_url_option}" ]] && log_super "Parameter Warning: The --auth-jamf-custom-url option is ignored on Mac computers with Intel."
		[[ -n "${auth_credential_failover_to_user_option}" ]] && log_super "Parameter Warning: The --auth-credential-failover-to-user option is ignored on Mac computers with Intel."
		[[ -n "${auth_mdm_failover_to_user_option}" ]] && log_super "Parameter Warning: The --auth-mdm-failover-to-user option is ignored on Mac computers with Intel."
	fi
	
	# Manage ${test_mode_option} and save to ${SUPER_LOCAL_PLIST}.
	if [[ ${test_mode_option} -eq 1 ]] || [[ "${test_mode_option}" == "TRUE" ]]; then
		test_mode_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" TestMode -bool true
	else
		test_mode_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" TestMode 2>/dev/null
	fi
	if [[ "${test_mode_option}" == "TRUE" ]] && [[ "${current_user_account_name}" == "FALSE" ]]; then
		log_super "Parameter Error: Test mode requires that a valid user is logged in."
		option_error="TRUE"
	fi
	if [[ "${test_mode_option}" == "TRUE" ]] && [[ "${workflow_only_download_option}" == "TRUE" ]]; then
		log_super "Parameter Error: The --test-mode option can not be used with the --workflow-only-download."
		option_error="TRUE"
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${test_mode_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: test_mode_option is: ${test_mode_option}"
	
	# Validate ${test_mode_timeout_option} input and if valid set "${test_mode_timeout_seconds}" and save to ${SUPER_LOCAL_PLIST}. If there is no "${test_mode_timeout_seconds}" then set it to ${TEST_MODE_DEFAULT_TIMEOUT}.
	if [[ "${test_mode_timeout_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --test-mode-timeout option, defaulting to ${TEST_MODE_DEFAULT_TIMEOUT} seconds."
		defaults delete "${SUPER_LOCAL_PLIST}" TestModeTimeout 2>/dev/null
		unset test_mode_timeout_option
	elif [[ -n "${test_mode_timeout_option}" ]] && [[ "${test_mode_timeout_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		if [[ "${test_mode_timeout_option}" -lt 10 ]]; then
			log_super "Parameter Warning: Specified --test-mode-timeout=seconds value of ${test_mode_timeout_option} seconds is too low, rounding up to 10 seconds."
			test_mode_timeout_seconds=10
		elif [[ "${test_mode_timeout_option}" -gt 120 ]]; then
			log_super "Parameter Warning: Specified --test-mode-timeout=seconds value of ${test_mode_timeout_option} seconds is too high, rounding down to 120 seconds (2 minutes)."
			test_mode_timeout_seconds=120
		else
			test_mode_timeout_seconds="${test_mode_timeout_option}"
		fi
		defaults write "${SUPER_LOCAL_PLIST}" TestModeTimeout -string "${test_mode_timeout_seconds}"
	elif [[ -n "${test_mode_timeout_option}" ]] && ! [[ "${test_mode_timeout_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --test-mode-timeout=seconds value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${test_mode_timeout_seconds}" ]] && test_mode_timeout_seconds="${TEST_MODE_DEFAULT_TIMEOUT}"
	if [[ "${test_mode_option}" == "TRUE" ]]; then
		if [[ -n "${dialog_timeout_default_seconds}" ]] && [[ "${dialog_timeout_default_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-default=seconds value from ${dialog_timeout_default_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_default_seconds="${test_mode_timeout_seconds}"
		fi
		if [[ -n "${dialog_timeout_user_choice_seconds}" ]] && [[ "${dialog_timeout_user_choice_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-user-choice=seconds value from ${dialog_timeout_user_choice_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_user_choice_seconds="${test_mode_timeout_seconds}"
		fi
		if [[ -n "${dialog_timeout_user_schedule_seconds}" ]] && [[ "${dialog_timeout_user_schedule_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-user-schedule=seconds value from ${dialog_timeout_user_schedule_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_user_schedule_seconds="${test_mode_timeout_seconds}"
		fi
		if [[ -n "${dialog_timeout_soft_deadline_seconds}" ]] && [[ "${dialog_timeout_soft_deadline_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-soft-deadline=seconds value from ${dialog_timeout_soft_deadline_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_soft_deadline_seconds="${test_mode_timeout_seconds}"
		fi
		if [[ -n "${dialog_timeout_user_auth_seconds}" ]] && [[ "${dialog_timeout_user_auth_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-user-auth=seconds value from ${dialog_timeout_user_auth_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_user_auth_seconds="${test_mode_timeout_seconds}"
		fi
		if [[ -n "${dialog_timeout_insufficient_storage_seconds}" ]] && [[ "${dialog_timeout_insufficient_storage_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-insufficient-storage=seconds value from ${dialog_timeout_insufficient_storage_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_insufficient_storage_seconds="${test_mode_timeout_seconds}"
		fi
		if [[ -n "${dialog_timeout_power_required_seconds}" ]] && [[ "${dialog_timeout_power_required_seconds}" -gt "${test_mode_timeout_seconds}" ]]; then
			log_super "Parameter Warning: Test mode requires temporary adjustment of the --dialog-timeout-power-required=seconds value from ${dialog_timeout_power_required_seconds} seconds to ${test_mode_timeout_seconds} seconds. This adjustment is not saved."
			dialog_timeout_power_required_seconds="${test_mode_timeout_seconds}"
		fi
	fi
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${test_mode_timeout_option}" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: test_mode_timeout_option is: ${test_mode_timeout_option}"
	
	# Validate ${test_storage_update_option} input and if valid set ${storage_required_update_gb} and save to ${SUPER_LOCAL_PLIST}. If there is no ${storage_required_update_gb} then set it to ${STORAGE_REQUIRED_UPDATE_DEFAULT_GB}.
	if [[ "${test_storage_update_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --test-storage-update option, defaulting to ${STORAGE_REQUIRED_UPDATE_DEFAULT_GB} GBs."
		defaults delete "${SUPER_LOCAL_PLIST}" TestStorageUpdate 2>/dev/null
		unset test_storage_update_option
	elif [[ -n "${test_storage_update_option}" ]] && [[ "${test_storage_update_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		[[ "${test_storage_update_option}" -ne "${storage_required_update_gb}" ]] && log_super "Parameter Warning: Specifying the --test-storage-update option should only be used for testing purposes."
		storage_required_update_gb="${test_storage_update_option}"
		defaults write "${SUPER_LOCAL_PLIST}" TestStorageUpdate -string "${storage_required_update_gb}"
	elif [[ -n "${test_storage_update_option}" ]] && ! [[ "${test_storage_update_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --test-storage-update=gigabytes value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${storage_required_update_gb}" ]] && storage_required_update_gb="${STORAGE_REQUIRED_UPDATE_DEFAULT_GB}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_required_update_gb is: ${storage_required_update_gb}"
	
	# Validate ${test_storage_upgrade_option} input and if valid set ${storage_required_upgrade_gb} and save to ${SUPER_LOCAL_PLIST}. If there is no ${storage_required_upgrade_gb} then set it to ${STORAGE_REQUIRED_UPGRADE_DEFAULT_GB}.
	if [[ "${test_storage_upgrade_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --test-storage-upgrade option, defaulting to ${STORAGE_REQUIRED_UPGRADE_DEFAULT_GB} GBs."
		defaults delete "${SUPER_LOCAL_PLIST}" TestStorageUpdate 2>/dev/null
		unset test_storage_upgrade_option
	elif [[ -n "${test_storage_upgrade_option}" ]] && [[ "${test_storage_upgrade_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		[[ "${test_storage_upgrade_option}" -ne "${storage_required_upgrade_gb}" ]] && log_super "Parameter Warning: Specifying the --test-storage-upgrade option should only be used for testing purposes."
		storage_required_upgrade_gb="${test_storage_upgrade_option}"
		defaults write "${SUPER_LOCAL_PLIST}" TestStorageUpdate -string "${storage_required_upgrade_gb}"
	elif [[ -n "${test_storage_upgrade_option}" ]] && ! [[ "${test_storage_upgrade_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --test-storage-upgrade=gigabytes value must only be a number."
		option_error="TRUE"
	fi
	[[ -z "${storage_required_upgrade_gb}" ]] && storage_required_upgrade_gb="${STORAGE_REQUIRED_UPGRADE_DEFAULT_GB}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_required_upgrade_gb is: ${storage_required_upgrade_gb}"
	
	# Validate ${test_battery_level_option} input and if valid set ${power_required_battery_percent} and save to ${SUPER_LOCAL_PLIST}. If there is no ${power_required_battery_percent} then set it to ${POWER_REQUIRED_BATTERY_APPLE_SILICON_PERCENT} or ${POWER_REQUIRED_BATTERY_INTEL_PERCENT}.
	if [[ "${test_battery_level_option}" == "X" ]]; then
		log_super "Status: Deleting local preference for the --test-battery-level option, defaulting to ${power_required_battery_percent}%."
		defaults delete "${SUPER_LOCAL_PLIST}" TestBatteryLevel 2>/dev/null
		unset test_battery_level_option
	elif [[ -n "${test_battery_level_option}" ]] && [[ "${test_battery_level_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		[[ "${test_battery_level_option}" -ne "${power_required_battery_percent}" ]] && log_super "Parameter Warning: Specifying the --test-battery-level option should only be used for testing purposes."
		power_required_battery_percent="${test_battery_level_option}"
		defaults write "${SUPER_LOCAL_PLIST}" TestBatteryLevel -string "${power_required_battery_percent}"
	elif [[ -n "${test_battery_level_option}" ]] && ! [[ "${test_battery_level_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Parameter Error: The --test-battery-level=percentage value must only be a number."
		option_error="TRUE"
	fi
	if [[ -z "${power_required_battery_percent}" ]]; then
		if [[ "${mac_cpu_architecture}" == "arm64" ]]; then
			power_required_battery_percent="${POWER_REQUIRED_BATTERY_APPLE_SILICON_PERCENT}"
		else # Intel.
			power_required_battery_percent="${POWER_REQUIRED_BATTERY_INTEL_PERCENT}"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_required_battery_percent is: ${power_required_battery_percent}"
}

# For Apple Silicon computers this function manages update/upgrade credentials given the various --auth_* options. Any error will set ${auth_error_new}.
manage_authentication_options() {
	auth_error_new="FALSE"
	
	# Collect any previously saved credential states (including legacy methods) from ${SUPER_LOCAL_PLIST}.
	auth_user_account_saved="FALSE"
	if [[ "${auth_ask_user_to_save_password}" == "TRUE" ]]; then
		if [[ "${current_user_account_name}" != "FALSE" ]]; then
			auth_user_password_keychain=$(launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security find-generic-password -w -a "super_auth_user_password" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" 2>&1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_password_keychain: ${auth_user_password_keychain}"
			if [[ $(echo "${auth_user_password_keychain}" | grep -c 'The specified item could not be found in the keychain.') -eq 0 ]]; then
				auth_user_account_saved="TRUE"
			else
				unset auth_user_password_keychain
			fi
		else # No ${current_user_account_name}
			log_super "Auth Warning: No currently logged in user, unable to the check status of the --auth-ask-user-to-save-password option."
		fi
	fi
	auth_local_account_saved=$(defaults read "${SUPER_LOCAL_PLIST}" AuthLocalAccount 2>/dev/null)
	[[ "${auth_local_account_saved}" -eq 1 ]] && auth_local_account_saved="TRUE"
	auth_service_account_saved=$(defaults read "${SUPER_LOCAL_PLIST}" AuthServiceAccount 2>/dev/null)
	[[ "${auth_service_account_saved}" -eq 1 ]] && auth_service_account_saved="TRUE"
	auth_jamf_client_saved=$(defaults read "${SUPER_LOCAL_PLIST}" AuthJamfClient 2>/dev/null)
	[[ "${auth_jamf_client_saved}" -eq 1 ]] && auth_jamf_client_saved="TRUE"
	auth_jamf_account_saved=$(defaults read "${SUPER_LOCAL_PLIST}" AuthJamfAccount 2>/dev/null)
	[[ "${auth_jamf_account_saved}" -eq 1 ]] && auth_jamf_account_saved="TRUE"
	local auth_legacy_local_account_saved
	auth_legacy_local_account_saved=$(defaults read "${SUPER_LOCAL_PLIST}" LocalAccount 2>/dev/null)
	local auth_legacy_super_account_saved
	auth_legacy_super_account_saved=$(defaults read "${SUPER_LOCAL_PLIST}" SuperAccount 2>/dev/null)
	local auth_legacy_jamf_account_saved
	auth_legacy_jamf_account_saved=$(defaults read "${SUPER_LOCAL_PLIST}" JamfAccount 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_ask_user_to_save_password: ${auth_ask_user_to_save_password}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_account_saved: ${auth_user_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_saved: ${auth_local_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_saved: ${auth_service_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_saved: ${auth_jamf_client_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_saved: ${auth_jamf_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_legacy_local_account_saved: ${auth_legacy_local_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_legacy_super_account_saved: ${auth_legacy_super_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_legacy_jamf_account_saved: ${auth_legacy_jamf_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_option: ${auth_local_account_option}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_add_via_admin_account_option: ${auth_service_add_via_admin_account_option}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_option: ${auth_jamf_client_option}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_option: ${auth_jamf_account_option}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_delete_all_option: ${auth_delete_all_option}"
	
	# Logging to indicate if there are no saved accounts when a delete is requested.
	{ [[ "${auth_ask_user_to_save_password}" == "FALSE" ]] && [[ "${auth_user_account_saved}" == "FALSE" ]] && [[ -z "${auth_local_account_saved}" ]] && [[ -z "${auth_service_account_saved}" ]] && [[ -z "${auth_jamf_client_saved}" ]] && [[ -z "${auth_jamf_account_saved}" ]] && [[ -z "${auth_legacy_local_account_saved}" ]] && [[ -z "${auth_legacy_super_account_saved}" ]] && [[ -z "${auth_legacy_jamf_account_saved}" ]] && [[ -n "${auth_delete_all_option}" ]]; } && log_super "Status: No saved authentication credentials to delete."
	
	# If the user specified any new Apple silicon authentication option or the ${auth_delete_all_option} then delete any previously saved credentials.
	if [[ "${auth_user_account_saved}" == "TRUE" ]] && { [[ "${auth_ask_user_to_save_password}" == "FALSE" ]] || [[ -n "${auth_local_account_option}" ]] || [[ -n "${auth_service_add_via_admin_account_option}" ]] || [[ -n "${auth_jamf_client_option}" ]] || [[ -n "${auth_jamf_account_option}" ]] || [[ "${auth_delete_all_option}" == "TRUE" ]]; }; then
		log_super "Status: Deleting saved credentials for the --auth-ask-user-to-save-password option."
		launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security delete-generic-password -a "super_auth_user_password" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" >/dev/null 2>&1
		defaults delete "${SUPER_LOCAL_PLIST}" AuthAskUserToSavePassword >/dev/null 2>&1
		auth_ask_user_to_save_password="FALSE"
		auth_user_account_saved="FALSE"
	fi
	if [[ "${auth_ask_user_to_save_password}" == "TRUE" ]] || [[ -n "${auth_local_account_option}" ]] || [[ -n "${auth_service_add_via_admin_account_option}" ]] || [[ -n "${auth_jamf_client_option}" ]] || [[ -n "${auth_jamf_account_option}" ]] || [[ "${auth_delete_all_option}" == "TRUE" ]]; then
		if [[ "${auth_local_account_saved}" == "TRUE" ]]; then
			log_super "Status: Deleting saved credentials for the --auth-local-account option."
			security delete-generic-password -a "super_auth_local_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_local_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			defaults delete "${SUPER_LOCAL_PLIST}" AuthLocalAccount >/dev/null 2>&1
			auth_local_account_saved="FALSE"
		fi
		if [[ "${auth_service_account_saved}" == "TRUE" ]]; then
			log_super "Status: Deleting the super service account and saved credentials."
			auth_service_account_keychain=$(security find-generic-password -w -a "super_auth_service_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			sysadminctl -deleteUser "${auth_service_account_keychain}" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_service_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_service_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			defaults delete "${SUPER_LOCAL_PLIST}" AuthServiceAccount >/dev/null 2>&1
			auth_service_account_saved="FALSE"
		fi
		if [[ "${auth_jamf_client_saved}" == "TRUE" ]]; then
			log_super "Status: Deleting saved credentials for the --auth-jamf-client option."
			security delete-generic-password -a "super_auth_jamf_client" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_jamf_secret" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			defaults delete "${SUPER_LOCAL_PLIST}" AuthJamfClient >/dev/null 2>&1
			auth_jamf_client_saved="FALSE"
		fi
		if [[ "${auth_jamf_account_saved}" == "TRUE" ]]; then
			log_super "Status: Deleting saved credentials for the --auth-jamf-account option."
			security delete-generic-password -a "super_auth_jamf_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_jamf_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			defaults delete "${SUPER_LOCAL_PLIST}" AuthJamfAccount >/dev/null 2>&1
			auth_jamf_account_saved="FALSE"
		fi
		if [[ -n "${auth_legacy_local_account_saved}" ]]; then
			log_super "Status: Deleting saved credentials for legacy local account."
			defaults delete "${SUPER_LOCAL_PLIST}" LocalAccount >/dev/null 2>&1
			security delete-generic-password -a "${auth_legacy_local_account_saved}" -s "Super Local Account" /Library/Keychains/System.keychain >/dev/null 2>&1
			unset auth_legacy_local_account_saved
		fi
		if [[ -n "${auth_legacy_super_account_saved}" ]]; then
			log_super "Status: Deleting local account and saved credentials for legacy super service account."
			sysadminctl -deleteUser "${auth_legacy_super_account_saved}" >/dev/null 2>&1
			defaults delete "${SUPER_LOCAL_PLIST}" SuperAccount >/dev/null 2>&1
			security delete-generic-password -a "${auth_legacy_super_account_saved}" -s "Super Service Account" /Library/Keychains/System.keychain >/dev/null 2>&1
			unset auth_legacy_super_account_saved
		fi
		if [[ -n "${auth_legacy_jamf_account_saved}" ]]; then
			log_super "Status: Deleting saved credentials for legacy Jamf Pro API account."
			defaults delete "${SUPER_LOCAL_PLIST}" JamfAccount >/dev/null 2>&1
			security delete-generic-password -a "${auth_legacy_jamf_account_saved}" -s "Super MDM Account" /Library/Keychains/System.keychain >/dev/null 2>&1
			unset auth_legacy_jamf_account_saved
		fi
	fi
	[[ "${auth_delete_all_option}" == "TRUE" ]] && return 0
	
	# Start migration of any legacy authentication items new keychain storage method.
	if [[ -n "${auth_legacy_local_account_saved}" ]]; then
		log_super "Status: Migrating saved legacy local account credentials..."
		local auth_legacy_local_password_saved
		auth_legacy_local_password_saved=$(security find-generic-password -w -a "${auth_legacy_local_account_saved}" -s "Super Local Account" /Library/Keychains/System.keychain 2>/dev/null)
		if [[ -n "${auth_legacy_local_password_saved}" ]]; then
			auth_local_account_option="${auth_legacy_local_account_saved}"
			auth_local_password_option="${auth_legacy_local_password_saved}"
			local auth_legacy_local_migrate
			auth_legacy_local_migrate="TRUE"
		else
			log_super "Auth Error: Unable to retrieve legacy local account password."
			auth_error_new="TRUE"
		fi
	fi
	if [[ -n "${auth_legacy_super_account_saved}" ]]; then
		log_super "Status: Migrating saved legacy super service account credentials..."
		local auth_legacy_super_password_saved
		auth_legacy_super_password_saved=$(security find-generic-password -w -a "${auth_legacy_super_account_saved}" -s "Super Service Account" /Library/Keychains/System.keychain 2>/dev/null)
		if [[ -n "${auth_legacy_super_password_saved}" ]]; then
			auth_service_account="${auth_legacy_super_account_saved}"
			auth_service_password="${auth_legacy_super_password_saved}"
			local auth_legacy_service_migrate
			auth_legacy_service_migrate="TRUE"
		else
			log_super "Auth Error: Unable to retrieve legacy super service account password."
			auth_error_new="TRUE"
		fi
	fi
	if [[ -n "${auth_legacy_jamf_account_saved}" ]]; then
		log_super "Status: Migrating saved legacy Jamf Pro API account credentials..."
		local auth_legacy_jamf_password_saved
		auth_legacy_jamf_password_saved=$(security find-generic-password -w -a "${auth_legacy_jamf_account_saved}" -s "Super MDM Account" /Library/Keychains/System.keychain 2>/dev/null)
		if [[ -n "${auth_legacy_jamf_password_saved}" ]]; then
			auth_jamf_account_option="${auth_legacy_jamf_account_saved}"
			auth_jamf_password_option="${auth_legacy_jamf_password_saved}"
			local auth_legacy_jamf_migrate
			auth_legacy_jamf_migrate="TRUE"
		else
			log_super "Auth Error: Unable to retrieve legacy Jamf Pro API account password."
			auth_error_new="TRUE"
		fi
	fi
	
	# This validates and saves to the keychain a single (non-end-user) Apple silicon authentication option. If multiple options are specified, only one is saved via the following priority order:
	# ${auth_ask_user_to_save_password} > ${auth_local_account_option} > ${auth_service_add_via_admin_account_option} > ${auth_jamf_client_option} > ${auth_jamf_account_option}
	if [[ "${auth_ask_user_to_save_password}" -eq 1 ]] || [[ "${auth_ask_user_to_save_password}" == "TRUE" ]]; then
		{ [[ -n "${auth_local_account_option}" ]] || [[ -n "${auth_service_add_via_admin_account_option}" ]] || [[ -n "${auth_jamf_client_option}" ]] || [[ -n "${auth_jamf_account_option}" ]]; } && log_super "Auth Warning: The --auth-ask-user-to-save-password option overrides all other Apple silicon authentication methods."
		[[ -n "${auth_local_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-local-account option."
		[[ -n "${auth_service_add_via_admin_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-service-add-via-admin-account option."
		[[ -n "${auth_jamf_client_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-client option."
		[[ -n "${auth_jamf_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-account option."
		[[ "${current_user_account_name}" != "FALSE" ]] && [[ "${auth_user_account_saved}" == "FALSE" ]] && log_super "Status: A new automatic authentication password will be saved the next time a valid user succesfully authenticates."
		# The ${auth_ask_user_to_save_password} option is saved later via the dialog_user_auth() function.
	elif [[ -n "${auth_local_account_option}" ]]; then
		{ [[ -n "${auth_service_add_via_admin_account_option}" ]] || [[ -n "${auth_jamf_client_option}" ]] || [[ -n "${auth_jamf_account_option}" ]]; } && log_super "Auth Warning: The --auth-local-account option overrides the --auth-service-add-via-admin-account option and any other Apple silicon MDM authentication methods."
		[[ -n "${auth_service_add_via_admin_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-service-add-via-admin-account option."
		[[ -n "${auth_jamf_client_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-client option."
		[[ -n "${auth_jamf_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-account option."
		[[ "${auth_legacy_local_migrate}" != "TRUE" ]] && log_super "Status: Validating new --auth-local-account credentials..."
		[[ "${auth_legacy_local_migrate}" == "TRUE" ]] && log_super "Status: Validating migrated --auth-local-account credentials..."
	
		# Validate that ${auth_local_account_option} exists, is a volume owner, and that ${auth_local_password_option} is correct.
		auth_local_account="${auth_local_account_option}"
		auth_local_password="${auth_local_password_option}"
		check_auth_local_account
		unset auth_local_account
		unset auth_local_password
		[[ "${auth_error_local}" == "TRUE" ]] && auth_error_new="TRUE"
	
		# If the ${auth_local_account_option} and ${auth_local_password_option} are valid then save credentials to keychain and then validate retrieval by setting ${auth_local_account_keychain} and ${auth_local_password_keychain}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			security add-generic-password -a "super_auth_local_account" -s "Super Update Service" -w "$(echo "${auth_local_account_option}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_local_account_keychain=$(security find-generic-password -w -a "super_auth_local_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_local_account_option}" != "${auth_local_account_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_option is: ${auth_local_account_option}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_keychain is: ${auth_local_account_keychain}"
				log_super "Auth Error: Unable to validate keychain item for --auth-local-account, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_local_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
			security add-generic-password -a "super_auth_local_password" -s "Super Update Service" -w "$(echo "${auth_local_password_option}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_local_password_keychain=$(security find-generic-password -w -a "super_auth_local_password" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_local_password_option}" != "${auth_local_password_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_password_option is: ${auth_local_password_option}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_password_keychain is: ${auth_local_password_keychain}"
				log_super "Auth Error: Unable to validate keychain item for --auth-local-password, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_local_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
		fi
	
		# If the saved credentials are valid then update ${SUPER_LOCAL_PLIST}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			[[ "${auth_legacy_local_migrate}" != "TRUE" ]] && log_super "Status: Saved new credentials for the --auth-local-account option."
			[[ "${auth_legacy_local_migrate}" == "TRUE" ]] && log_super "Status: Saved migrated credentials for the --auth-local-account option."
			defaults write "${SUPER_LOCAL_PLIST}" AuthLocalAccount -bool true
			auth_local_account_saved="TRUE"
		else
			[[ "${auth_legacy_local_migrate}" != "TRUE" ]] && log_super "Auth Error: The new --auth-local-account credentials will not be saved due to validation errors."
			[[ "${auth_legacy_local_migrate}" == "TRUE" ]] && log_super "Auth Error: The migrated --auth-local-account and credentials will not be saved due to validation errors."
			auth_local_account_saved="FALSE"
			unset auth_local_account_keychain
			unset auth_local_password_keychain
		fi
	elif [[ -n "${auth_service_add_via_admin_account_option}" ]] || [[ "${auth_legacy_service_migrate}" == "TRUE" ]]; then
		{ [[ -n "${auth_jamf_client_option}" ]] || [[ -n "${auth_jamf_account_option}" ]]; } && log_super "Auth Warning: The --auth-service-add-via-admin-account option overrides any other Apple silicon MDM authentication methods."
		[[ -n "${auth_jamf_client_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-client option."
		[[ -n "${auth_jamf_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-account option."
		[[ "${auth_legacy_service_migrate}" != "TRUE" ]] && log_super "Status: Creating and validating new super service account..."
		[[ "${auth_legacy_service_migrate}" == "TRUE" ]] && log_super "Status: Validating migratred super service account..."
	
		# Validate that ${auth_service_add_via_admin_account_option} exists, is a volume owner, a local admin, and that ${auth_service_add_via_admin_password_option} is correct.
		if [[ "${auth_legacy_service_migrate}" != "TRUE" ]]; then # If migrating a legacy sevice account, then the ${auth_service_add_via_admin_account_option} doesn't have to be validated.
			if [[ $(groups "${auth_service_add_via_admin_account_option}" 2>/dev/null | grep -c 'admin') -eq 0 ]]; then
				log_super "Auth Error: The account \"${auth_service_add_via_admin_account_option}\" is not a local administrator."
				auth_error_new="TRUE"
			fi
			if [[ "${auth_error_new}" != "TRUE" ]]; then
				auth_local_account="${auth_service_add_via_admin_account_option}"
				auth_local_password="${auth_service_add_via_admin_password_option}"
				check_auth_local_account
				unset auth_local_account
				unset auth_local_password
				[[ "${auth_error_local}" == "TRUE" ]] && auth_error_new="TRUE"
			fi
		fi
	
		# Set the ${auth_service_account}, ${auth_service_real_name}, and ${auth_service_password} in preparation to create the super service account.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			if [[ "${auth_legacy_service_migrate}" != "TRUE" ]]; then # If migrating a legacy sevice account, then a new service account doesn't have to be created.
				local auth_service_account
				local auth_service_real_name
				if [[ -n "${auth_service_account_option}" ]]; then
					auth_service_account="${auth_service_account_option}"
					auth_service_real_name="${auth_service_account_option}"
				else
					auth_service_account="super"
					auth_service_real_name="Super Update Service"
				fi
	
				local auth_service_password
				if [[ -n "${auth_service_password_option}" ]]; then
					auth_service_password="${auth_service_password_option}"
				else
					auth_service_password=$(uuidgen)
				fi
			fi
	
			# Save ${auth_service_account} and ${auth_service_password} credentials to keychain and then validate retrieval by setting ${auth_service_account_keychain} and ${auth_service_password_keychain}.
			security add-generic-password -a "super_auth_service_account" -s "Super Update Service" -w "$(echo "${auth_service_account}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_service_account_keychain=$(security find-generic-password -w -a "super_auth_service_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_service_account}" != "${auth_service_account_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account is: ${auth_service_account}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_keychain is: ${auth_service_account_keychain}"
				log_super "Auth Error: Unable to validate keychain item for the super service account, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_service_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
			security add-generic-password -a "super_auth_service_password" -s "Super Update Service" -w "$(echo "${auth_service_password}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_service_password_keychain=$(security find-generic-password -w -a "super_auth_service_password" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_service_password}" != "${auth_service_password_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_password is: ${auth_service_password}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_password_keychain is: ${auth_service_password_keychain}"
				log_super "Auth Error: Unable to validate keychain item for the super service password, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_service_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
		fi
	
		# If the saved credentials are valid then create the new super service account.
		if [[ "${auth_error_new}" != "TRUE" ]] && [[ "${auth_legacy_service_migrate}" != "TRUE" ]]; then # If migrating a legacy sevice account, then a new service account doesn't have to be created.
			local auth_service_uid
			auth_service_uid=501
			while [[ $(id "${auth_service_uid}" 2>&1 | grep -c 'no such user') -eq 0 ]]; do
				auth_service_uid=$((auth_service_uid + 1))
			done
			local sysadminctl_response
			sysadminctl_response=$(sysadminctl -addUser "${auth_service_account}" -fullName "${auth_service_real_name}" -password "${auth_service_password}" -UID "${auth_service_uid}" -GID 20 -shell "/dev/null" -home "/dev/null" -picture "${display_icon_light}" -adminUser "${auth_service_add_via_admin_account_option}" -adminPassword "${auth_service_add_via_admin_password_option}" 2>&1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: sysadminctl_response is:\n${sysadminctl_response}"
			dscl . create /Users/"${auth_service_account}" IsHidden 1
		fi
	
		# Validate the super service account locally.
		auth_local_account="${auth_service_account}"
		auth_local_password="${auth_service_password}"
		check_auth_local_account
		unset auth_local_account
		unset auth_local_password
		[[ "${auth_error_local}" == "TRUE" ]] && auth_error_new="TRUE"
	
		# If the super service account is valid then update ${SUPER_LOCAL_PLIST}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			[[ "${auth_legacy_service_migrate}" != "TRUE" ]] && log_super "Status: Created new super service account."
			[[ "${auth_legacy_service_migrate}" == "TRUE" ]] && log_super "Status: Validated migrated super service account."
			defaults write "${SUPER_LOCAL_PLIST}" AuthServiceAccount -bool true
			auth_service_account_saved="TRUE"
		else
			[[ "${auth_legacy_service_migrate}" != "TRUE" ]] && log_super "Auth Error: Unable to validate newly created super service account, deleting account"
			auth_error_new="TRUE"
			[[ "${auth_legacy_service_migrate}" == "TRUE" ]] && log_super "Auth Error: Unable to validate migrated super service account, deleting account."
			auth_error_new="TRUE"
			sysadminctl -deleteUser "${auth_service_account}" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_service_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			security delete-generic-password -a "super_auth_service_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_service_account_saved="FALSE"
			unset auth_service_account_keychain
			unset auth_service_password_keychain
		fi
	elif [[ -n "${auth_jamf_client_option}" ]]; then
		[[ -n "${auth_jamf_account_option}" ]] && log_super "Auth Warning: The --auth-jamf-client option overrides the --auth-jamf-account option."
		[[ -n "${auth_jamf_account_option}" ]] && log_super "Auth Warning: Ignoring the --auth-jamf-account option."
		log_super "Status: Validating new --auth-jamf-client credentials..."
	
		# Validate that the client ${auth_jamf_client_option} and ${auth_jamf_secret_option} are valid.
		auth_jamf_client="${auth_jamf_client_option}"
		auth_jamf_secret="${auth_jamf_secret_option}"
		check_jamf_api_credentials
		delete_jamf_api_access_token
		unset auth_jamf_client
		unset auth_jamf_secret
		[[ "${auth_error_jamf}" == "TRUE" ]] && auth_error_new="TRUE"
	
		# If the ${auth_jamf_client_option} and ${auth_jamf_secret_option} are valid then save credentials to keychain and then validate retrieval by setting ${auth_jamf_client_keychain} and ${auth_jamf_secret_keychain}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			security add-generic-password -a "super_auth_jamf_client" -s "Super Update Service" -w "$(echo "${auth_jamf_client_option}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_jamf_client_keychain=$(security find-generic-password -w -a "super_auth_jamf_client" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_jamf_client_option}" != "${auth_jamf_client_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_option is: ${auth_jamf_client_option}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_keychain is: ${auth_jamf_client_keychain}"
				log_super "Auth Error: Unable to validate keychain item for --auth-jamf-client, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_jamf_client" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
			security add-generic-password -a "super_auth_jamf_secret" -s "Super Update Service" -w "$(echo "${auth_jamf_secret_option}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_jamf_secret_keychain=$(security find-generic-password -w -a "super_auth_jamf_secret" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_jamf_secret_option}" != "${auth_jamf_secret_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_secret_option is: ${auth_jamf_secret_option}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_secret_keychain is: ${auth_jamf_secret_keychain}"
				log_super "Auth Error: Unable to validate keychain item for --auth-jamf-secret, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_jamf_secret" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
		fi
	
		# If the saved credentials are valid then update ${SUPER_LOCAL_PLIST}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			log_super "Status: Saved new credentials for the --auth-jamf-client option."
			defaults write "${SUPER_LOCAL_PLIST}" AuthJamfClient -bool true
			auth_jamf_client_saved="TRUE"
		else
			log_super "Auth Error: The --auth-jamf-client credentials will not be saved due to validation errors."
			auth_jamf_client_saved="FALSE"
			unset auth_jamf_client_keychain
			unset auth_jamf_secret_keychain
		fi
	elif [[ -n "${auth_jamf_account_option}" ]]; then
		[[ "${auth_legacy_jamf_migrate}" != "TRUE" ]] && log_super "Status: Validating new --auth-jamf-account credentials..."
		[[ "${auth_legacy_jamf_migrate}" == "TRUE" ]] && log_super "Status: Validating migrated --auth-jamf-account credentials..."
	
		# Validate that the account ${auth_jamf_account_option} and ${auth_jamf_password_option} are valid.
		auth_jamf_account="${auth_jamf_account_option}"
		auth_jamf_password="${auth_jamf_password_option}"
		check_jamf_api_credentials
		delete_jamf_api_access_token
		unset auth_jamf_account
		unset auth_jamf_password
		[[ "${auth_error_jamf}" == "TRUE" ]] && auth_error_new="TRUE"
	
		# If the ${super_auth_jamf_account} and ${super_auth_jamf_password} are valid then save credentials to keychain and then validate retrieval by setting ${auth_jamf_account_keychain} and ${auth_jamf_password_keychain}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			security add-generic-password -a "super_auth_jamf_account" -s "Super Update Service" -w "$(echo "${auth_jamf_account_option}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_jamf_account_keychain=$(security find-generic-password -w -a "super_auth_jamf_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_jamf_account_option}" != "${auth_jamf_account_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_option is: ${auth_jamf_account_option}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_keychain is: ${auth_jamf_account_keychain}"
				log_super "Auth Error: Unable to validate keychain item for --auth-jamf-account, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_jamf_account" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
			security add-generic-password -a "super_auth_jamf_password" -s "Super Update Service" -w "$(echo "${auth_jamf_password_option}" | base64)" -T "/usr/bin/security" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			auth_jamf_password_keychain=$(security find-generic-password -w -a "super_auth_jamf_password" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
			if [[ "${auth_jamf_password_option}" != "${auth_jamf_password_keychain}" ]]; then
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_password_option is: ${auth_jamf_password_option}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_password_keychain is: ${auth_jamf_password_keychain}"
				log_super "Auth Error: Unable to validate keychain item for --auth-jamf-password, deleting keychain item."
				auth_error_new="TRUE"
				security delete-generic-password -a "super_auth_jamf_password" "/Library/Keychains/System.keychain" >/dev/null 2>&1
			fi
		fi
	
		# If the saved credentials are valid then update ${SUPER_LOCAL_PLIST}.
		if [[ "${auth_error_new}" != "TRUE" ]]; then
			[[ "${auth_legacy_jamf_migrate}" != "TRUE" ]] && log_super "Status: Saved new credentials for the --auth-jamf-account option."
			[[ "${auth_legacy_jamf_migrate}" == "TRUE" ]] && log_super "Status: Saved migrated credentials for the --auth-jamf-account option."
			defaults write "${SUPER_LOCAL_PLIST}" AuthJamfAccount -bool true
			auth_jamf_account_saved="TRUE"
		else
			[[ "${auth_legacy_jamf_migrate}" != "TRUE" ]] && log_super "Auth Error: The new --auth-jamf-account credentials will not be saved due to validation errors."
			[[ "${auth_legacy_jamf_migrate}" == "TRUE" ]] && log_super "Auth Error: The migrated --auth-jamf-account credentials will not be saved due to validation errors."
			auth_jamf_account_saved="FALSE"
			unset auth_jamf_account_keychain
			unset auth_jamf_password_keychain
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_account_saved: ${auth_user_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_password_keychain: ${auth_user_password_keychain}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_saved: ${auth_local_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_saved: ${auth_service_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_saved: ${auth_jamf_client_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_saved: ${auth_jamf_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_error_new: ${auth_error_new}"
	
	# Delete any migrated legacy credentials.
	if [[ "${auth_error_new}" == "FALSE" ]]; then
		if [[ "${auth_legacy_local_migrate}" == "TRUE" ]]; then
			log_super "Status: Deleting saved credentials for legacy local account."
			defaults delete "${SUPER_LOCAL_PLIST}" LocalAccount >/dev/null 2>&1
			security delete-generic-password -a "${auth_legacy_local_account_saved}" -s "Super Local Account" /Library/Keychains/System.keychain >/dev/null 2>&1
		fi
		if [[ "${auth_legacy_service_migrate}" == "TRUE" ]]; then
			log_super "Status: Deleting saved credentials for legacy super service account."
			defaults delete "${SUPER_LOCAL_PLIST}" SuperAccount >/dev/null 2>&1
			security delete-generic-password -a "${auth_legacy_super_account_saved}" -s "Super Service Account" /Library/Keychains/System.keychain >/dev/null 2>&1
		fi
		if [[ "${auth_legacy_jamf_migrate}" == "TRUE" ]]; then
			log_super "Status: Deleting saved credentials for legacy Jamf Pro API account."
			defaults delete "${SUPER_LOCAL_PLIST}" JamfAccount >/dev/null 2>&1
			security delete-generic-password -a "${auth_legacy_jamf_account_saved}" -s "Super MDM Account" /Library/Keychains/System.keychain >/dev/null 2>&1
		fi
	fi
}

# This function determines what ${workflow_macos_auth} workflows are possible given the architecture and authentication options during startup.
manage_workflow_options() {
	workflow_auth_error="FALSE"
	
	# If the ${workflow_disable_update_check_option} is enabled then there is no reason to continue this function.
	[[ "${workflow_disable_update_check_option}" == "TRUE" ]] && return 0
	
	# Logic to determine update/upgrade workflow authentication method, assuming no ${auth_error_new}.
	if [[ "${auth_error_new}" != "TRUE" ]]; then
		if [[ "${mac_cpu_architecture}" == "i386" ]] || [[ "${workflow_only_download_active}" == "TRUE" ]]; then # All Intel workflows and the only download workflow do not need authentication.
			[[ "${workflow_only_download_active}" != "TRUE" ]] && log_super "Status: macOS update/upgrade workflows automatically authenticated via system account (root)."
			workflow_macos_auth="LOCAL"
		else # Standard workflow and computers with Apple silicon.
			if [[ "${auth_user_account_saved}" == "TRUE" ]] || [[ "${auth_local_account_saved}" == "TRUE" ]] || [[ "${auth_service_account_saved}" == "TRUE" ]]; then
				[[ "${auth_user_account_saved}" == "TRUE" ]] && log_super "Status: macOS update/upgrade workflows automatically authenticated via saved password for current user: ${current_user_account_name}"
				[[ "${auth_local_account_saved}" == "TRUE" ]] && log_super "Status: macOS update/upgrade workflows automatically authenticated via saved local account."
				[[ "${auth_service_account_saved}" == "TRUE" ]] && log_super "Status: macOS update/upgrade workflows automatically authenticated via super service account."
				workflow_macos_auth="LOCAL"
			elif [[ "${auth_jamf_client_saved}" == "TRUE" ]] || [[ "${auth_jamf_account_saved}" == "TRUE" ]]; then
				if [[ "${macos_version_number}" -ge 1103 ]]; then
					[[ -n "${auth_mdm_failover_to_user_option}" ]] && log_super "Status: macOS update/upgrade workflows automatically authenticated via Jamf Pro API with --auth-mdm-failover-to-user=${auth_mdm_failover_to_user_option}."
					[[ -z "${auth_mdm_failover_to_user_option}" ]] && log_super "Status: macOS update/upgrade workflows automatically authenticated via Jamf Pro API with no --auth-mdm-failover-to-user options."
					workflow_macos_auth="JAMF"
				else # Systems older than macOS 11.3.
					log_super "Warning: Automatic macOS update/upgrade enforcement via MDM is only available on macOS 11.3 or newer."
					if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${current_user_has_secure_token}" == "TRUE" ]] && [[ "${current_user_is_volume_owner}" == "TRUE" ]]; then
						log_super "Status: User authentication is required to perform a macOS update/upgrade."
						workflow_macos_auth="USER"
					else # No valid current user to authenticate workflow.
						workflow_auth_error="TRUE"
					fi
				fi
			else # No Apple silicon authentication options were provided.
				log_super "Warning: Automatic macOS update/upgrade enforcement on Apple Silicon computers requires authentication credentials."
				if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${current_user_has_secure_token}" == "TRUE" ]] && [[ "${current_user_is_volume_owner}" == "TRUE" ]]; then
					log_super "Status: User authentication is required to perform a macOS update/upgrade."
					workflow_macos_auth="USER"
				else # No valid current user to authenticate workflow.
					workflow_auth_error="TRUE"
				fi
			fi
		fi
	else # New authentication validation errors.
		if [[ "${auth_credential_failover_to_user_option}" == "TRUE" ]]; then
			if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${current_user_has_secure_token}" == "TRUE" ]] && [[ "${current_user_is_volume_owner}" == "TRUE" ]]; then
				log_super "Warning: Apple silicon authentication options could not be validated, failing over to user authenticated workflow."
				workflow_macos_auth="FAILOVER"
			else # No valid current user to authenticate workflow.
				log_super "Auth Error: Apple silicon authentication options could not be validated and user authentication failover is not currently possible."
				workflow_auth_error="TRUE"
			fi
		elif { [[ "${auth_jamf_client_saved}" -eq 1 ]] || [[ "${auth_jamf_account_saved}" -eq 1 ]]; } && { [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]] || [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ERROR') -gt 0 ]] || { [[ "${workflow_install_now_active}" == "TRUE" ]] && [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'INSTALLNOW') -gt 0 ]]; }; }; then
			if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${current_user_has_secure_token}" == "TRUE" ]] && [[ "${current_user_is_volume_owner}" == "TRUE" ]]; then
				log_super "Warning: Apple silicon MDM credentials could not be validated, failing over to user authenticated workflow."
				workflow_macos_auth="FAILOVER"
			else # No valid current user to authenticate workflow.
				log_super "Auth Error: Apple silicon MDM credentials could not be validated and user authentication failover is not currently possible."
				workflow_auth_error="TRUE"
			fi
		else # No authentication failover options.
			log_super "Exit: Apple silicon authentication options could not be validated and no failover option was specified, the workflow cannot continue."
			log_status "Inactive Error: Apple silicon authentication options could not be validated and no failover option was specified, the workflow cannot continue."
			{ [[ "${workflow_install_now_active}" == "TRUE" ]] && [[ "${current_user_account_name}" != "FALSE" ]]; } && notification_install_now_failed
			exit_error
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_auth_error is: ${workflow_auth_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_macos_auth is: ${workflow_macos_auth}"
	
	# Provide logging for ${workflow_auth_error} conditions, which at this point is a workflow-stopper.
	if [[ "${workflow_auth_error}" == "TRUE" ]]; then
		if [[ "${current_user_account_name}" == "FALSE" ]]; then
			log_super "Auth Error: No current active user to provide local authentication."
		else
			[[ "${current_user_has_secure_token}" == "FALSE" ]] && log_super "Auth Error: The user \"${current_user_account_name}\" does not have a secure token."
			[[ "${current_user_is_volume_owner}" == "FALSE" ]] && log_super "Auth Error: The user \"${current_user_account_name}\" is not a system volume owner."
		fi
	fi
	
	# Provide logging if there is a scheduled installation option that will fail without saved authentication, which at this point is a workflow-stopper.
	if { [[ -n "${scheduled_install_days}" ]] || [[ -n "${scheduled_install_date}" ]]; } && { [[ "${workflow_auth_error}" == "TRUE" ]] || [[ "${workflow_macos_auth}" == "USER" ]]; }; then
		log_super "Auth Error: The --scheduled-install-date and --scheduled-install-days options require valid saved authentication."
		workflow_auth_error="TRUE"
	fi
}

# For Apple Silicon computers this function validates previously saved update/upgrade credentials given the various --auth_* options. Any error will set ${auth_error_saved}.
get_saved_authentication() {
	auth_error_saved="FALSE"
	auth_user_saved_password_valid="FALSE"
	auth_local_account_valid="FALSE"
	auth_service_account_valid="FALSE"
	auth_jamf_client_valid="FALSE"
	auth_jamf_account_valid="FALSE"
	
	# If there is a previously saved user account then validate the credentials and set ${auth_local_account} and ${auth_local_password}.
	if [[ "${auth_ask_user_to_save_password}" -eq 1 ]] || [[ "${auth_ask_user_to_save_password}" == "TRUE" ]]; then
		[[ -z "${auth_user_password_keychain}" ]] && auth_user_password_keychain=$(launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security find-generic-password -w -a "super_auth_user_password" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" 2>&1)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_password_keychain: ${auth_user_password_keychain}"
		if [[ $(echo "${auth_user_password_keychain}" | grep -c 'The specified item could not be found in the keychain.') -ge 1 ]]; then
			log_super "Status: The --auth-ask-user-to-save-password option is enabled but a user password is not currently saved."
			log_super "Status: A new automatic authentication password will be saved the next time a valid user succesfully authenticates."
			auth_error_saved="TRUE"
			auth_user_account_saved="FALSE"
		elif [[ $(echo "${auth_user_password_keychain}" | grep -c 'Failed to get user context') -ge 1 ]]; then
			log_super "Warning: The user's keychain is not currently available, unable to validate saved credentials for user: ${current_user_account_name}."
			auth_error_saved="TRUE"
			auth_user_account_saved="FALSE"
		else
			auth_local_account="${current_user_account_name}"
			auth_local_password="${auth_user_password_keychain}"
			check_auth_local_account
			if [[ "${auth_error_local}" != "TRUE" ]]; then
				log_super "Status: Validated saved credentials for the current user: ${current_user_account_name}"
				auth_user_saved_password_valid="TRUE"
			else
				log_super "Warning: Unable to validate previously saved credentials for the current user: ${current_user_account_name}"
				unset auth_local_account
				unset auth_local_password
				launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security delete-generic-password -a "super_auth_user_password" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" >/dev/null 2>&1
				log_super "Status: A new automatic authentication password will be saved the next time a valid user succesfully authenticates."
				auth_error_saved="TRUE"
				auth_user_account_saved="FALSE"
			fi
		fi
		unset auth_user_password_keychain
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_ask_user_to_save_password: ${auth_ask_user_to_save_password}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_saved_password_valid: ${auth_user_saved_password_valid}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_account_saved: ${auth_user_account_saved}"
	
	# If there is a previously saved local account then validate the credentials and set ${auth_local_account} and ${auth_local_password}.
	if [[ "${auth_local_account_saved}" -eq 1 ]] || [[ "${auth_local_account_saved}" == "TRUE" ]]; then
		[[ -z "${auth_local_account_keychain}" ]] && auth_local_account_keychain=$(security find-generic-password -w -a "super_auth_local_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ -z "${auth_local_password_keychain}" ]] && auth_local_password_keychain=$(security find-generic-password -w -a "super_auth_local_password" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_keychain: ${auth_local_account_keychain}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_password_keychain: ${auth_local_password_keychain}"
		if [[ -n "${auth_local_account_keychain}" ]] && [[ -n "${auth_local_password_keychain}" ]]; then
			auth_local_account="${auth_local_account_keychain}"
			auth_local_password="${auth_local_password_keychain}"
			check_auth_local_account
			if [[ "${auth_error_local}" != "TRUE" ]]; then
				log_super "Status: Validated saved credentials for the --auth-local-account option."
				auth_local_account_valid="TRUE"
			else
				log_super "Auth Error: Unable to validate the saved --auth-local-account credentials."
				auth_error_saved="TRUE"
				unset auth_local_account
				unset auth_local_password
			fi
		else
			log_super "Auth Error: Unable to retrieve keychain items for the saved --auth-local-account credentials."
			auth_error_saved="TRUE"
		fi
		unset auth_local_account_keychain
		unset auth_local_password_keychain
	else
		auth_local_account_saved="FALSE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_saved: ${auth_local_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account_valid: ${auth_local_account_valid}"
	
	# If there is a previously saved super service account then validate the credentials and set ${auth_local_account} and ${auth_local_password}.
	if [[ "${auth_service_account_saved}" -eq 1 ]] || [[ "${auth_service_account_saved}" == "TRUE" ]]; then
		[[ -z "${auth_service_account_keychain}" ]] && auth_service_account_keychain=$(security find-generic-password -w -a "super_auth_service_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ -z "${auth_service_password_keychain}" ]] && auth_service_password_keychain=$(security find-generic-password -w -a "super_auth_service_password" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_keychain: ${auth_service_account_keychain}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_password_keychain: ${auth_service_password_keychain}"
		if [[ -n "${auth_service_account_keychain}" ]] && [[ -n "${auth_service_password_keychain}" ]]; then
			auth_local_account="${auth_service_account_keychain}"
			auth_local_password="${auth_service_password_keychain}"
			check_auth_local_account
			if [[ "${auth_error_local}" != "TRUE" ]]; then
				log_super "Status: Validated saved credentials for the super service account."
				auth_service_account_valid="TRUE"
			else
				log_super "Auth Error: Unable to validate the saved super service account credentials."
				auth_error_saved="TRUE"
				unset auth_local_account
				unset auth_local_password
			fi
		else
			log_super "Auth Error: Unable to retrieve keychain items for the saved super service account credentials."
			auth_error_saved="TRUE"
		fi
		unset auth_service_account_keychain
		unset auth_service_password_keychain
	else
		auth_service_account_saved="FALSE"
	fi
	
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_saved: ${auth_service_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_service_account_valid: ${auth_service_account_valid}"
	
	# If there is a previously saved Jamf Pro API client then validate the credentials and set ${auth_jamf_client} and ${auth_jamf_secret}.
	if [[ "${auth_jamf_client_saved}" -eq 1 ]] || [[ "${auth_jamf_client_saved}" == "TRUE" ]]; then
		[[ -z "${auth_jamf_client_keychain}" ]] && auth_jamf_client_keychain=$(security find-generic-password -w -a "super_auth_jamf_client" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ -z "${auth_jamf_secret_keychain}" ]] && auth_jamf_secret_keychain=$(security find-generic-password -w -a "super_auth_jamf_secret" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_keychain: ${auth_jamf_client_keychain}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_secret_keychain: ${auth_jamf_secret_keychain}"
		if [[ -n "${auth_jamf_client_keychain}" ]] && [[ -n "${auth_jamf_secret_keychain}" ]]; then
			auth_jamf_client="${auth_jamf_client_keychain}"
			auth_jamf_secret="${auth_jamf_secret_keychain}"
			check_jamf_api_credentials
			if [[ "${auth_error_jamf}" != "TRUE" ]]; then
				log_super "Status: Validated saved credentials for the --auth-jamf-client option."
				auth_jamf_client_valid="TRUE"
			else
				log_super "Auth Error: Unable to validate the saved --auth-jamf-client credentials."
				auth_error_saved="TRUE"
				unset auth_jamf_client
				unset auth_jamf_secret
			fi
		else
			log_super "Auth Error: Unable to retrieve keychain items for the saved --auth-jamf-client credentials."
			auth_error_saved="TRUE"
		fi
		unset auth_jamf_client_keychain
		unset auth_jamf_secret_keychain
	else
		auth_jamf_client_saved="FALSE"
	fi
	
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_saved: ${auth_jamf_client_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client_valid: ${auth_jamf_client_valid}"
	
	# If there is a previously saved Jamf Pro API account then validate the credentials and set ${auth_jamf_account} and ${auth_jamf_password}.
	if [[ "${auth_jamf_account_saved}" -eq 1 ]] || [[ "${auth_jamf_account_saved}" == "TRUE" ]]; then
		[[ -z "${auth_jamf_account_keychain}" ]] && auth_jamf_account_keychain=$(security find-generic-password -w -a "super_auth_jamf_account" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ -z "${auth_jamf_password_keychain}" ]] && auth_jamf_password_keychain=$(security find-generic-password -w -a "super_auth_jamf_password" "/Library/Keychains/System.keychain" 2>/dev/null | base64 --decode)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_keychain: ${auth_jamf_account_keychain}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_password_keychain: ${auth_jamf_password_keychain}"
		if [[ -n "${auth_jamf_account_keychain}" ]] && [[ -n "${auth_jamf_password_keychain}" ]]; then
			auth_jamf_account="${auth_jamf_account_keychain}"
			auth_jamf_password="${auth_jamf_password_keychain}"
			check_jamf_api_credentials
			if [[ "${auth_error_jamf}" != "TRUE" ]]; then
				log_super "Status: Validated saved credentials for the --auth-jamf-account option."
				auth_jamf_account_valid="TRUE"
			else
				log_super "Auth Error: Unable to validate the saved --auth-jamf-account credentials."
				auth_error_saved="TRUE"
				unset auth_jamf_account
				unset auth_jamf_password
			fi
		else
			log_super "Auth Error: Unable to retrieve keychain items for the saved --auth-jamf-account credentials."
			auth_error_saved="TRUE"
		fi
		unset auth_jamf_account_keychain
		unset auth_jamf_password_keychain
	else
		auth_jamf_account_saved="FALSE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_saved: ${auth_jamf_account_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account_valid: ${auth_jamf_account_valid}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_error_saved: ${auth_error_saved}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account: ${auth_local_account}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_password: ${auth_local_password}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client: ${auth_jamf_client}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_secret: ${auth_jamf_secret}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account: ${auth_jamf_account}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_password: ${auth_jamf_password}"
}

# MARK: *** Installation & Startup ***
################################################################################

# Install items required for super.
workflow_installation() {
	[[ ! -d "${SUPER_FOLDER}" ]] && mkdir -p "${SUPER_FOLDER}"
	[[ ! -d "${SUPER_LOG_FOLDER}" ]] && mkdir -p "${SUPER_LOG_FOLDER}"
	[[ ! -d "${SUPER_LOG_ARCHIVE_FOLDER}" ]] && mkdir -p "${SUPER_LOG_ARCHIVE_FOLDER}"
	log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - SUPER INSTALLATION ****"
	log_status "Running: Installation workflow."
	
	log_super "Installation: Copying super to: ${SUPER_FOLDER}/super"
	cp "$0" "${SUPER_FOLDER}/super" >/dev/null 2>&1
	if [[ ! -d "/usr/local/bin" ]]; then
		log_super "Installation: Creating local search path folder: /usr/local/bin"
		mkdir -p "/usr/local/bin"
		chmod -R a+rx "/usr/local/bin"
	fi
	
	log_super "Installation: Creating super search path link: ${SUPER_LINK}"
	ln -s "${SUPER_FOLDER}/super" "${SUPER_LINK}" >/dev/null 2>&1
	
	log_super "Installation: Creating super LaunchDaemon helper: ${SUPER_FOLDER}/super-starter"
	/bin/cat <<EOSS >"${SUPER_FOLDER}/super-starter"
#!/bin/bash
# S.U.P.E.R.M.A.N. STARTER
# Software Update/Upgrade Policy Enforcement (with) Recursive Messaging And Notification
# https://github.com/Macjutsu/super
# by Kevin M. White

# This script is ran by launchd every 60 seconds per the /Library/LaunchDaemons/com.macjutsu.super.plist.
# This script checks a variety of settings to ensure that the super workflow only restarts when necissary.
# Version ${SUPER_VERSION}
# ${SUPER_DATE}

# Exit this script if super is already running.
[[ "\$(pgrep -F "${SUPER_PID_FILE}" 2> /dev/null)" ]] && exit 0

# Exit this script if the super auto launch workflow is disabled.
next_auto_launch=\$(/usr/libexec/PlistBuddy -c "Print :NextAutoLaunch" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null)
if [[ "\${next_auto_launch}" == "FALSE" ]] || [[ "\${next_auto_launch}" == "false" ]]; then
	exit 0
fi

# Exit this script if the super auto launch workflow is deferred until a system restart.
if [[ "\$(/usr/libexec/PlistBuddy -c "Print :WorkflowRestartValidate" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null)" == "true" ]]; then
	mac_last_startup_saved_epoch=\$(date -j -f %Y-%m-%d:%H:%M:%S "\$(/usr/libexec/PlistBuddy -c "Print :MacLastStartup" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null)" +%s 2> /dev/null)
	kernel_boot_epoch=\$(sysctl -n kern.boottime | awk -F 'sec = |, usec' '{print \$2}')
	[[ -n "\${mac_last_startup_saved_epoch}" ]] && [[ -n "\${kernel_boot_epoch}" ]] && [[ "\${mac_last_startup_saved_epoch}" -ge "\${kernel_boot_epoch}" ]] && exit 0
fi

# Exit this script if the super auto launch workflow is deferred until a later date
if [[ \$(date +%s) -lt \$(date -j -f %Y-%m-%d:%H:%M:%S "\${next_auto_launch}" +%s 2> /dev/null) ]]; then
	exit 0
fi

# If this script has not exited yet, then it's time to start the super workflow.
echo "\$(date +"%a %b %d %T") \$(hostname -s) \$(basename "\$0")[\$\$]: **** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - LAUNCHDAEMON ****" | tee -a "${SUPER_LOG}"
"${SUPER_FOLDER}/super" &
disown -a
exit 0
EOSS
	
	if [[ -f "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist" ]]; then
		log_super "Installation: Removing previous super LaunchDaemon: /Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist"
		launchctl bootout system "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist" 2>/dev/null
		rm -f "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist" 2>/dev/null
	fi
	
	log_super "Installation: Creating super LaunchDaemon: /Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist."
	/bin/cat <<EOLDL >"/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${SUPER_LAUNCH_DAEMON_LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${SUPER_FOLDER}/super-starter</string>
	</array>
	<key>UserName</key>
	<string>root</string>
	<key>AbandonProcessGroup</key>
	<true/>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>60</integer>
</dict>
</plist>
EOLDL
	
	log_super "Installation: Setting permissions for installed super items."
	chown -R root:wheel "${SUPER_FOLDER}"
	chmod -R a+r "${SUPER_FOLDER}"
	chmod -R go-w "${SUPER_FOLDER}"
	chmod a+x "${SUPER_FOLDER}/super"
	chmod a+x "${SUPER_FOLDER}/super-starter"
	chown root:wheel "${SUPER_LINK}"
	chmod a+rx "${SUPER_LINK}"
	chmod go-w "${SUPER_LINK}"
	chmod 644 "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist"
	chown root:wheel "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist"
	defaults write "${SUPER_LOCAL_PLIST}" SuperVersion -string "${SUPER_VERSION}"
}

# Download and install the IBM Notifier.app.
get_ibm_notifier() {
	log_super "Status: Attempting to download and install IBM Notifier.app..."
	local previous_umask
	previous_umask=$(umask)
	umask 077
	local temp_file
	temp_file="$(mktemp).zip"
	local download_response
	download_response=$(curl --location "${IBM_NOTIFIER_DOWNLOAD_URL}" --output "${temp_file}" 2>&1)
	if [[ -f "${temp_file}" ]]; then
		local unzip_response
		unzip_response=$(unzip "${temp_file}" -d "${SUPER_FOLDER}/" 2>&1)
		if [[ -d "${IBM_NOTIFIER_APP}" ]]; then
			[[ -d "${SUPER_FOLDER}/__MACOSX" ]] && rm -Rf "${SUPER_FOLDER}/__MACOSX" >/dev/null 2>&1
			chmod -R a+rx "${IBM_NOTIFIER_APP}"
		else
			log_super "Error: Unable to install IBM Notifier.app."
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: unzip_response is:\n${unzip_response}"
		fi
	else
		log_super "Error: Unable to download IBM Notifier.app from: ${IBM_NOTIFIER_DOWNLOAD_URL}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_response is:\n${download_response}"
	fi
	rm -Rf "${temp_file}" >/dev/null 2>&1
	umask "${previous_umask}"
}

# Check the IBM Notifier.app for validity.
check_ibm_notifier() {
	ibm_notifier_valid="FALSE"
	local codesign_response
	codesign_response=$(codesign --verify --verbose "${IBM_NOTIFIER_APP}" 2>&1)
	if [[ $(echo "${codesign_response}" | grep -c 'valid on disk') -gt 0 ]]; then
		local version_response
		version_response=$(defaults read "${IBM_NOTIFIER_APP}/Contents/Info.plist" CFBundleShortVersionString)
		if [[ "${IBM_NOTIFIER_TARGET_VERSION}" == "${version_response}" ]]; then
			ibm_notifier_valid="TRUE"
		else
			log_super "Warning: IBM Notifier at path: ${IBM_NOTIFIER_APP} is version ${version_response}, this does not match target version ${IBM_NOTIFIER_TARGET_VERSION}."
		fi
	else
		log_super "Warning: unable validate signature for IBM Notifier at path: ${IBM_NOTIFIER_APP}."
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: codesign_response is:\n${codesign_response}"
	fi
}

# Locate and verify ${get_display_icon_path} and, if valid save, to ${get_display_icon_temp_file}.
get_display_icon() {
	get_display_icon_error="FALSE"
	local previous_umask
	previous_umask=$(umask)
	umask 066
	local get_response
	get_display_icon_temp_file=$(mktemp)
	if [[ "${get_display_icon_path}" =~ ${REGEX_HTML_URL} ]]; then
		log_super "Status: Attempting to download new requested display icon from URL source..."
		get_response=$(curl --location "${get_display_icon_path}" --output "${get_display_icon_temp_file}" 2>&1)
		if [[ ! -f "${get_display_icon_temp_file}" ]]; then
			log_super "Helper Error: Unable to download display icon file from: ${get_display_icon_path}"
			get_display_icon_error="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_response is:\n${get_response}"
		fi
	else # Local file copy.
		log_super "Status: Attempting to copy new requested display icon from local path..."
		get_response=$(cp "${get_display_icon_path}" "${get_display_icon_temp_file}" 2>&1)
		if [[ ! -f "${get_display_icon_temp_file}" ]]; then
			log_super "Helper Error: Unable to copy display icon file from: ${get_display_icon_path}"
			get_display_icon_error="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_response is:\n${get_response}"
		fi
	fi
	if [[ "${get_display_icon_error}" == "FALSE" ]]; then
		local sips_response
		sips_response=$(sips --setProperty format png "${get_display_icon_temp_file}" --out "${get_display_icon_temp_file}.png" 2>&1)
		if [[ ! -f "${get_display_icon_temp_file}.png" ]] || [[ $(echo "${sips_response}" | grep -c 'Warning') -gt 0 ]] || [[ $(echo "${sips_response}" | grep -c 'Error') -gt 0 ]]; then
			log_super "Helper Error: Unable convert display icon file to PNG."
			get_display_icon_error="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: sips_response is:\n${sips_response}"
		fi
	fi
	rm -Rf "${get_display_icon_temp_file}" >/dev/null 2>&1
	umask "${previous_umask}"
	unset get_display_icon_path
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_display_icon_error is: ${get_display_icon_error}"
}

# Download and install mist-cli.
get_mist_cli() {
	log_super "Status: Attempting to download and install mist-cli..."
	local previous_umask
	previous_umask=$(umask)
	umask 077
	local temp_file
	temp_file="$(mktemp).pkg"
	local download_response
	download_response=$(curl --location "${MIST_CLI_DOWNLOAD_URL}" --output "${temp_file}" 2>&1)
	if [[ -f "${temp_file}" ]]; then
		local install_response
		install_response=$(installer -verboseR -pkg "${temp_file}" -target / 2>&1)
		if ! { [[ $(echo "${install_response}" | grep -c 'The software was successfully installed.') -gt 0 ]] || [[ $(echo "${install_response}" | grep -c 'The install was successful.') -gt 0 ]]; }; then
			log_super "Error: Unable to install mist-cli."
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_response is:\n${install_response}"
		fi
	else
		log_super "Error: Unable to download mist-cli.pkg from: ${MIST_CLI_DOWNLOAD_URL}."
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_response is:\n${download_response}"
	fi
	rm -Rf "${temp_file}" >/dev/null 2>&1
	umask "${previous_umask}"
}

# Check mist-cli for validity.
check_mist_cli() {
	mist_cli_valid="FALSE"
	local codesign_response
	codesign_response=$(codesign --verify --verbose "${MIST_CLI_BINARY}" 2>&1)
	if [[ $(echo "${codesign_response}" | grep -c 'valid on disk') -gt 0 ]]; then
		local version_response
		version_response=$("${MIST_CLI_BINARY}" --version | head -1 | awk '{print $1;}')
		if [[ "${MIST_CLI_TARGET_VERSION}" == "${version_response}" ]]; then
			mist_cli_valid="TRUE"
		else
			log_super "Warning: mist-cli at path: ${MIST_CLI_BINARY} is version ${version_response}, this does not match target version ${MIST_CLI_TARGET_VERSION}."
		fi
	else
		log_super "Warning: unable validate signature for mist-cli at path: ${MIST_CLI_BINARY}."
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: codesign_response is:\n${codesign_response}"
	fi
}

# Install and validate helper items that may be used by super.
manage_helpers() {
	helper_error="FALSE"
	# Validate the IBM Notifier.app, if missing or invalid then install and check again.
	if [[ ! -d "${IBM_NOTIFIER_APP}" ]]; then
		get_ibm_notifier
		[[ -d "${IBM_NOTIFIER_APP}" ]] && check_ibm_notifier
		[[ "${ibm_notifier_valid}" == "FALSE" ]] && log_super "Error: Unable to validate IBM Notifier.app after installation."
	else # IBM Notifier.app is already installed.
		check_ibm_notifier
		if [[ "${ibm_notifier_valid}" == "FALSE" ]]; then
			log_super "Status: Removing previously installed IBM Notifier.app."
			rm -Rf "${IBM_NOTIFIER_APP}" >/dev/null 2>&1
			[[ -d "${SUPER_FOLDER}/__MACOSX" ]] && rm -Rf "${SUPER_FOLDER}/__MACOSX" >/dev/null 2>&1
			get_ibm_notifier
			[[ -d "${IBM_NOTIFIER_APP}" ]] && check_ibm_notifier
		fi
		[[ "${ibm_notifier_valid}" == "FALSE" ]] && log_super "Error: Unable to validate IBM Notifier.app after re-installation."
	fi
	[[ "${ibm_notifier_valid}" == "FALSE" ]] && helper_error="TRUE"
	
	# Set the ${display_icon_light} by validating the ${DISPLAY_ICON_LIGHT_FILE_CACHE}, if missing or changed, then get a new display icon light file or fail over to local ${DISPLAY_ICON_DEFAULT_FILE}.
	local display_icon_light_file_cached_origin
	display_icon_light_file_cached_origin=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayIconLightFileCachedOrigin 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_light_file_cached_origin is: ${display_icon_light_file_cached_origin}"
	if [[ -f "${DISPLAY_ICON_LIGHT_FILE_CACHE}" ]] && [[ "${display_icon_light_file_path}" == "${display_icon_light_file_cached_origin}" ]]; then
		display_icon_light="${DISPLAY_ICON_LIGHT_FILE_CACHE}"
	else # Need to get a new ${DISPLAY_ICON_LIGHT_FILE_CACHE} or fail over to local ${DISPLAY_ICON_DEFAULT_FILE}.
		[[ -f "${DISPLAY_ICON_LIGHT_FILE_CACHE}" ]] && rm -f "${DISPLAY_ICON_LIGHT_FILE_CACHE}" 2>/dev/null
		if [[ "${display_icon_light_file_path}" != "FALSE" ]]; then
			defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconLightFileCachedOrigin 2>/dev/null
			get_display_icon_path="${display_icon_light_file_path}"
			get_display_icon
			if [[ "${get_display_icon_error}" == "FALSE" ]]; then
				log_super "Status: Validated new diplay icon for light mode sourced from: ${display_icon_light_file_path}"
				cp "${get_display_icon_temp_file}.png" "${DISPLAY_ICON_LIGHT_FILE_CACHE}" 2>/dev/null 2>&1
				display_icon_light="${DISPLAY_ICON_LIGHT_FILE_CACHE}"
				chmod a+r "${DISPLAY_ICON_LIGHT_FILE_CACHE}"  2>/dev/null 2>&1
				rm -Rf "${get_display_icon_temp_file}.png" >/dev/null 2>&1
				unset get_display_icon_temp_file
				defaults write "${SUPER_LOCAL_PLIST}" DisplayIconLightFileCachedOrigin -string "${display_icon_light_file_path}"
			else
				log_super "Helper Warning: Unable to locate requested display icon for light mode, using default display icon: ${DISPLAY_ICON_DEFAULT_FILE}"
				display_icon_light="${DISPLAY_ICON_DEFAULT_FILE}"
			fi
		else # Using failover ${DISPLAY_ICON_DEFAULT_FILE}.
			if [[ "${display_icon_light_file_cached_origin}" == "DEFAULT" ]]; then
				display_icon_light="${DISPLAY_ICON_DEFAULT_FILE}"
			else
				log_super "Status: No display icon for light mode specified, setting to default display icon: ${DISPLAY_ICON_DEFAULT_FILE}"
				defaults write "${SUPER_LOCAL_PLIST}" DisplayIconLightFileCachedOrigin -string "DEFAULT"
				display_icon_light="${DISPLAY_ICON_DEFAULT_FILE}"
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_light is: ${display_icon_light}"
	
	# Set the ${display_icon_dark} by validating the ${DISPLAY_ICON_DARK_FILE_CACHE}, if missing or changed, then get a new display icon dark file or fail over to local ${DISPLAY_ICON_DEFAULT_FILE}.
	local display_icon_dark_file_cached_origin
	display_icon_dark_file_cached_origin=$(defaults read "${SUPER_LOCAL_PLIST}" DisplayIconDarkFileCachedOrigin 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_dark_file_cached_origin is: ${display_icon_dark_file_cached_origin}"
	if [[ -f "${DISPLAY_ICON_DARK_FILE_CACHE}" ]] && [[ "${display_icon_dark_file_path}" == "${display_icon_dark_file_cached_origin}" ]]; then
		display_icon_dark="${DISPLAY_ICON_DARK_FILE_CACHE}"
	else # Need to get a new ${DISPLAY_ICON_DARK_FILE_CACHE} or fail over to local ${DISPLAY_ICON_DEFAULT_FILE}.
		[[ -f "${DISPLAY_ICON_DARK_FILE_CACHE}" ]] && rm -f "${DISPLAY_ICON_DARK_FILE_CACHE}" 2>/dev/null
		if [[ "${display_icon_dark_file_path}" != "FALSE" ]]; then
			defaults delete "${SUPER_LOCAL_PLIST}" DisplayIconDarkFileCachedOrigin 2>/dev/null
			get_display_icon_path="${display_icon_dark_file_path}"
			get_display_icon
			if [[ "${get_display_icon_error}" == "FALSE" ]]; then
				log_super "Status: Validated new diplay icon for dark mode sourced from: ${display_icon_dark_file_path}"
				cp "${get_display_icon_temp_file}.png" "${DISPLAY_ICON_DARK_FILE_CACHE}" 2>/dev/null 2>&1
				display_icon_dark="${DISPLAY_ICON_DARK_FILE_CACHE}"
				chmod a+r "${DISPLAY_ICON_DARK_FILE_CACHE}"  2>/dev/null 2>&1
				rm -Rf "${get_display_icon_temp_file}.png" >/dev/null 2>&1
				unset get_display_icon_temp_file
				defaults write "${SUPER_LOCAL_PLIST}" DisplayIconDarkFileCachedOrigin -string "${display_icon_dark_file_path}"
			else
				log_super "Helper Warning: Unable to locate requested display icon for dark mode, using default display icon: ${DISPLAY_ICON_DEFAULT_FILE}"
				display_icon_dark="${DISPLAY_ICON_DEFAULT_FILE}"
			fi
		else # Using failover ${DISPLAY_ICON_DEFAULT_FILE}.
			if [[ "${display_icon_dark_file_cached_origin}" == "DEFAULT" ]]; then
				display_icon_dark="${DISPLAY_ICON_DEFAULT_FILE}"
			else
				log_super "Status: No display icon for dark mode specified, setting to default display icon: ${DISPLAY_ICON_DEFAULT_FILE}"
				defaults write "${SUPER_LOCAL_PLIST}" DisplayIconDarkFileCachedOrigin -string "DEFAULT"
				display_icon_dark="${DISPLAY_ICON_DEFAULT_FILE}"
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_icon_dark is: ${display_icon_dark}"
	
	# If needed, validate mist-cli and if missing or invalid then install and check again.
	if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && { [[ "${macos_version_major}" -lt 13 ]] || [[ -n "${install_macos_major_upgrades_target}" ]]; }; then
		if [[ ! -f "${MIST_CLI_BINARY}" ]]; then
			get_mist_cli
			[[ -f "${MIST_CLI_BINARY}" ]] && check_mist_cli
			[[ "${mist_cli_valid}" == "FALSE" ]] && log_super "Error: Unable to validate mist-cli after installation."
		else
			check_mist_cli
			if [[ "${mist_cli_valid}" == "FALSE" ]]; then
				log_super "Status: Removing previously installed mist-cli."
				rm -Rf "${MIST_CLI_BINARY}" >/dev/null 2>&1
				get_mist_cli
				[[ -f "${MIST_CLI_BINARY}" ]] && check_mist_cli
			fi
			[[ "${mist_cli_valid}" == "FALSE" ]] && log_super "Error: Unable to validate mist-cli after re-installation."
		fi
		[[ "${mist_cli_valid}" == "FALSE" ]] && helper_error="TRUE"
	fi
}

# Prepare super by cleaning after previous super runs, record various maintenance modes, validate parameters, and if necessary restart via the super LaunchDaemon.
workflow_startup() {
	# Make sure super is running as root.
	if [[ $(id -u) -ne 0 ]]; then
		log_echo "Exit: super must run with root privileges."
		exit 1
	fi
	
	# Make sure macOS meets the minimum requirement of macOS 11.
	macos_version_major=$(sw_vers -productVersion | cut -d'.' -f1) # Expected output: 10, 11, 12
	if [[ "${macos_version_major}" -lt 11 ]]; then
		if [[ -d "${SUPER_FOLDER}" ]]; then
			log_super "Exit: This computer is running macOS ${macos_version_major} and super requires macOS 11 Big Sur or newer."
			exit_error
		else # super is not installed yet.
			log_echo "Exit: This computer is running macOS ${macos_version_major} and super requires macOS 11 Big Sur or newer."
			exit 1
		fi
	fi
	
	# Check for any previous super processes and kill them.
	killall -9 "softwareupdate" "mist" >/dev/null 2>&1
	killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
	local super_previous_pid
	super_previous_pid=$(pgrep -F "${SUPER_PID_FILE}" 2>/dev/null)
	if [[ -n "${super_previous_pid}" ]]; then
		[[ -d "${SUPER_LOG_FOLDER}" ]] && log_super "Status: Found previous super instance running with PID ${super_previous_pid}, killing processes..."
		[[ ! -d "${SUPER_LOG_FOLDER}" ]] && log_echo "Status: Found previous super instance running with PID ${super_previous_pid}, killing processes..."
		kill -9 "${super_previous_pid}" >/dev/null 2>&1
	fi
	
	# Create new ${SUPER_PID_FILE} for this instance of super.
	echo $$ >"${SUPER_PID_FILE}"
	
	# If super crashes or the system restarts unexpectedly before super exits, then automatically launch again.
	/usr/libexec/PlistBuddy -c "Delete :NextAutoLaunch" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
	
	# Check for super installation.
	local super_current_folder
	super_current_folder=$(dirname "$0")
	! { [[ "${super_current_folder}" == "${SUPER_FOLDER}" ]] || [[ "${super_current_folder}" == $(dirname "${SUPER_LINK}") ]]; } && workflow_installation
	
	# Check for logs that need to be archived.
	archive_logs
	
	# After installation is verified, the startup workflow can begin.
	log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - SUPER STARTUP ****"
	log_status "Running: Startup workflow."
	
	# Manage the ${verbose_mode_option} and if enabled start additional logging.
	[[ "${reset_super_option}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" VerboseMode 2>/dev/null
	if [[ -f "${SUPER_MANAGED_PLIST}.plist" ]]; then
		local verbose_mode_managed
		verbose_mode_managed=$(defaults read "${SUPER_MANAGED_PLIST}" VerboseMode 2>/dev/null)
	fi
	if [[ -f "${SUPER_LOCAL_PLIST}.plist" ]]; then
		local verbose_mode_local
		verbose_mode_local=$(defaults read "${SUPER_LOCAL_PLIST}" VerboseMode 2>/dev/null)
	fi
	[[ -n "${verbose_mode_managed}" ]] && verbose_mode_option="${verbose_mode_managed}"
	{ [[ -z "${verbose_mode_managed}" ]] && [[ -z "${verbose_mode_option}" ]] && [[ -n "${verbose_mode_local}" ]]; } && verbose_mode_option="${verbose_mode_local}"
	if [[ "${verbose_mode_option}" -eq 1 ]] || [[ "${verbose_mode_option}" == "TRUE" ]]; then
		verbose_mode_option="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" VerboseMode -bool true
	else
		verbose_mode_option="FALSE"
		defaults delete "${SUPER_LOCAL_PLIST}" VerboseMode 2>/dev/null
	fi
	if [[ "${verbose_mode_option}" == "TRUE" ]]; then
		log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Verbose mode enabled."
		log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: super_current_folder is: ${super_current_folder}"
		log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Uptime is: $(uptime)"
	fi
	
	# In case super is running at system startup, wait for the loginwindow process before continuing.
	local startup_timeout
	startup_timeout=0
	while [[ ! $(pgrep "loginwindow") ]] && [[ "${startup_timeout}" -lt 600 ]]; do
		log_super "Status: Waiting for macOS startup to complete..."
		sleep 10
		startup_timeout=$((startup_timeout + 10))
	done
	
	# Detailed system and user checks.
	check_system
	check_current_user
	check_msu_settings
	
	# Workflow for for ${open_logs_option}.
	if [[ "${open_logs_option}" == "TRUE" ]]; then
		if [[ "${current_user_account_name}" != "FALSE" ]]; then
			log_super "Status: Opening logs for current user: ${current_user_account_name}."
			if [[ "${mac_cpu_architecture}" == "arm64" ]]; then
				touch "${MDM_WORKFLOW_LOG}" "${MDM_WORKFLOW_DEBUG_LOG}" "${MDM_COMMAND_LOG}" "${MDM_COMMAND_DEBUG_LOG}"
				sudo -u "${current_user_account_name}" open "${MDM_WORKFLOW_LOG}"
				sudo -u "${current_user_account_name}" open "${MDM_WORKFLOW_DEBUG_LOG}"
				sudo -u "${current_user_account_name}" open "${MDM_COMMAND_LOG}"
				sudo -u "${current_user_account_name}" open "${MDM_COMMAND_DEBUG_LOG}"
			fi
			touch "${INSTALLER_WORKFLOW_LOG}" "${MSU_WORKFLOW_LOG}" "${MACOS_INSTALLERS_LIST_LOG}" "${MDMCLIENT_LIST_LOG}" "${MSU_LIST_LOG}" "${SUPER_LOG}"
			sudo -u "${current_user_account_name}" open "${INSTALLER_WORKFLOW_LOG}"
			sudo -u "${current_user_account_name}" open "${MSU_WORKFLOW_LOG}"
			sudo -u "${current_user_account_name}" open "${MACOS_INSTALLERS_LIST_LOG}"
			sudo -u "${current_user_account_name}" open "${MDMCLIENT_LIST_LOG}"
			sudo -u "${current_user_account_name}" open "${MSU_LIST_LOG}"
			sudo -u "${current_user_account_name}" open "${SUPER_LOG}"
		else # No current GUI user.
			log_super "Warning: Can't open logs because there is currently no local user logged into the GUI."
		fi
	fi
	
	# Initial Parameter and helper validation, if any of these fail then it's unsafe for the workflow to continue.
	get_preferences
	check_jamf_management_framework
	manage_parameter_options
	manage_helpers
	if [[ "${check_error}" == "TRUE" ]] || [[ "${option_error}" == "TRUE" ]] || [[ "${helper_error}" == "TRUE" ]]; then
		log_super "Exit: Initial startup validation failed."
		log_status "Inactive Error: Initial startup validation failed."
		exit_error
	fi
	
	# Initial preparation for various workflow modes. This enforces a hierarchy of workflows as follows: Restart Validate > Install Now > Scheduled Installation > Only Download > Default Workflow.
	[[ "${test_mode_option}" == "TRUE" ]] && log_super "Status: Test mode active with ${test_mode_timeout_seconds} second timeout."
	local workflow_restart_validate_local
	workflow_restart_validate_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowRestartValidate 2>/dev/null)
	local workflow_scheduled_install_local
	workflow_scheduled_install_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null)
	local workflow_scheduled_install_local
	workflow_reset_super_after_completion_local=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletion 2>/dev/null)
	if [[ "${workflow_restart_validate_local}" -eq 1 ]]; then
		log_super "Status: Restart validation workflow active."
		workflow_restart_validate_active="TRUE"
	elif [[ "${workflow_install_now_option}" == "TRUE" ]]; then
		log_super "Status: Install now workflow active."
		workflow_install_now_active="TRUE"
		[[ $(echo "${display_unmovable_option}" | grep -c 'INSTALLNOW') -gt 0 ]] && display_unmovable_status="TRUE"
		[[ $(echo "${display_hide_background_option}" | grep -c 'INSTALLNOW') -gt 0 ]] && display_hide_background_status="TRUE"
		[[ $(echo "${display_silently_option}" | grep -c 'INSTALLNOW') -gt 0 ]] && display_silently_status="TRUE"
		[[ $(echo "${display_notifications_centered_option}" | grep -c 'INSTALLNOW') -gt 0 ]] && display_notifications_centered_status="TRUE"
		[[ $(echo "${display_hide_progress_bar_option}" | grep -c 'INSTALLNOW') -gt 0 ]] && display_hide_progress_bar_status="TRUE"
		if [[ "${current_user_account_name}" != "FALSE" ]]; then
			notification_install_now_start
			if [[ "${test_mode_option}" == "TRUE" ]]; then
				log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the install now start notification..."
				sleep "${test_mode_timeout_seconds}"
			fi
		fi
		if [[ -n "${workflow_scheduled_install_local}" ]]; then
			log_super "Warning: Removing previously scheduled installation workflow due to current install now workflow."
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
		fi
	elif [[ "${workflow_scheduled_install_local}" =~ ${REGEX_DATE_HOURS_MINUTES} ]]; then
		workflow_scheduled_install="${workflow_scheduled_install_local}"
		log_super "Status: Previously scheduled installation workflow active for: ${workflow_scheduled_install}"
		workflow_scheduled_install_active="TRUE"
	elif [[ "${workflow_only_download_option}" == "TRUE" ]]; then
		log_super "Status: Only download workflow active."
		workflow_only_download_active="TRUE"
	fi
	{ [[ "${workflow_only_download_active}" != "TRUE" ]] && [[ -n "${install_jamf_policy_triggers_option}" ]]; } && log_super "Status: Jamf Pro Policy triggers: ${install_jamf_policy_triggers_option}"
	[[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]] && log_super "Warning: Install Jamf Pro Policy Triggers without restarting is enabled, this computer will run Jamf Pro Policies even if there is no macOS update or upgrade available."
	[[ "${workflow_restart_without_updates_option}" == "TRUE" ]] && log_super "Warning: Restart without updates workflow is enabled, this computer will restart even if there is no macOS update or upgrade available."
	if [[ "${workflow_reset_super_after_completion_active}" == "TRUE" ]] || [[ "${workflow_reset_super_after_completion_local}" -eq 1 ]]; then
		log_super "Status: Workflow reset super after completion is active. All local (non-managed and non-authentication) preferences will be deleted after workflow completion."
		workflow_reset_super_after_completion_active="TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletion -bool true
	fi
	[[ "${workflow_restart_validate_active}" != "TRUE" ]] && defaults write "${SUPER_LOCAL_PLIST}" MacLastStartup -string "${mac_last_startup}"
	
	# Apple silicon authentication and workflow validations.
	[[ "${mac_cpu_architecture}" == "arm64" ]] && manage_authentication_options
	manage_workflow_options
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file after startup validation: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
	
	# If super is running via Jamf, then restart via LaunchDaemon to release the jamf parent process.
	if [[ "${parent_process_is_jamf}" == "TRUE" ]]; then
		log_super "Status: Found that Jamf is installing or is the parent process, restarting via LaunchDaemon..."
		restart_super_sleep_seconds=5
		restart_super
	fi
	
	# If super is running from outside the ${SUPER_FOLDER}, then restart via LaunchDaemon to release any parent installer process.
	if ! { [[ "${super_current_folder}" == "${SUPER_FOLDER}" ]] || [[ "${super_current_folder}" == $(dirname "${SUPER_LINK}") ]]; }; then
		log_super "Status: Found that super is installing, restarting via LaunchDaemon..."
		restart_super_sleep_seconds=5
		restart_super
	fi
	
	# Handle the ${workflow_auth_error} condition, which is a workflow-stopper unless the restart validate or only download workflows are active.
	if [[ "${workflow_auth_error}" == "TRUE" ]] && [[ "${workflow_restart_validate_active}" != "TRUE" ]] && [[ "${workflow_only_download_active}" != "TRUE" ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "Error: Configured authentication workflow can not currently install macOS updates/upgrades, install now workflow can not continue."
			log_status "Inactive Error: Configured authentication workflow can not currently install macOS updates/upgrades, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
		else
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Workflow Error: Configured authentication workflow is not currently possible, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Configured authentication workflow is not currently possible, trying again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
	
	# Wait for a valid network connection. If there is still no network after two minutes, an automatic deferral is started.
	local network_timeout
	network_timeout=0
	while [[ $(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l) -le 0 ]] && [[ "${network_timeout}" -lt 120 ]]; do
		log_super "Status: Waiting for network..."
		sleep 5
		network_timeout=$((network_timeout + 5))
	done
	if [[ $(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l) -le 0 ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "Error: Network unavailable, install now workflow can not continue."
			log_status "Inactive Error: Network unavailable, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
			exit_error
		else
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Error: Network unavailable, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Network unavailable, trying again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
}

# MARK: *** Process Management ***
################################################################################

# This function is only used for debugging from the command line to interrupt the workflow and wait for the user to press Enter to continue. Insert the following line wherever you want an interrupt to occur:
# [[ "${current_user_account_name}" != "FALSE" ]] && interactive_interrupt
interactive_interrupt() {
	# shellcheck disable=SC2317
	log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INTERACTIVE INTERRUPT - PRESS ENTER TO CONTINUE ****"
	# shellcheck disable=SC2317
	read -n 1 -p -r >/dev/null 2>&1
}

# Restart super via the LaunchDaemon after waiting for ${restart_super_sleep_seconds} seconds.
restart_super() {
	/usr/libexec/PlistBuddy -c "Delete :NextAutoLaunch" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
	{
		sleep $restart_super_sleep_seconds
		launchctl bootout system "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist" >/dev/null 2>&1
		launchctl bootstrap system "/Library/LaunchDaemons/${SUPER_LAUNCH_DAEMON_LABEL}.plist" >/dev/null 2>&1
	} &
	disown -a
	[[ -n "${jamf_access_token}" ]] && delete_jamf_api_access_token
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file at restart exit: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
	log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - EXIT AND RESTART WORKFLOW ****"
	rm -f "${SUPER_PID_FILE}" 2>/dev/null
	exit 0
}

# Configure super to automatically launch ${deferral_timer_minutes} from now by setting the NextAutoLaunch attribute in the ${SUPER_LOCAL_PLIST}.
set_auto_launch_deferral() {
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_minutes is: ${deferral_timer_minutes}"
	local deferral_timer_epoch
	deferral_timer_epoch=$(($(date +%s) + (deferral_timer_minutes * 60)))
	local deferral_timer_year
	deferral_timer_year=$(date -j -f %s "${deferral_timer_epoch}" +%Y | xargs)
	local deferral_timer_month
	deferral_timer_month=$(date -j -f %s "${deferral_timer_epoch}" +%m | xargs)
	local deferral_timer_day
	deferral_timer_day=$(date -j -f %s "${deferral_timer_epoch}" +%d | xargs)
	local deferral_timer_hour
	deferral_timer_hour=$(date -j -f %s "${deferral_timer_epoch}" +%H | xargs)
	local deferral_timer_minute
	deferral_timer_minute=$(date -j -f %s "${deferral_timer_epoch}" +%M | xargs)
	local next_auto_launch
	next_auto_launch="${deferral_timer_year}-${deferral_timer_month}-${deferral_timer_day}:${deferral_timer_hour}:${deferral_timer_minute}:00"
	/usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string ${next_auto_launch}" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
	log_super "Exit: super is scheduled to automatically relaunch at: ${next_auto_launch}"
	exit_clean
}

# This function is used when the super workflow exits with no errors.
exit_clean() {
	[[ -n "${jamf_access_token}" ]] && delete_jamf_api_access_token
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file at clean exit: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
	log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - EXIT CLEAN ****"
	rm -f "${SUPER_PID_FILE}" 2>/dev/null
	exit 0
}

# This function is used when the super workflow must exit due to an unrecoverable error.
exit_error() {
	[[ -n "${jamf_access_token}" ]] && delete_jamf_api_access_token
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file at error exit: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
	log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - EXIT ERROR ****"
	rm -f "${SUPER_PID_FILE}" 2>/dev/null
	exit 1
}

# MARK: *** Logging ***
################################################################################

# Append input to the command line and log located at ${SUPER_LOG}.
log_super() {
	echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" | tee -a "${SUPER_LOG}"
}

# Send input to the command line only, so as not to save secrets to the ${SUPER_LOG}.
log_echo() {
	echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: Not Logged: $*"
}

# Send input to the command line only replacing the current line, so as not to save save interactive progress updates to the ${SUPER_LOG}.
log_echo_replace_line() {
	echo -ne "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: Not Logged: $*\r"
}

# Append input to a log located at ${MSU_WORKFLOW_LOG}.
log_msu() {
	echo -e "\n$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >>"${MSU_WORKFLOW_LOG}"
}

# Append input to a log located at ${INSTALLER_WORKFLOW_LOG}.
log_installer() {
	echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >>"${INSTALLER_WORKFLOW_LOG}"
}

# Append input to a log located at ${MDM_COMMAND_LOG}.
log_mdm_command() {
	echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >>"${MDM_COMMAND_LOG}"
}

# Append input to a log located at ${MDM_WORKFLOW_LOG}.
log_mdm_workflow() {
	echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" >>"${MDM_WORKFLOW_LOG}"
}

# Update the SuperStatus key in the ${SUPER_LOCAL_PLIST}.
log_status() {
	defaults write "${SUPER_LOCAL_PLIST}" SuperStatus -string "$(date +"%a %b %d %T"): $*"
}

# Archive all legacy log files to the ${SUPER_LOG_ARCHIVE_FOLDER}, and if needed, archive larger current logs.
archive_logs() {
	# First, archive any legacy super logs.
	if [[ -f "${SUPER_FOLDER}/super.log" ]]; then
		local log_archive_legacy_name
		log_archive_legacy_name=$(date +%Y-%m-%d.%H-%M-%S.legacy)
		log_super "Status: Archiving legacy super logs to: ${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}.zip"
		mkdir -p "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}"
		mv "${SUPER_FOLDER}/super.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/super.log"
		[[ -f "${SUPER_FOLDER}/asuList.log" ]] && rm -f "${SUPER_FOLDER}/asuList.log" 2>/dev/null
		[[ -f "${SUPER_FOLDER}/installerList.log" ]] && rm -f "${SUPER_FOLDER}/installerList.log" 2>/dev/null
		[[ -f "${SUPER_FOLDER}/asu.log" ]] && mv "${SUPER_FOLDER}/asu.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/asu.log"
		[[ -f "${SUPER_FOLDER}/installer.log" ]] && mv "${SUPER_FOLDER}/installer.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/installer.log"
		[[ -f "${SUPER_FOLDER}/mdmCommand.log" ]] && mv "${SUPER_FOLDER}/mdmCommand.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/mdmCommand.log"
		[[ -f "${SUPER_FOLDER}/mdmCommandDebug.log" ]] && mv "${SUPER_FOLDER}/mdmCommandDebug.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/mdmCommandDebug.log"
		[[ -f "${SUPER_FOLDER}/mdmWorkflow.log" ]] && mv "${SUPER_FOLDER}/mdmWorkflow.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/mdmWorkflow.log"
		[[ -f "${SUPER_FOLDER}/mdmWorkflowDebug.log" ]] && mv "${SUPER_FOLDER}/mdmWorkflowDebug.log" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}/mdmWorkflowDebug.log"
		zip -r -j "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}.zip" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_legacy_name}" >/dev/null 2>&1
		rm -rf "${SUPER_LOG_ARCHIVE_FOLDER:?}/${log_archive_legacy_name}" 2>/dev/null
		chown -R root:wheel "${SUPER_LOG_ARCHIVE_FOLDER}"
		chmod -R a+r "${SUPER_LOG_ARCHIVE_FOLDER}"
	fi
	
	# Check to see if any log file is larger than $SUPER_LOG_ARCHIVE_SIZE.
	local archive_logs_needed
	archive_logs_needed="FALSE"
	[[ $(ls -l "${SUPER_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	[[ $(ls -l "${MSU_WORKFLOW_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	[[ $(ls -l "${INSTALLER_WORKFLOW_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	[[ $(ls -l "${MDM_COMMAND_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	[[ $(ls -l "${MDM_COMMAND_DEBUG_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	[[ $(ls -l "${MDM_WORKFLOW_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	[[ $(ls -l "${MDM_WORKFLOW_DEBUG_LOG}" 2>/dev/null | awk '{print int($5/1000)}') -gt $SUPER_LOG_ARCHIVE_SIZE ]] && archive_logs_needed="TRUE"
	
	# A super log has become to large, archival is required.
	if [[ "${archive_logs_needed}" == "TRUE" ]]; then
		local log_archive_name
		log_archive_name=$(date +%Y-%m-%d.%H-%M-%S)
		log_super "Status: A super log is larger than ${SUPER_LOG_ARCHIVE_SIZE} KB, archiving super logs to: ${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}.zip"
		log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - LOGS ARCHIVAL ****"
		mkdir -p "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}"
		mv "${SUPER_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${SUPER_LOG})"
		log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - LOGS ARCHIVAL ****"
		log_super "Status: A super log was larger than ${SUPER_LOG_ARCHIVE_SIZE} KB, previous super logs archived to: ${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}.zip"
		[[ -f "${MSU_WORKFLOW_LOG}" ]] && mv "${MSU_WORKFLOW_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${MSU_WORKFLOW_LOG})"
		[[ -f "${INSTALLER_WORKFLOW_LOG}" ]] && mv "${INSTALLER_WORKFLOW_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${INSTALLER_WORKFLOW_LOG})"
		[[ -f "${MDM_COMMAND_LOG}" ]] && mv "${MDM_COMMAND_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${MDM_COMMAND_LOG})"
		[[ -f "${MDM_COMMAND_DEBUG_LOG}" ]] && mv "${MDM_COMMAND_DEBUG_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${MDM_COMMAND_DEBUG_LOG})"
		[[ -f "${MDM_WORKFLOW_LOG}" ]] && mv "${MDM_WORKFLOW_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${MDM_WORKFLOW_LOG})"
		[[ -f "${MDM_WORKFLOW_DEBUG_LOG}" ]] && mv "${MDM_WORKFLOW_DEBUG_LOG}" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}/$(basename ${MDM_WORKFLOW_DEBUG_LOG})"
		zip -r -j "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}.zip" "${SUPER_LOG_ARCHIVE_FOLDER}/${log_archive_name}" >/dev/null 2>&1
		rm -rf "${SUPER_LOG_ARCHIVE_FOLDER:?}/${log_archive_name}" 2>/dev/null
		chown -R root:wheel "${SUPER_LOG_ARCHIVE_FOLDER}"
		chmod -R a+r "${SUPER_LOG_ARCHIVE_FOLDER}"
	fi
	
	# This is a fail-safe to remove any excessively large files from the ${SUPER_LOG_ARCHIVE_FOLDER}.
	for log_archive_file in "${SUPER_LOG_ARCHIVE_FOLDER}"/*; do
		if [[ $(ls -l "${log_archive_file}" 2>/dev/null | awk '{print int($5/1000)}') -gt $((SUPER_LOG_ARCHIVE_SIZE * 10)) ]]; then
			log_super "Warning: A file in the super log archive folder was larger than $((SUPER_LOG_ARCHIVE_SIZE * 10)) KB, deleting file to save space: ${log_archive_file}"
			rm -rf "${log_archive_file:?}" 2>/dev/null
		fi
	done
}

# MARK: *** Local System Validation ***
################################################################################

# Set ${current_user_account_name} to the currently logged in GUI user or "FALSE" if there is none or a system account.
# If the current user is a normal account then this also sets ${current_user_id}, ${current_user_guid}, ${current_user_real_name}, ${current_user_is_admin}, ${current_user_has_secure_token}, ${current_user_is_volume_owner}, and ${current_user_appearance_mode}.
check_current_user() {
	[[ -z "${current_user_account_name}" ]] && current_user_account_name="FALSE"
	[[ -z "${current_user_id}" ]] && current_user_id="FALSE"
	local current_user_account_name_response
	current_user_account_name_response=$(scutil <<<"show State:/Users/ConsoleUser" | awk '/Name :/ {$1=$2="";print $0;}' | xargs)
	local current_user_id_response
	current_user_id_response=$(id -u "${current_user_account_name_response}" 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_account_name is: ${current_user_account_name}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_id is: ${current_user_id}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_account_name_response is: ${current_user_account_name_response}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_id_response is: ${current_user_id_response}"
	
	# If this function was already run earlier then check to see if ${current_user_account_name} and ${current_user_id} are the same as before, if so then it's not necessary to continue this function.
	if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${current_user_id}" != "FALSE" ]] && [[ "${current_user_account_name}" == "${current_user_account_name_response}" ]] && [[ "${current_user_id}" == "${current_user_id_response}" ]]; then
		return 0
	fi
	
	# Make sure we have a "normal" logged in user.
	if [[ -z "${current_user_account_name_response}" ]]; then
		{ [[ $(id -u) -eq 0 ]] && [[ -d "${SUPER_LOG_FOLDER}" ]]; } && log_super "Status: No GUI user currently logged in."
		{ [[ $(id -u) -ne 0 ]] || [[ ! -d "${SUPER_LOG_FOLDER}" ]]; } && log_echo "Status: No GUI user currently logged in."
	elif [[ "${current_user_account_name_response}" == "root" ]] || [[ "${current_user_account_name_response}" == "_mbsetupuser" ]] || [[ "${current_user_account_name_response}" == "loginwindow" ]]; then
		{ [[ $(id -u) -eq 0 ]] && [[ -d "${SUPER_LOG_FOLDER}" ]]; } && log_super "Status: Current GUI user is system account: ${current_user_account_name_response}"
		{ [[ $(id -u) -ne 0 ]] || [[ ! -d "${SUPER_LOG_FOLDER}" ]]; } && log_echo "Status: Current GUI user is system account: ${current_user_account_name_response}"
	else # Normal locally logged in user.
		current_user_account_name="${current_user_account_name_response}"
		current_user_id=$(id -u "${current_user_account_name}" 2>/dev/null)
		{ [[ $(id -u) -eq 0 ]] && [[ -d "${SUPER_LOG_FOLDER}" ]]; } && log_super "Status: Current active GUI user is: ${current_user_account_name} (${current_user_id})"
		{ [[ $(id -u) -ne 0 ]] || [[ ! -d "${SUPER_LOG_FOLDER}" ]]; } && log_echo "Status: Current active GUI user is: ${current_user_account_name} (${current_user_id})"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_account_name is: ${current_user_account_name}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_id is: ${current_user_id}"
	
	# Only collect user details if it's a "normal" GUI user.
	if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${current_user_id}" != "FALSE" ]] && [[ -d "${SUPER_LOG_FOLDER}" ]]; then
		current_user_guid=$(dscl . read "/Users/${current_user_account_name}" GeneratedUID 2>/dev/null | awk '{print $2;}')
		current_user_real_name=$(dscl . read "/Users/${current_user_account_name}" RealName 2>/dev/null | tail -1 | sed -e 's/^RealName: //g' -e 's/^ //g')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_guid is: ${current_user_guid}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_real_name is: ${current_user_real_name}"
		current_user_is_admin="FALSE"
		current_user_has_secure_token="FALSE"
		current_user_is_volume_owner="FALSE"
		current_user_password_policies="FALSE"
		current_user_system_password_policies="FALSE"
		if [[ -n "${current_user_id}" ]] && [[ -n "${current_user_guid}" ]] && [[ -n "${current_user_real_name}" ]]; then
			[[ $(groups "${current_user_account_name}" 2>/dev/null | grep -c 'admin') -gt 0 ]] && current_user_is_admin="TRUE"
			[[ $(dscl . read "/Users/${current_user_account_name}" AuthenticationAuthority 2>/dev/null | grep -c 'SecureToken') -gt 0 ]] && current_user_has_secure_token="TRUE"
			[[ $(diskutil apfs listcryptousers / 2>/dev/null | grep -c "${current_user_guid}") -gt 0 ]] && current_user_is_volume_owner="TRUE"
			local current_user_appearance_mode_response
			current_user_appearance_mode_response=$(sudo -u "${current_user_account_name}" osascript -l 'JavaScript' -e "ObjC.import('AppKit'); $.NSAppearance.currentDrawingAppearance.bestMatchFromAppearancesWithNames(['NSAppearanceNameAqua', 'NSAppearanceNameDarkAqua']).js;" 2>/dev/null)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_appearance_mode_response is: ${current_user_appearance_mode_response}"
			[[ "${current_user_appearance_mode_response}" == "NSAppearanceNameAqua" ]] && current_user_appearance_mode="LIGHT"
			[[ "${current_user_appearance_mode_response}" == "NSAppearanceNameDarkAqua" ]] && current_user_appearance_mode="DARK"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_is_admin is: ${current_user_is_admin}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_has_secure_token is: ${current_user_has_secure_token}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_is_volume_owner is: ${current_user_is_volume_owner}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_appearance_mode is: ${current_user_appearance_mode}"
		else
			log_super "Parameter Error: Unable to determine account details for current user: ${current_user_account_name}"
			option_error="TRUE"
		fi
	fi
}

# Collect parameters for detailed system information setting a variety of parameters including ${macos_version_minor}, ${macos_version_patch}, ${macos_version_number}, ${macos_version_extra}, ${macos_build}, ${macos_title}, ${macos_version_full}, ${mac_cpu_architecture}, ${mac_model_name}, ${mac_is_portable}, and ${mac_last_startup}.
check_system() {
	check_error="FALSE"
	macos_version_minor=$(sw_vers -productVersion | cut -d'.' -f2) # Expected output: 6, 1
	macos_version_patch=$(sw_vers -productVersion | cut -d'.' -f3) # Expected output: 6, 1
	macos_version_number="${macos_version_major}$(printf "%02d" "${macos_version_minor}")" # Expected output: 1014, 1015, 1106, 1203
	[[ "${macos_version_major}" -ge 13 ]] && macos_version_extra=$(sw_vers -productVersionExtra | cut -d'.' -f2) # Expected output: (a), (b), (c)
	macos_build=$(sw_vers -buildVersion) # Expected output: 22D68
	macos_title="macOS $(awk '/SOFTWARE LICENSE AGREEMENT FOR/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | awk -F 'macOS ' '{print $NF}' | awk '{print substr($0, 0, length($0)-1)}')" # Expected output: macOS Ventura or "*PRE-RELEASE*"
	[[ $(echo "${macos_title}" | grep -c 'PRE-RELEASE') -gt 0 ]] && macos_title="macOS Beta"
	mac_cpu_architecture=$(arch) # Expected output: i386, arm64
	mac_model_name=$(system_profiler SPHardwareDataType | grep 'Model Name' | awk -F ': ' '{print $2;}') # Expected output: MacBook Pro
	[[ $(echo "${mac_model_name}" | grep -c 'Book') -gt 0 ]] && mac_is_portable="TRUE" # Expected output: TRUE
	if [[ -n "${macos_version_patch}" ]]; then # macOS version has a patch number.
		[[ -n "${macos_version_extra}" ]] && macos_version_full="${macos_title} ${macos_version_major}.${macos_version_minor}.${macos_version_patch}${macos_version_extra}-${macos_build}"
		[[ -z "${macos_version_extra}" ]] && macos_version_full="${macos_title} ${macos_version_major}.${macos_version_minor}.${macos_version_patch}-${macos_build}"
	else # macOS version does not have a patch number.
		[[ -n "${macos_version_extra}" ]] && macos_version_full="${macos_title} ${macos_version_major}.${macos_version_minor}${macos_version_extra}-${macos_build}"
		[[ -z "${macos_version_extra}" ]] && macos_version_full="${macos_title} ${macos_version_major}.${macos_version_minor}-${macos_build}"
	fi
	if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Mac computers with Apple Silicon.
		log_super "Status: Mac computer with Apple silicon running: ${macos_version_full}"
	else # Mac computers with Intel.
		log_super "Status: Mac computer with Intel running: ${macos_version_full}"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_version_number is: ${macos_version_number}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mac_model_name is: ${mac_model_name}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mac_is_portable is: ${mac_is_portable}"
	local kernel_boot_epoch
	kernel_boot_epoch=$(sysctl -n kern.boottime | awk -F 'sec = |, usec' '{print $2}') # Expected outputs: seconds since epoch
	if [[ "${kernel_boot_epoch}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		mac_last_startup=$(date -r "${kernel_boot_epoch}" +%Y-%m-%d:%H:%M:%S) # Expected output: 2023-08-25:00:16:00
	else
		log_super "Error: Unrecognized kernel boot epoch time: ${kernel_boot_epoch}"
		check_error="TRUE"
	fi
	if [[ "${mac_last_startup}" =~ ${REGEX_DATE_HOURS_MINUTES_SECONDS} ]]; then
		log_super "Status: Last macOS startup was: ${mac_last_startup}"
	else
		log_super "Error: Unrecognized last startup date and time: ${mac_last_startup}"
		check_error="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: check_error is: ${check_error}"
}

# Check for software update settings to report non-ideal configurations, this also sets ${msu_automatic_check} and ${msu_automatic_security_updates} appropriately.
check_msu_settings() {
	msu_automatic_check="TRUE"
	msu_automatic_download="TRUE"
	msu_automatic_macos_installation="TRUE"
	msu_automatic_security_updates="TRUE"
	
	# Start with automatic check.
	local msu_automatic_check_managed
	msu_automatic_check_managed=$(defaults read "${MSU_MANAGED_PLIST}" AutomaticCheckEnabled 2>/dev/null)
	local msu_automatic_check_local
	msu_automatic_check_local=$(defaults read "${MSU_LOCAL_PLIST}" AutomaticCheckEnabled 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_check_managed is: ${msu_automatic_check_managed}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_check_local is: ${msu_automatic_check_local}"
	[[ -n $msu_automatic_check_managed ]] && [[ $msu_automatic_check_managed -eq 0 ]] && msu_automatic_download="FALSE"
	[[ -z $msu_automatic_check_managed ]] && [[ -n $msu_automatic_check_local ]] && [[ $msu_automatic_check_local -eq 0 ]] && msu_automatic_download="FALSE"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_check is: ${msu_automatic_check}"
	if [[ "${msu_automatic_check}" == "TRUE" ]]; then
		# Automatic download check.
		local msu_automatic_download_managed
		msu_automatic_download_managed=$(defaults read "${MSU_MANAGED_PLIST}" AutomaticDownload 2>/dev/null)
		local msu_automatic_download_local
		msu_automatic_download_local=$(defaults read "${MSU_LOCAL_PLIST}" AutomaticDownload 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_download_managed is: ${msu_automatic_download_managed}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_download_local is: ${msu_automatic_download_local}"
		[[ -n $msu_automatic_download_managed ]] && [[ $msu_automatic_download_managed -eq 0 ]] && msu_automatic_download="FALSE"
		[[ -z $msu_automatic_download_managed ]] && [[ -n $msu_automatic_download_local ]] && [[ $msu_automatic_download_local -eq 0 ]] && msu_automatic_download="FALSE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_download is: ${msu_automatic_download}"
		
		# Automatic macOS installation check.
		local msu_automatic_macos_installation_managed
		msu_automatic_macos_installation_managed=$(defaults read "${MSU_MANAGED_PLIST}" AutomaticallyInstallMacOSUpdates 2>/dev/null)
		local msu_automatic_macos_installation_local
		msu_automatic_macos_installation_local=$(defaults read "${MSU_LOCAL_PLIST}" AutomaticallyInstallMacOSUpdates 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_macos_installation_managed is: ${msu_automatic_macos_installation_managed}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_macos_installation_local is: ${msu_automatic_macos_installation_local}"
		[[ -n $msu_automatic_macos_installation_managed ]] && [[ $msu_automatic_macos_installation_managed -eq 0 ]] && msu_automatic_macos_installation="FALSE"
		[[ -z $msu_automatic_macos_installation_managed ]] && [[ -n $msu_automatic_macos_installation_local ]] && [[ $msu_automatic_macos_installation_local -eq 0 ]] && msu_automatic_macos_installation="FALSE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_macos_installation is: ${msu_automatic_macos_installation}"
		
		# Automatic security update check.
		local msu_automatic_config_data_managed
		msu_automatic_config_data_managed=$(defaults read "${MSU_MANAGED_PLIST}" ConfigDataInstall 2>/dev/null)
		local msu_automatic_config_data_local
		msu_automatic_config_data_local=$(defaults read "${MSU_LOCAL_PLIST}" ConfigDataInstall 2>/dev/null)
		local msu_automatic_critical_update_managed
		msu_automatic_critical_update_managed=$(defaults read "${MSU_MANAGED_PLIST}" CriticalUpdateInstall 2>/dev/null)
		local msu_automatic_critical_update_local
		msu_automatic_critical_update_local=$(defaults read "${MSU_LOCAL_PLIST}" CriticalUpdateInstall 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_config_data_managed is: ${msu_automatic_config_data_managed}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_config_data_local is: ${msu_automatic_config_data_local}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_critical_update_managed is: ${msu_automatic_critical_update_managed}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_critical_update_local is: ${msu_automatic_critical_update_local}"
		{ { [[ -n $msu_automatic_config_data_managed ]] && [[ $msu_automatic_config_data_managed -eq 0 ]]; } || { [[ -n $msu_automatic_critical_update_managed ]] && [[ $msu_automatic_critical_update_managed -eq 0 ]]; }; } && msu_automatic_security_updates="FALSE"
		{ { [[ -z $msu_automatic_config_data_managed ]] && [[ -n $msu_automatic_config_data_local ]] && [[ $msu_automatic_config_data_local -eq 0 ]]; } || { [[ -z $msu_automatic_critical_update_managed ]] && [[ -n $msu_automatic_critical_update_local ]] && [[ $msu_automatic_critical_update_local -eq 0 ]]; }; } && msu_automatic_security_updates="FALSE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_automatic_security_updates is: ${msu_automatic_security_updates}"
		
		# Log any warnings.
		if [[ "${msu_automatic_download}" == "TRUE" ]]; then
			[[ "${msu_automatic_macos_installation}" == "FALSE" ]] && log_super "Warning: Automatic download of macOS updates is currently enabled, this can result in updates being downloaded outside of super workflows."
			[[ "${msu_automatic_macos_installation}" == "TRUE" ]] && log_super "Warning: Automatic download and installation of macOS updates is currently enabled, this can result in updates being installed outside of super workflows."
		fi
		[[ "${msu_automatic_security_updates}" == "FALSE" ]] && log_super "Warning: Automatic installation of macOS security updates is disabled, this is a significant security risk."
	else # msu_automatic_check="FALSE"
		log_super "Warning: Automatic Apple software updated checking is currently disabled, this is not ideal for the super workflow and prevents macOS security updates from being installed which is a significant security risk."
		msu_automatic_download="FALSE"
		msu_automatic_macos_installation="FALSE"
		msu_automatic_security_updates="FALSE"
	fi
}

# Validate that the account ${auth_local_account} and ${auth_local_password} are valid credentials to a volume owner. If not set ${auth_error_local}.
check_auth_local_account() {
	auth_error_local="FALSE"
	local auth_local_guid
	auth_local_guid=$(dscl . read "/Users/${auth_local_account}" GeneratedUID 2>/dev/null | awk '{print $2;}')
	if [[ -n "${auth_local_guid}" ]]; then
		if ! [[ $(diskutil apfs listcryptousers / | grep -c "${auth_local_guid}") -gt 0 ]]; then
			log_super "Auth Error: The account \"${auth_local_account}\" is not a system volume owner."
			auth_error_local="TRUE"
		fi
		if [[ $(dscl /Local/Default -authonly "${auth_local_account}" "${auth_local_password}" 2>&1 | grep -c 'eDSAuthFailed') -gt 0 ]]; then
			log_super "Auth Error: The password for account \"${auth_local_account}\" is not valid."
			auth_error_local="TRUE"
		fi
	else
		log_super "Auth Error: Could not retrieve GUID for account \"${auth_local_account}\". Verify that account exists locally."
		auth_error_local="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_account: ${auth_local_account}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_password: ${auth_local_password}"
}

# Collect the available storage and set ${storage_ready} accordingly. This also sets ${storage_available_gigabytes} and ${storage_required_gigabytes}.
check_storage_available() {
	check_storage_available_error="FALSE"
	storage_ready="FALSE"
	[[ -z "${current_user_account_name}" ]] && check_current_user
	[[ "${current_user_account_name}" != "FALSE" ]] && storage_available_gigabytes=$(osascript -l 'JavaScript' -e "ObjC.import('Foundation'); var freeSpaceBytesRef=Ref(); $.NSURL.fileURLWithPath('/').getResourceValueForKeyError(freeSpaceBytesRef, 'NSURLVolumeAvailableCapacityForImportantUsageKey', null); Math.round(ObjC.unwrap(freeSpaceBytesRef[0]) / 1000000000)")
	[[ "${current_user_account_name}" == "FALSE" ]] && storage_available_gigabytes=$(/usr/libexec/mdmclient QueryDeviceInformation 2>/dev/null | grep 'AvailableDeviceCapacity' | head -n 1 | awk '{print $3;}' | sed -e 's/;//g' -e 's/"//g' -e 's/\.[0-9]*//g')
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_available_gigabytes: ${storage_available_gigabytes}"
	if [[ -z "${storage_available_gigabytes}" ]] || [[ ! "${storage_available_gigabytes}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		log_super "Error: Unable to determine available storage."
		check_storage_available_error="TRUE"
	elif [[ "${macos_installer_target}" != "FALSE" ]] || [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] || [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then
		{ [[ -z "${test_storage_update_option}" ]] && [[ "${macos_msu_size}" -lt 5 ]]; } && storage_required_update_gb=$((macos_msu_size * 2))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_download_required: ${macos_installer_download_required}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_size: ${macos_installer_size}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_download_required: ${macos_msu_download_required}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_size: ${macos_msu_size}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_required_upgrade_gb: ${storage_required_upgrade_gb}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_required_update_gb: ${storage_required_update_gb}"
		if [[ "${macos_installer_target}" != "FALSE" ]]; then # Target is a macOS major upgrade via installer.
			if [[ "${macos_installer_download_required}" == "TRUE" ]]; then
				storage_required_gigabytes=$((storage_required_upgrade_gb + macos_installer_size))
			else # Download calculation is not required.
				storage_required_gigabytes="${storage_required_upgrade_gb}"
			fi
		fi
		if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]]; then # Target is a macOS major upgrade via MSU.
			if [[ "${macos_msu_download_required}" == "TRUE" ]]; then
				storage_required_gigabytes=$((storage_required_upgrade_gb + macos_msu_size))
			else # Download calculation is not required.
				storage_required_gigabytes="${storage_required_upgrade_gb}"
			fi
		fi
		if [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then # Target is a macOS minor update.
			if [[ "${macos_msu_download_required}" == "TRUE" ]]; then
				storage_required_gigabytes=$((storage_required_update_gb + macos_msu_size))
			else # Download calculation is not required.
				storage_required_gigabytes="${storage_required_update_gb}"
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_required_gigabytes: ${storage_required_gigabytes}"
		[[ "${storage_available_gigabytes}" -ge "${storage_required_gigabytes}" ]] && storage_ready="TRUE"
	else # No macOS update/upgrade is available.
		storage_ready="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: check_storage_available_error: ${check_storage_available_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_ready: ${storage_ready}"
}

# Validate if current system power is adequate for performing a macOS update/upgrade and set ${power_ready} accordingly. Desktops, obviously, always return that they are ready.
check_power_required() {
	local power_required_charger_connected
	power_required_charger_connected="FALSE"
	check_power_required_error="FALSE"
	power_ready="FALSE"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mac_is_portable: ${mac_is_portable}"
	if [[ "${mac_is_portable}" == "TRUE" ]]; then
		[[ $(pmset -g ps | grep -ic 'AC Power') -ne 0 ]] && power_required_charger_connected="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_required_charger_connected: ${power_required_charger_connected}"
		if [[ "${power_required_charger_connected}" == "TRUE" ]]; then
			power_ready="TRUE"
		else # Not plugged into AC power.
			power_battery_percent=$(pmset -g ps | grep '%' | awk '{print $3;}' | sed -e 's/%;//g')
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_battery_percent: ${power_battery_percent}"
			if [[ -z "${power_battery_percent}" ]] || [[ ! "${power_battery_percent}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
				log_super "Error: Unable to determine battery power level."
				check_power_required_error="TRUE"
			else # Battery level is a real number.
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_required_battery_percent: ${power_required_battery_percent}"
				[[ "${power_battery_percent}" -gt "${power_required_battery_percent}" ]] && power_ready="TRUE"
			fi
		fi
	else # Mac desktop.
		power_ready="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: check_power_required_error: ${check_power_required_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_ready: ${power_ready}"
}

# Validate the computer's MDM service status and set ${mdm_enrolled}, ${mdm_automatically_enrolled}, ${mdm_service_url}, and ${auth_error_mdm}.
# Unlike other MDM validation functions, this function is MDM-vendor agnostic.
check_mdm_service() {
	mdm_enrolled="FALSE"
	mdm_automatically_enrolled="FALSE"
	auth_error_mdm="FALSE"
	local profiles_response
	profiles_response=$(profiles status -type enrollment 2>&1)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: profiles_response:\n${profiles_response}"
	if [[ $(echo "${profiles_response}" | grep -c 'MDM server') -gt 0 ]]; then
		mdm_enrolled="TRUE"
		[[ $(echo "${profiles_response}" | grep 'Enrolled via DEP:' | grep -c 'Yes') -gt 0 ]] && mdm_automatically_enrolled="TRUE"
		mdm_service_url="https://$(echo "${profiles_response}" | grep 'MDM server' | awk -F '/' '{print $3;}')"
		local curl_response
		curl_response=$(curl -Is "${mdm_service_url}" | head -n 1)
		if [[ $(echo "${curl_response}" | grep -c 'HTTP') -gt 0 ]] && [[ $(echo "${curl_response}" | grep -c -e '400' -e '40[4-9]' -e '4[1-9][0-9]' -e '5[0-9][0-9]') -eq 0 ]]; then
			log_super "Status: MDM service is currently available at: ${mdm_service_url}"
		else
			log_super "Warning: MDM service at ${mdm_service_url} is currently unavailable with status: ${curl_response}"
			auth_error_mdm="TRUE"
		fi
	else
		log_super "Warning: System is not enrolled with a MDM service."
		auth_error_mdm="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdm_enrolled: ${mdm_enrolled}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdm_automatically_enrolled: ${mdm_automatically_enrolled}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdm_service_url: ${mdm_service_url}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_error_mdm: ${auth_error_mdm}"
}

# Validate that the computer's bootstrap token is properly escrowed and set ${auth_error_bootstrap_token}.
check_bootstrap_token_escrow() {
	auth_error_bootstrap_token="FALSE"
	local profiles_response
	profiles_response=$(profiles status -type bootstraptoken 2>&1)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: profiles_response:\n${profiles_response}"
	if [[ $(echo "${profiles_response}" | grep -c 'YES') -eq 2 ]]; then
		if [[ "${macos_version_number}" -ge 1303 ]]; then
			if [[ "${auth_error_mdm}" == "FALSE" ]]; then
				local mdmclient_response
				mdmclient_response=$(/usr/libexec/mdmclient QueryDeviceInformation 2>/dev/null | grep 'EACSPreflight' | sed -e 's/        EACSPreflight = //g' -e 's/"//g' -e 's/;//g')
				if [[ $(echo "${mdmclient_response}" | grep -c 'success') -gt 0 ]] || [[ $(echo "${mdmclient_response}" | grep -c 'EFI password exists') -gt 0 ]]; then
					log_super "Status: Bootstrap token escrowed and validated with MDM service."
				else
					log_super "Warning: Bootstrap token escrow validation failed with status: ${mdmclient_response}"
					auth_error_bootstrap_token="TRUE"
				fi
			else
				log_super "Warning: Bootstrap token was previously escrowed with MDM service but the service is currently unavailable so it can not be validated."
			fi
		else
			log_super "Status: Bootstrap token escrowed with MDM service."
		fi
	else
		log_super "Warning: Bootstrap token is not escrowed with MDM service."
		auth_error_bootstrap_token="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_error_bootstrap_token: ${auth_error_bootstrap_token}"
}

# MARK: *** Schedules, Deferrals, & Deadlines ***
################################################################################

# Delete the deadline counters in ${SUPER_LOCAL_PLIST} to reset the counters.
reset_deadline_counters() {
	log_super "Status: Resetting any deadline counters."
	defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCounterFocus 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCounterSoft 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" DeadlineCounterHard 2>/dev/null
}

# Delete any automatic zero dates and associated cached dates in ${SUPER_LOCAL_PLIST}.
reset_schedule_zero_date() {
	log_super "Status: Resetting any workflow dates."
	defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticStart 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysFocusDate 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysSoftDate 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" DeadlineDaysHardDate 2>/dev/null
}

# Evaluate ${schedule_workflow_active_option} and set ${workflow_time_weekday}, ${schedule_workflow_active_array}, and ${schedule_workflow_active_deferral} accordingly.
# If the workflow schedule is currently active then set ${schedule_workflow_active_current_end_epoch} and ${schedule_workflow_active_current_end}, but if the workflow schedule is currently inactive then set ${schedule_workflow_active_next_start_epoch} and ${schedule_workflow_active_next_start}.
check_schedule_workflow_active() {
	schedule_workflow_active_deferral="TRUE"
	workflow_time_weekday=$(date +%a | tr '[:lower:]' '[:upper:]')
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_option is: ${schedule_workflow_active_option}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_time_weekday is: ${workflow_time_weekday}"
	
	# First check to see if workflow is allowed for current weekday and time.
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=','
	[[ -z "${schedule_workflow_active_array[*]}" ]] && read -r -a schedule_workflow_active_array <<<"${schedule_workflow_active_option}"
	local schedule_schedule_workflow_active_time_frame_start_epoch
	local schedule_schedule_workflow_active_time_frame_end_epoch
	local schedule_workflow_active_next_start_difference
	local schedule_workflow_active_next_start_epoch_array
	schedule_workflow_active_next_start_epoch_array=()
	for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
		# Convert the ${schedule_workflow_active_time_frame} into start and end epoch times relative to the current week.
		schedule_schedule_workflow_active_time_frame_start_epoch=$(date -j -v"${schedule_workflow_active_time_frame:0:3}"d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s)
		schedule_schedule_workflow_active_time_frame_end_epoch=$(date -j -v"${schedule_workflow_active_time_frame:0:3}"d -v"${schedule_workflow_active_time_frame:10:2}"H -v"${schedule_workflow_active_time_frame:13:2}"M -v00S +%s)
		if [[ $workflow_time_epoch -ge $schedule_schedule_workflow_active_time_frame_start_epoch ]] && [[ $workflow_time_epoch -lt $schedule_schedule_workflow_active_time_frame_end_epoch ]]; then # If the current time is between the start and end of the ${schedule_workflow_active_time_frame}.
			schedule_workflow_active_deferral="FALSE"
			schedule_workflow_active_current_end_epoch="${schedule_schedule_workflow_active_time_frame_end_epoch}"
			schedule_workflow_active_current_end="$(date -j -f %s "${schedule_workflow_active_current_end_epoch}" +%a:%H:%M | tr '[:lower:]' '[:upper:]')"
			break
		elif [[ $workflow_time_epoch -lt $schedule_schedule_workflow_active_time_frame_start_epoch ]]; then # If the current time is less than the start time of the ${schedule_workflow_active_time_frame}.
			schedule_workflow_active_next_start_difference=$((schedule_schedule_workflow_active_time_frame_start_epoch - workflow_time_epoch))
			if [[ "${schedule_workflow_active_next_start_difference}" -le 180 ]]; then
				log_super "Status: The next schedule workflow active time frame starts in only ${schedule_workflow_active_next_start_difference} seconds, waiting for time frame to start..."
				sleep $((schedule_workflow_active_next_start_difference + 1 ))
				schedule_workflow_active_deferral="FALSE"
				schedule_workflow_active_current_end_epoch="${schedule_schedule_workflow_active_time_frame_end_epoch}"
				schedule_workflow_active_current_end="$(date -j -f %s "${schedule_workflow_active_current_end_epoch}" +%a:%H:%M | tr '[:lower:]' '[:upper:]')"
				break
			else
				schedule_workflow_active_next_start_epoch_array+=("${schedule_schedule_workflow_active_time_frame_start_epoch}")
			fi
		elif [[ $workflow_time_epoch -gt $schedule_schedule_workflow_active_time_frame_end_epoch ]] && [[ "${workflow_time_weekday}" != "${schedule_workflow_active_time_frame:0:3}" ]]; then # The current time is past the end time of the ${schedule_workflow_active_time_frame} and it's not today.
			schedule_workflow_active_next_start_epoch_array+=("$(date -j -v+"${schedule_workflow_active_time_frame:0:3}"d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s)")
		fi
	done
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_deferral is: ${schedule_workflow_active_deferral}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_current_end_epoch is: ${schedule_workflow_active_current_end_epoch}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_current_end is: ${schedule_workflow_active_current_end}"
	
	# If ${schedule_workflow_active_deferral} is "TRUE" then set ${schedule_workflow_active_next_start_epoch}.
	if [[ "${schedule_workflow_active_deferral}" == "TRUE" ]]; then
		IFS=$'\n'
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_next_start_epoch_array is:\n${schedule_workflow_active_next_start_epoch_array[*]}"
		schedule_workflow_active_next_start_epoch="$(echo "${schedule_workflow_active_next_start_epoch_array[*]}" | sort | head -1)"
		schedule_workflow_active_next_start="$(date -j -f %s "${schedule_workflow_active_next_start_epoch}" +%a:%H:%M | tr '[:lower:]' '[:upper:]')"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_next_start_epoch is: ${schedule_workflow_active_next_start_epoch}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_next_start is: ${schedule_workflow_active_next_start}"
	fi
	IFS="${previous_ifs}"
}

# Adjust ${deferral_timer_minutes_schedule_workflow_active_check}, ${deadline_epoch_schedule_workflow_active_check}, or ${workflow_scheduled_install} to coordinate with the ${schedule_workflow_active_option}.
# This function can set ${deferral_timer_minutes_schedule_workflow_active_adjusted}, ${deadline_epoch_schedule_workflow_active_adjusted}, ${workflow_scheduled_install_adjusted}, ${schedule_workflow_active_matches_now}, and ${scheduled_install_user_choice_adjusted}.
set_schedule_workflow_active_adjustments() {
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=','
	[[ -z "${schedule_workflow_active_array[*]}" ]] && read -r -a schedule_workflow_active_array <<<"${schedule_workflow_active_option}"
	local schedule_workflow_active_match_start_epoch
	local schedule_workflow_active_match_end_epoch
	schedule_workflow_active_matches_now="FALSE"
	local schedule_workflow_active_match_start_epochs_array
	schedule_workflow_active_match_start_epochs_array=()
	local schedule_workflow_active_match_weekday_start_epoch
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_time_epoch: ${workflow_time_epoch}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_time_weekday: ${workflow_time_weekday}"
	
	# If there is a ${deferral_timer_minutes_schedule_workflow_active_check} or ${deferral_timer_menu_schedule_workflow_active_check} then adjust it to coordinate with the ${schedule_workflow_active_option} and set ${deferral_timer_minutes_schedule_workflow_active_adjusted} accordingly.
	if [[ -n "${deferral_timer_minutes_schedule_workflow_active_check}" ]] || [[ -n "${deferral_timer_menu_schedule_workflow_active_check}" ]]; then
		local deferral_timer_match
		deferral_timer_match="FALSE"
		local deferral_timer_epoch_temp
		[[ -n "${deferral_timer_minutes_schedule_workflow_active_check}" ]] && deferral_timer_epoch_temp=$((workflow_time_epoch + (deferral_timer_minutes_schedule_workflow_active_check * 60)))
		[[ -n "${deferral_timer_menu_schedule_workflow_active_check}" ]] && deferral_timer_epoch_temp=$((workflow_time_epoch + (deferral_timer_menu_schedule_workflow_active_check * 60)))
		local deferral_timer_days_away
		deferral_timer_days_away=$(((deferral_timer_epoch_temp - $(date -v+0d -v0H -v0M -v0S +%s)) / 86400))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_epoch_temp: ${deferral_timer_epoch_temp}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_days_away: ${deferral_timer_days_away}"
		
		# Loop through the weekdays (starting with today) and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		for ((counter=0; counter<7; ++counter)); do
			local deferral_timer_weekday
			deferral_timer_weekday="$(date -v+$((deferral_timer_days_away + counter))d +%a | tr '[:lower:]' '[:upper:]')"
			for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
				if [[ "${schedule_workflow_active_time_frame:0:3}" == "${deferral_timer_weekday}" ]]; then
					schedule_workflow_active_match_start_epoch=$(date -j -v+$((deferral_timer_days_away + counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s)
					schedule_workflow_active_match_end_epoch=$(date -j -v+$((deferral_timer_days_away + counter))d -v"${schedule_workflow_active_time_frame:10:2}"H -v"${schedule_workflow_active_time_frame:13:2}"M -v00S +%s)
					if [[ $schedule_workflow_active_match_start_epoch -le $deferral_timer_epoch_temp ]] && [[ $deferral_timer_epoch_temp -le $schedule_workflow_active_match_end_epoch ]]; then
						deferral_timer_match="TRUE"
						{ [[ $schedule_workflow_active_match_start_epoch -le $workflow_time_epoch ]] && [[ $workflow_time_epoch -le $schedule_workflow_active_match_end_epoch ]]; } && schedule_workflow_active_matches_now="TRUE"
						break
					elif [[ $deferral_timer_epoch_temp -le $schedule_workflow_active_match_start_epoch ]]; then
						schedule_workflow_active_match_start_epochs_array+=($(date -v+$((deferral_timer_days_away + counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s))
					fi
				fi
			done
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_match: ${deferral_timer_match}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_matches_now: ${schedule_workflow_active_matches_now}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		
		# If at least one matching workflow active timeframe was identified then set ${deferral_timer_minutes_schedule_workflow_active_adjusted}.
		if [[ "${deferral_timer_match}" == "TRUE" ]]; then
			if [[ -n "${deferral_timer_minutes_schedule_workflow_active_check}" ]]; then
				[[ "${schedule_workflow_active_matches_now}" == "TRUE" ]] && log_super "Status: The default deferral timer falls within the current schedule workflow active time frame."
				[[ "${schedule_workflow_active_matches_now}" == "FALSE" ]] && log_super "Status: The default deferral timer falls within a future schedule workflow active time frame."
				deferral_timer_minutes_schedule_workflow_active_adjusted="${deferral_timer_minutes_schedule_workflow_active_check}"
			else # ${deferral_timer_menu_schedule_workflow_active_check}
				deferral_timer_minutes_schedule_workflow_active_adjusted="${deferral_timer_menu_schedule_workflow_active_check}"
			fi
		elif [[ -n "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			IFS=$'\n'
			schedule_workflow_active_match_weekday_start_epoch=$(echo "${schedule_workflow_active_match_start_epochs_array[*]}" | sort | head -1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_weekday_start_epoch: ${schedule_workflow_active_match_weekday_start_epoch}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_epoch: ${deadline_epoch}"
			if [[ -n "${deadline_epoch}" ]] && [[ $deadline_epoch -lt $schedule_workflow_active_match_weekday_start_epoch ]]; then
				deferral_timer_minutes_schedule_workflow_active_adjusted=$(((deadline_epoch - workflow_time_epoch) / 60))
				[[ -n "${deferral_timer_minutes_schedule_workflow_active_check}" ]] && log_super "Warning: Adjusting the default deferral timer to coordinate with the current deadline."
			else
				deferral_timer_minutes_schedule_workflow_active_adjusted=$(((schedule_workflow_active_match_weekday_start_epoch - workflow_time_epoch) / 60))
				[[ -n "${deferral_timer_minutes_schedule_workflow_active_check}" ]] && log_super "Warning: Adjusting the default deferral timer to coordinate with a future schedule workflow active time frame that starts at $(date -j -f %s "${schedule_workflow_active_match_weekday_start_epoch}" +%a:%H:%M | tr '[:lower:]' '[:upper:]')."
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_minutes_schedule_workflow_active_adjusted: ${deferral_timer_minutes_schedule_workflow_active_adjusted}"
		IFS="${previous_ifs}"
		return 0
	fi
	
	# If there is a ${deadline_epoch_schedule_workflow_active_check} then adjust it to coordinate with the ${schedule_workflow_active_option} and set ${deadline_epoch_schedule_workflow_active_adjusted} accordingly.
	if [[ -n "${deadline_epoch_schedule_workflow_active_check}" ]]; then
		local deadline_epoch_temp
		deadline_epoch_temp=$(date -j -f %Y-%m-%d:%H:%M:%S "$(date -r "${deadline_epoch_schedule_workflow_active_check}" "+%Y-%m-%d:23:59:59")" +%s)
		local deadline_days_away
		deadline_days_away=$(((deadline_epoch_temp - $(date -v+0d -v0H -v0M -v0S +%s)) / 86400))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_epoch_temp: ${deadline_epoch_temp}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_away: ${deadline_days_away}"
		
		# If needed, look for ${schedule_workflow_active} time frames that match today and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if [[ $deadline_days_away -eq 0 ]]; then
			for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
				if [[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_time_weekday}" ]]; then
					schedule_workflow_active_match_start_epoch=$(date -j -f %H:%M:%S "${schedule_workflow_active_time_frame:4:5}:00" +%s)
					schedule_workflow_active_match_end_epoch=$(date -j -f %H:%M:%S "${schedule_workflow_active_time_frame:10:5}:00" +%s)
					if [[ $schedule_workflow_active_match_start_epoch -le $workflow_time_epoch ]] && [[ $workflow_time_epoch -le $schedule_workflow_active_match_end_epoch ]]; then
						schedule_workflow_active_match_start_epochs_array=("${schedule_workflow_active_match_start_epoch}")
						schedule_workflow_active_matches_now="TRUE"
						break
					elif [[ $workflow_time_epoch -le $schedule_workflow_active_match_start_epoch ]]; then
						schedule_workflow_active_match_start_epochs_array+=("${schedule_workflow_active_match_start_epoch}")
					fi
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_matches_now: ${schedule_workflow_active_matches_now}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# If needed, find future ${schedule_workflow_active} time frames by looping through 7 weekdays in reverse from the deadline day and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if [[ -z "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			local deadline_weekday
			deadline_weekday="$(date -j -f %s "${deadline_epoch_temp}" +%a | tr '[:lower:]' '[:upper:]')"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_weekday: ${deadline_weekday}"
			for ((counter=0; counter<6; ++counter)); do
				if [[ $((deadline_days_away - counter)) -ge 1 ]]; then
					for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
						[[ "${schedule_workflow_active_time_frame:0:3}" == "${deadline_weekday}" ]] && schedule_workflow_active_match_start_epochs_array+=($(date -j -v+$((deadline_days_away - counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s))
					done
				else # No more weekdays to check.
					break
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# If at least one matching workflow active timeframe was identified then set ${deadline_epoch_schedule_workflow_active_adjusted}.
		if [[ -n "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			IFS=$'\n'
			[[ "${schedule_workflow_active_matches_now}" == "TRUE" ]] && deadline_epoch_schedule_workflow_active_adjusted=${schedule_workflow_active_match_start_epochs_array[0]}
			[[ "${schedule_workflow_active_matches_now}" == "FALSE" ]] && deadline_epoch_schedule_workflow_active_adjusted=$(echo "${schedule_workflow_active_match_start_epochs_array[*]}" | sort -r | head -1)
			log_super "Warning: Adjusting the dealine to coordinate with a schedule workflow active time frame that starts at $(date -j -f %s "${deadline_epoch_schedule_workflow_active_adjusted}" +%a:%H:%M | tr '[:lower:]' '[:upper:]')."
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_epoch_schedule_workflow_active_adjusted: ${deadline_epoch_schedule_workflow_active_adjusted}"
		IFS="${previous_ifs}"
		return 0
	fi
	
	# If there is a ${workflow_scheduled_install} via the ${scheduled_install_days} and ${scheduled_install_date} options then compare to the ${schedule_workflow_active_option} for possible adjustments.
	if [[ -n "${scheduled_install_days}" ]] || [[ -n "${scheduled_install_date}" ]]; then
		local workflow_scheduled_install_weekday
		[[ $(echo "${workflow_scheduled_install}" | grep -c ':00:00$') -gt 0 ]] && workflow_scheduled_install="${workflow_scheduled_install:0:10}:23:59"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install: ${workflow_scheduled_install}"
		
		# If needed, look for ${schedule_workflow_active} time frames that match today and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if { [[ -n "${scheduled_install_days}" ]] && [[ $scheduled_install_days -eq 0 ]]; } || [[ "${scheduled_install_past_deadline}" == "TRUE" ]]; then
			for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
				if [[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_time_weekday}" ]]; then
					schedule_workflow_active_match_start_epoch=$(date -j -f %H:%M:%S "${schedule_workflow_active_time_frame:4:5}:00" +%s)
					schedule_workflow_active_match_end_epoch=$(date -j -f %H:%M:%S "${schedule_workflow_active_time_frame:10:5}:00" +%s)
					if [[ $schedule_workflow_active_match_start_epoch -le $workflow_time_epoch ]] && [[ $workflow_time_epoch -le $schedule_workflow_active_match_end_epoch ]]; then
						schedule_workflow_active_match_start_epochs_array=("${schedule_workflow_active_match_start_epoch}")
						schedule_workflow_active_matches_now="TRUE"
						break
					elif [[ $workflow_time_epoch -le $schedule_workflow_active_match_start_epoch ]]; then
						schedule_workflow_active_match_start_epochs_array+=("${schedule_workflow_active_match_start_epoch}")
					fi
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_matches_now: ${schedule_workflow_active_matches_now}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# At this point if a new ${scheduled_install_past_deadline} and there is no ${schedule_workflow_active_match_start_epochs_array[*]}, the install should be ASAP.
		if [[ "${scheduled_install_past_deadline}" == "TRUE" ]] && [[ -z "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			[[ $(echo "${workflow_scheduled_install}" | grep -c ':23:59$') -gt 0 ]] && workflow_scheduled_install="${workflow_scheduled_install:0:10}:00:00"
			return 0
		fi
		
		# If ${scheduled_install_days} is zero and there are no matching time frames yet, then loop through the next 7 weekdays starting from tomorrow and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if { [[ -n "${scheduled_install_days}" ]] && [[ $scheduled_install_days -eq 0 ]]; } && [[ -z "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			for ((counter=1; counter<8; ++counter)); do
				workflow_scheduled_install_weekday="$(date -v+${counter}d +%a | tr '[:lower:]' '[:upper:]')"
				for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
					if [[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_scheduled_install_weekday}" ]]; then
						schedule_workflow_active_match_start_epochs_array+=($(date -v+"${counter}"d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s))
					fi
				done
				[[ -n "${schedule_workflow_active_match_start_epochs_array[*]}" ]] && break
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# If needed, find future ${schedule_workflow_active} time frames by looping through 7 weekdays in reverse from the scheduled day and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if [[ -z "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			local workflow_scheduled_install_days_away
			workflow_scheduled_install_days_away=$((($(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install:0:10}:23:23:59" +%s) - $(date -v+0d -v0H -v0M -v0S +%s)) / 86400))
			workflow_scheduled_install_weekday="$(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%a | tr '[:lower:]' '[:upper:]')"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_days_away: ${workflow_scheduled_install_days_away}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_weekday: ${workflow_scheduled_install_weekday}"
			for ((counter=0; counter<6; ++counter)); do
				if [[ $((workflow_scheduled_install_days_away - counter)) -ge 1 ]]; then
					for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
						[[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_scheduled_install_weekday}" ]] && schedule_workflow_active_match_start_epochs_array+=($(date -j -v+$((workflow_scheduled_install_days_away - counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s))
					done
				else # No more weekdays to check.
					break
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# If at least one matching workflow active timeframe was identified then set ${workflow_scheduled_install_adjusted}.
		if [[ -n "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			IFS=$'\n'
			[[ "${schedule_workflow_active_matches_now}" == "TRUE" ]] && schedule_workflow_active_match_weekday_start_epoch=${schedule_workflow_active_match_start_epochs_array[0]}
			[[ "${schedule_workflow_active_matches_now}" == "FALSE" ]] && schedule_workflow_active_match_weekday_start_epoch=$(echo "${schedule_workflow_active_match_start_epochs_array[*]}" | sort -r | head -1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_weekday_start_epoch: ${schedule_workflow_active_match_weekday_start_epoch}"
			workflow_scheduled_install_adjusted="$(date -j -f %s "${schedule_workflow_active_match_weekday_start_epoch}" +%Y-%m-%d:%H:%M)"
			[[ -n "${scheduled_install_days}" ]] && log_super "Warning: Adjusting the original scheduled installation of $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install:0:10} (${scheduled_install_days} days after zero day) to coordinate with a schedule workflow active time frame."
			[[ -n "${scheduled_install_date}" ]] && log_super "Warning: Adjusting the original manually scheduled installation of $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install:0:10} to coordinate with a schedule workflow active time frame."
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_adjusted: ${workflow_scheduled_install_adjusted}"
		{ [[ -z "${workflow_scheduled_install_adjusted}" ]] && [[ $(echo "${workflow_scheduled_install}" | grep -c ':23:59$') -gt 0 ]]; } && workflow_scheduled_install="${workflow_scheduled_install:0:10}:00:00"
	fi
	
	# If there is a ${workflow_scheduled_install} via the ${scheduled_install_user_choice_option} then compare it to the ${schedule_workflow_active_option} for possible adjustment.
	if [[ "${scheduled_install_user_choice_option}" == "TRUE" ]]; then
		local scheduled_install_user_choice_match
		scheduled_install_user_choice_match="FALSE"
		scheduled_install_user_choice_adjusted="FALSE"
		local workflow_scheduled_install_epoch_temp
		workflow_scheduled_install_epoch_temp=$(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%s)
		local workflow_scheduled_install_days_away
		workflow_scheduled_install_days_away=$((($(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install:0:10}:23:23:59" +%s) - $(date -v+0d -v0H -v0M -v0S +%s)) / 86400))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install: ${workflow_scheduled_install}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_epoch_temp: ${workflow_scheduled_install_epoch_temp}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_days_away: ${workflow_scheduled_install_days_away}"
		
		# If needed, look for a ${schedule_workflow_active} time frame that matches today to set ${scheduled_install_user_choice_match} and ${schedule_workflow_active_matches_now} accordingly.
		if [[ $workflow_scheduled_install_days_away -eq 0 ]]; then
			for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
				if [[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_time_weekday}" ]]; then
					schedule_workflow_active_match_start_epoch=$(date -j -f %H:%M:%S "${schedule_workflow_active_time_frame:4:5}:00" +%s)
					schedule_workflow_active_match_end_epoch=$(date -j -f %H:%M:%S "${schedule_workflow_active_time_frame:10:5}:00" +%s)
					if [[ $schedule_workflow_active_match_start_epoch -le $workflow_scheduled_install_epoch_temp ]] && [[ $workflow_scheduled_install_epoch_temp -le $schedule_workflow_active_match_end_epoch ]]; then
						scheduled_install_user_choice_match="TRUE"
						{ [[ $schedule_workflow_active_match_start_epoch -le $workflow_time_epoch ]] && [[ $workflow_time_epoch -le $schedule_workflow_active_match_end_epoch ]]; } && schedule_workflow_active_matches_now="TRUE"
						break
					fi
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_match: ${scheduled_install_user_choice_match}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_matches_now: ${schedule_workflow_active_matches_now}"
		fi
		
		# If needed, find future ${schedule_workflow_active} time frames by looping through 7 weekdays in reverse from the scheduled day and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if [[ "${scheduled_install_user_choice_match}" == "FALSE" ]]; then
			local workflow_scheduled_install_weekday
			workflow_scheduled_install_weekday="$(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%a | tr '[:lower:]' '[:upper:]')"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_days_away: ${workflow_scheduled_install_days_away}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_weekday: ${workflow_scheduled_install_weekday}"
			for ((counter=0; counter<6; ++counter)); do
				if [[ $((workflow_scheduled_install_days_away - counter)) -ge 0 ]]; then
					for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
						if [[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_scheduled_install_weekday}" ]]; then
							schedule_workflow_active_match_start_epoch=$(date -j -v+$((workflow_scheduled_install_days_away - counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s)
							schedule_workflow_active_match_end_epoch=$(date -j -v+$((workflow_scheduled_install_days_away - counter))d -v"${schedule_workflow_active_time_frame:10:2}"H -v"${schedule_workflow_active_time_frame:13:2}"M -v00S +%s)
							if [[ $schedule_workflow_active_match_start_epoch -le $workflow_scheduled_install_epoch_temp ]] && [[ $workflow_scheduled_install_epoch_temp -le $schedule_workflow_active_match_end_epoch ]]; then
								scheduled_install_user_choice_match="TRUE"
								break
							elif [[ $workflow_scheduled_install_epoch_temp -le $schedule_workflow_active_match_start_epoch ]]; then
								schedule_workflow_active_match_start_epochs_array+=($(date -j -v+$((workflow_scheduled_install_days_away - counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s))
							fi
						fi
					done
				else # No more weekdays to check.
					break
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_match: ${scheduled_install_user_choice_match}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# If there is still no matching time frame, then loop through the following 7 weekdays starting from tomorrow and set ${schedule_workflow_active_match_start_epochs_array[*]} accordingly.
		if [[ "${scheduled_install_user_choice_match}" == "FALSE" ]] && [[ -z "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			for ((counter=1; counter<8; ++counter)); do
				workflow_scheduled_install_weekday="$(date -v+$((workflow_scheduled_install_days_away + counter))d +%a | tr '[:lower:]' '[:upper:]')"
				for schedule_workflow_active_time_frame in "${schedule_workflow_active_array[@]}"; do
					if [[ "${schedule_workflow_active_time_frame:0:3}" == "${workflow_scheduled_install_weekday}" ]]; then
						schedule_workflow_active_match_start_epochs_array+=($(date -v+$((workflow_scheduled_install_days_away + counter))d -v"${schedule_workflow_active_time_frame:4:2}"H -v"${schedule_workflow_active_time_frame:7:2}"M -v00S +%s))
					fi
				done
				[[ -n "${schedule_workflow_active_match_start_epochs_array[*]}" ]] && break
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_start_epochs_array is:\n${schedule_workflow_active_match_start_epochs_array[*]}"
		fi
		
		# If at least one matching workflow active timeframe was identified so set ${workflow_scheduled_install_adjusted}.
		if [[ "${scheduled_install_user_choice_match}" == "TRUE" ]]; then
			if [[ $workflow_scheduled_install_days_away -eq 0 ]]; then
				[[ "${schedule_workflow_active_matches_now}" == "TRUE" ]] && log_super "Status: The current user selected scheduled installation falls within the current schedule workflow active time frame."
				[[ "${schedule_workflow_active_matches_now}" == "FALSE" ]] && log_super "Status: The current user selected scheduled installation falls within a future schedule workflow active time frame later today."
			else
				log_super "Status: The current user selected scheduled installation falls within a future schedule workflow active time frame on another day."
			fi
			workflow_scheduled_install_adjusted="${workflow_scheduled_install}"
		elif [[ -n "${schedule_workflow_active_match_start_epochs_array[*]}" ]]; then
			IFS=$'\n'
			schedule_workflow_active_match_weekday_start_epoch=$(echo "${schedule_workflow_active_match_start_epochs_array[*]}" | sort -r | head -1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_workflow_active_match_weekday_start_epoch: ${schedule_workflow_active_match_weekday_start_epoch}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_epoch: ${deadline_epoch}"
			if [[ -n "${deadline_epoch}" ]] && [[ $deadline_epoch -lt $schedule_workflow_active_match_weekday_start_epoch ]]; then
				workflow_scheduled_install_adjusted="$(date -j -f %s "${deadline_epoch}" +%Y-%m-%d:%H:%M)"
				log_super "Warning: Adjusting the original user selected scheduled installation of $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install:0:10} to coordinate with the current deadline."
			else
				workflow_scheduled_install_adjusted="$(date -j -f %s "${schedule_workflow_active_match_weekday_start_epoch}" +%Y-%m-%d:%H:%M)"
				log_super "Warning: Adjusting the original user selected scheduled installation of $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install:0:10} to coordinate with a schedule workflow active time frame."
			fi
			scheduled_install_user_choice_adjusted="TRUE"
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_adjusted: ${scheduled_install_user_choice_adjusted}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_adjusted: ${workflow_scheduled_install_adjusted}"
	fi
	IFS="${previous_ifs}"
}

# Download the SOFA macOS releases json feed and set ${sofa_macos_json} and cache information.
get_sofa_macos_json() {
	sofa_macos_cache="FALSE"
	sofa_macos_json="FALSE"
	
	# First check for an existing local SOFA macOS releases json feed cache.
	local sofa_macos_json_checksum_cache
	sofa_macos_json_checksum_cache=$(defaults read "${SUPER_LOCAL_PLIST}" SOFAMacOSJsonCacheChecksum 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: sofa_macos_json_checksum_cache is: ${sofa_macos_json_checksum_cache}"
	if [[ -n "${sofa_macos_json_checksum_cache}" ]]; then
		if [[ -e "${SOFA_MACOS_JSON_ETAG_CACHE}" ]] && [[ "${sofa_macos_json_checksum_cache}" == "$(md5 -q "${SOFA_MACOS_JSON_CACHE}" 2>/dev/null)" ]]; then
			sofa_macos_cache="TRUE"
		else
			log_super "Status: The SOFA macOS releases feed cache is not valid, a new feed must be downloaded."
			defaults delete "${SUPER_LOCAL_PLIST}" SOFAMacOSJsonCacheChecksum 2>/dev/null
			rm -f "${SOFA_MACOS_JSON_ETAG_CACHE}" 2>/dev/null
			rm -f "${SOFA_MACOS_JSON_CACHE}" 2>/dev/null
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: sofa_macos_cache is: ${sofa_macos_cache}"
	
	# Check SOFA macOS releases json feed cache via HTTP ETag or download a new feed.
	local curl_response
	if [[ "${sofa_macos_cache}" == "TRUE" ]]; then
		log_super "Status: Validating SOFA macOS releases feed cache..."
		curl_response=$(curl --write-out "%{http_code}" --max-time 5 --etag-compare "${SOFA_MACOS_JSON_ETAG_CACHE}" --location "${sofa_macos_url}" --etag-save "${SOFA_MACOS_JSON_ETAG_CACHE}" --output "${SOFA_MACOS_JSON_CACHE}" 2>&1)
		[[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]] && log_super "Status: An updated SOFA macOS releases feed was downloaded."
	else
		log_super "Status: Downloading new SOFA macOS releases feed..."
		curl_response=$(curl --write-out "%{http_code}" --max-time 5 --location "${sofa_macos_url}" --etag-save "${SOFA_MACOS_JSON_ETAG_CACHE}" --output "${SOFA_MACOS_JSON_CACHE}" 2>&1)
	fi
	
	# Verify the SOFA releases json feed download completed and is valid.
	if { [[ $(echo "${curl_response}" | grep -c '304') -gt 0 ]] || [[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]]; } && [[ -e "${SOFA_MACOS_JSON_ETAG_CACHE}" ]] && [[ -e "${SOFA_MACOS_JSON_CACHE}" ]]; then
		if [[ $(sqlite3 /dev/null "SELECT json_valid(readfile('${SOFA_MACOS_JSON_CACHE}'))") -eq 1 ]] && [[ -n $(sqlite3 /dev/null "SELECT json_extract(readfile('${SOFA_MACOS_JSON_CACHE}'), '$.UpdateHash')") ]]; then
			sofa_macos_json="TRUE"
		else
			log_super "Error: The downloaded SOFA macOS releases feed ${SOFA_MACOS_JSON_CACHE} appears to be invalid."
		fi
	else
		log_super "Error: SOFA macOS releases feed failed to download: ${curl_response}"
	fi
	
	# If the ${SOFA_MACOS_JSON_CACHE} is valid, then save cache information.
	if [[ "${sofa_macos_json}" == "TRUE" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" SOFAMacOSJsonCacheChecksum -string "$(md5 -q "${SOFA_MACOS_JSON_CACHE}" 2>/dev/null)"
	else
		defaults delete "${SUPER_LOCAL_PLIST}" SOFAMacOSJsonCacheChecksum 2>/dev/null
		rm -f "${SOFA_MACOS_JSON_ETAG_CACHE}" 2>/dev/null
	fi
}

# Evaluate ${schedule_zero_date_manual} and ${schedule_zero_date_release_option} to set ${schedule_zero_date}, ${schedule_zero_date_epoch}, and ${display_string_schedule_zero_date} accordingly.
check_schedule_zero_date() {
	schedule_zero_date="FALSE"
	local schedule_zero_date_automatic_release_previous
	schedule_zero_date_automatic_release_previous=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_automatic_release_previous: ${schedule_zero_date_automatic_release_previous}"
	local schedule_zero_date_automatic_release_failover_previous
	schedule_zero_date_automatic_release_failover_previous=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticReleaseFailover 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_automatic_release_failover_previous: ${schedule_zero_date_automatic_release_failover_previous}"
	local schedule_zero_date_automatic_start_previous
	schedule_zero_date_automatic_start_previous=$(defaults read "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticStart 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_automatic_start_previous: ${schedule_zero_date_automatic_start_previous}"
	
	# If there is a ${schedule_zero_date_manual} then just use that.
	if [[ -n "${schedule_zero_date_manual}" ]]; then
		schedule_zero_date="${schedule_zero_date_manual}"
		log_super "Warning: Using manually set zero date of ${schedule_zero_date}. This date does not change automatically."
		[[ -n "${schedule_zero_date_automatic_start_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticStart 2>/dev/null
		[[ -n "${schedule_zero_date_automatic_start_previous}" ]] && unset schedule_zero_date_automatic_start_previous
		[[ -n "${schedule_zero_date_automatic_release_failover_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticReleaseFailover 2>/dev/null
		[[ -n "${schedule_zero_date_automatic_release_failover_previous}" ]] && unset schedule_zero_date_automatic_release_failover_previous
		[[ -n "${schedule_zero_date_automatic_release_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease 2>/dev/null
		[[ -n "${schedule_zero_date_automatic_release_previous}" ]] && unset schedule_zero_date_automatic_release_previous
	fi
	
	# If no ${schedule_zero_date} yet then check for previously set automatic zero dates.
	if [[ "${schedule_zero_date}" == "FALSE" ]]; then
		# If the ${workflow_target} is not a macOS version then the automatic release date cannot be used.
		if { [[ "${workflow_target}" == "Non-system Software Updates" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers With Restart" ]] || [[ "${workflow_target}" == "Restart Without Updates" ]]; } && [[ "${schedule_zero_date_release_option}" == "TRUE" ]]; then
			log_super "Warning: The --schedule-zero-date-release option can not be used with the current ${workflow_target} workflow target."
			schedule_zero_date_release_option="FALSE"
		fi
		
		# If the current ${workflow_target} matches the previously set workflow target then collect any previously saved zero dates.
		local workflow_target_previous
		workflow_target_previous=$(defaults read "${SUPER_LOCAL_PLIST}" WorkflowTarget 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_target: ${workflow_target}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_target_previous: ${workflow_target_previous}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_release_option: ${schedule_zero_date_release_option}"
		if [[ "${workflow_target}" == "${workflow_target_previous}" ]]; then
			if [[ "${schedule_zero_date_release_option}" == "TRUE" ]] && [[ "${schedule_zero_date_automatic_release_failover_previous}" -ne 1 ]]; then
				if [[ -n "${schedule_zero_date_automatic_release_previous}" ]]; then
					schedule_zero_date="${schedule_zero_date_automatic_release_previous}"
					log_super "Status: Previously set automatic zero date based on the ${workflow_target} release date of ${schedule_zero_date}."
				fi
				[[ -n "${schedule_zero_date_automatic_release_failover_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticReleaseFailover 2>/dev/null
				[[ -n "${schedule_zero_date_automatic_release_failover_previous}" ]] && unset schedule_zero_date_automatic_release_failover_previous
				[[ -n "${schedule_zero_date_automatic_start_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticStart 2>/dev/null
				[[ -n "${schedule_zero_date_automatic_start_previous}" ]] && unset schedule_zero_date_automatic_start_previous
			else # Automatic workflow start date or automatic release failover.
				if [[ -n "${schedule_zero_date_automatic_start_previous}" ]]; then
					schedule_zero_date="${schedule_zero_date_automatic_start_previous}"
					log_super "Status: Previously set automatic zero date based on the ${workflow_target} workflow start date of ${schedule_zero_date}."
				fi
				[[ -n "${schedule_zero_date_automatic_release_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease 2>/dev/null
				[[ -n "${schedule_zero_date_automatic_release_previous}" ]] && unset schedule_zero_date_automatic_release_previous
			fi
		else # If the current ${workflow_target} does not match the previously saved target.
			{ [[ -n "${workflow_target_previous}" ]] && [[ "${workflow_target_previous}" != "FALSE" ]]; } && log_super "Warning: The previously saved ${workflow_target_previous} workflow target does not match the current ${workflow_target} workflow target."
		fi
	fi
	
	# If no ${schedule_zero_date} yet and the ${schedule_zero_date_release_option} is enabled then download ${SOFA_MACOS_JSON_CACHE} if it hasn't already been cached.
	if [[ "${schedule_zero_date}" == "FALSE" ]] && [[ "${schedule_zero_date_release_option}" == "TRUE" ]]; then
		sofa_macos_json="FALSE"
		local schedule_zero_date_release_failover
		schedule_zero_date_release_failover="FALSE"
		local schedule_zero_date_version_target
		schedule_zero_date_version_target="FALSE"
		[[ "${macos_installer_target}" != "FALSE" ]] && schedule_zero_date_version_target="${macos_installer_version}"
		{ [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] || [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; } && schedule_zero_date_version_target="${macos_msu_version}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_version_target: ${schedule_zero_date_version_target}"
		if [[ $(echo "${schedule_zero_date_version_target}" | awk -F '.' '{print $1}') -ge 13 ]]; then
			# If required collecte a new ${sofa_macos_json}.
			if [[ "${check_software_status_required}" == "TRUE" ]] || [[ "${sofa_macos_json}" == "FALSE" ]]; then
				get_sofa_macos_json
				
				# Error handling if curl is misbehaving.
				if [[ "${sofa_macos_json}" == "FALSE" ]]; then
					log_super "Warning: Re-starting downloading SOFA macOS releases feed..."
					get_sofa_macos_json
				fi
				if [[ "${sofa_macos_json}" == "FALSE" ]]; then
					log_super "Warning: Downloading SOFA macOS releases feed did not complete after multiple attempts, failing over to automatic zero date based on the workflow start date."
					schedule_zero_date_release_failover="TRUE"
				fi
			fi
		else # The ${schedule_zero_date_version_target} is too old.
			log_super "Warning: The workflow target of macOS $(echo "${schedule_zero_date_version_target}" | awk -F '.' '{print $1}') is no longer updated by Apple therefore all release dates are well past being useful, failing over to automatic zero date based on the workflow start date."
			sofa_macos_json="FALSE"
			schedule_zero_date_release_failover="TRUE"
		fi
	fi
	
	# If no ${schedule_zero_date} yet and the ${schedule_zero_date_release_option} is enabled and there is a ${schedule_zero_date_version_target} and there appears to be a valid ${SOFA_MACOS_JSON_CACHE}, then attempt to parse and find the release date associated with ${schedule_zero_date_version_target}
	if [[ "${schedule_zero_date}" == "FALSE" ]] && [[ "${schedule_zero_date_version_target}" != "FALSE" ]] && [[ "${schedule_zero_date_release_option}" == "TRUE" ]] && [[ "${sofa_macos_json}" == "TRUE" ]]; then
		local sofa_osversions_array_index
		for array_index in $(seq 0 "$(sqlite3 /dev/null "SELECT json_array_length(readfile('${SOFA_MACOS_JSON_CACHE}'), '$.OSVersions')"-1 2>/dev/null)"); do
			if [[ $(sqlite3 /dev/null "SELECT json_extract(readfile('${SOFA_MACOS_JSON_CACHE}'), '$.OSVersions[$array_index].OSVersion')" 2>/dev/null | awk '{print $2;}') -eq $(echo "${schedule_zero_date_version_target}" | awk -F '.' '{print $1}') ]]; then
				sofa_osversions_array_index=$array_index
				break
			fi
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: sofa_osversions_array_index: ${sofa_osversions_array_index}"
		for array_index in $(seq 0 "$(sqlite3 /dev/null "SELECT json_array_length(readfile('${SOFA_MACOS_JSON_CACHE}'), '$.OSVersions[$sofa_osversions_array_index].SecurityReleases')"-1 2>/dev/null)"); do
			if [[ $(sqlite3 /dev/null "SELECT json_extract(readfile('${SOFA_MACOS_JSON_CACHE}'), '$.OSVersions[$sofa_osversions_array_index].SecurityReleases[$array_index].ProductVersion')" 2>/dev/null) == "${schedule_zero_date_version_target}" ]]; then
				schedule_zero_date=$(sqlite3 /dev/null "SELECT json_extract(readfile('${SOFA_MACOS_JSON_CACHE}'), '$.OSVersions[$sofa_osversions_array_index].SecurityReleases[$array_index].ReleaseDate')" 2>/dev/null | sed -e 's/T/:/g' -e 's/:00Z//g')
				log_super "Status: Setting new automatic zero date based on the ${workflow_target} release date of ${schedule_zero_date}."
				defaults write "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease -string "${schedule_zero_date}"
				[[ -n "${schedule_zero_date_automatic_start_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticStart 2>/dev/null
				[[ -n "${schedule_zero_date_automatic_start_previous}" ]] && unset schedule_zero_date_automatic_start_previous
				break
			fi
		done
		if [[ "${schedule_zero_date}" == "FALSE" ]]; then
			log_super "Warning: Unable to find release date for target macOS ${schedule_zero_date_version_target}, failing over to automatic zero date based on the workflow start date."
			schedule_zero_date_release_failover="TRUE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_release_failover: ${schedule_zero_date_release_failover}"
	
	# If there is no ${schedule_zero_date} at this point then set one based on workflow start date/time of now.
	if [[ "${schedule_zero_date}" == "FALSE" ]]; then
		schedule_zero_date=$(date +%Y-%m-%d:%H:%M)
		log_super "Status: Setting new automatic zero date based on the ${workflow_target} workflow start date of ${schedule_zero_date}."
		defaults write "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticStart -string "${schedule_zero_date}"
		defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease 2>/dev/null
		[[ -n "${schedule_zero_date_automatic_release_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticRelease 2>/dev/null
		[[ -n "${schedule_zero_date_automatic_release_previous}" ]] && unset schedule_zero_date_automatic_release_previous
		if [[ "${schedule_zero_date_release_failover}" == "TRUE" ]]; then
			defaults write "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticReleaseFailover -bool true
		else
			[[ -n "${schedule_zero_date_automatic_release_failover_previous}" ]] && defaults delete "${SUPER_LOCAL_PLIST}" ScheduleZeroDateAutomaticReleaseFailover 2>/dev/null
			[[ -n "${schedule_zero_date_automatic_release_failover_previous}" ]] && unset schedule_zero_date_automatic_release_failover_previous
		fi
	fi
	
	# Set remaining zero date parameters.
	schedule_zero_date_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${schedule_zero_date}:00" +%s)
	local display_string_schedule_zero_date_only_date
	display_string_schedule_zero_date_only_date=$(date -r "${schedule_zero_date_epoch}" "+${DISPLAY_STRING_FORMAT_DATE}")
	local display_string_schedule_zero_date_only_time
	display_string_schedule_zero_date_only_time=$(date -r "${schedule_zero_date_epoch}" "+${DISPLAY_STRING_FORMAT_TIME}" | sed 's/^ *//g')
	if [[ $(date -r "${schedule_zero_date_epoch}" +%H:%M) == "00:00" ]]; then
		display_string_schedule_zero_date="${display_string_schedule_zero_date_only_date}"
	else
		display_string_schedule_zero_date="${display_string_schedule_zero_date_only_date}${DISPLAY_STRING_FORMAT_DATE_TIME_SEPARATOR}${display_string_schedule_zero_date_only_time}"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: schedule_zero_date_epoch: ${schedule_zero_date_epoch}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_schedule_zero_date_only_date: ${display_string_schedule_zero_date_only_date}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_schedule_zero_date_only_time: ${display_string_schedule_zero_date_only_time}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_schedule_zero_date: ${display_string_schedule_zero_date}"
}

# Evaluate any previously set ${workflow_scheduled_install_active}, ${scheduled_install_days}, and ${scheduled_install_date} options.
# If needed will set ${workflow_scheduled_install}, ${workflow_scheduled_install_epoch}, ${workflow_scheduled_install_active}, ${workflow_scheduled_install_now}, ${scheduled_install_past_deadline}, ${scheduled_install_suppress_reminder}, ${scheduled_install_final_reminder}, and ${scheduled_install_user_choice_active}.
check_scheduled_install() {
	workflow_scheduled_install_now="FALSE"
	scheduled_install_past_deadline="FALSE"
	scheduled_install_suppress_reminder="FALSE"
	scheduled_install_final_reminder="FALSE"
	scheduled_install_user_choice_active="FALSE"
	
	# If there is no ${workflow_scheduled_install} yet then, if needed, set it per the ${scheduled_install_days} or ${scheduled_install_date} options.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_days: ${scheduled_install_days}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_date: ${scheduled_install_date}"
	if [[ -z "${workflow_scheduled_install}" ]] && { [[ -n "${scheduled_install_days}" ]] || [[ -n "${scheduled_install_date}" ]]; }; then
		local workflow_scheduled_install_epoch_temp
		if [[ -n "${scheduled_install_days}" ]]; then
			if [[ $scheduled_install_days -eq 0 ]]; then
				log_super "Warning: The --scheduled-install-days option is set to 0. Adjusting scheduled installation date to today."
				workflow_scheduled_install="$(date -r "$((workflow_time_epoch - 1))" +%Y-%m-%d):00:00"
			else
				workflow_scheduled_install_epoch_temp=$((schedule_zero_date_epoch + (scheduled_install_days * 86400)))
				workflow_scheduled_install="$(date -r "${workflow_scheduled_install_epoch_temp}" +%Y-%m-%d):00:00"
				if [[ $workflow_scheduled_install_epoch_temp -le $workflow_time_epoch ]]; then
					log_super "Warning: The --scheduled-install-days option of ${scheduled_install_days} days is in the past given the current zero day of ${display_string_schedule_zero_date}."
					scheduled_install_past_deadline="TRUE"
				fi
			fi
			scheduled_install_suppress_reminder="TRUE"
		fi
		if [[ -n "${scheduled_install_date}" ]]; then
			[[ -n "${scheduled_install_date}" ]] && log_super "Warning: The date and time specified in the --scheduled-install-date option does not change automatically when newer updates or workflows are made available."
			workflow_scheduled_install="${scheduled_install_date}"
			if [[ $(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%s) -le $workflow_time_epoch ]]; then
				log_super "Warning: The date and time specified in the --scheduled-install-date option of ${scheduled_install_date} is in the past."
				scheduled_install_past_deadline="TRUE"
			fi
			scheduled_install_suppress_reminder="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_past_deadline: ${scheduled_install_past_deadline}"
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install: ${workflow_scheduled_install}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_suppress_reminder: ${scheduled_install_suppress_reminder}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install: ${workflow_scheduled_install}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_past_deadline: ${scheduled_install_past_deadline}"
		
		# If needed adjust for the ${schedule_workflow_active_option} and also write to log.
		if [[ -n "${schedule_workflow_active_option}" ]] && { [[ -n "${scheduled_install_days}" ]] || [[ $(echo "${scheduled_install_date}" | grep -c ':00:00$') -gt 0 ]]; }; then
			set_schedule_workflow_active_adjustments
			if [[ -n "${workflow_scheduled_install_adjusted}" ]]; then
				workflow_scheduled_install="${workflow_scheduled_install_adjusted}"
				if [[ -n "${scheduled_install_days}" ]] && [[ $scheduled_install_days -eq 0 ]]; then
					log_super "Status: Setting new scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} which is the start of the soonest workflow active time frame after zero day."
				else
					[[ "${schedule_workflow_active_matches_now}" == "TRUE" ]] && log_super "Status: Setting new scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} which is the start of the current schedule workflow active time frame."
					[[ "${schedule_workflow_active_matches_now}" == "FALSE" ]] && log_super "Status: Setting new scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} which is the start of the latest workflow active time frame on the original scheduled installation date."
				fi
			else
				[[ -n "${scheduled_install_days}" ]] && log_super "Warning: The current scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} (${scheduled_install_days} days after zero day) is overriding the schedule workflow active option because no coordinating time frame could be resolved."
				[[ -n "${scheduled_install_date}" ]] && log_super "Warning: The current scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} is overriding the schedule workflow active option because no coordinating time frame could be resolved."
			fi
		elif [[ -n "${schedule_workflow_active_option}" ]]; then
			log_super "Warning: The manually scheduled installation date option that also includes a specific time of ${workflow_scheduled_install} is overriding the schedule workflow active option."
		else # Default super workflow.
			[[ -n "${scheduled_install_days}" ]] && log_super "Status: Setting new scheduled installation for ${workflow_scheduled_install} which is ${scheduled_install_days} days after zero date."
			[[ -n "${scheduled_install_date}" ]] && log_super "Status: Using manually scheduled installation date and time of ${workflow_scheduled_install}."
		fi
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall -string "${workflow_scheduled_install}"
	fi
	
	# If there is a ${workflow_scheduled_install} then set both ${workflow_scheduled_install_epoch} and ${workflow_scheduled_install_active}.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install: ${workflow_scheduled_install}"
	if [[ -n "${workflow_scheduled_install}" ]]; then
		workflow_scheduled_install_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%s)
		workflow_scheduled_install_active="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_epoch: ${workflow_scheduled_install_epoch}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_active: ${workflow_scheduled_install_active}"
	
	# If a scheduled install is active then set display strings and evaluate ${workflow_scheduled_install_now}.
	if [[ "${workflow_scheduled_install_active}" == "TRUE" ]]; then
		# Set various display options for scheduled installation dialogs.
		[[ $(echo "${display_unmovable_option}" | grep -c 'SCHEDULED') -gt 0 ]] && display_unmovable_status="TRUE"
		[[ $(echo "${display_hide_background_option}" | grep -c 'SCHEDULED') -gt 0 ]] && display_hide_background_status="TRUE"
		[[ $(echo "${display_silently_option}" | grep -c 'SCHEDULED') -gt 0 ]] && display_silently_status="TRUE"
		[[ $(echo "${display_notifications_centered_option}" | grep -c 'SCHEDULED') -gt 0 ]] && display_notifications_centered_status="TRUE"
		[[ $(echo "${display_hide_progress_bar_option}" | grep -c 'SCHEDULED') -gt 0 ]] && display_hide_progress_bar_status="TRUE"
		local display_string_scheduled_install_only_date
		display_string_scheduled_install_only_date=$(date -r "${workflow_scheduled_install_epoch}" "+${DISPLAY_STRING_FORMAT_DATE}")
		local display_string_scheduled_install_only_time
		display_string_scheduled_install_only_time=$(date -r "${workflow_scheduled_install_epoch}" "+${DISPLAY_STRING_FORMAT_TIME}" | sed 's/^ *//g')
		if [[ $(date -r "${workflow_scheduled_install_epoch}" +%H:%M) == "00:00" ]]; then
			display_string_scheduled_install="${display_string_scheduled_install_only_date}"
		else
			display_string_scheduled_install="${display_string_scheduled_install_only_date}${DISPLAY_STRING_FORMAT_DATE_TIME_SEPARATOR}${display_string_scheduled_install_only_time}"
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_scheduled_install_only_date: ${display_string_scheduled_install_only_date}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_scheduled_install_only_time: ${display_string_scheduled_install_only_time}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_scheduled_install: ${display_string_scheduled_install}"
		
		# Evaluate if the scheduled installation should take place now or later.
		if [[ "${schedule_workflow_active_matches_now}" == "TRUE" ]] || [[ $workflow_scheduled_install_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Scheduled installation date of ${workflow_scheduled_install} has passed."
			workflow_scheduled_install_now="TRUE"
		else
			workflow_scheduled_install_difference=$((workflow_scheduled_install_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_difference is: ${workflow_scheduled_install_difference}"
			{ [[ "${scheduled_install_user_choice_option}" == "TRUE" ]] && [[ "${workflow_scheduled_install_difference}" -gt "${deferral_timer_minutes}" ]]; } && scheduled_install_user_choice_active="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_active: ${scheduled_install_user_choice_active}"
			if [[ "${workflow_scheduled_install_difference}" -le 180 ]]; then
				[[ "${scheduled_install_user_choice_active}" == "FALSE" ]] && log_super "Status: Scheduled installation date of ${workflow_scheduled_install} is only ${workflow_scheduled_install_difference} seconds away, waiting for time to pass..."
				[[ "${scheduled_install_user_choice_active}" == "TRUE" ]] && log_super "Status: Scheduled installation date of ${workflow_scheduled_install} is only ${workflow_scheduled_install_difference} seconds away but the user can still reschedule, waiting for time to pass..."
				if [[ "${current_user_account_name}" != "FALSE" ]]; then
					scheduled_install_final_reminder="TRUE"
					dialog_schedule_reminder
				else
					sleep $((workflow_scheduled_install_difference + 1))
				fi
				log_super "Status: Scheduled installation date of ${workflow_scheduled_install} has passed."
				workflow_scheduled_install_now="TRUE"
			else
				[[ "${scheduled_install_user_choice_active}" == "FALSE" ]] && log_super "Status: Scheduled installation date of ${workflow_scheduled_install} has not passed."
				[[ "${scheduled_install_user_choice_active}" == "TRUE" ]] && log_super "Status: Scheduled installation date of ${workflow_scheduled_install} has not passed and the user can reschedule."
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_now: ${workflow_scheduled_install_now}"
	fi
}

# Evaluate ${workflow_scheduled_install} and ${scheduled_install_reminder_minutes} to set a new ${deferral_timer_minutes}.
set_scheduled_install_deferral() {
	[[ -z "${workflow_scheduled_install_epoch}" ]] && workflow_scheduled_install_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%s)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_scheduled_install_epoch: ${workflow_scheduled_install_epoch}"
	local deferral_timer_scheduled_install_minutes
	deferral_timer_scheduled_install_minutes=$(((workflow_scheduled_install_epoch - workflow_time_epoch) / 60 ))
	if [[ -n "${scheduled_install_reminder_minutes}" ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_reminder_minutes is: ${scheduled_install_reminder_minutes}"
		local previous_ifs
		previous_ifs="${IFS}"
		IFS=','
		local scheduled_install_reminder_array
		read -r -a scheduled_install_reminder_array <<<"${scheduled_install_reminder_minutes}"
		for scheduled_install_reminder_item in "${scheduled_install_reminder_array[@]}"; do
			if [[ $scheduled_install_reminder_item -ge $deferral_timer_scheduled_install_minutes ]]; then
				log_super "Status: Scheduled installation reminder of ${scheduled_install_reminder_item} minutes prior to installation has passed."
				scheduled_install_suppress_reminder="FALSE"
			elif [[ $scheduled_install_reminder_item -lt $deferral_timer_scheduled_install_minutes ]]; then
				deferral_timer_minutes=$((deferral_timer_scheduled_install_minutes - scheduled_install_reminder_item))
				[[ $deferral_timer_minutes -lt 2 ]] && deferral_timer_scheduled_install_minutes=2
				log_super "Status: Scheduled installation on $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install}, with a warning notification ${scheduled_install_reminder_item} minutes prior, deferring for ${deferral_timer_minutes} minutes from now."
				log_status "Pending: Scheduled installation on $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install}, with a warning notification ${scheduled_install_reminder_item} minutes prior, deferring for ${deferral_timer_minutes} minutes from now."
			break
			fi
		done
		IFS="${previous_ifs}"
	else # Default scheduled installation deferral.
		deferral_timer_minutes="${deferral_timer_scheduled_install_minutes}"
		log_super "Status: Scheduled installation on $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install}, deferring for ${deferral_timer_minutes} minutes from now."
		log_status "Pending: Scheduled installation on $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install}, deferring for ${deferral_timer_minutes} minutes from now."
	fi
}

# Evaluate ${deadline_days_focus}, ${deadline_days_soft}, and ${deadline_days_hard}, then set ${deadline_days_status}, ${deadline_days_epoch}, ${deadline_date_epoch}, ${deadline_epoch}, and ${display_string_deadline} accordingly.
check_deadlines_days_date() {
	deadline_days_status="FALSE" # Deadline status modes: FALSE, SOFT, or HARD
	deadline_date_status="FALSE" # Deadline status modes: FALSE, SOFT, or HARD
	
	# Evaluate days deadlines and set ${deadline_days_status} and ${deadline_days_epoch}.
	if [[ -n "${deadline_days_focus}" ]]; then
		local deadline_days_focus_date
		deadline_days_focus_date=$(date -r $((schedule_zero_date_epoch + (deadline_days_focus * 86400))) +%Y-%m-%d)
		defaults write "${SUPER_LOCAL_PLIST}" DeadlineDaysFocusDate -string "${deadline_days_focus_date}"
		local deadline_days_focus_epoch
		deadline_days_focus_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${deadline_days_focus_date}:00:00:00" +%s)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_focus_epoch: ${deadline_days_focus_epoch}"
		if [[ $deadline_days_focus_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${schedule_zero_date}) has passed."
			deadline_days_status="FOCUS"
		else
			local deadline_days_focus_difference
			deadline_days_focus_difference=$((deadline_days_focus_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_focus_difference is: ${deadline_days_focus_difference}"
			if [[ "${deadline_days_focus_difference}" -le 180 ]]; then
				log_super "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${schedule_zero_date}) is only ${deadline_days_focus_difference} seconds away, waiting for deadline to pass..."
				sleep $((deadline_days_focus_difference + 1))
				log_super "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${schedule_zero_date}) has passed."
				deadline_days_status="FOCUS"
			else
				log_super "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${schedule_zero_date}) not passed."
			fi
		fi
	fi
	if [[ -n "${deadline_days_soft}" ]]; then
		local deadline_days_soft_date
		deadline_days_soft_date=$(date -r $((schedule_zero_date_epoch + (deadline_days_soft * 86400))) +%Y-%m-%d)
		defaults write "${SUPER_LOCAL_PLIST}" DeadlineDaysSoftDate -string "${deadline_days_soft_date}"
		local deadline_days_soft_epoch
		deadline_days_soft_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${deadline_days_soft_date}:00:00:00" +%s)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_soft_epoch: ${deadline_days_soft_epoch}"
		if [[ $deadline_days_soft_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Soft days deadline of ${deadline_days_soft_date} (${deadline_days_soft} day(s) after ${schedule_zero_date}) has passed."
			deadline_days_status="SOFT"
		else
			local deadline_days_soft_difference
			deadline_days_soft_difference=$((deadline_days_soft_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_soft_difference is: ${deadline_days_soft_difference}"
			if [[ "${deadline_days_soft_difference}" -le 180 ]]; then
				log_super "Status: Soft days deadline of ${deadline_days_soft_date} (${deadline_days_soft} day(s) after ${schedule_zero_date}) is only ${deadline_days_soft_difference} seconds away, waiting for deadline to pass..."
				sleep $((deadline_days_soft_difference + 1))
				log_super "Status: Soft days deadline of ${deadline_days_soft_date} (${deadline_days_soft} day(s) after ${schedule_zero_date}) has passed."
				deadline_days_status="SOFT"
			else
				log_super "Status: Soft days deadline of ${deadline_days_soft_date} (${deadline_days_soft} day(s) after ${schedule_zero_date}) not passed."
			fi
		fi
	fi
	if [[ -n "${deadline_days_hard}" ]]; then
		local deadline_days_hard_date
		deadline_days_hard_date=$(date -r $((schedule_zero_date_epoch + (deadline_days_hard * 86400))) +%Y-%m-%d)
		defaults write "${SUPER_LOCAL_PLIST}" DeadlineDaysHardDate -string "${deadline_days_hard_date}"
		local deadline_days_hard_epoch
		deadline_days_hard_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${deadline_days_hard_date}:00:00:00" +%s)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_hard_epoch: ${deadline_days_hard_epoch}"
		if [[ $deadline_days_hard_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${schedule_zero_date}) has passed."
			deadline_days_status="HARD"
		else
			local deadline_days_hard_difference
			deadline_days_hard_difference=$((deadline_days_hard_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_hard_difference is: ${deadline_days_hard_difference}"
			if [[ "${deadline_days_hard_difference}" -le 180 ]]; then
				log_super "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${schedule_zero_date}) is only ${deadline_days_hard_difference} seconds away, waiting for deadline to pass..."
				sleep $((deadline_days_hard_difference + 1))
				log_super "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${schedule_zero_date}) has passed."
				deadline_days_status="HARD"
			else
				log_super "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${schedule_zero_date}) not passed."
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_status is: ${deadline_days_status}"
	[[ -n ${deadline_days_hard} ]] && deadline_days_epoch="${deadline_days_hard_epoch}"
	[[ -n ${deadline_days_soft} ]] && deadline_days_epoch="${deadline_days_soft_epoch}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_days_epoch is: ${deadline_days_epoch}"
	
	# Evaluate date deadlines and set ${deadline_date_status} and ${deadline_date_epoch}.
	if [[ -n "${deadline_date_focus}" ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_focus_epoch is: ${deadline_date_focus_epoch}"
		if [[ $deadline_date_focus_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Focus deadline date of ${deadline_date_focus} has passed."
			deadline_date_status="FOCUS"
		else
			local deadline_date_focus_difference
			deadline_date_focus_difference=$((deadline_date_focus_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_focus_difference is: ${deadline_date_focus_difference}"
			if [[ "${deadline_date_focus_difference}" -le 180 ]]; then
				log_super "Status: Focus deadline date of ${deadline_date_focus} is only ${deadline_date_focus_difference} seconds away, waiting for deadline to pass..."
				sleep $((deadline_date_focus_difference + 1))
				log_super "Status: Focus deadline date of ${deadline_date_focus} has passed."
				deadline_date_status="FOCUS"
			else
				log_super "Status: Focus deadline date of ${deadline_date_focus} not passed."
			fi
		fi
	fi
	if [[ -n "${deadline_date_soft}" ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_soft_epoch is: ${deadline_date_soft_epoch}"
		if [[ $deadline_date_soft_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Soft deadline date of ${deadline_date_soft} has passed."
			deadline_date_status="SOFT"
		else
			local deadline_date_soft_difference
			deadline_date_soft_difference=$((deadline_date_soft_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_soft_difference is: ${deadline_date_soft_difference}"
			if [[ "${deadline_date_soft_difference}" -le 180 ]]; then
				log_super "Status: Soft deadline date of ${deadline_date_soft} is only ${deadline_date_soft_difference} seconds away, waiting for deadline to pass..."
				sleep $((deadline_date_soft_difference + 1))
				log_super "Status: Soft deadline date of ${deadline_date_soft} has passed."
				deadline_date_status="SOFT"
			else
				log_super "Status: Soft deadline date of ${deadline_date_soft} not passed."
			fi
		fi
	fi
	if [[ -n "${deadline_date_hard}" ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_hard_epoch is: ${deadline_date_hard_epoch}"
		if [[ $deadline_date_hard_epoch -lt $workflow_time_epoch ]]; then
			log_super "Status: Hard deadline date of ${deadline_date_hard} has passed."
			deadline_date_status="HARD"
		else
			local deadline_date_hard_difference
			deadline_date_hard_difference=$((deadline_date_hard_epoch - workflow_time_epoch))
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_hard_difference is: ${deadline_date_hard_difference}"
			if [[ "${deadline_date_hard_difference}" -le 180 ]]; then
				log_super "Status: Hard deadline date of ${deadline_date_soft} is only ${deadline_date_hard_difference} seconds away, waiting for deadline to pass..."
				sleep $((deadline_date_hard_difference + 1))
				log_super "Status: Hard deadline date of ${deadline_date_soft} has passed."
				deadline_date_status="HARD"
			else
				log_super "Status: Hard deadline date of ${deadline_date_hard} not passed."
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_status is: ${deadline_date_status}"
	[[ -n "${deadline_date_hard}" ]] && deadline_date_epoch="${deadline_date_hard_epoch}"
	[[ -n "${deadline_date_soft}" ]] && deadline_date_epoch="${deadline_date_soft_epoch}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_date_epoch is: ${deadline_date_epoch}"
	
	# Set ${deadline_epoch} to the soonest of either days or date deadlines.
	{ [[ -n "${deadline_days_epoch}" ]] && [[ -z "${deadline_date_epoch}" ]]; } && deadline_epoch="${deadline_days_epoch}"
	{ [[ -z "${deadline_days_epoch}" ]] && [[ -n "${deadline_date_epoch}" ]]; } && deadline_epoch="${deadline_date_epoch}"
	if [[ -n "${deadline_days_epoch}" ]] && [[ -n "${deadline_date_epoch}" ]]; then
		if [[ "${deadline_days_epoch}" -le "${deadline_date_epoch}" ]]; then
			deadline_epoch="${deadline_days_epoch}"
			unset deadline_date_epoch
		else
			deadline_epoch="${deadline_date_epoch}"
			unset deadline_days_epoch
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_epoch is: ${deadline_epoch}"
	
	# If needed adjust the ${deadline_epoch} for the ${schedule_workflow_active_option} and also write to log.
	if [[ -n "${schedule_workflow_active_option}" ]] && [[ -n "${deadline_epoch}" ]]; then
		if [[ "${deadline_date_status}" != "FALSE" ]] && [[ "${deadline_date_status}" != "FALSE" ]]; then
			log_super "Warning: The past due deadline is overriding the schedule workflow active option."
		elif [[ -n "${deadline_date_epoch}" ]] && [[ $(date -r "${deadline_epoch}" +%H:%M) != "00:00" ]]; then
			log_super "Warning: The manually set deadline date option that also includes a specific time is overriding the schedule workflow active option."
		else
			deadline_epoch_schedule_workflow_active_check="${deadline_epoch}"
			set_schedule_workflow_active_adjustments
			if [[ -n "${deadline_epoch_schedule_workflow_active_adjusted}" ]]; then
				deadline_epoch="${deadline_epoch_schedule_workflow_active_adjusted}"
			else
				log_super "Warning: The deadline is overriding the schedule workflow active option because no coordinating time frame could be resolved."
			fi
			unset deadline_epoch_schedule_workflow_active_check
			unset deadline_epoch_schedule_workflow_active_adjusted
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_epoch is: ${deadline_epoch}"
		fi
	fi
	
	# If there is a ${deadline_epoch} then set ${display_string_deadline}.
	if [[ -n "${deadline_epoch}" ]]; then
		local display_string_deadline_only_date
		display_string_deadline_only_date=$(date -r "${deadline_epoch}" "+${DISPLAY_STRING_FORMAT_DATE}")
		local display_string_deadline_only_time
		display_string_deadline_only_time=$(date -r "${deadline_epoch}" "+${DISPLAY_STRING_FORMAT_TIME}" | sed 's/^ *//g')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_deadline_only_date is: ${display_string_deadline_only_date}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_deadline_only_time is: ${display_string_deadline_only_time}"
		if [[ $(date -r "${deadline_epoch}" +%H:%M) == "00:00" ]]; then
			display_string_deadline="${display_string_deadline_only_date}"
		else
			display_string_deadline="${display_string_deadline_only_date}${DISPLAY_STRING_FORMAT_DATE_TIME_SEPARATOR}${display_string_deadline_only_time}"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_string_deadline is: ${display_string_deadline}"
	
	# If there is a ${deadline_epoch}, then make sure no user deferral timer or display timeout exceeds the deadline.
	if [[ -n "${deadline_epoch}" ]]; then
		local deferral_timer_deadline_minutes
		deferral_timer_deadline_minutes=$(((deadline_epoch - workflow_time_epoch) / 60))
		local deferral_timer_deadline_active
		deferral_timer_deadline_active="FALSE"
		[[ $deferral_timer_deadline_minutes -lt 2 ]] && deferral_timer_deadline_minutes=2
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_deadline_minutes is: ${deferral_timer_deadline_minutes}"
		if [[ -n "${deferral_timer_menu_minutes}" ]]; then
			local previous_ifs
			previous_ifs="${IFS}"
			IFS=','
			local deferral_timer_menu_minutes_array
			read -r -a deferral_timer_menu_minutes_array <<<"${deferral_timer_menu_minutes}"
			local deferral_timer_menu_reduced_array
			deferral_timer_menu_reduced_array=()
			local deferral_timer_menu_reduced
			deferral_timer_menu_reduced="FALSE"
			for deferral_timer_menu_item in "${deferral_timer_menu_minutes_array[@]}"; do
				if [[ $deferral_timer_deadline_minutes -le $deferral_timer_menu_item ]]; then
					if [[ "${deferral_timer_menu_reduced}" == "FALSE" ]]; then
						deferral_timer_menu_reduced_array+=("${deferral_timer_deadline_minutes}")
						deferral_timer_menu_reduced="TRUE"
						deferral_timer_deadline_active="TRUE"
					fi
				else
					deferral_timer_menu_reduced_array+=("${deferral_timer_menu_item}")
				fi
			done
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_menu_reduced is: ${deferral_timer_menu_reduced}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_menu_reduced_array is: ${deferral_timer_menu_reduced_array[*]}"
			if [[ "${deferral_timer_menu_reduced}" == "TRUE" ]]; then
				if [[ ${#deferral_timer_menu_reduced_array[@]} -gt 1 ]]; then
					deferral_timer_menu_minutes="${deferral_timer_menu_reduced_array[*]}"
					log_super "Warning: The deferral timer menu list has been reduced to ${deferral_timer_menu_minutes} minutes given the deadline of ${display_string_deadline}."
				else
					unset deferral_timer_menu_minutes
					log_super "Warning: Not showing the deferral timer menu given the deadline of ${display_string_deadline}."
				fi
			fi
			IFS="${previous_ifs}"
		fi
		if [[ -z "${deferral_timer_menu_minutes}" ]]; then
			if [[ $deferral_timer_deadline_minutes -lt $deferral_timer_minutes ]]; then
				log_super "Warning: Reducing user deferral timers to ${deferral_timer_deadline_minutes} minutes given the deadline of ${display_string_deadline}."
				deferral_timer_minutes="${deferral_timer_deadline_minutes}"
				[[ -n "${deferral_timer_focus_minutes}" ]] && deferral_timer_focus_minutes="${deferral_timer_deadline_minutes}"
				deferral_timer_deadline_active="TRUE"
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_deadline_active is: ${deferral_timer_deadline_active}"
		if [[ "${deferral_timer_deadline_active}" == "TRUE" ]]; then
			if [[ -n "${dialog_timeout_default_seconds}" ]] && [[ $dialog_timeout_default_seconds -gt 120 ]]; then
				dialog_timeout_default_seconds=120
				log_super "Warning: Reducing the --dialog-timeout-default option to ${dialog_timeout_default_seconds} seconds given the approaching deadline."
			fi
			if [[ -n "${dialog_timeout_user_choice_seconds}" ]] && [[ $dialog_timeout_user_choice_seconds -gt 120 ]]; then
				dialog_timeout_user_choice_seconds=120
				log_super "Warning: Reducing the --dialog-timeout-user-choice option to ${dialog_timeout_user_choice_seconds} seconds given the approaching deadline."
			fi
			if [[ -n "${dialog_timeout_soft_deadline_seconds}" ]] && [[ $dialog_timeout_soft_deadline_seconds -gt 120 ]]; then
				dialog_timeout_soft_deadline_seconds=120
				log_super "Warning: Reducing the --dialog-timeout-soft-deadline option to ${dialog_timeout_soft_deadline_seconds} seconds given the approaching deadline."
			fi
			if [[ -n "${dialog_timeout_user_auth_seconds}" ]] && [[ $dialog_timeout_user_auth_seconds -gt 120 ]]; then
				dialog_timeout_user_auth_seconds=120
				log_super "Warning: Reducing the --dialog-timeout-user-auth option to ${dialog_timeout_user_auth_seconds} seconds given the approaching deadline."
			fi
			if [[ -n "${dialog_timeout_insufficient_storage_seconds}" ]] && [[ $dialog_timeout_insufficient_storage_seconds -gt 120 ]]; then
				dialog_timeout_insufficient_storage_seconds=120
				log_super "Warning: Reducing the --dialog-timeout-insufficient-storage option to ${dialog_timeout_insufficient_storage_seconds} seconds given the approaching deadline."
			fi
			if [[ -n "${dialog_timeout_power_required_seconds}" ]] && [[ $dialog_timeout_power_required_seconds -gt 120 ]]; then
				dialog_timeout_power_required_seconds=120
				log_super "Warning: Reducing the --dialog-timeout-power-required option to ${dialog_timeout_power_required_seconds} seconds given the approaching deadline."
			fi
		fi
	fi
}

# Evaluate if a process has told the display to not sleep or the user has enabled Focus or Do Not Disturb, and set ${user_focus_active} accordingly.
check_user_focus() {
	user_focus_active="FALSE"
	if [[ -n "${deadline_count_focus}" ]] || [[ -n "${deadline_days_focus}" ]] || [[ -n "${deadline_date_focus}" ]]; then
		local focus_response
		focus_response=$(plutil -extract data.0.storeAssertionRecords.0.assertionDetails.assertionDetailsModeIdentifier raw -o - "/Users/${current_user_account_name}/Library/DoNotDisturb/DB/Assertions.json" | grep -ic 'com.apple.')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: focus_response is: ${focus_response}"
		if [[ "${focus_response}" -gt 0 ]]; then
			log_super "Status: Focus or Do Not Disturb enabled for current user: ${current_user_account_name}."
			user_focus_active="TRUE"
		fi
		local previous_ifs
		previous_ifs="${IFS}"
		IFS=$'\n'
		local display_assertions_array
		display_assertions_array=($(pmset -g assertions | awk '/NoDisplaySleepAssertion | PreventUserIdleDisplaySleep/ && match($0,/\(.+\)/) && ! /coreaudiod/ {gsub(/^\ +/,"",$0); print};'))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_assertions_array is:\n${display_assertions_array[*]}"
		if [[ -n "${display_assertions_array[*]}" ]]; then
			for display_assertion in "${display_assertions_array[@]}"; do
				log_super "Status: The following Display Sleep Assertion was found: $(echo "${display_assertion}" | awk -F ':' '{print $1;}')"
			done
			user_focus_active="TRUE"
		fi
		IFS="${previous_ifs}"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: user_focus_active is: ${user_focus_active}"
}

# Evaluate ${deadline_count_focus}, ${deadline_count_soft}, and ${deadline_count_hard}, then set ${user_focus_active}, ${deadline_count_status}, ${display_string_deadline_count}, and ${display_string_deadline_count_maximum} accordingly.
check_deadlines_count() {
	deadline_count_status="FALSE" # Deadline status modes: FALSE, SOFT, or HARD
	if [[ "${user_focus_active}" == "TRUE" ]]; then
		if [[ -n "${deadline_count_focus}" ]]; then
			local deadline_counter_focus_previous
			local deadline_counter_focus_current
			deadline_counter_focus_previous=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineCounterFocus 2>/dev/null)
			if [[ -z "${deadline_counter_focus_previous}" ]]; then
				deadline_counter_focus_current=0
				defaults write "${SUPER_LOCAL_PLIST}" DeadlineCounterFocus -int "${deadline_counter_focus_current}"
			else
				deadline_counter_focus_current=$((deadline_counter_focus_previous + 1))
				defaults write "${SUPER_LOCAL_PLIST}" DeadlineCounterFocus -int "${deadline_counter_focus_current}"
			fi
			if [[ "${deadline_counter_focus_current}" -ge "${deadline_count_focus}" ]]; then
				log_super "Status: Focus maximum deferral count of ${deadline_count_focus} has passed."
				deadline_count_status="FOCUS"
				user_focus_active="FALSE"
			else
				display_string_deadline_count_focus=$((deadline_count_focus - deadline_counter_focus_current))
				log_super "Status: Focus maximum deferral count of ${deadline_count_focus} not passed with ${display_string_deadline_count_focus} remaining."
			fi
		else
			log_super "Status: Focus or Do Not Disturb active, and no maximum focus deferral, so not incrementing deferral counters."
		fi
	fi
	if [[ "${user_focus_active}" == "FALSE" ]]; then
		if [[ -n "${deadline_count_soft}" ]]; then
			local deadline_counter_soft_previous
			local deadline_counter_soft_current
			deadline_counter_soft_previous=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineCounterSoft 2>/dev/null)
			if [[ -z "${deadline_counter_soft_previous}" ]]; then
				deadline_counter_soft_current=0
				defaults write "${SUPER_LOCAL_PLIST}" DeadlineCounterSoft -int "${deadline_counter_soft_current}"
			else
				deadline_counter_soft_current=$((deadline_counter_soft_previous + 1))
				defaults write "${SUPER_LOCAL_PLIST}" DeadlineCounterSoft -int "${deadline_counter_soft_current}"
			fi
			if [[ "${deadline_counter_soft_current}" -ge "${deadline_count_soft}" ]]; then
				log_super "Status: Soft maximum deferral count of ${deadline_count_soft} has passed."
				deadline_count_status="SOFT"
			else
				display_string_deadline_count_soft=$((deadline_count_soft - deadline_counter_soft_current))
				log_super "Status: Soft maximum deferral count of ${deadline_count_soft} not passed with ${display_string_deadline_count_soft} remaining."
			fi
			display_string_deadline_count="${display_string_deadline_count_soft}"
			display_string_deadline_count_maximum="${deadline_count_soft}"
		fi
		if [[ -n "${deadline_count_hard}" ]]; then
			local deadline_counter_hard_previous
			local deadline_counter_hard_current
			deadline_counter_hard_previous=$(defaults read "${SUPER_LOCAL_PLIST}" DeadlineCounterHard 2>/dev/null)
			if [[ -z "${deadline_counter_hard_previous}" ]]; then
				deadline_counter_hard_current=0
				defaults write "${SUPER_LOCAL_PLIST}" DeadlineCounterHard -int "${deadline_counter_hard_current}"
			else
				deadline_counter_hard_current=$((deadline_counter_hard_previous + 1))
				defaults write "${SUPER_LOCAL_PLIST}" DeadlineCounterHard -int "${deadline_counter_hard_current}"
			fi
			if [[ "${deadline_counter_hard_current}" -ge "${deadline_count_hard}" ]]; then
				log_super "Status: Hard maximum deferral count of ${deadline_count_hard} has passed."
				deadline_count_status="HARD"
			else
				display_string_deadline_count_hard=$((deadline_count_hard - deadline_counter_hard_current))
				log_super "Status: Hard maximum deferral count of ${deadline_count_hard} not passed with ${display_string_deadline_count_hard} remaining."
			fi
			display_string_deadline_count="${display_string_deadline_count_hard}"
			display_string_deadline_count_maximum="${deadline_count_hard}"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deadline_count_status is: ${deadline_count_status}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: user_focus_active is: ${user_focus_active}"
}

# MARK: *** Software Update Status ***
################################################################################

# This function checks the validity of software updates/upgrade caches.
check_software_update_status_cached() {
	check_software_status_required="FALSE"
	macos_beta_program="FALSE"
	mdmclient_available="FALSE"
	mdmclient_list="FALSE"
	macos_installers_list="FALSE"
	msu_list="FALSE"
	
	# Check how long ago the last successful macOS software check update was.
	local msu_last_sccessful_date
	msu_last_sccessful_date=$(defaults read "${MSU_LOCAL_PLIST}" LastSuccessfulDate 2>/dev/null)
	local msu_last_sccessful_epoch
	[[ -n "${msu_last_sccessful_date}" ]] && msu_last_sccessful_epoch=$(date -j -u -f "%Y-%m-%d %H:%M:%S %z" "${msu_last_sccessful_date}" +%s)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_last_sccessful_date is: ${msu_last_sccessful_date}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_last_sccessful_epoch is: ${msu_last_sccessful_epoch}"
	if [[ "${msu_last_sccessful_epoch}" -lt $(($(date +%s) - 21600)) ]]; then
		log_super "Status: Last macOS software update check was more than 6 hours ago, full software status check required."
		check_software_status_required="TRUE"
		return 0
	fi
	
	# Check macOS deferral restrictions cache.
	local restrictions_deferral_checksum_cache
	restrictions_deferral_checksum_cache=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralRestrictionsChecksum 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: restrictions_deferral_checksum_cache is: ${restrictions_deferral_checksum_cache}"
	if { [[ "${restrictions_deferral_checksum_cache}" == "0" ]] && [[ ! -f "${APPLICATION_ACCESS_MANAGED_PLIST}.plist" ]]; } || [[ "${restrictions_deferral_checksum_cache}" == "$(md5 -q "${APPLICATION_ACCESS_MANAGED_PLIST}.plist" 2>/dev/null)" ]]; then
		local restrictions_deferral_cache
		restrictions_deferral_cache=$(defaults read "${SUPER_LOCAL_PLIST}" DeferralRestrictionsCache 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: restrictions_deferral_cache is: ${restrictions_deferral_cache}"
		if [[ -n "${restrictions_deferral_cache}" ]]; then
			check_restrictions_deferral
		else
			log_super "Status: No deferral restrictions cache, full software status check required."
			check_software_status_required="TRUE"
			return 0
		fi
	else
		log_super "Status: Deferral restrictions have changed since last super workflow run, full software status check required."
		check_software_status_required="TRUE"
		return 0
	fi
	
	# Check macOS beta program status cache.
	local macos_beta_program_cache
	macos_beta_program_cache=$(defaults read "${SUPER_LOCAL_PLIST}" MacOSBetaProgramCache 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_beta_program_cache is: ${macos_beta_program_cache}"
	if [[ -n "${macos_beta_program_cache}" ]]; then
		if [[ "${macos_beta_program_cache}" == "1" ]]; then
			log_super "Status: This system is currently configured to receive macOS beta updates/upgrades."
			macos_beta_program="TRUE"
		fi
	else
		log_super "Status: No macOS beta program status cache, full software status check required."
		check_software_status_required="TRUE"
		return 0
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_beta_program is: ${macos_beta_program}"
	
	# Check the mdmclient list cache.
	local mdmclient_list_checksum_cache
	mdmclient_list_checksum_cache=$(defaults read "${SUPER_LOCAL_PLIST}" MDMClientListChecksum 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_list_checksum_cache is: ${mdmclient_list_checksum_cache}"
	if [[ "${mdmclient_list_checksum_cache}" == "$(md5 -q "${MDMCLIENT_LIST_LOG}" 2>/dev/null)" ]]; then
		local mdmclient_available_cache
		mdmclient_available_cache=$(defaults read "${SUPER_LOCAL_PLIST}" MDMClientAvailableCache 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_available_cache is: ${mdmclient_available_cache}"
		if [[ -n "${mdmclient_available_cache}" ]]; then
			if [[ "${mdmclient_available_cache}" == "1" ]]; then
				mdmclient_available="TRUE"
				mdmclient_list=$(sed -e '1,/^Available updates/d' -e '/^)$/d' < "${MDMCLIENT_LIST_LOG}")
			fi
		else
			log_super "Status: No mdmclient available status cache, full software status check required."
			check_software_status_required="TRUE"
			return 0
		fi
	else
		log_super "Status: The ${MDMCLIENT_LIST_LOG} has changed since last super workflow run, full software status check required."
		check_software_status_required="TRUE"
		return 0
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_list is:\n${mdmclient_list}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_available is: ${mdmclient_available}"
	
	# Check the macOS installers list cache.
	local macos_installers_list_checksum_cache
	macos_installers_list_checksum_cache=$(defaults read "${SUPER_LOCAL_PLIST}" MacOSInstallersListChecksum 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installers_list_checksum_cache is: ${macos_installers_list_checksum_cache}"
	if [[ -n "${macos_installers_list_checksum_cache}" ]]; then
		if [[ "${macos_installers_list_checksum_cache}" == "$(md5 -q "${MACOS_INSTALLERS_LIST_LOG}" 2>/dev/null)" ]]; then
			macos_installers_list=$(sed -e '1,/^Identifier/d' -e '/^$/d' < "${MACOS_INSTALLERS_LIST_LOG}")
		else
			log_super "Status: The ${MACOS_INSTALLERS_LIST_LOG} has changed since last super workflow run, full software status check required."
			check_software_status_required="TRUE"
			return 0
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installers_list is:\n${macos_installers_list}"
	
	# Check the macOS software update list cache.
	local msu_list_checksum_cache
	msu_list_checksum_cache=$(defaults read "${SUPER_LOCAL_PLIST}" MSUListChecksum 2>/dev/null)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_list_checksum_cache is: ${msu_list_checksum_cache}"
	if [[ -n "${msu_list_checksum_cache}" ]]; then
		if [[ "${msu_list_checksum_cache}" == "$(md5 -q "${MSU_LIST_LOG}" 2>/dev/null)" ]]; then
			msu_list=$(<"${MSU_LIST_LOG}")
		else
			log_super "Status: The ${MSU_LIST_LOG} has changed since last super workflow run, full software status check required."
			check_software_status_required="TRUE"
			return 0
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_list is:\n${msu_list}"
}

# This function clears any cached update/upgrade information except for the SOFA cache (because SOFA has it's own cache mechanism).
reset_software_update_status() {
	# Non-local get_*_list() parameters.
	restrictions_deferral_macOS_minor_updates="FALSE"
	restrictions_deferral_macOS_major_upgrades="FALSE"
	restrictions_deferral_non_system_updates="FALSE"
	macos_beta_program="FALSE"
	mdmclient_available="FALSE"
	mdmclient_list="FALSE"
	macos_installers_list="FALSE"
	msu_list="FALSE"
	
	# Non-local workflow_check_software_status() parameters.
	unset macos_installer_title
	unset macos_installer_version
	unset macos_installer_build
	unset macos_installer_size
	unset macos_msu_label
	unset macos_msu_title
	unset macos_msu_version
	unset macos_msu_build
	unset macos_msu_size
	unset non_system_msu_labels_array
	unset non_system_msu_titles_array
	
	# Externally stored items.
	defaults delete "${SUPER_LOCAL_PLIST}" DeferralRestrictionsChecksum 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" DeferralRestrictionsCache 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MacOSBetaProgramCache 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MDMClientListChecksum 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MDMClientAvailableCache 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded 2>/dev/null
	rm -f "${MDMCLIENT_LIST_LOG}" 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MacOSInstallersListChecksum 2>/dev/null
	rm -f "${MACOS_INSTALLERS_LIST_LOG}" 2>/dev/null
	defaults delete "${SUPER_LOCAL_PLIST}" MSUListChecksum 2>/dev/null
	rm -f "${MSU_LIST_LOG}" 2>/dev/null
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file after reset_software_update_status: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
}

# Check for restrictions configuration profile deferrals and set ${restrictions_deferral_macOS_minor_updates}, ${restrictions_deferral_macOS_major_upgrades}, and ${restrictions_deferral_non_system_updates} accordingly.
check_restrictions_deferral() {
	restrictions_deferral_macOS_major_upgrades="FALSE"
	restrictions_deferral_macOS_minor_updates="FALSE"
	restrictions_deferral_non_system_updates="FALSE"
	if [[ -f "${APPLICATION_ACCESS_MANAGED_PLIST}.plist" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" DeferralRestrictionsChecksum -string "$(md5 -q "${APPLICATION_ACCESS_MANAGED_PLIST}.plist" 2>/dev/null)"
		local restrictions_deferral_response
		restrictions_deferral_response=$(defaults read "${APPLICATION_ACCESS_MANAGED_PLIST}" 2>&1 | grep -E 'enforcedSoftware|forceDelayed' | tr -d ';')
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: restrictions_deferral_response is:\n${restrictions_deferral_response}"
	if [[ -n "${restrictions_deferral_response}" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" DeferralRestrictionsCache -bool true
		if [[ $(echo "${restrictions_deferral_response}" | awk '/forceDelayedMajorSoftwareUpdates/ {print $3}') -gt 0 ]]; then
			restrictions_deferral_macOS_major_upgrades=30
			[[ $(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateMajorOSDeferredInstallDelay/ {print $3}') -gt 0 ]] && restrictions_deferral_macOS_major_upgrades=$(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateMajorOSDeferredInstallDelay/ {print $3}')
			log_super "Status: Restrictions configuration profile is deferring macOS major upgrades for ${restrictions_deferral_macOS_major_upgrades} days."
		fi
		if [[ $(echo "${restrictions_deferral_response}" | awk '/forceDelayedSoftwareUpdates/ {print $3}') -gt 0 ]]; then
			restrictions_deferral_macOS_minor_updates=30
			[[ $(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateDelay/ {print $3}') -gt 0 ]] && restrictions_deferral_macOS_minor_updates=$(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateDelay/ {print $3}')
			[[ $(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateMinorOSDeferredInstallDelay/ {print $3}') -gt 0 ]] && restrictions_deferral_macOS_minor_updates=$(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateMinorOSDeferredInstallDelay/ {print $3}')
			log_super "Status: Restrictions configuration profile is deferring macOS minor updates for ${restrictions_deferral_macOS_minor_updates} days."
		fi
		if [[ $(echo "${restrictions_deferral_response}" | awk '/forceDelayedAppSoftwareUpdates/ {print $3}') -gt 0 ]]; then
			restrictions_deferral_non_system_updates=30
			[[ $(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateDelay/ {print $3}') -gt 0 ]] && restrictions_deferral_non_system_updates=$(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateDelay/ {print $3}')
			[[ $(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateNonOSDeferredInstallDelay/ {print $3}') -gt 0 ]] && restrictions_deferral_non_system_updates=$(echo "${restrictions_deferral_response}" | awk '/enforcedSoftwareUpdateNonOSDeferredInstallDelay/ {print $3}')
			log_super "Status: Restrictions configuration profile is deferring non-system updates for ${restrictions_deferral_non_system_updates} days."
		fi
	else
		defaults write "${SUPER_LOCAL_PLIST}" DeferralRestrictionsChecksum -int 0
		defaults write "${SUPER_LOCAL_PLIST}" DeferralRestrictionsCache -bool false
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: restrictions_deferral_macOS_major_upgrades is: ${restrictions_deferral_macOS_major_upgrades}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: restrictions_deferral_macOS_minor_updates is: ${restrictions_deferral_macOS_minor_updates}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: restrictions_deferral_non_system_updates is: ${restrictions_deferral_non_system_updates}"
}

# Check for macOS beta program enrollment and set ${macos_beta_program} accordingly.
check_macos_beta_program() {
	macos_beta_program="FALSE"
	if [[ "${macos_version_number}" -ge 1304 ]]; then
		local mdmclient_response
		mdmclient_response=$(/usr/libexec/mdmclient QueryDeviceInformation 2>/dev/null | grep 'IsDefaultCatalog')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_response is:\n${mdmclient_response}"
		if [[ $(echo "${mdmclient_response}" | grep -c '1') -eq 0 ]]; then
			log_super "Status: This system is currently configured to receive macOS beta updates/upgrades."
			macos_beta_program="TRUE"
		fi
	else # macOS versions prior to 13.4.
		local seedutil_response
		seedutil_response=$(/System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil current)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: seedutil_response is:\n${seedutil_response}"
		if [[ $(echo "${seedutil_response}" | grep -c 'Is Enrolled: YES') -gt 0 ]]; then
			log_super "Status: This system is currently configured to receive macOS beta updates/upgrades."
			macos_beta_program="TRUE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_beta_program is: ${macos_beta_program}"
	if [[ "${macos_beta_program}" == "FALSE" ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" MacOSBetaProgramCache -bool false
	else # "${macos_beta_program}" == "TRUE"
		defaults write "${SUPER_LOCAL_PLIST}" MacOSBetaProgramCache -bool true
	fi
}

# This restarts various softwareupdate daemon processes for systems older than macOS 14.4.
kick_softwareupdated() {
	if [[ "${macos_version_number}" -ge 1404 ]]; then
		log_super "Warning: Apple no longer allows for restarting of software update services on macOS 14.4 or newer. The system may need to be restarted for software update to function properly."
		defaults delete /Library/Preferences/com.apple.Softwareupdate.plist >/dev/null 2>&1
		return 0
	fi
	
	log_super "Status: Restarting various softwareupdate daemon processes..."
	defaults delete /Library/Preferences/com.apple.Softwareupdate.plist >/dev/null 2>&1
	
	if ! launchctl kickstart -k "system/com.apple.mobile.softwareupdated"; then
		log_super "Warning: Restarting mobile softwareupdate daemon didn't respond, trying again in 10 seconds..."
		sleep 10
		launchctl kickstart -k "system/com.apple.mobile.softwareupdated"
	fi
	
	if ! launchctl kickstart -k "system/com.apple.softwareupdated"; then
		log_super "Warning: Restarting system softwareupdate daemon didn't respond, trying again in 10 seconds..."
		sleep 10
		launchctl kickstart -k "system/com.apple.softwareupdated"
	fi
	
	# If a user is logged in then also restart the Software Update Notification Manager daemon.
	if [[ "${current_user_account_name}" != "FALSE" ]]; then
		if ! launchctl kickstart -k "gui/${current_user_id}/com.apple.SoftwareUpdateNotificationManager"; then
			log_super "Warning: Restarting Software Update Notification Manager didn't respond, trying again in 10 seconds..."
			sleep 10
			launchctl kickstart -k "gui/${current_user_id}/com.apple.SoftwareUpdateNotificationManager"
		fi
	fi
}

# Check for updates via the the mdmclient command to create the ${MDMCLIENT_LIST_LOG} and set the ${mdmclient_list} and ${mdmclient_available} parameters. This is in a separate function to facilitate list caching and multiple run workflows.
# This also sets ${get_mdmclient_list_error} and ${get_mdmclient_list_timeout}.
get_mdmclient_list() {
	mdmclient_available="FALSE"
	mdmclient_list="FALSE"
	log_super "mdmclient: Waiting for available updates listing..."
	
	# Background the mdmclient list process and send to ${MDMCLIENT_LIST_LOG}.
	/usr/libexec/mdmclient AvailableOSUpdates > "${MDMCLIENT_LIST_LOG}" 2>&1 &
	local get_mdmclient_list_pid
	get_mdmclient_list_pid="$!"
	
	# Watch ${MDMCLIENT_LIST_LOG} while waiting for the mdmclient list process to complete. Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS}.
	get_mdmclient_list_error="TRUE"
	get_mdmclient_list_timeout="TRUE"
	local get_mdmclient_list_timeout_seconds
	get_mdmclient_list_timeout_seconds="${TIMEOUT_START_SECONDS}"
	while read -t "${get_mdmclient_list_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c 'Available updates') -gt 0 ]]; then
			get_mdmclient_list_error="FALSE"
			get_mdmclient_list_timeout="FALSE"
			wait "${get_mdmclient_list_pid}"
			break
		fi
	done < <(tail -n1 -F "${MDMCLIENT_LIST_LOG}")
	
	# If the mdmclient list completed, then collect information.
	if [[ "${get_mdmclient_list_error}" == "FALSE" ]] && [[ "${get_mdmclient_list_timeout}" == "FALSE" ]]; then
		mdmclient_list=$(sed -e '1,/^Available updates/d' -e '/^)$/d' < "${MDMCLIENT_LIST_LOG}")
		defaults write "${SUPER_LOCAL_PLIST}" MDMClientListChecksum -string "$(md5 -q "${MDMCLIENT_LIST_LOG}" 2>/dev/null)"
		if [[ $(echo "${mdmclient_list}" | grep -c 'HumanReadableName') -gt 0 ]]; then
			mdmclient_available="TRUE"
			defaults write "${SUPER_LOCAL_PLIST}" MDMClientAvailableCache -bool true
		else
			defaults write "${SUPER_LOCAL_PLIST}" MDMClientAvailableCache -bool false
		fi
	else # mdmclient list failures.
		[[ "${get_mdmclient_list_error}" == "TRUE" ]] && log_super "mdmclient Error: Apple update listing failed, check ${MDMCLIENT_LIST_LOG} for more detail."
		[[ "${get_mdmclient_list_timeout}" == "TRUE" ]] && log_super "mdmclient Error: Apple update listing failed to complete, as indicated by no progress after waiting for ${get_mdmclient_list_timeout_seconds} seconds."
		kill -9 "${get_mdmclient_list_pid}" >/dev/null 2>&1
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_mdmclient_list_error is: ${get_mdmclient_list_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_mdmclient_list_timeout is: ${get_mdmclient_list_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_available is: ${mdmclient_available}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_list is:\n${mdmclient_list}"
}

# Check for full macOS installers via the mist-cli command to create the ${MACOS_INSTALLERS_LIST_LOG} and set the ${macos_installers_list} parameter. This is in a separate function to facilitate list caching and multiple run workflows.
# This also sets ${get_macos_installers_list_error} and ${get_macos_installers_list_timeout}.
get_macos_installers_list() {
	macos_installers_list="FALSE"
	
	# Background the mist-cli list process and send to ${MACOS_INSTALLERS_LIST_LOG}.
	local get_macos_installers_list_pid
	if [[ "${macos_beta_program}" == "FALSE" ]]; then
		"${MIST_CLI_BINARY}" list installer --output-type csv --no-ansi --compatible >"${MACOS_INSTALLERS_LIST_LOG}" 2>&1 &
		get_macos_installers_list_pid="$!"
	else # macOS beta workflow.
		"${MIST_CLI_BINARY}" list installer --output-type csv --no-ansi --compatible --include-betas >"${MACOS_INSTALLERS_LIST_LOG}" 2>&1 &
		get_macos_installers_list_pid="$!"
	fi
	
	# Watch ${MACOS_INSTALLERS_LIST_LOG} while waiting for the mist-cli list process to complete. Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS}.
	get_macos_installers_list_error="TRUE"
	get_macos_installers_list_timeout="TRUE"
	local get_macos_installers_list_timeout_seconds
	get_macos_installers_list_timeout_seconds="${TIMEOUT_START_SECONDS}"
	while read -t "${get_macos_installers_list_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c 'SEARCH') -gt 0 ]]; then
			log_super "mist-cli: Waiting for macOS installers listing..."
		elif [[ $(echo "${log_line}" | grep -c 'Found 0') -gt 0 ]]; then
			get_macos_installers_list_timeout="FALSE"
			wait "${get_macos_installers_list_pid}"
			break
		elif [[ $(echo "${log_line}" | grep -c 'Found') -gt 0 ]]; then
			get_macos_installers_list_error="FALSE"
			get_macos_installers_list_timeout="FALSE"
			wait "${get_macos_installers_list_pid}"
			break
		fi
	done < <(tail -n1 -F "${MACOS_INSTALLERS_LIST_LOG}")
	
	# If the mist-cli list completed, then collect information.
	if [[ "${get_macos_installers_list_error}" == "FALSE" ]] && [[ "${get_macos_installers_list_timeout}" == "FALSE" ]]; then
		macos_installers_list=$(sed -e '1,/^Identifier/d' -e '/^$/d' < "${MACOS_INSTALLERS_LIST_LOG}")
		defaults write "${SUPER_LOCAL_PLIST}" MacOSInstallersListChecksum -string "$(md5 -q "${MACOS_INSTALLERS_LIST_LOG}" 2>/dev/null)"
	else
		[[ "${get_macos_installers_list_error}" == "TRUE" ]] && log_super "mist-cli Error: macOS installers listing failed, check ${MACOS_INSTALLERS_LIST_LOG} for more detail."
		[[ "${get_macos_installers_list_timeout}" == "TRUE" ]] && log_super "mist-cli Error: macOS installers listing failed to complete, as indicated by no progress after waiting for ${get_macos_installers_list_timeout_seconds} seconds."
		kill -9 "${get_macos_installers_list_pid}" >/dev/null 2>&1
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_macos_installers_list_error is: ${get_macos_installers_list_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_macos_installers_list_timeout is: ${get_macos_installers_list_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installers_list is:\n${macos_installers_list}"
}

# Check for updates via the softwareupdate command to create the ${MSU_LIST_LOG} and set the ${msu_list} parameter. This is in a separate function to facilitate list caching and multiple run workflows.
# This also sets ${get_msu_list_error} and ${get_msu_list_timeout}.
get_msu_list() {
	msu_list="FALSE"
	log_super "softwareupdate: Waiting for available updates listing..."
	
	# Background the softwareupdate checking process and send to ${MSU_LIST_LOG}.
	sudo -u root softwareupdate --list > "${MSU_LIST_LOG}" 2>&1 &
	local get_msu_list_pid
	get_msu_list_pid="$!"
	
	# Watch ${MSU_LIST_LOG} while waiting for the softwareupdate list process to complete. Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS}.
	get_msu_list_error="TRUE"
	get_msu_list_timeout="TRUE"
	local get_msu_list_timeout_seconds
	get_msu_list_timeout_seconds="${TIMEOUT_START_SECONDS}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_msu_list_timeout is: ${get_msu_list_timeout}"
	while read -t "${get_msu_list_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c "Can’t connect") -gt 0 ]] || [[ $(echo "${log_line}" | grep -c "Couldn't communicate") -gt 0 ]]; then
			break
		elif [[ $(echo "${log_line}" | grep -c 'Software Update found') -gt 0 ]]; then
			get_msu_list_error="FALSE"
			get_msu_list_timeout="FALSE"
			wait "${get_msu_list_pid}"
			break
		elif [[ $(echo "${log_line}" | grep -c 'No new software available.') -gt 0 ]]; then
			get_msu_list_error="FALSE"
			get_msu_list_timeout="FALSE"
			wait "${get_msu_list_pid}"
			break
		fi
	done < <(tail -n1 -F "${MSU_LIST_LOG}")
	
	# If the softwareupdate list completed, then collect information.
	if [[ "${get_msu_list_error}" == "FALSE" ]] && [[ "${get_msu_list_timeout}" == "FALSE" ]]; then
		msu_list=$(<"${MSU_LIST_LOG}")
		defaults write "${SUPER_LOCAL_PLIST}" MSUListChecksum -string "$(md5 -q "${MSU_LIST_LOG}" 2>/dev/null)"
	else # softwareupdate list failures.
		[[ "${get_msu_list_error}" == "TRUE" ]] && log_super "softwareupdate Error: macOS software update listing failed, check ${MSU_LIST_LOG} for more detail."
		[[ "${get_msu_list_timeout}" == "TRUE" ]] && log_super "softwareupdate Error: macOS software update listing failed to complete, as indicated by no progress after waiting for ${get_msu_list_timeout_seconds} seconds."
		kill -9 "${get_msu_list_pid}" >/dev/null 2>&1
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_msu_list_error is: ${get_msu_list_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: get_msu_list_timeout is: ${get_msu_list_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_list is:\n${msu_list}"
}

# This is the main workflow for checking all available macOS software including macOS major upgrades, macOS minor updates, and non-system software.
# This function sets ${macos_installer_target}, ${macos_msu_major_upgrade_target}, ${macos_msu_minor_update_target}, and ${non_system_msu_targets}.
# If there is a ${macos_installer_target} then this also sets ${macos_installer_title}, ${macos_installer_version}, ${macos_installer_build}, and ${macos_installer_size}.
# If there is a ${macos_msu_major_upgrade_target} or a ${macos_msu_minor_update_target} then this also sets ${macos_msu_label}, ${macos_msu_title}, ${macos_msu_version}, ${macos_msu_build}, and ${macos_msu_size}.
# If there is ${non_system_msu_targets} then this also sets ${non_system_msu_labels_array[]} and ${non_system_msu_titles_array[]}.
workflow_check_software_status() {
	log_status "Running: Check for software update status workflow."
	local mdmclient_macos_installer_target
	mdmclient_macos_installer_target="FALSE"
	local mdmclient_macos_msu_major_upgrade_target
	mdmclient_macos_msu_major_upgrade_target="FALSE"
	local mdmclient_macos_msu_minor_update_target
	mdmclient_macos_msu_minor_update_target="FALSE"
	macos_installer_target="FALSE"
	macos_msu_major_upgrade_target="FALSE"
	macos_major_upgrade_latest="FALSE"
	macos_msu_minor_update_target="FALSE"
	macos_minor_update_latest="FALSE"
	non_system_msu_targets="FALSE"
	local workflow_check_software_status_error
	workflow_check_software_status_error="FALSE"
	
	# First check caches to see if a full check can be avoided.
	[[ "${check_software_status_required}" != "TRUE" ]] && check_software_update_status_cached
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: check_software_status_required is: ${check_software_status_required}"
	
	# When a full software status check is required start with reseting caches and then check for beta program and mdmclient listing.
	if [[ "${check_software_status_required}" == "TRUE" ]]; then
		reset_software_update_status
		check_restrictions_deferral
		check_macos_beta_program
	fi
	
	# If (no errors) a full software status check is required then start with mdmclient listing.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${check_software_status_required}" == "TRUE" ]]; then
		get_mdmclient_list
	
		# Error handling if mdmclient is misbehaving.
		if [[ "${get_mdmclient_list_error}" == "TRUE" ]] || [[ "${get_mdmclient_list_timeout}" == "TRUE" ]]; then
			log_super "Warning: Re-starting mdmclient available updates listing..."
			kick_softwareupdated
			sleep 10
			get_mdmclient_list
		elif [[ "${macos_version_number}" -lt 1303 ]] && [[ "${mdmclient_available}" == "FALSE" ]]; then
			log_super "Status: macOS 11.x - macOS 13.2, double-checking mdmclient available updates listing..."
			sleep 10
			get_mdmclient_list
		fi
		if [[ "${get_mdmclient_list_error}" == "TRUE" ]] || [[ "${get_mdmclient_list_timeout}" == "TRUE" ]]; then
			log_super "Error: Checking for mdmclient available updates listing did not complete after multiple attempts."
			workflow_check_software_status_error="TRUE"
		fi
	fi
	
	# If (no errors) there are no macOS software updates available, then exit this function.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${mdmclient_available}" == "FALSE" ]]; then
		log_super "Status: No available macOS software updates."
		return 0
	fi
	
	# If (no errors) then parse ${mdmclient_list} for all update items.
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=$'\n'
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]]; then
		# First clean up the structured data section of the ${mdmclient_list}.
		local mdmclient_sanitized_list
		mdmclient_sanitized_list=$(echo "${mdmclient_list}" | grep -e '^\s*Build ' -e '^\s*DeferredUntil ' -e '^\s*HumanReadableName ' -e '^\s*Version ' -e '},' | tr -d '\n' | sed -e 's/},/\n/g' -e 's/"//g' -e 's/  //g' -e 's/ = /:/g' -e 's/ +0000//g' -e 's/;/,/g' -e 's/HumanReadableName:/Title:/g')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_sanitized_list is:\n${mdmclient_sanitized_list}"
		
		# Create arrays for available macOS and non-system updates.
		local mdmclient_macos_installers_array
		mdmclient_macos_installers_array=($(echo "${mdmclient_sanitized_list}" | grep -E 'macOS' | grep -Ev 'Build|Deferred|Installer' | awk -F ',' '{print $1 "," $2}' | uniq | sort -t ':' -k3 -V -r))
		local mdmclient_macos_msu_array
		mdmclient_macos_msu_array=($(echo "${mdmclient_sanitized_list}" | grep -E 'Build.*macOS' | grep -Ev 'Deferred' | awk -F ',' '{print $2 "," $1 "," $3}' | uniq | sort -t ':' -k4 -V -r))
		local mdmclient_non_system_array
		mdmclient_non_system_array=($(echo "${mdmclient_sanitized_list}" | grep -Ev 'macOS|XProtect|MRT|Gatekeeper|DeferredUntil' | awk -F ',' '{print $1 "," $2}' | uniq))
		
		# Create arrays for macOS and non-system updates reporting as deferred.
		local mdmclient_macos_installers_deferred_array
		mdmclient_macos_installers_deferred_array=($(echo "${mdmclient_sanitized_list}" | grep -E 'Deferred.*macOS' | grep -Ev 'Build' | awk -F ',' '{print $1 "," $2 "," $3}' | uniq | sort -t ':' -k6 -V -r))
		local mdmclient_macos_msu_deferred_array
		mdmclient_macos_msu_deferred_array=($(echo "${mdmclient_sanitized_list}" | grep -E 'Build.*Deferred.*macOS' | awk -F ',' '{print $2 "," $3 "," $1 "," $4}'| uniq | sort -t ':' -k7 -V -r))
		local mdmclient_non_system_deferred_array
		mdmclient_non_system_deferred_array=($(echo "${mdmclient_sanitized_list}" | grep -Ev 'macOS|XProtect|MRT|Gatekeeper' | grep -E 'Deferred' | awk -F ',' '{print $1 "," $2 "," $3}' | uniq))
		
		# Create an array for security updates that can not be installed programmatically.
		local mdmclient_security_array
		mdmclient_security_array=($(echo "${mdmclient_sanitized_list}" | grep -E 'XProtect|MRT|Gatekeeper' | awk -F ',' '{print $1 "," $2}' | uniq))
		
		# Evaluate the numer of available updates and make sure there is at least one update available.
		if [[ ${#mdmclient_macos_installers_array[@]} -eq 0 ]] && [[ ${#mdmclient_macos_msu_array[@]} -eq 0 ]] && [[ ${#mdmclient_non_system_array[@]} -eq 0 ]] && [[ ${#mdmclient_macos_installers_deferred_array[@]} -eq 0 ]] && [[ ${#mdmclient_macos_msu_deferred_array[@]} -eq 0 ]] && [[ ${#mdmclient_non_system_deferred_array[@]} -eq 0 ]] && [[ ${#mdmclient_security_array[@]} -eq 0 ]]; then
			log_super "Error: Parsing mdmclient available updates listing did not find any available or deferred updates."
			workflow_check_software_status_error="TRUE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_installers_array is:\n${mdmclient_macos_installers_array[*]}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_array is:\n${mdmclient_macos_msu_array[*]}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_non_system_array is:\n${mdmclient_non_system_array[*]}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_installers_deferred_array is:\n${mdmclient_macos_installers_deferred_array[*]}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_deferred_array is:\n${mdmclient_macos_msu_deferred_array[*]}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_non_system_deferred_array is:\n${mdmclient_non_system_deferred_array[*]}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_security_array is:\n${mdmclient_security_array[*]}"
	
	# If (no errors) split ${mdmclient_macos_msu_array[]} and into separate major upgrade and minor update arrays.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ ${#mdmclient_macos_msu_array[@]} -gt 0 ]]; then
		local mdmclient_macos_msu_major_upgrade_array
		mdmclient_macos_msu_major_upgrade_array=()
		local mdmclient_macos_msu_minor_update_array
		mdmclient_macos_msu_minor_update_array=()
		for mdmclient_macos_msu_item in "${mdmclient_macos_msu_array[@]}"; do
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_item is:\n${mdmclient_macos_msu_item}"
			[[ $(echo "${mdmclient_macos_msu_item}" | awk -F ',' '{print $3}' | sed -e 's/.*://g' -e 's/\..*//g') -gt "${macos_version_major}" ]] && mdmclient_macos_msu_major_upgrade_array+=("${mdmclient_macos_msu_item}")
			[[ $(echo "${mdmclient_macos_msu_item}" | awk -F ',' '{print $3}' | sed -e 's/.*://g' -e 's/\..*//g') -eq "${macos_version_major}" ]] && mdmclient_macos_msu_minor_update_array+=("${mdmclient_macos_msu_item}")
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_major_upgrade_array is:\n${mdmclient_macos_msu_major_upgrade_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_minor_update_array is:\n${mdmclient_macos_msu_minor_update_array[*]}"
	fi
	
	# If (no errors) split ${mdmclient_macos_msu_deferred_array[]} and into separate major upgrade and minor update arrays.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ ${#mdmclient_macos_msu_deferred_array[@]} -gt 0 ]]; then
		local mdmclient_macos_msu_major_upgrade_deferred_array
		mdmclient_macos_msu_major_upgrade_deferred_array=()
		local mdmclient_macos_msu_minor_update_deferred_array
		mdmclient_macos_msu_minor_update_deferred_array=()
		for mdmclient_macos_msu_item in "${mdmclient_macos_msu_deferred_array[@]}"; do
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_item is:\n${mdmclient_macos_msu_item}"
			[[ $(echo "${mdmclient_macos_msu_item}" | awk -F ',' '{print $4}' | sed -e 's/.*://g' -e 's/\..*//g') -gt "${macos_version_major}" ]] && mdmclient_macos_msu_major_upgrade_deferred_array+=("${mdmclient_macos_msu_item}")
			[[ $(echo "${mdmclient_macos_msu_item}" | awk -F ',' '{print $4}' | sed -e 's/.*://g' -e 's/\..*//g') -eq "${macos_version_major}" ]] && mdmclient_macos_msu_minor_update_deferred_array+=("${mdmclient_macos_msu_item}")
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_major_upgrade_deferred_array is:\n${mdmclient_macos_msu_major_upgrade_deferred_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_minor_update_deferred_array is:\n${mdmclient_macos_msu_minor_update_deferred_array[*]}"
	fi
	
	# If (no errors) there are deferred items then evaluate and report to super.log. Further, if restrictions deferrals are not present then erroneously deferred items are moved back to the appropriate available items array.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && { [[ ${#mdmclient_macos_installers_deferred_array[@]} -gt 0 ]] || [[ ${#mdmclient_macos_msu_major_upgrade_deferred_array[@]} -gt 0 ]] || [[ ${#mdmclient_macos_msu_minor_update_deferred_array[@]} -gt 0 ]] || [[ ${#mdmclient_non_system_deferred_array[@]} -gt 0 ]]; }; then
		# Iterate trough the deferred arrays for logging and erroneous deferrals.
		{ [[ "${restrictions_deferral_macOS_major_upgrades}" != "FALSE" ]] || [[ "${restrictions_deferral_macOS_minor_updates}" != "FALSE" ]] || [[ "${restrictions_deferral_non_system_updates}" != "FALSE" ]]; } && log_super "Status: Some updates are deferred due to a restrictions deferral configuration profile."
		{ [[ "${restrictions_deferral_macOS_major_upgrades}" == "FALSE" ]] || [[ "${restrictions_deferral_macOS_minor_updates}" == "FALSE" ]] || [[ "${restrictions_deferral_non_system_updates}" == "FALSE" ]]; } && log_super "Warning: Some updates are inaccurately reporting as deferred even though restrictions deferral configuration is not enabled. As such, these updates will still be considered for installation."
		if [[ ${#mdmclient_macos_installers_deferred_array[@]} -gt 0 ]]; then
			for array_index in "${!mdmclient_macos_installers_deferred_array[@]}"; do
				[[ "${restrictions_deferral_macOS_major_upgrades}" != "FALSE" ]] && log_super "Restrictions Deferral: macOS major upgrade installer $((array_index + 1)) of ${#mdmclient_macos_installers_deferred_array[@]} is: ${mdmclient_macos_installers_deferred_array[array_index]}"
				if [[ "${restrictions_deferral_macOS_major_upgrades}" == "FALSE" ]]; then
					log_super "Warning: Inaccurate deferral found for macOS major upgrade installer $((array_index + 1)) of ${#mdmclient_macos_installers_deferred_array[@]} is: ${mdmclient_macos_installers_deferred_array[array_index]}"
					# shellcheck disable=SC2001
					mdmclient_macos_installers_array+=($(echo "${mdmclient_macos_installers_deferred_array[array_index]}" | sed -e 's/^Deferred.*,T/T/g'))
				fi
			done
			[[ "${restrictions_deferral_macOS_major_upgrades}" == "FALSE" ]] && mdmclient_macos_installers_array=($(sort -t ':' -k4 -V -r  <<<"${mdmclient_macos_installers_array[*]}"))
		fi
		
		if [[ ${#mdmclient_macos_msu_major_upgrade_deferred_array[@]} -gt 0 ]]; then
			for array_index in "${!mdmclient_macos_msu_major_upgrade_deferred_array[@]}"; do
				[[ "${restrictions_deferral_macOS_major_upgrades}" != "FALSE" ]] && log_super "Restrictions Deferral: macOS major upgrade $((array_index + 1)) of ${#mdmclient_macos_msu_major_upgrade_deferred_array[@]} is: ${mdmclient_macos_msu_major_upgrade_deferred_array[array_index]}"
				if [[ "${restrictions_deferral_macOS_major_upgrades}" == "FALSE" ]]; then
					log_super "Warning: Inaccurate deferral found for macOS major upgrade $((array_index + 1)) of ${#mdmclient_macos_msu_major_upgrade_deferred_array[@]} is: ${mdmclient_macos_msu_major_upgrade_deferred_array[array_index]}"
					# shellcheck disable=SC2001
					mdmclient_macos_msu_major_upgrade_array+=($(echo "${mdmclient_macos_msu_major_upgrade_deferred_array[array_index]}" | sed -e 's/^Deferred.*,T/T/g'))
				fi
			done
			[[ "${restrictions_deferral_macOS_major_upgrades}" == "FALSE" ]] && mdmclient_macos_msu_major_upgrade_array=($(sort -t ':' -k3 -V -r  <<<"${mdmclient_macos_msu_major_upgrade_array[*]}"))
		fi
		
		if [[ ${#mdmclient_macos_msu_minor_update_deferred_array[@]} -gt 0 ]]; then
			for array_index in "${!mdmclient_macos_msu_minor_update_deferred_array[@]}"; do
				[[ "${restrictions_deferral_macOS_minor_updates}" != "FALSE" ]] && log_super "Restrictions Deferral: macOS minor update $((array_index + 1)) of ${#mdmclient_macos_msu_minor_update_deferred_array[@]} is: ${mdmclient_macos_msu_minor_update_deferred_array[array_index]}"
				if [[ "${restrictions_deferral_macOS_minor_updates}" == "FALSE" ]]; then
					log_super "Warning: Inaccurate deferral found for macOS minor update $((array_index + 1)) of ${#mdmclient_macos_msu_minor_update_deferred_array[@]} is: ${mdmclient_macos_msu_minor_update_deferred_array[array_index]}"
					# shellcheck disable=SC2001
					mdmclient_macos_msu_minor_update_array+=($(echo "${mdmclient_macos_msu_minor_update_deferred_array[array_index]}" | sed -e 's/^Deferred.*,T/T/g'))
				fi
			done
			[[ "${restrictions_deferral_macOS_minor_updates}" == "FALSE" ]] && mdmclient_macos_msu_minor_update_array=($(sort -t ':' -k3 -V -r  <<<"${mdmclient_macos_msu_minor_update_array[*]}"))
		fi
		
		if [[ ${#mdmclient_non_system_deferred_array[@]} -gt 0 ]]; then
			for array_index in "${!mdmclient_non_system_deferred_array[@]}"; do
				[[ "${restrictions_deferral_non_system_updates}" != "FALSE" ]] && log_super "Restrictions Deferral: Non-system update $((array_index + 1)) of ${#mdmclient_non_system_deferred_array[@]} is: ${mdmclient_non_system_deferred_array[array_index]}"
				if [[ "${restrictions_deferral_non_system_updates}" == "FALSE" ]]; then
					log_super "Warning: Inaccurate deferral found for Non-system update $((array_index + 1)) of ${#mdmclient_non_system_deferred_array[@]} is: ${mdmclient_non_system_deferred_array[array_index]}"
					# shellcheck disable=SC2001
					mdmclient_non_system_array+=($(echo "${mdmclient_non_system_deferred_array[array_index]}" | sed -e 's/^Deferred.*,T/T/g'))
				fi
			done
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_installers_array is:\n${mdmclient_macos_installers_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_major_upgrade_array is:\n${mdmclient_macos_msu_major_upgrade_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_minor_update_array is:\n${mdmclient_macos_msu_minor_update_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_non_system_array is:\n${mdmclient_non_system_array[*]}"
	fi
	
	# If (no errors) no installable updates then report any macOS security updates (that can't be installed programmatically) and then exit this function.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ ${#mdmclient_macos_installers_array[@]} -eq 0 ]] && [[ ${#mdmclient_macos_msu_major_upgrade_array[@]} -eq 0 ]] && [[ ${#mdmclient_macos_msu_minor_update_array[@]} -eq 0 ]] && [[ ${#mdmclient_non_system_array[@]} -eq 0 ]]; then
		{ [[ ${#mdmclient_macos_installers_deferred_array[@]} -gt 0 ]] || [[ ${#mdmclient_macos_msu_major_upgrade_deferred_array[@]} -gt 0 ]] || [[ ${#mdmclient_macos_msu_minor_update_deferred_array[@]} -gt 0 ]] || [[ ${#mdmclient_non_system_deferred_array[@]} -gt 0 ]]; } && log_super "Status: No currently available macOS software updates due to software update deferral restrictions configuration profile."
		if [[ ${#mdmclient_security_array[@]} -gt 0 ]]; then
			[[ "${msu_automatic_security_updates}" == "TRUE" ]] && log_super "Status: The following security updates are currently available and they should be installed soon via automatic macOS software udpate:"
			[[ "${msu_automatic_security_updates}" == "FALSE" ]] && log_super "Warning: The following security updates are available but due to macOS software update settings are not allowed for installation:"
			for array_index in "${!mdmclient_security_array[@]}"; do
				[[ "${msu_automatic_security_updates}" == "TRUE" ]] && log_super "Status: Security update $((array_index + 1)) of ${#mdmclient_security_array[@]} is: ${mdmclient_security_array[array_index]}"
				[[ "${msu_automatic_security_updates}" == "FALSE" ]] && log_super "Warning: Security update $((array_index + 1)) of ${#mdmclient_security_array[@]} is: ${mdmclient_security_array[array_index]}"
			done
		fi
		IFS="${previous_ifs}"
		return 0
	fi
	
	# If (no errors) macOS major upgrades are available then determine if any of them are allowed.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && { [[ ${#mdmclient_macos_installers_array[@]} -gt 0 ]] || [[ ${#mdmclient_macos_msu_major_upgrade_array[@]} -gt 0 ]]; }; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_major_upgrades is: ${install_macos_major_upgrades}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_major_upgrades_target is: ${install_macos_major_upgrades_target}"
		
		# If there is no ${install_macos_major_upgrades_target}, then the newest macOS major upgrade versions should be the targets.
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ -z "${install_macos_major_upgrades_target}" ]]; then
			[[ ${#mdmclient_macos_installers_array[@]} -gt 0 ]] && mdmclient_macos_installer_target="${mdmclient_macos_installers_array[0]}"
			[[ ${#mdmclient_macos_msu_major_upgrade_array[@]} -gt 0 ]] && mdmclient_macos_msu_major_upgrade_target="${mdmclient_macos_msu_major_upgrade_array[0]}"
			[[ "${restrictions_deferral_macOS_major_upgrades}" == "FALSE" ]] && macos_major_upgrade_latest="TRUE"
		fi
		
		# If there is a ${install_macos_major_upgrades_target} then evaluate versions in ${mdmclient_macos_installers_array[]} for a possible target.
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ -n "${install_macos_major_upgrades_target}" ]] && [[ ${#mdmclient_macos_installers_array[@]} -gt 0 ]]; then
			local mdmclient_macos_installers_disallowed_array
			mdmclient_macos_installers_disallowed_array=()
			for mdmclient_macos_installer_item in "${mdmclient_macos_installers_array[@]}"; do
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_installer_item is:\n${mdmclient_macos_installer_item}"
				if [[ $(echo "${mdmclient_macos_installer_item}" | awk -F ',' '{print $2}' | sed -e 's/.*://g' -e 's/\..*//g') -eq ${install_macos_major_upgrades_target} ]]; then
					mdmclient_macos_installer_target="${mdmclient_macos_installer_item}"
					break
				fi
				[[ "${mdmclient_macos_installer_target}" == "FALSE" ]] && mdmclient_macos_installers_disallowed_array+=("${mdmclient_macos_installer_item}")
			done
		fi
		
		# If there is a ${install_macos_major_upgrades_target}then evaluate versions in ${mdmclient_macos_msu_major_upgrade_array[]} for a possible target.
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ -n "${install_macos_major_upgrades_target}" ]] && [[ ${#mdmclient_macos_msu_major_upgrade_array[@]} -gt 0 ]]; then
			local mdmclient_macos_msu_major_upgrades_disallowed_array
			mdmclient_macos_msu_major_upgrades_disallowed_array=()
			for mdmclient_macos_msu_item in "${mdmclient_macos_msu_major_upgrade_array[@]}"; do
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_item is:\n${mdmclient_macos_msu_item}"
				if [[ $(echo "${mdmclient_macos_msu_item}" | awk -F ',' '{print $3}' | sed -e 's/.*://g' -e 's/\..*//g') -eq ${install_macos_major_upgrades_target} ]]; then
					mdmclient_macos_msu_major_upgrade_target="${mdmclient_macos_msu_item}"
					break
				fi
				[[ "${mdmclient_macos_msu_major_upgrade_target}" == "FALSE" ]] && mdmclient_macos_msu_major_upgrades_disallowed_array+=("${mdmclient_macos_msu_item}")
			done
		fi
		
		# If using an older version of macOS and the MDM workflow then major upgrades via MSU are not possible.
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ "${mdmclient_macos_msu_major_upgrade_target}" != "FALSE" ]] && [[ "${macos_version_major}" -lt 13 ]] && [[ "${workflow_macos_auth}" == "JAMF" ]]; then
			log_super "Warning: The MDM upgrade command on macOS 12 only supports full macOS installers, thus the following \"over-the-air\" macOS major upgrade is not currently possible: ${mdmclient_macos_msu_major_upgrade_target}"
			mdmclient_macos_msu_major_upgrade_target="FALSE"
		fi
		
		# At this point if there is both a target installer and a target MSU major upgrade, then the MSU major upgrade takes priority.
		{ [[ "${mdmclient_macos_installer_target}" != "FALSE" ]] && [[ "${mdmclient_macos_msu_major_upgrade_target}" != "FALSE" ]]; } && mdmclient_macos_installer_target="FALSE"
		
		# If there are macOS major upgrades but they aren't possible or allowed then report to super.log.
		if [[ "${install_macos_major_upgrades}" == "FALSE" ]] && [[ ${#mdmclient_macos_installers_array[@]} -gt 0 ]]; then
			log_super "Disallowed: The following macOS major upgrade installers are available but not allowed:"
			for array_index in "${!mdmclient_macos_installers_array[@]}"; do
				log_super "Disallowed: macOS major upgrade installer $((array_index + 1)) of ${#mdmclient_macos_installers_array[@]} is: ${mdmclient_macos_installers_array[array_index]}"
			done
		fi
		if [[ "${install_macos_major_upgrades}" == "FALSE" ]] && [[ ${#mdmclient_macos_msu_major_upgrade_array[@]} -gt 0 ]]; then
			log_super "Disallowed: The following \"over-the-air\" macOS major upgrades are available but not allowed:"
			for array_index in "${!mdmclient_macos_msu_major_upgrade_array[@]}"; do
				log_super "Disallowed: macOS major upgrade $((array_index + 1)) of ${#mdmclient_macos_msu_major_upgrade_array[@]} is: ${mdmclient_macos_msu_major_upgrade_array[array_index]}"
			done
		fi
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ ${#mdmclient_macos_installers_disallowed_array[@]} -gt 0 ]]; then
			log_super "Disallowed: The following macOS major upgrade installers are available but not allowed:"
			for array_index in "${!mdmclient_macos_installers_disallowed_array[@]}"; do
				log_super "Disallowed: macOS major upgrade installer $((array_index + 1)) of ${#mdmclient_macos_installers_disallowed_array[@]} is: ${mdmclient_macos_installers_disallowed_array[array_index]}"
			done
		fi
		if [[ "${install_macos_major_upgrades}" == "TRUE" ]] && [[ ${#mdmclient_macos_msu_major_upgrades_disallowed_array[@]} -gt 0 ]]; then
			log_super "Disallowed: The following \"over-the-air\" macOS major upgrades are available but not allowed:"
			for array_index in "${!mdmclient_macos_msu_major_upgrades_disallowed_array[@]}"; do
				log_super "Disallowed: macOS major upgrade $((array_index + 1)) of ${#mdmclient_macos_msu_major_upgrades_disallowed_array[@]} is: ${mdmclient_macos_msu_major_upgrades_disallowed_array[array_index]}"
			done
			{ [[ "${mdmclient_macos_msu_major_upgrade_target}" == "FALSE" ]] && [[ "${mdmclient_macos_installer_target}" != "FALSE" ]]; } && log_super "Warning: The --install-macos-major-version-target=${install_macos_major_upgrades_target} option is forcing the workflow to target an older macOS installer (as opposed to a more efficient \"over-the-air\" macOS major upgrade)."
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_installer_target is: ${mdmclient_macos_installer_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_major_upgrade_target is: ${mdmclient_macos_msu_major_upgrade_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_major_upgrade_latest is: ${macos_major_upgrade_latest}"
	
	# If (no errors) check for previously targeted macOS major upgrade betas plus Jamf API beta limitation.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ -n "${install_macos_major_upgrades_target}" ]] && [[ "${macos_beta_program}" == "TRUE" ]] && [[ "${workflow_macos_auth}" == "JAMF" ]]; then
		local macos_older_beta_target
		{ [[ "${mdmclient_macos_installer_target}" != "FALSE" ]] && [[ $(echo "${mdmclient_macos_installers_array[0]}" | awk -F ',' '{print $2}' | sed -e 's/.*://g' -e 's/\..*//g') -gt ${install_macos_major_upgrades_target} ]]; } && macos_older_beta_target="${mdmclient_macos_installer_target}"
		{ [[ "${mdmclient_macos_msu_major_upgrade_target}" != "FALSE" ]] && [[ $(echo "${mdmclient_macos_msu_major_upgrade_array[0]}" | awk -F ',' '{print $3}' | sed -e 's/.*://g' -e 's/\..*//g') -gt ${install_macos_major_upgrades_target} ]]; } && macos_older_beta_target="${mdmclient_macos_msu_major_upgrade_target}"
		if [[ -n "${macos_older_beta_target}" ]]; then
			check_mdm_service
			[[ "${auth_error_mdm}" == "FALSE" ]] && get_saved_authentication
			[[ "${auth_error_saved}" == "FALSE" ]] && check_jamf_api_access_token
			[[ "${auth_error_jamf}" == "FALSE" ]] && check_jamf_api_update_workflow
			if [[ "${auth_error_jamf}" == "FALSE" ]]; then
				if [[ "${jamf_api_update_workflow}" == "NEW" ]]; then
					log_super "Error: Unable to target older macOS beta major upgrade: ${macos_older_beta_target}"
					log_super "Error: The Jamf Pro new Managed Software Updates API does not support targeting older macOS beta major upgrades. To target older macOS beta major upgrades you must disable the new Managed Software Updates feature in Jamf Pro or use a local authentication option."
					workflow_check_software_status_error="TRUE"
				fi
			fi
			if [[ "${auth_error_mdm}" == "TRUE" ]] || [[ "${auth_error_saved}" == "TRUE" ]] || [[ "${auth_error_jamf}" == "TRUE" ]]; then
				log_super "Error: Failed to validate Jamf Pro API configuration. Verify Jamf Pro API configuration: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials"
				workflow_check_software_status_error="TRUE"
				unset auth_jamf_client
				unset auth_jamf_secret
			fi
		fi
	fi
	
	# If (no errors) no macOS major upgrade is targeted and a macOS minor update is available then select the latest for the ${mdmclient_macos_msu_minor_update_target}.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${mdmclient_macos_installer_target}" == "FALSE" ]] && [[ "${mdmclient_macos_msu_major_upgrade_target}" == "FALSE" ]] && [[ ${#mdmclient_macos_msu_minor_update_array[@]} -gt 0 ]]; then
		mdmclient_macos_msu_minor_update_target="${mdmclient_macos_msu_minor_update_array[0]}"
		[[ "${restrictions_deferral_macOS_minor_updates}" == "FALSE" ]] && macos_minor_update_latest="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdmclient_macos_msu_minor_update_target is: ${mdmclient_macos_msu_minor_update_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_minor_update_latest is: ${macos_minor_update_latest}"
	
	# If (no errors) there is a macOS installer targeted then collect/verify the ${macos_installers_list}.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${mdmclient_macos_installer_target}" != "FALSE" ]]; then
		# If required collecte a new ${macos_installers_list}.
		if [[ "${check_software_status_required}" == "TRUE" ]] || [[ "${macos_installers_list}" == "FALSE" ]] || [[ -z "${macos_installers_list}" ]]; then
			get_macos_installers_list
			
			# Error handling if mist-list is misbehaving.
			if [[ "${get_macos_installers_list_error}" == "TRUE" ]] || [[ "${get_macos_installers_list_timeout}" == "TRUE" ]]; then
				log_super "Warning: Re-starting check for macOS installers..."
				get_macos_installers_list
			fi
			if [[ "${get_mdmclient_list_error}" == "TRUE" ]] || [[ "${get_mdmclient_list_timeout}" == "TRUE" ]]; then
				log_super "Error: Checking for macOS installers listing did not complete after multiple attempts."
				workflow_check_software_status_error="TRUE"
			fi
		fi
		
		# Make sure we have a ${macos_installers_list}, this checks both new and cached lists.
		if [[ "${macos_installers_list}" == "FALSE" ]]; then
			log_super "Error: Checking for macOS installers listing did not return any available installers."
			workflow_check_software_status_error="TRUE"
		fi
	fi
	
	# If (no errors) there is a ${mdmclient_macos_installer_target} then evaluate the ${macos_installers_list} to select the appropriate ${macos_installer_target}.
	# If a ${macos_installer_target} is selected then this function will also set ${macos_installer_title}, ${macos_installer_version}, ${macos_installer_build}, ${macos_installer_size}, and then exit this function.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${mdmclient_macos_installer_target}" != "FALSE" ]] && [[ "${macos_installers_list}" != "FALSE" ]]; then
		# Clean up the ${macos_installers_list} and create an array for searching.
		local macos_installers_sanitized_list
		macos_installers_sanitized_list=$(echo "${macos_installers_list}" | sed -e 's/"//g' -e 's/=//g')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installers_sanitized_list is:\n${macos_installers_sanitized_list}"
		local macos_installers_array
		macos_installers_array=($(echo "${macos_installers_sanitized_list}" | awk -F ',' '{print "Title:" $2 ",Version:" $3 ",Build:" $4 ",Size:" $5}'))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installers_array is:\n${macos_installers_array[*]}"
		
		# Pick the appropriate macOS installer from the ${macos_installers_array} based on the ${mdmclient_macos_installer_target}.
		for macos_installer_item in "${macos_installers_array[@]}"; do
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_item is:\n${macos_installer_item}"
			if [[ "$(echo "${macos_installer_item}" | awk -F ',' '{print $2}' | sed -e 's/.*://g')" == "$(echo "${mdmclient_macos_installer_target}" | awk -F ',' '{print $2}' | sed -e 's/.*://g')" ]]; then
				macos_installer_target="${macos_installer_item}"
				break
			fi
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_target is: ${macos_installer_target}"
		
		# If there is a ${macos_installer_target} then set the remaining individual parameters.
		if [[ "${macos_installer_target}" != "FALSE" ]]; then
			macos_installer_title=$(echo "${macos_installer_target}" | awk -F ',' '{print $1}' | sed -e 's/.*://g')
			macos_installer_version=$(echo "${macos_installer_target}" | awk -F ',' '{print $2}' | sed -e 's/.*://g')
			macos_installer_build=$(echo "${macos_installer_target}" | awk -F ',' '{print $3}' | sed -e 's/.*://g')
			macos_installer_size=$(echo "${macos_installer_target}" | awk -F ',' '{print $4}' | sed -e 's/.*://g' | awk '{print $1"/1000000000 +1"}' | bc)
			log_super "Target: macOS major upgrade installer ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} which is a ${macos_installer_size}GB download."
			IFS="${previous_ifs}"
			return 0
		else
			log_super "Error: The mist-cli listing did not contain a macOS installer that matches targeted version: ${macos_installer_target}"
			workflow_check_software_status_error="TRUE"
		fi
	fi
	
	# If (no errors) the function is still running at this point then it's time to collect/verify the ${msu_list}.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]]; then
		# If required collecte a new ${msu_list}.
		if [[ "${check_software_status_required}" == "TRUE" ]] || [[ "${msu_list}" == "FALSE" ]] || [[ -z "${msu_list}" ]]; then
			get_msu_list
			
			# Error handling if softwareupdate is misbehaving.
			if [[ "${get_msu_list_error}" == "TRUE" ]] || [[ "${get_msu_list_timeout}" == "TRUE" ]]; then
				log_super "Warning: Re-starting softwareupdate available updates listing..."
				kick_softwareupdated
				sleep 10
				get_msu_list
			elif [[ "${macos_version_number}" -lt 1303 ]] && [[ $(echo "${msu_list}" | grep -c 'macOS') -eq 0 ]]; then
				log_super "Status: macOS 11.x - macOS 13.2, double-checking softwareupdate available updates listing..."
				sleep 10
				get_msu_list
			fi
			if [[ "${get_msu_list_error}" == "TRUE" ]] || [[ "${get_msu_list_timeout}" == "TRUE" ]]; then
				log_super "Error: Checking for softwareupdate available updates listing did not complete after multiple attempts."
				workflow_check_software_status_error="TRUE"
			fi
		fi
		
		# Make sure we have a ${msu_list}, this checks both new and cached lists.
		if [[ "${msu_list}" == "FALSE" ]]; then
			log_super "Error: Checking for macOS software update listing did not return any available updates."
			workflow_check_software_status_error="TRUE"
		fi
	fi
	
	# If (no errors) and there is a ${msu_list} then parse and split the updates in to individual arrays.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${msu_list}" != "FALSE" ]]; then
		local msu_sanitized_list
		msu_sanitized_list=$(echo "${msu_list}" | grep -e 'Label' -e 'Title' | tr -d '\n' | sed -e 's/^* //' -e 's/* /\n/g' -e 's/\tTitle/,Title/g' -e 's/, /,/g' -e 's/: /:/g')
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: msu_sanitized_list is:\n${msu_sanitized_list}"
		local macos_msu_array
		macos_msu_array=($(echo "${msu_sanitized_list}" | grep 'macOS' | awk -F ',' '{print $1 "," $2 "," $4 "," $3}' | sort -t ':' -k5 -V -r))
		non_system_msu_array=($(echo "${msu_sanitized_list}" | grep -v 'macOS' | awk -F ',' '{print $1 "," $2 "," $4 "," $3}'))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_array is:\n${macos_msu_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: non_system_msu_array is:\n${non_system_msu_array[*]}"
	fi
	
	# If (no errors) there is a ${mdmclient_macos_msu_major_upgrade_target} then evaluate the ${macos_msu_array[]} to select the appropriate macOS major upgrade for the ${macos_msu_major_upgrade_target}.
	# If a ${macos_msu_major_upgrade_target} is selected then this function will also set ${macos_msu_label}, ${macos_msu_title}, ${macos_msu_version}, ${macos_msu_build}, ${macos_msu_size } and then exit this function.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${mdmclient_macos_msu_major_upgrade_target}" != "FALSE" ]] && [[ ${#macos_msu_array[@]} -gt 0 ]]; then
		# Pick the appropriate macOS major upgrade from the ${macos_msu_array} based on the ${mdmclient_macos_msu_major_upgrade_target}.
		for macos_msu_item in "${macos_msu_array[@]}"; do
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_item is:\n${macos_msu_item}"
			if [[ "$(echo "${macos_msu_item}" | awk -F ',' '{print $4}' | sed -e 's/.*://g')" == "$(echo "${mdmclient_macos_msu_major_upgrade_target}" | awk -F ',' '{print $3}' | sed -e 's/.*://g')" ]]; then
				macos_msu_major_upgrade_target="${macos_msu_item}"
				break
			fi
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_major_upgrade_target is: ${macos_msu_major_upgrade_target}"
		
		# If there is a ${macos_msu_major_upgrade_target} then set the remaining individual parameters.
		if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]]; then
			macos_msu_label=$(echo "${macos_msu_major_upgrade_target}" | awk -F ',' '{print $1}' | sed -e 's/.*://g')
			[[ $(echo "${macos_msu_major_upgrade_target}" | grep -c 'Beta') -eq 0 ]] && macos_msu_title=$(echo "${macos_msu_major_upgrade_target}" | awk -F ',' '{print $2}' | sed -e 's/.*://g' -e 's/ [1-9].*//g')
			[[ $(echo "${macos_msu_major_upgrade_target}" | grep -c 'Beta') -gt 0 ]] && macos_msu_title=$(echo "${macos_msu_major_upgrade_target}" | awk -F ',' '{print $2}' | sed -e 's/.*://g' -e 's/ [1-9].*/ Beta/g')
			macos_msu_version=$(echo "${macos_msu_major_upgrade_target}" | awk -F ',' '{print $4}' | sed -e 's/.*://g')
			macos_msu_build=$(echo "${macos_msu_major_upgrade_target}" | awk -F ',' '{print $1}' | sed -e 's/.*://g' -e 's/^.*-//g')
			macos_msu_size=$(echo "${macos_msu_major_upgrade_target}" | awk -F ',' '{print $3}' | sed -e 's/.*://g' -e 's/[^0-9]//g' | awk '{print $1"/1000000 +1"}' | bc)
			log_super "Target: \"Over-the-air\" macOS major upgrade ${macos_msu_title} ${macos_msu_version}-${macos_msu_build} which is a ${macos_msu_size}GB download."
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_label is: ${macos_msu_label}"
			IFS="${previous_ifs}"
			return 0
		else
			log_super "Error: The softwareupdate listing did not contain a macOS major upgrade that matches targeted version: ${mdmclient_macos_msu_major_upgrade_target}"
			workflow_check_software_status_error="TRUE"
		fi
	fi
	
	# If (no errors) there is a ${mdmclient_macos_msu_minor_update_target} then evaluate the ${macos_msu_array[]} to select the appropriate macOS minor update for the ${macos_msu_minor_update_target}.
	# If a ${macos_msu_minor_update_target} is selected then this function will also set ${macos_msu_label}, ${macos_msu_title}, ${macos_msu_version}, ${macos_msu_build}, ${macos_msu_size } and then exit this function.
		if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ "${mdmclient_macos_msu_minor_update_target}" != "FALSE" ]] && [[ ${#macos_msu_array[@]} -gt 0 ]]; then
		# Pick the appropriate macOS minor update from the ${macos_msu_array} based on the ${mdmclient_macos_msu_minor_update_target}.
		for macos_msu_item in "${macos_msu_array[@]}"; do
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_item is:\n${macos_msu_item}"
			if [[ "$(echo "${macos_msu_item}" | awk -F ',' '{print $4}' | sed -e 's/.*://g')" == "$(echo "${mdmclient_macos_msu_minor_update_target}" | awk -F ',' '{print $3}' | sed -e 's/.*://g')" ]]; then
				macos_msu_minor_update_target="${macos_msu_item}"
				break
			fi
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_minor_update_target is: ${macos_msu_minor_update_target}"
		
		# If there is a ${macos_msu_minor_update_target} then set the remaining individual parameters.
		if [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then
			macos_msu_label=$(echo "${macos_msu_minor_update_target}" | awk -F ',' '{print $1}' | sed -e 's/.*://g')
			[[ $(echo "${macos_msu_minor_update_target}" | grep -c 'Beta') -eq 0 ]] &&  macos_msu_title=$(echo "${macos_msu_minor_update_target}" | awk -F ',' '{print $2}' | sed -e 's/.*://g' -e 's/ [1-9].*//g')
			[[ $(echo "${macos_msu_minor_update_target}" | grep -c 'Beta') -gt 0 ]] &&  macos_msu_title=$(echo "${macos_msu_minor_update_target}" | awk -F ',' '{print $2}' | sed -e 's/.*://g' -e 's/ [1-9].*/ Beta/g')
			macos_msu_version=$(echo "${macos_msu_minor_update_target}" | awk -F ',' '{print $4}' | sed -e 's/.*://g')
			macos_msu_build=$(echo "${macos_msu_minor_update_target}" | awk -F ',' '{print $1}' | sed -e 's/.*://g' -e 's/^.*-//g')
			macos_msu_size=$(echo "${macos_msu_minor_update_target}" | awk -F ',' '{print $3}' | sed -e 's/.*://g' -e 's/[^0-9]//g' | awk '{print $1"/1000000 +1"}' | bc)
			log_super "Target: macOS minor update ${macos_msu_title} ${macos_msu_version}-${macos_msu_build} which is a ${macos_msu_size}GB download."
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_label is: ${macos_msu_label}"
			IFS="${previous_ifs}"
			return 0
		else
			log_super "Error: The softwareupdate listing did not contain a macOS minor update that matches targeted version: ${mdmclient_macos_msu_minor_update_target}"
			workflow_check_software_status_error="TRUE"
		fi
	fi
	
	# If (no errors) the only updates are non-system updates then evaluate the ${non_system_msu_array[]} and set ${non_system_msu_targets}.
	# If there are ${non_system_msu_targets} then this function will also set ${non_system_msu_labels_array[]} and ${non_system_msu_titles_array[]}.
	if [[ "${workflow_check_software_status_error}" == "FALSE" ]] && [[ ${#mdmclient_non_system_array[@]} -gt 0 ]] && [[ ${#non_system_msu_array[@]} -gt 0 ]]; then
		# Make sure the number of non-system updates collected by mdmclient and msu match.
		if [[ ${#non_system_msu_array[@]} -eq ${#mdmclient_non_system_array[@]} ]];then 
			non_system_msu_targets="TRUE"
			non_system_msu_labels_array=()
			non_system_msu_titles_array=()
			for array_index in "${!non_system_msu_array[@]}"; do
				non_system_msu_labels_array+=($(echo "${non_system_msu_array[array_index]}" | awk -F ',' '{print $1}' | sed -e 's/.*://g'))
				non_system_msu_titles_array+=($(echo "${non_system_msu_array[array_index]}" | awk -F ',' '{print $2}' | sed -e 's/.*://g'))
				log_super "Target: Non-system update $((array_index + 1)) of ${#non_system_msu_array[@]} is: ${non_system_msu_titles_array[array_index]} $(echo "${non_system_msu_array[array_index]}" | awk -F ',' '{print $4}' | sed -e 's/.*://g')"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: non_system_msu_labels_array[${array_index}] is: ${non_system_msu_labels_array[array_index]}"
			done
		else
			log_super "Error: The softwareupdate listing did not contain the expeted number of non-system updates."
			workflow_check_software_status_error="TRUE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: non_system_msu_targets is: ${non_system_msu_targets}"
	
	IFS="${previous_ifs}"
	if [[ "${workflow_check_software_status_error}" == "TRUE" ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_super "Error: Checking for macOS software status workflow failed, install now workflow can not continue."
			log_status "Inactive Error: Checking for macOS software status workflow failed, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
			exit_error
		else # Default super workflow.
			if [[ "${workflow_restart_validate_active}" == "TRUE" ]]; then
				deferral_timer_minutes="${DEFERRAL_TIMER_RESTART_VALIDATION_ERROR_MINUTES}"
				log_super "Error: Checking for macOS software status workflow failed, trying restart validation workflow again in ${deferral_timer_minutes} minutes."
				log_status "Pending: Checking for macOS software status workflow failed, trying restart validation workflow again in ${deferral_timer_minutes} minutes."
			else # Default super workflow.
				deferral_timer_minutes="${deferral_timer_error_minutes}"
				log_super "Error: Checking for macOS software status workflow failed, trying again in ${deferral_timer_minutes} minutes."
				log_status "Pending: Checking for macOS software status workflow failed, trying again in ${deferral_timer_minutes} minutes."
			fi
			set_auto_launch_deferral
		fi
	fi
}

# MARK: *** Downloads ***
################################################################################

# This function determines which macOS updates, upgrades, or installers should be downloaded and validates any previously downloaded macOS updates, upgrades, or installers and sets ${macos_installer_download_required}, ${macos_msu_download_required}, ${macos_msu_label}, and ${macos_msu_title} accordingly.
check_macos_downloads() {
	macos_installer_download_required="FALSE"
	macos_msu_download_required="FALSE"
	
	# If a macOS installer is targeted then evaluate any local installers and set ${macos_installer_download_required}.
	if [[ "${macos_installer_target}" != "FALSE" ]]; then
		local macos_installer_download
		macos_installer_download=$(defaults read "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded 2>/dev/null)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_download is: ${macos_installer_download}"
		if [[ -d "/Applications/Install ${macos_installer_title}.app" ]]; then
			check_macos_installer
			if [[ "${check_macos_installer_error}" == "TRUE" ]]; then
				[[ -n "${macos_installer_download}" ]] && log_super "Warning: Previously downloaded macOS installer failed local validations, removing installer: /Applications/Install ${macos_installer_title}.app."
				[[ -z "${macos_installer_download}" ]] && log_super "Warning: Existing macOS installer failed local validations, removing installer: /Applications/Install ${macos_installer_title}.app."
				macos_installer_download_required="TRUE"
				defaults delete "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded 2>/dev/null
				rm -Rf "/Applications/Install ${macos_installer_title}.app" >/dev/null 2>&1
			fi
			defaults write "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded -string "${macos_installer_title} ${macos_installer_version}-${macos_installer_build}"
		else # No local macOS installer.
			[[ -n "${macos_installer_download}" ]] && log_super "Warning: Previously downloaded macOS installer could not be found."
			macos_installer_download_required="TRUE"
			defaults delete "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded 2>/dev/null
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_download_required is: ${macos_installer_download_required}"
	
	# If a softwareupdate is targeted then evaluate cached macOS update/upgrade.
	if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] || [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then
		macos_msu_label_downloaded=$(defaults read "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded 2>/dev/null)
		local macos_msu_last_startup_downloaded
		macos_msu_last_startup_downloaded=$(defaults read "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded 2>/dev/null)
		[[ $(defaults read "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null) -eq 1 ]] && workflow_download_macos_auth_required="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_label_downloaded is: ${macos_msu_label_downloaded}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_last_startup_downloaded is: ${macos_msu_last_startup_downloaded}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_download_macos_auth_required is: ${workflow_download_macos_auth_required}"
		
		# Only validate if we know the list of previous downloads and last startup time.
		if [[ -n "${macos_msu_label_downloaded}" ]] && [[ -n "${macos_msu_last_startup_downloaded}" ]]; then
			local macos_msu_downloaded_error
			macos_msu_downloaded_error="FALSE"
			if [[ "${macos_msu_label_downloaded}" != "${macos_msu_label}" ]]; then
				log_super "Warning: Previously downloaded macOS update/upgrade \"${macos_msu_label_downloaded}\" does not match the expected macOS update/upgrade \"${macos_msu_label}\", download workflow needs to run again."
				macos_msu_downloaded_error="TRUE"
			fi
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mac_last_startup is: ${mac_last_startup}"
			if [[ "${macos_msu_last_startup_downloaded}" != "${mac_last_startup}" ]]; then
				log_super "Warning: The system has been restarted without applying the previously downloaded macOS update/upgrade, download workflow needs to run again."
				macos_msu_downloaded_error="TRUE"
			fi
			if [[ "${macos_msu_downloaded_error}" == "FALSE" ]]; then
				local update_asset_attributes
				update_asset_attributes=$(defaults read /System/Volumes/Update/Update update-asset-attributes 2>/dev/null)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: update_asset_attributes is:\n${update_asset_attributes}"
				local macos_msu_version_prepared
				macos_msu_version_prepared=$(echo "${update_asset_attributes}" | grep -w 'OSVersion' | awk -F '"' '{print $2;}')
				if [[ ${macos_version_major} -ge 13 ]]; then
					local macos_msu_prepared_version_extra
					macos_msu_prepared_version_extra=$(echo "${update_asset_attributes}" | grep -w 'ProductVersionExtra' | awk -F '"' '{print $2;}')
					[[ -n "${macos_msu_prepared_version_extra}" ]] && macos_msu_version_prepared="${macos_msu_version_prepared} ${macos_msu_prepared_version_extra}"
					[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_prepared_version_extra is: ${macos_msu_prepared_version_extra}"
				fi
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_version_prepared is: ${macos_msu_version_prepared}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_version is: ${macos_msu_version}"
				if [[ -z "${macos_msu_version_prepared}" ]]; then
					log_super "Warning: Previously downloaded macOS update/upgrade is no longer valid, download workflow needs to run again."
					macos_msu_downloaded_error="TRUE"
				else
					if [[ "${macos_msu_version_prepared}" != "${macos_msu_version}" ]]; then
						macos_msu_downloaded_error="TRUE"
						[[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] && log_super "Warning: Previously downloaded macOS major upgrade version ${macos_msu_version_prepared} doesn't match expected version ${macos_msu_version}, download workflow needs to run again."
						[[ "${macos_msu_minor_update_target}" != "FALSE" ]] && log_super "Warning: Previously downloaded macOS minor update version ${macos_msu_version_prepared} doesn't match expected version ${macos_msu_version}, download workflow needs to run again."
					fi
				fi
			fi
			if [[ "${macos_msu_downloaded_error}" == "TRUE" ]]; then
				macos_msu_download_required="TRUE"
				defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded 2>/dev/null
				defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded 2>/dev/null
			fi
		else
			macos_msu_download_required="TRUE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_download_required is: ${macos_msu_download_required}"
}

# This function checks the macOS installer to be used for upgrades matches the ${macos_installer_build} and passes Gatekeeper validation.
check_macos_installer() {
	check_macos_installer_error="FALSE"
	log_super "Status: Gatekeeper and version validation of /Applications/Install ${macos_installer_title}.app..."
	
	# First check to see if the downloaded macOS installer build version matches the ${macos_installer_build}.
	[[ -d "/Volumes/Shared Support" ]] && diskutil unmount force "/Volumes/Shared Support" >/dev/null 2>&1
	sleep 1
	if [[ -f "/Applications/Install ${macos_installer_title}.app/Contents/SharedSupport/SharedSupport.dmg" ]]; then
		local hidiutil_response
		hidiutil_response=$(hdiutil attach -quiet -noverify -nobrowse "/Applications/Install ${macos_installer_title}.app/Contents/SharedSupport/SharedSupport.dmg" 2>&1)
		sleep 1
		if [[ -d "/Volumes/Shared Support" ]]; then
			if [[ -f "/Volumes/Shared Support/com_apple_MobileAsset_MacSoftwareUpdate/com_apple_MobileAsset_MacSoftwareUpdate.xml" ]]; then
				local macos_installer_build_downloaded
				macos_installer_build_downloaded=$(/usr/libexec/PlistBuddy -c "Print :Assets:0:Build" "/Volumes/Shared Support/com_apple_MobileAsset_MacSoftwareUpdate/com_apple_MobileAsset_MacSoftwareUpdate.xml")
				sleep 1
				diskutil unmount force "/Volumes/Shared Support" >/dev/null 2>&1
				if [[ -n "${macos_installer_build_downloaded}" ]]; then
					if [[ "${macos_installer_build_downloaded}" != "${macos_installer_build}" ]]; then
						log_super "Status: Currently downloaded macOS installer build number ${macos_installer_build_downloaded} does not match target build number ${macos_installer_build}."
						check_macos_installer_error="TRUE"
					fi
				else
					log_super "Status: Unable to resolve the macOS installer build version."
					check_macos_installer_error="TRUE"
					[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_build_downloaded is: ${macos_installer_build_downloaded}"
				fi
			else
				log_super "Status: Unable to locate macOS installer com_apple_MobileAsset_MacSoftwareUpdate.xml file for validation."
				check_macos_installer_error="TRUE"
			fi
		else
			log_super "Status: Unable to mount macOS installer SharedSupport.dmg for validation."
			check_macos_installer_error="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: hidiutil_response is:\n${hidiutil_response}"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: check_macos_installer_error is: ${check_macos_installer_error}"
	
	# If there are no errors, then move on to gatekeeper validation.
	if [[ "${check_macos_installer_error}" == "FALSE" ]]; then
		local startosinstall_response
		startosinstall_response=$("/Applications/Install ${macos_installer_title}.app/Contents/Resources/startosinstall" --usage 2>&1)
		if [[ $(echo "${startosinstall_response}" | grep -c 'Usage: startosinstall') -eq 0 ]]; then
			log_super "Status: Currently downloaded macOS installer failed Gatekeeper validation."
			check_macos_installer_error="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: startosinstall_response is:\n${startosinstall_response}"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: check_macos_installer_error is: ${check_macos_installer_error}"
}

# Delete any unneeded macOS installers based on the value of ${macos_installer_target} in order to save space.
delete_unneeded_macos_installers() {
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=$'\n'
	local mdfind_macos_installers_array
	mdfind_macos_installers_array=($(mdfind kind:app -name "Install macOS" 2>/dev/null))
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: mdfind_macos_installers_array is:\n${mdfind_macos_installers_array[*]}"
	if [[ -n "${mdfind_macos_installers_array[*]}" ]]; then
		for macos_installer_path in "${mdfind_macos_installers_array[@]}"; do
			if [[ $(echo "${macos_installer_path}" | grep -c '/Volumes/') -gt 0 ]] || { [[ $(echo "${macos_installer_path}" | grep -c '/Users/') -gt 0 ]] && [[ $(echo "${macos_installer_path}" | grep -c '/Users/.*/Applications/') -eq 0 ]] && [[ $(echo "${macos_installer_path}" | grep -c '/Users/.*/Desktop/') -eq 0 ]] && [[ $(echo "${macos_installer_path}" | grep -c '/Users/.*/Downloads/') -eq 0 ]]; }; then
				log_super "Status: Skipping deletion of assumed archived macOS installer at: ${macos_installer_path}"
			else
				if [[ "${macos_installer_target}" == "FALSE" ]]; then
					if [[ "${test_mode_option}" == "TRUE" ]]; then # Test mode.
						log_super "Test Mode: macOS upgrades are not allowed, found unnecessary macOS installer at: ${macos_installer_path}"
					else # Normal workflow.
						log_super "Warning: macOS upgrades are not allowed, removing unnecessary macOS installer at: ${macos_installer_path}"
						rm -Rf "${macos_installer_path}" >/dev/null 2>&1
					fi
				elif [[ "${macos_installer_path}" != "/Applications/Install ${macos_installer_title}.app" ]]; then
					if [[ "${test_mode_option}" == "TRUE" ]]; then # Test mode.
						log_super "Test Mode: Found unnecessary macOS installer at: ${macos_installer_path}"
					else # Normal workflow.
						log_super "Warning: Removing unnecessary macOS installer at: ${macos_installer_path}"
						rm -Rf "${macos_installer_path}" >/dev/null 2>&1
					fi
				fi
			fi
		done
	fi
	IFS="${previous_ifs}"
}

# Download macOS update or upgrade via softwareupdate command, and also save responses to ${SUPER_LOG}, ${MSU_WORKFLOW_LOG}, and ${SUPER_LOCAL_PLIST}.
download_macos_msu() {
	# If ${test_mode_option} then it's not necessary to continue this function.
	if [[ "${test_mode_option}" == "TRUE" ]]; then
		log_super "Test Mode: Skipping the download macOS update/upgrade via MSU workflow."
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for install now download notification..."
			sleep "${test_mode_timeout_seconds}"
		fi
		download_maocs_msu_error="FALSE"
		return 0
	fi
	
	# Start with log and status updates.
	if [[ "${macos_version_major}" -ge 14 ]] && [[ "${workflow_download_macos_auth_required}" == "TRUE" ]]; then
		log_super "softwareupdate: Starting ${macos_msu_title} authenticated download workflow, check ${MSU_WORKFLOW_LOG} for more detail."
		log_status "Running: softwareupdate: Starting ${macos_msu_title} authenticated download workflow."
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD ${macos_msu_title} VIA AUTHENTICATED SOFTWAREUPDATE START ****"
	else
		log_super "softwareupdate: Starting ${macos_msu_title} download workflow, check ${MSU_WORKFLOW_LOG} for more detail."
		log_status "Running: softwareupdate: Starting ${macos_msu_title} download workflow."
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD ${macos_msu_title} VIA SOFTWAREUPDATE START ****"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_label is: ${macos_msu_label}"
	
	# The softwareupdate download process is backgrounded and is watched via a while loop later on. Also note the difference between macOS versions.
	local download_macos_msu_pid
	if [[ "${macos_version_major}" -ge 14 ]] && [[ "${workflow_download_macos_auth_required}" == "TRUE" ]]; then # macOS 14+ on Apple Silicon systems that require authenticated downloads.
		echo "${auth_local_password}" | launchctl asuser "${current_user_id}" sudo -u root softwareupdate --download "${macos_msu_label}" --agree-to-license --user "${auth_local_account}" --stdinpass >>"${MSU_WORKFLOW_LOG}" 2>&1 &
		download_macos_msu_pid="$!"
	elif [[ "${macos_version_major}" -ge 13 ]]; then # macOS 13+
		if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
			echo ' ' | launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" softwareupdate --download "${macos_msu_label}" --agree-to-license --user "${current_user_account_name}" --stdinpass >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		else # Intel.
			launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" softwareupdate --download "${macos_msu_label}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		fi
	elif [[ "${macos_version_major}" -ge 12 ]]; then # macOS 12
		if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
			launchctl asuser "${current_user_id}" sudo -u root softwareupdate --download "${macos_msu_label}" --agree-to-license --user "root" --stdinpass "" >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		else # Intel.
			launchctl asuser "${current_user_id}" sudo -u root softwareupdate --download "${macos_msu_label}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		fi
	else # macOS 11
		if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
			echo ' ' | softwareupdate --download "${macos_msu_label}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
		else # Intel.
			softwareupdate --download "${macos_msu_label}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		fi
	fi
	
	# Watch ${MSU_WORKFLOW_LOG} while waiting for the softwareupdate download workflow to complete.
	# Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS} then changes to ${TIMEOUT_MSU_SYSTEM_SECONDS}.
	local download_macos_msu_start_error
	download_macos_msu_start_error="TRUE"
	local download_macos_msu_start_timeout
	download_macos_msu_start_timeout="TRUE"
	local download_macos_msu_timeout_error
	download_macos_msu_timeout_error="TRUE"
	local download_macos_msu_timeout_seconds
	download_macos_msu_timeout_seconds="${TIMEOUT_START_SECONDS}"
	local download_macos_msu_phase
	download_macos_msu_phase="START"
	local download_macos_msu_complete_perecent
	download_macos_msu_complete_perecent=0
	local download_macos_msu_complete_perecent_previous
	download_macos_msu_complete_perecent_previous=0
	local download_macos_msu_complete_display
	unset macos_msu_title_downloaded
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_timeout_seconds is: ${download_macos_msu_timeout_seconds}"
	while read -t "${download_macos_msu_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c "Can’t connect") -gt 0 ]] || [[ $(echo "${log_line}" | grep -c "Couldn't communicate") -gt 0 ]]; then
			download_macos_msu_start_error="CONNECT"
			break
		elif [[ $(echo "${log_line}" | grep -c 'No such update') -gt 0 ]]; then
			download_macos_msu_start_error="NOUPDATE"
			break
		elif [[ $(echo "${log_line}" | grep -c 'Not enough free disk space') -gt 0 ]]; then
			download_macos_msu_start_error="SPACE"
			break
		elif [[ $(echo "${log_line}" | grep -c 'Failed to authenticate') -gt 0 ]]; then
			download_macos_msu_start_error="AUTH"
			break
		elif [[ $(echo "${log_line}" | grep -c 'Failed to download') -gt 0 ]]; then
			download_macos_msu_start_error="FAILED"
			break
		elif [[ $(echo "${log_line}" | grep -c 'Downloading') -gt 0 ]] && [[ "${download_macos_msu_phase}" == "START" ]]; then
			macos_msu_title_downloaded="${log_line/Downloading /}"
			log_super "softwareupdate: ${macos_msu_title_downloaded} is downloading..."
			log_msu "**** TIMESTAMP ****"
			download_macos_msu_phase="DOWNLOADING"
			download_macos_msu_timeout_seconds="${TIMEOUT_MSU_SYSTEM_SECONDS}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_timeout_seconds is: ${download_macos_msu_timeout_seconds}"
			download_macos_msu_start_error="FALSE"
			download_macos_msu_start_timeout="FALSE"
			[[ $(echo "${macos_msu_title_downloaded}" | grep -c 'macOS') -gt 0 ]] && download_macos_msu_phase="DOWNLOADING"
		elif [[ $(echo "${log_line}" | grep -c 'Downloading') -gt 0 ]] && [[ "${download_macos_msu_phase}" == "DOWNLOADING" ]]; then
			download_macos_msu_complete_perecent=$(echo "${log_line}" | sed -e 's/Downloading: //' -e 's/\.[0-9][0-9]//' | tr -d '\n' | tr -d '\r')
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_complete_perecent is: ${download_macos_msu_complete_perecent}"
			if [[ "${download_macos_msu_complete_perecent}" -ge 60 ]]; then
				log_echo_replace_line "${macos_msu_title_downloaded} download progress: 100%\n"
				log_super "softwareupdate: ${macos_msu_title_downloaded} download complete, now preparing..."
				log_msu "**** TIMESTAMP ****"
				download_macos_msu_phase="PREPARING"
			elif [[ "${download_macos_msu_complete_perecent}" -gt "${download_macos_msu_complete_perecent_previous}" ]]; then
				download_macos_msu_complete_display=$( (echo "${download_macos_msu_complete_perecent} * 1.69" | bc) | cut -d '.' -f1)
				log_echo_replace_line "${macos_msu_title_downloaded} download progress: ${download_macos_msu_complete_display}%"
				download_macos_msu_complete_perecent_previous=${download_macos_msu_complete_perecent}
			fi
		elif [[ $(echo "${log_line}" | grep -c 'Downloading') -gt 0 ]] && [[ "${download_macos_msu_phase}" == "PREPARING" ]]; then
			download_macos_msu_complete_perecent=$(echo "${log_line}" | sed -e 's/Downloading: //' -e 's/\.[0-9][0-9]//' | tr -d '\n' | tr -d '\r')
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_complete_perecent is: ${download_macos_msu_complete_perecent}"
			if [[ ${download_macos_msu_complete_perecent} -ge 100 ]]; then
				log_echo_replace_line "${macos_msu_title_downloaded} preparing progress: 100%\n"
				log_msu "**** TIMESTAMP ****"
				download_macos_msu_phase="DONE"
			elif [[ "${download_macos_msu_complete_perecent}" -gt "${download_macos_msu_complete_perecent_previous}" ]]; then
				download_macos_msu_complete_display=$(((download_macos_msu_complete_perecent - 60) * 2))
				log_echo_replace_line "${macos_msu_title_downloaded} preparing progress: ${download_macos_msu_complete_display}%"
				download_macos_msu_complete_perecent_previous=${download_macos_msu_complete_perecent}
			fi
		elif [[ $(echo "${log_line}" | grep -c 'Downloaded') -gt 0 ]]; then
			macos_msu_title_downloaded=$(echo "${log_line}" | sed -e 's/://' -e 's/Downloaded //')
			log_super "softwareupdate: ${macos_msu_title_downloaded} download and preparation complete."
			download_macos_msu_start_error="FALSE"
			download_macos_msu_start_timeout="FALSE"
			download_macos_msu_timeout_error="FALSE"
			break
		fi
	done < <(tail -n1 -F "${MSU_WORKFLOW_LOG}" | tr -u '%' '\n')
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_start_timeout is: ${download_macos_msu_start_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_start_error is: ${download_macos_msu_start_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_timeout_error is: ${download_macos_msu_timeout_error}"
	
	# If the softwareupdate download workflow completed, then validate the prepared macOS update/upgrade.
	if [[ "${download_macos_msu_start_error}" == "FALSE" ]] && [[ "${download_macos_msu_start_timeout}" == "FALSE" ]] && [[ "${download_macos_msu_timeout_error}" == "FALSE" ]]; then
		local download_macos_msu_title_error
		download_macos_msu_title_error="TRUE"
		local download_macos_msu_validation_error
		download_macos_msu_validation_error="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_title is: ${macos_msu_title}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_title_downloaded is: ${macos_msu_title_downloaded}"
		if [[ "${macos_msu_title}" == "${macos_msu_title_downloaded}" ]]; then
			download_macos_msu_title_error="FALSE"
			local update_asset_attributes
			update_asset_attributes=$(defaults read /System/Volumes/Update/Update update-asset-attributes 2>/dev/null)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: update_asset_attributes is:\n${update_asset_attributes}"
			local macos_msu_version_prepared
			macos_msu_version_prepared=$(echo "${update_asset_attributes}" | grep -w 'OSVersion' | awk -F '"' '{print $2;}')
			if [[ "${macos_version_major}" -ge 13 ]]; then
				local macos_msu_prepared_version_extra
				macos_msu_prepared_version_extra=$(echo "${update_asset_attributes}" | grep -w 'ProductVersionExtra' | awk -F '"' '{print $2;}')
				[[ -n "${macos_msu_prepared_version_extra}" ]] && macos_msu_version_prepared="${macos_msu_version_prepared} ${macos_msu_prepared_version_extra}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_prepared_version_extra is: ${macos_msu_prepared_version_extra}"
			fi
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_version_prepared is: ${macos_msu_version_prepared}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_version is: ${macos_msu_version}"
			[[ "${macos_msu_version_prepared}" == "${macos_msu_version}" ]] && download_macos_msu_validation_error="FALSE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_title_error is: ${download_macos_msu_title_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_msu_validation_error is: ${download_macos_msu_validation_error}"
	
	# If the macOS update/upgrade is downloaded and prepared, then collect information.
	if [[ "${download_macos_msu_start_error}" == "FALSE" ]] || [[ "${download_macos_msu_start_timeout}" == "FALSE" ]] || [[ "${download_macos_msu_timeout_error}" == "FALSE" ]] || [[ "${download_macos_msu_title_error}" == "FALSE" ]] || [[ "${download_macos_msu_validation_error}" == "FALSE" ]]; then
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS VIA SOFTWAREUPDATE COMPLETED ****"
		download_maocs_msu_error="FALSE"
		macos_msu_download_required="FALSE"
		defaults write "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded -string "${macos_msu_label}"
		defaults write "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded -string "${mac_last_startup}"
	else # Some part of the softwareupdate download workflow failed.
		if [[ "${download_macos_msu_start_error}" == "CONNECT" ]]; then
			log_msu "Error: Unable to reach macOS software update servers."
			log_super "Error: Unable to reach macOS software update servers."
		elif [[ "${download_macos_msu_start_error}" == "NOUPDATE" ]]; then
			log_msu "Error: Unable to find requested macOS update/upgrade via softwareupdate."
			log_super "Error: Unable to find requested macOS update/upgrade via softwareupdate."
		elif [[ "${download_macos_msu_start_error}" == "SPACE" ]]; then
			log_msu "Error: Not enough available storage to download macOS update/upgrade."
			log_super "Error: Not enough available storage to download macOS update/upgrade."
		elif [[ "${download_macos_msu_start_error}" == "AUTH" ]]; then
			log_msu "Error: Download of macOS update/upgrade via softwareupdate failed to authenticate."
			log_super "Error: Download of macOS update/upgrade via softwareupdate failed to authenticate."
			[[ "${mac_cpu_architecture}" == "arm64" ]] && workflow_download_macos_auth_required="TRUE"
			[[ "${mac_cpu_architecture}" == "arm64" ]] && defaults write "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired -bool true
		elif [[ "${download_macos_msu_start_error}" == "FAILED" ]]; then
			log_msu "Error: Download of macOS update/upgrade via softwareupdate failed to start."
			log_super "Error: Download of macOS update/upgrade via softwareupdate failed to start."
		elif [[ "${download_macos_msu_start_timeout}" == "TRUE" ]]; then
			log_msu "Error: Download of macOS update/upgrade via softwareupdate failed to start after waiting for ${download_macos_msu_timeout_seconds} seconds."
			log_super "Error: Download of macOS update/upgrade via softwareupdate failed to start after waiting for ${download_macos_msu_timeout_seconds} seconds."
		elif [[ "${download_macos_msu_timeout_error}" == "TRUE" ]]; then
			log_msu "Error: Download of macOS update/upgrade via softwareupdate failed to complete, as indicated by no progress after waiting for ${download_macos_msu_timeout_seconds} seconds."
			log_super "Error: Download of macOS update/upgrade via softwareupdate failed to complete, as indicated by no progress after waiting for ${download_macos_msu_timeout_seconds} seconds."
		elif [[ "${download_macos_msu_title_error}" == "TRUE" ]]; then
			log_msu "Error: Download of ${macos_msu_title} did not complete or match requested download title."
			log_super "Error: Download of ${macos_msu_title} ddid not complete or match requested download title."
		else # "${download_macos_msu_validation_error}" == "TRUE"
			if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]]; then
				log_msu "Error: Downloaded macOS major upgrade version of ${macos_msu_version_prepared} doesn't match expected version ${macos_msu_version}."
				log_super "Error: Downloaded macOS major upgrade version of ${macos_msu_version_prepared} doesn't match expected version ${macos_msu_version}."
			else # "${macos_msu_minor_update_target}" != "FALSE"
				log_msu "Error: Downloaded macOS minor update version of ${macos_msu_version_prepared} doesn't match expected version ${macos_msu_version}."
				log_super "Error: Downloaded macOS mintor update version of ${macos_msu_version_prepared} doesn't match expected version ${macos_msu_version}."
			fi
		fi
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS VIA SOFTWAREUPDATE FAILED ****"
		download_maocs_msu_error="TRUE"
		macos_msu_download_required="TRUE"
		defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded 2>/dev/null
		kill -9 "${download_macos_msu_pid}" >/dev/null 2>&1
		kick_softwareupdated
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_maocs_msu_error is: ${download_maocs_msu_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_download_required is: ${macos_msu_download_required}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_download_macos_auth_required is: ${workflow_download_macos_auth_required}"
}

# Download macOS installer via ${MIST_CLI_BINARY}, and also save responses to ${SUPER_LOG}, ${INSTALLER_WORKFLOW_LOG}, and ${SUPER_LOCAL_PLIST}.
download_macos_installer() {
	# If ${test_mode_option} then it's not necessary to continue this function.
	if [[ "${test_mode_option}" == "TRUE" ]]; then
		log_super "Test Mode: Skipping the download macOS update/upgrade via installer workflow."
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for install now download notification..."
			sleep "${test_mode_timeout_seconds}"
		fi
		download_macos_installer_error="FALSE"
		return 0
	fi
	
	# Start with log and status updates.
	log_super "mist_cli: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} download installer workflow, check ${INSTALLER_WORKFLOW_LOG} for more detail."
	log_status "Running: mist_cli: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} download installer workflow."
	log_installer "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} INSTALLER APP START ****"
	
	# Background the ${MIST_CLI_BINARY} download process and send to ${INSTALLER_WORKFLOW_LOG}.
	local download_macos_installer_mist_pid
	if [[ "${macos_beta_program}" == "FALSE" ]]; then
		"${MIST_CLI_BINARY}" download installer --force --no-ansi --output-directory "/Applications" --compatible "${macos_installer_build}" application --application-name "Install %NAME%.app" >>"${INSTALLER_WORKFLOW_LOG}" 2>&1 &
		download_macos_installer_mist_pid="$!"
	else # macOS beta workflow.
		"${MIST_CLI_BINARY}" download installer --force --no-ansi --output-directory "/Applications" --compatible --include-betas "${macos_installer_build}" application --application-name "Install %NAME%.app" >>"${INSTALLER_WORKFLOW_LOG}" 2>&1 &
		download_macos_installer_mist_pid="$!"
	fi
	
	# Watch ${INSTALLER_WORKFLOW_LOG} while waiting for the mist-cli download process to complete.
	# Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS} then changes to ${TIMEOUT_INSTALLER_DOWNLOAD_SECONDS}.
	local download_macos_installer_start_error
	download_macos_installer_start_error="TRUE"
	local download_macos_installer_start_timeout
	download_macos_installer_start_timeout="TRUE"
	local download_macos_installer_timeout_error
	download_macos_installer_timeout_error="TRUE"
	local download_macos_installer_timeout_seconds
	download_macos_installer_timeout_seconds="${TIMEOUT_START_SECONDS}"
	local download_macos_installer_phase
	download_macos_installer_phase="START"
	local download_macos_installer_complete_percent
	download_macos_installer_complete_percent=0
	local download_macos_installer_complete_percent_previous
	download_macos_installer_complete_percent_previous=0
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_timeout_seconds is: ${download_macos_installer_timeout_seconds}"
	while read -t "${download_macos_installer_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c 'No macOS Installer found') -gt 0 ]]; then
			break
		elif [[ $(echo "${log_line}" | grep -c 'DOWNLOAD') -gt 0 ]] && [[ "${download_macos_installer_phase}" != "DOWNLOADING" ]]; then
			log_super "mist_cli: Install ${macos_installer_title}.app is downloading..."
			log_installer "**** TIMESTAMP ****"
			download_macos_installer_timeout_seconds="${TIMEOUT_INSTALLER_DOWNLOAD_SECONDS}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_timeout_seconds is: ${download_macos_installer_timeout_seconds}"
			download_macos_installer_phase="DOWNLOADING"
			download_macos_installer_start_error="FALSE"
			download_macos_installer_start_timeout="FALSE"
		elif [[ "${download_macos_installer_phase}" == "DOWNLOADING" ]] && [[ $(echo "${log_line}" | grep -c 'InstallAssistant.pkg') -gt 0 ]]; then
			download_macos_installer_complete_percent=$(echo "${log_line}" | awk -F '(' '{print $2;}' | awk -F '.' '{print $1;}' | tr -d -c 0-9)
			download_macos_installer_complete_percent=${download_macos_installer_complete_percent#0}
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_complete_percent is: ${download_macos_installer_complete_percent}"
			if [[ $download_macos_installer_complete_percent -ge 100 ]]; then
				log_echo_replace_line "Install ${macos_installer_title}.app download progress: 100%\n"
				log_super "mist_cli: Install ${macos_installer_title}.app downloaded, now verifying..."
				log_installer "**** TIMESTAMP ****"
				download_macos_installer_phase="DONE"
			elif [[ $download_macos_installer_complete_percent -gt $download_macos_installer_complete_percent_previous ]]; then
				log_echo_replace_line "Install ${macos_installer_title}.app download progress: ${download_macos_installer_complete_percent}%"
				download_macos_installer_complete_percent_previous=$download_macos_installer_complete_percent
			fi
		elif [[ $(echo "${log_line}" | grep -c 'INSTALL') -gt 0 ]]; then
			log_super "mist_cli: Install ${macos_installer_title}.app verified, now preparing..."
			log_installer "**** TIMESTAMP ****"
		elif [[ $(echo "${log_line}" | grep -c 'APPLICATION') -gt 0 ]]; then
			log_super "mist_cli: Install ${macos_installer_title}.app prepared, now moving to /Applications..."
			log_installer "**** TIMESTAMP ****"
			download_macos_installer_phase="APPLICATION"
		elif [[ $(echo "${log_line}" | grep -c 'TEARDOWN') -gt 0 ]]; then
			log_installer "**** TIMESTAMP ****"
			download_macos_installer_start_error="FALSE"
			download_macos_installer_start_timeout="FALSE"
			download_macos_installer_timeout_error="FALSE"
			break
		fi
	done < <(tail -n1 -F "${INSTALLER_WORKFLOW_LOG}")
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_start_error is: ${download_macos_installer_start_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_start_timeout is: ${download_macos_installer_start_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_timeout_error is: ${download_macos_installer_timeout_error}"
	
	# If the mist-cli download workflow completed, then validate the macOS installer application.
	if [[ "${download_macos_installer_start_error}" == "FALSE" ]] && [[ "${download_macos_installer_start_timeout}" == "FALSE" ]] && [[ "${download_macos_installer_timeout_error}" == "FALSE" ]]; then
		local download_macos_installer_app_error
		download_macos_installer_app_error="TRUE"
		local download_macos_installer_validation_error
		download_macos_installer_validation_error="TRUE"
		if [[ -d "/Applications/Install ${macos_installer_title}.app" ]]; then
			download_macos_installer_app_error="FALSE"
			check_macos_installer
			[[ "${check_macos_installer_error}" == "FALSE" ]] && download_macos_installer_validation_error="FALSE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_app_error is: ${download_macos_installer_app_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_validation_error is: ${download_macos_installer_validation_error}"
	
	# If the macOS installer application is downloaded and valid, then collect information.
	if [[ "${download_macos_installer_start_error}" == "FALSE" ]] || [[ "${download_macos_installer_start_timeout}" == "FALSE" ]] || [[ "${download_macos_installer_timeout_error}" == "FALSE" ]] || [[ "${download_macos_installer_app_error}" == "FALSE" ]] || [[ "${download_macos_installer_validation_error}" == "FALSE" ]]; then
		log_installer "Status: A macOS installer is now available at: /Applications/Install ${macos_installer_title}.app"
		log_installer "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS INSTALLER APP COMPLETE ****"
		log_super "Status: A macOS installer is now available at: /Applications/Install ${macos_installer_title}.app"
		download_macos_installer_error="FALSE"
		macos_installer_download_required="FALSE"
		defaults write "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded -string "${macos_installer_title} ${macos_installer_version}-${macos_installer_build}"
	else # Some part of the macOS installer download workflow failed.
		if [[ "${download_macos_installer_start_error}" == "TRUE" ]]; then
			log_installer "Error: macOS installer download failed start or the requested installer could not be found."
			log_super "Error: macOS installer download failed start or the requested installer could not be found."
		elif [[ "${download_macos_installer_start_timeout}" == "TRUE" ]]; then
			log_installer "Error: macOS installer download failed to start after waiting for ${download_macos_installer_timeout_seconds} seconds."
			log_super "Error: macOS installer download failed to start after waiting for ${download_macos_installer_timeout_seconds} seconds."
		elif [[ "${download_macos_installer_timeout_error}" == "TRUE" ]]; then
			log_installer "Error: macOS installer download failed to complete, as indicated by no progress after waiting for ${download_macos_installer_timeout_seconds} seconds."
			log_super "Error: macOS installer download failed to complete, as indicated by no progress after waiting for ${download_macos_installer_timeout_seconds} seconds."
		elif [[ "${download_macos_installer_app_error}" == "TRUE" ]]; then
			log_installer "Error: The target macOS installer could not be found in the /Applications folder."
			log_super "Error: The target macOS installer could not be found in the /Applications folder."
		else # "${download_macos_installer_validation_error}" == "TRUE"
			log_installer "Error: macOS installer failed local validations, removing installer: /Applications/Install ${macos_installer_title}.app."
			log_super "Error: macOS installer failed local validations, removing installer: /Applications/Install ${macos_installer_title}.app."
			rm -Rf "/Applications/Install ${macos_installer_title}.app" >/dev/null 2>&1
		fi
		log_installer "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS INSTALLER APP FAILED ****"
		kill -9 "${download_macos_installer_mist_pid}" >/dev/null 2>&1
		download_macos_installer_error="TRUE"
		defaults delete "${SUPER_LOCAL_PLIST}" MacOSInstallerDownloaded 2>/dev/null
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: download_macos_installer_error is: ${download_macos_installer_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_download_required is: ${macos_installer_download_required}"
}

# This function contains logic to determine the correct download behavior based on system condition and specified options.
# This function only runs if there is an active user.
workflow_download_macos() {
	workflow_download_macos_error="FALSE"
	workflow_download_macos_check_user="FALSE"
	download_macos_installer_error="FALSE"
	download_maocs_msu_error="FALSE"
	push_macos_mdm_download_error="FALSE"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_download_required is: ${macos_installer_download_required}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_download_required is: ${macos_msu_download_required}"
	
	# If downloads are required then check available storage.
	if [[ "${macos_installer_download_required}" == "TRUE" ]] || [[ "${macos_msu_download_required}" == "TRUE" ]]; then
		check_storage_available
		if [[ "${check_storage_available_error}" == "FALSE" ]]; then
			if [[ "${storage_ready}" == "FALSE" ]]; then
				if [[ "${current_user_account_name}" == "FALSE" ]]; then
					log_super "Error: Current available storage is at ${storage_available_gigabytes} GBs which is below the ${storage_required_gigabytes} GBs that is required for download. And no active user is logged in to attempt remediation."
					workflow_download_macos_error="TRUE"
				else # A normal user is currently logged in.
					dialog_insufficient_storage
					[[ "${dialog_insufficient_storage_error}" == "TRUE" ]] && workflow_download_macos_error="TRUE"
				fi
			fi
		else # "${check_storage_available_error}" == "TRUE"
			workflow_download_macos_error="TRUE"
		fi
	else # Downloads not required so log that download is not needed.
		[[ "${macos_installer_target}" != "FALSE" ]] && log_super "Status: Previously downloaded ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installer is available at: /Applications/Install ${macos_installer_title}.app"
		[[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] && log_super "Status: Previously downloaded macOS major upgrade is prepared: ${macos_msu_label_downloaded}"
		[[ "${macos_msu_minor_update_target}" != "FALSE" ]] && log_super "Status: Previously downloaded macOS minor update is prepared: ${macos_msu_label_downloaded}"	
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_download_macos_error is: ${workflow_download_macos_error}"
	
	# If (no errors) and ${test_mode_option} then simulate dialogs and notifications for potential user authenticated download dialog.
	if [[ "${workflow_download_macos_error}" == "FALSE" ]] && [[ "${test_mode_option}" == "TRUE" ]] && [[ "${macos_version_major}" -ge 14 ]] && [[ "${mac_cpu_architecture}" == "arm64" ]] && [[ "${workflow_macos_auth}" == "USER" ]]; then
		local current_user_password_policies
		local current_user_system_password_policies
		[[ $(dscl . read "/Users/${current_user_account_name}" accountPolicyData 2>/dev/null | grep -c '<key>policies</key>') -gt 0 ]] && current_user_password_policies="TRUE"
		[[ $(system_profiler SPConfigurationProfileDataType | grep -c 'passwordpolicy') -gt 0 ]] && current_user_system_password_policies="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_password_policies is: ${current_user_password_policies}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: current_user_system_password_policies is: ${current_user_system_password_policies}"
		if [[ "${current_user_password_policies}" == "TRUE" ]] || [[ "${current_user_system_password_policies}" == "TRUE" ]]; then
			workflow_download_macos_auth_required="TRUE"
			defaults write "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired -bool true
			log_super "Test Mode: Simluating authenticated download requirement because user password policies were found. Under normal curcumstances this dialog would only appear if an earlier download attempt failed because it required authentication."
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_download_macos_auth_required is: ${workflow_download_macos_auth_required}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_now_active is: ${workflow_install_now_active}"
	
	# If (no errors) and macOS installer download is needed.
	if [[ "${workflow_download_macos_error}" == "FALSE" ]] && [[ "${macos_installer_download_required}" == "TRUE" ]]; then
		[[ "${workflow_install_now_active}" == "TRUE" ]] && notification_install_now_download
		download_macos_installer
		[[ "${download_macos_installer_error}" == "TRUE" ]] && workflow_download_macos_error="TRUE"
		[[ "${download_macos_installer_error}" == "FALSE" ]] && workflow_download_macos_check_user="TRUE"
	fi
	
	# If (no errors) and macOS update/upgrade via MSU download is needed, attempt an unauthenticated download.
	if [[ "${workflow_download_macos_error}" == "FALSE" ]] && [[ "${macos_msu_download_required}" == "TRUE" ]] && [[ "${workflow_download_macos_auth_required}" != "TRUE" ]]; then
		[[ "${workflow_install_now_active}" == "TRUE" ]] && notification_install_now_download
		download_macos_msu
		if [[ "${download_maocs_msu_error}" == "TRUE" ]]; then
			if [[ "${workflow_download_macos_auth_required}" == "TRUE" ]]; then
				log_super "Warning: Initial attempt of unauthenticated download of macOS update/upgrade via MSU failed, failing over to authenticated download workflow."
			else
				workflow_download_macos_error="TRUE"
			fi
		else
			workflow_download_macos_check_user="TRUE"
		fi
	fi
	
	# If (no errors) and macOS update/upgrade via MSU authenticated download is needed.
	if [[ "${workflow_download_macos_error}" == "FALSE" ]] && [[ "${macos_msu_download_required}" == "TRUE" ]] && [[ "${workflow_download_macos_auth_required}" == "TRUE" ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_macos_auth is: ${workflow_macos_auth}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_mdm_failover_to_user_status is: ${auth_mdm_failover_to_user_status}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_credential_failover_to_user_option is: ${auth_credential_failover_to_user_option}"
		
		# If an MDM workflow is expected, first check for MDM service, bootstrap token, and possibly failover to user authentication workflow.
		if [[ "${workflow_macos_auth}" == "JAMF" ]]; then
			check_mdm_service
			if [[ "${auth_error_mdm}" == "TRUE" ]]; then
				if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]] || [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ERROR') -gt 0 ]] || { [[ "${workflow_install_now_active}" == "TRUE" ]] && [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'INSTALLNOW') -gt 0 ]]; }; then
					log_super "Warning: MDM service is not available, failing over to local (and possibly user authenticated) download workflow."
					workflow_macos_auth="FAILOVER"
				else
					log_super "Error: Can not use MDM workflow because the MDM service is not available."
					workflow_download_macos_error="TRUE"
				fi
			else # MDM service is available.
				check_bootstrap_token_escrow
				if [[ "${auth_error_bootstrap_token}" == "TRUE" ]]; then
					if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]] || [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ERROR') -gt 0 ]] || { [[ "${workflow_install_now_active}" == "TRUE" ]] && [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'INSTALLNOW') -gt 0 ]]; }; then
						log_super "Warning: Missing or invalid bootstrap token escrow, failing over to local (and possibly user authenticated) download workflow."
						workflow_macos_auth="FAILOVER"
					else
						log_super "Error: Can not use MDM workflow because this computer's bootstrap token is not escrowed."
						workflow_download_macos_error="TRUE"
					fi
				fi
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_macos_auth is: ${workflow_macos_auth}"
		
		# If (no errors) then get authentication.
		if [[ "${workflow_download_macos_error}" == "FALSE" ]] && [[ "${workflow_macos_auth}" != "FALSE" ]]; then
			if [[ "${workflow_macos_auth}" == "LOCAL" ]] || [[ "${workflow_macos_auth}" == "JAMF" ]]; then
				get_saved_authentication
				if [[ "${auth_error_saved}" == "TRUE" ]]; then
					if [[ "${auth_credential_failover_to_user_option}" == "TRUE" ]] || [[ "${auth_ask_user_to_save_password}" == "TRUE" ]]; then
						log_super "Warning: Saved authentication error, failing over to user authenticated download workflow."
						workflow_macos_auth="FAILOVER"
						if [[ "${dialog_user_auth_valid}" != "TRUE" ]]; then
							dialog_user_auth_type="DOWNLOAD"
							dialog_user_auth
							unset dialog_user_auth_type
							[[ "${dialog_user_auth_error}" == "TRUE" ]] && workflow_download_macos_error="TRUE"
						fi
					else
						log_super "Error: Unable to use saved authentication for download and the --auth-credential-failover-to-user option is not enabled."
						workflow_download_macos_error="TRUE"
					fi
				fi
			else # [[ "${workflow_macos_auth}" == "USER" ]] || [[ "${workflow_macos_auth}" == "FAILOVER" ]]
				if [[ "${dialog_user_auth_valid}" != "TRUE" ]]; then
					dialog_user_auth_type="DOWNLOAD"
					dialog_user_auth
					unset dialog_user_auth_type
					[[ "${dialog_user_auth_error}" == "TRUE" ]] && workflow_download_macos_error="TRUE"
				fi
			fi
		fi
			
		# If no errors, then start the appropriate authenticated download workflow.
		if [[ "${workflow_download_macos_error}" == "FALSE" ]]; then
			[[ "${workflow_install_now_active}" == "TRUE" ]] && notification_install_now_download
			if [[ "${workflow_macos_auth}" == "LOCAL" ]] || [[ "${workflow_macos_auth}" == "USER" ]] || [[ "${workflow_macos_auth}" == "FAILOVER" ]]; then
				download_macos_msu
				[[ "${download_maocs_msu_error}" == "TRUE" ]] && workflow_download_macos_error="TRUE"
				[[ "${download_maocs_msu_error}" == "FALSE" ]] && workflow_download_macos_check_user="TRUE"
			else # [[ "${workflow_macos_auth}" == "JAMF" ]]
				push_macos_mdm_workflow="DOWNLOAD"
				push_macos_mdm
				unset push_macos_mdm_workflow
				[[ "${push_macos_mdm_download_error}" == "TRUE" ]] && workflow_download_macos_error="TRUE"
				[[ "${push_macos_mdm_download_error}" == "FALSE" ]] && workflow_download_macos_check_user="TRUE"
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_download_macos_error is: ${workflow_download_macos_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_download_macos_check_user is: ${workflow_download_macos_check_user}"
	
	# Handle download workflow failures.
	if [[ "${workflow_download_macos_error}" == "TRUE" ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_super "Error: Download macOS update/upgrade workflow failed, install now workflow can not continue."
			log_status "Inactive Error: Download macOS update/upgrade workflow failed, install now workflow can not continue."
			notification_install_now_failed
			exit_error
		else # Default super workflow.
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Error: Download macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Download macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
}

# MARK: *** Installation & Restart ***
################################################################################

# Install only non-system macOS software updates via the softwareupdate command, and also save responses to ${SUPER_LOG} and ${MSU_WORKFLOW_LOG}.
install_non_system_msu() {
	install_non_system_msu_error="TRUE"
	log_super "softwareupdate: Starting non-system macOS software updates installation workflow, check ${MSU_WORKFLOW_LOG} for more detail."
	log_status "Running: softwareupdate: Starting non-system macOS software updates installation workflow."
	log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL NON-SYSTEM UPDATES VIA SOFTWAREUPDATE START ****"
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=$' '
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: non_system_msu_labels_array is:\n${non_system_msu_labels_array[*]}"
	
	# The update process is backgrounded and is watched via a while loop later on. Also note the different requirements between macOS versions.
	local download_macos_msu_pid
	if [[ ${macos_version_major} -ge 12 ]]; then
		if [[ "${current_user_account_name}" == "FALSE" ]]; then
			sudo -i softwareupdate --install "${non_system_msu_labels_array[@]}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		else # Local user is logged in.
			launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" softwareupdate --install "${non_system_msu_labels_array[@]}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			download_macos_msu_pid="$!"
		fi
	else # macOS 11
		softwareupdate --install "${non_system_msu_labels_array[@]}" --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
		download_macos_msu_pid="$!"
	fi
	
	# Watch ${MSU_WORKFLOW_LOG} while waiting for the softwareupdate installation workflow to complete.
	# Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS} then changes to ${TIMEOUT_non_system_msu_SECONDS}.
	local install_non_system_msu_start_timeout
	install_non_system_msu_start_timeout="TRUE"
	local install_non_system_msu_start_error
	install_non_system_msu_start_error="TRUE"
	local install_non_system_msu_timeout_error
	install_non_system_msu_timeout_error="TRUE"
	local install_non_system_msu_timeout_seconds
	install_non_system_msu_timeout_seconds="${TIMEOUT_START_SECONDS}"
	local install_non_system_msu_installed_title
	local install_non_system_msu_installed_titles_array
	install_non_system_msu_installed_titles_array=()
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_non_system_msu_timeout_seconds is: ${install_non_system_msu_timeout_seconds}"
	while read -t "${install_non_system_msu_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c "Can’t connect") -gt 0 ]] || [[ $(echo "${log_line}" | grep -c "Couldn't communicate") -gt 0 ]] || [[ $(echo "${log_line}" | grep -c 'No such update') -gt 0 ]]; then
			install_non_system_msu_start_timeout="FALSE"
			break
		elif [[ $(echo "${log_line}" | grep -c 'Downloading') -gt 0 ]]; then
			macos_msu_title_downloaded=$(echo "${log_line}" | sed -e 's/://' | awk -F 'Downloading ' '{print $2;}')
			log_super "softwareupdate: ${macos_msu_title_downloaded} is downloading..."
			log_msu "**** TIMESTAMP ****"
			install_non_system_msu_timeout_seconds="${TIMEOUT_non_system_msu_SECONDS}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_non_system_msu_timeout_seconds is: ${install_non_system_msu_timeout_seconds}"
			install_non_system_msu_start_timeout="FALSE"
			install_non_system_msu_start_error="FALSE"
		elif [[ $(echo "${log_line}" | grep -c 'Downloaded') -gt 0 ]]; then
			macos_msu_title_downloaded=$(echo "${log_line}" | sed -e 's/://' | awk -F 'Downloaded ' '{print $2;}')
			log_super "softwareupdate: ${macos_msu_title_downloaded} download complete."
			install_non_system_msu_timeout_seconds="${TIMEOUT_non_system_msu_SECONDS}"
			log_msu "**** TIMESTAMP ****"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_non_system_msu_timeout_seconds is: ${install_non_system_msu_timeout_seconds}"
			install_non_system_msu_start_timeout="FALSE"
			install_non_system_msu_start_error="FALSE"
		elif [[ $(echo "${log_line}" | grep -c 'Done with') -gt 0 ]]; then
			install_non_system_msu_installed_title=$(echo "${log_line}" | sed -e 's/://' | awk -F 'Done with ' '{print $2;}')
			log_super "softwareupdate: ${install_non_system_msu_installed_title} installed."
			install_non_system_msu_installed_titles_array+=("${install_non_system_msu_installed_title}")
			log_msu "**** TIMESTAMP ****"
			install_non_system_msu_start_timeout="FALSE"
			install_non_system_msu_start_error="FALSE"
		elif [[ $(echo "${log_line}" | grep -c 'Done.') -gt 0 ]]; then
			log_msu "**** TIMESTAMP ****"
			install_non_system_msu_timeout_error="FALSE"
			break
		fi
	done < <(tail -n1 -F "${MSU_WORKFLOW_LOG}")
	
	# If the softwareupdate installation workflow completed, then validate and collect information.
	if [[ "${install_non_system_msu_start_timeout}" == "FALSE" ]] && [[ "${install_non_system_msu_start_error}" == "FALSE" ]] && [[ "${install_non_system_msu_timeout_error}" == "FALSE" ]]; then
		local previous_ifs
		previous_ifs="${IFS}"
		IFS=$'\n'
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: non_system_msu_titles_array is:\n${non_system_msu_titles_array[*]}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_non_system_msu_installed_titles_array is:\n${install_non_system_msu_installed_titles_array[*]}"
		if [[ ! $(echo -e "${non_system_msu_titles_array[*]}\n${install_non_system_msu_installed_titles_array[*]}" | sort | uniq -u) ]]; then
			log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL NON-SYSTEM UPDATES VIA SOFTWAREUPDATE COMPLETED ****"
			install_non_system_msu_error="FALSE"
		else # The expected ${non_system_msu_titles_array} did not match the ${install_non_system_msu_installed_titles_array}.
			log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL NON-SYSTEM UPDATES VIA SOFTWAREUPDATE INCOMPLETE ****"
			log_msu "Error: Installation of non-system macOS software updates did not complete."
			log_super "Error: Installation of non-system macOS software updates did not complete."
		fi
	else # The softwareupdate installation workflow failed.
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL NON-SYSTEM UPDATES VIA SOFTWAREUPDATE FAILED ****"
		if [[ "${install_non_system_msu_start_timeout}" == "TRUE" ]]; then
			log_msu "Error: Installation of non-system macOS software updates failed to start after waiting for ${install_non_system_msu_timeout_seconds} seconds."
			log_super "Error: Installation of non-system macOS software updates failed to start after waiting for ${install_non_system_msu_timeout_seconds} seconds."
		elif [[ "${install_non_system_msu_start_error}" == "TRUE" ]]; then
			log_msu "Error: Unable to reach macOS software update server."
			log_super "Error: Unable to reach macOS software update server."
		elif [[ "${install_non_system_msu_timeout_error}" == "TRUE" ]]; then
			log_msu "Error: Installation of non-system macOS software updates failed, as indicated by no progress after waiting for ${install_non_system_msu_timeout_seconds} seconds."
			log_super "Error: Installation of non-system macOS software updates failed, as indicated by no progress after waiting for ${install_non_system_msu_timeout_seconds} seconds."
		fi
		kill -9 "${download_macos_msu_pid}" >/dev/null 2>&1
		kick_softwareupdated
	fi
	IFS="${previous_ifs}"
}

# Install macOS updates via the softwareupdate command, and also save responses to ${SUPER_LOG}, ${MSU_WORKFLOW_LOG}, and ${SUPER_LOCAL_PLIST}.
install_macos_msu() {
	[[ "${current_user_account_name}" != "FALSE" ]] && notification_restart
	# If ${test_mode_option} then it's not necessary to continue this function.
	if [[ "${test_mode_option}" == "TRUE" ]]; then
		[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
		log_super "Test Mode: Skipping the macOS update/upgrade via softwareupdate workflow."
		if [[ "${current_user_account_name}" != "FALSE" ]]; then
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the restart notification..."
			sleep "${test_mode_timeout_seconds}"
			killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
		fi
		# Reset various items after test macOS update is complete.
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null
		reset_schedule_zero_date
		reset_deadline_counters
		return 0
	fi
	
	# Start with log and status updates.
	if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]]; then # macOS major upgrade via MSU.
		if [[ "${macos_msu_download_required}" == "TRUE" ]]; then # If no ${current_user_account_name} then the sytem update was not pre-downloaded.
			log_super "softwareupdate: Starting ${macos_msu_label} download and upgrade workflow, check ${MSU_WORKFLOW_LOG} for more detail."
			log_status "Running: softwareupdate: Starting ${macos_msu_label} download and upgrade workflow."
			log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD AND UPGRADE ${macos_msu_label} VIA SOFTWAREUPDATE START ****"
		else
			log_super "softwareupdate: Starting ${macos_msu_label} upgrade workflow, check ${MSU_WORKFLOW_LOG} for more detail."
			log_status "Running: softwareupdate: Starting ${macos_msu_label} upgrade workflow."
			log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - UPGRADE ${macos_msu_label} VIA SOFTWAREUPDATE START ****"
		fi
	else # macOS minor update via MSU.
		if [[ "${macos_msu_download_required}" == "TRUE" ]]; then # If no ${current_user_account_name} then the sytem update was not pre-downloaded.
			log_super "softwareupdate: Starting ${macos_msu_label} download and update workflow, check ${MSU_WORKFLOW_LOG} for more detail."
			log_status "Running: softwareupdate: Starting ${macos_msu_label} download and update workflow."
			log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD AND UPDATE ${macos_msu_label} VIA SOFTWAREUPDATE START ****"
		else
			log_super "softwareupdate: Starting ${macos_msu_label} update workflow, check ${MSU_WORKFLOW_LOG} for more detail."
			log_status "Running: softwareupdate: Starting ${macos_msu_label} update workflow."
			log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - UPDATE ${macos_msu_label} VIA SOFTWAREUPDATE START ****"
		fi
	fi
	
	# The update/upgrade process is backgrounded and is watched via while loops later on. Also note the different requirements between macOS versions.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_label is: ${macos_msu_label}"
	local install_macos_msu_pid
	if [[ "${macos_version_major}" -ge 13 ]]; then # macOS 13+
		if [[ "${current_user_account_name}" == "FALSE" ]]; then # Local user not is logged in.
			if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
				echo "${auth_local_password}" | sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license --user "${auth_local_account}" --stdinpass >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			else # Intel.
				sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			fi
		else # Local user is logged in.
			if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
				echo "${auth_local_password}" | launchctl asuser "${current_user_id}" sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license --user "${auth_local_account}" --stdinpass >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			else # Intel.
				launchctl asuser "${current_user_id}" sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			fi
		fi
	elif [[ "${macos_version_major}" -ge 12 ]]; then # macOS 12
		if [[ "${current_user_account_name}" == "FALSE" ]]; then # Local user not is logged in.
			if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
				sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license --user "${auth_local_account}" --stdinpass "${auth_local_password}" >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			else # Intel.
				sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			fi
		else # Local user is logged in.
			if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
				launchctl asuser "${current_user_id}" sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license --user "${auth_local_account}" --stdinpass "${auth_local_password}" >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			else # Intel.
				launchctl asuser "${current_user_id}" sudo -u root softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
				install_macos_msu_pid="$!"
			fi
		fi
	else # macOS 11
		if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
			echo ' ' | softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			install_macos_msu_pid="$!"
		else # Intel.
			softwareupdate --install "${macos_msu_label}" --restart --force --no-scan --agree-to-license >>"${MSU_WORKFLOW_LOG}" 2>&1 &
			install_macos_msu_pid="$!"
		fi
	fi
	disown -a
	
	# Watch ${MSU_WORKFLOW_LOG} while waiting for the softwareupdate installation workflow to complete.
	# Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS} then changes to ${TIMEOUT_MSU_SYSTEM_SECONDS}.
	local install_macos_msu_start_error
	install_macos_msu_start_error="TRUE"
	local install_macos_msu_start_timeout
	install_macos_msu_start_timeout="TRUE"
	local install_macos_msu_timeout_error
	install_macos_msu_timeout_error="TRUE"
	local install_macos_msu_timeout_seconds
	install_macos_msu_timeout_seconds="${TIMEOUT_START_SECONDS}"
	local install_macos_msu_phase
	install_macos_msu_phase="START"
	local install_macos_msu_complete_percent
	install_macos_msu_complete_percent=0
	local install_macos_msu_complete_percent_previous
	install_macos_msu_complete_percent_previous=0
	local install_macos_msu_complete_percent_display
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_timeout_seconds is: ${install_macos_msu_timeout_seconds}"
	while read -t "${install_macos_msu_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c "Can’t connect") -gt 0 ]] || [[ $(echo "${log_line}" | grep -c "Couldn't communicate") -gt 0 ]] || [[ $(echo "${log_line}" | grep -c 'No such update') -gt 0 ]] || [[ $(echo "${log_line}" | grep -c 'Failed to download') -gt 0 ]]; then
			break
		elif [[ $(echo "${log_line}" | grep -c 'Downloading') -gt 0 ]] && [[ $(echo "${log_line}" | grep -c 'Downloading:') -eq 0 ]]; then
			macos_msu_title_downloaded="${log_line/Downloading /}"
			log_super "softwareupdate: ${macos_msu_title_downloaded} is downloading..."
			log_msu "**** TIMESTAMP ****"
			install_macos_msu_timeout_seconds="${TIMEOUT_MSU_SYSTEM_SECONDS}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_timeout_seconds is: ${install_macos_msu_timeout_seconds}"
			install_macos_msu_start_error="FALSE"
			[[ $(echo "${macos_msu_title_downloaded}" | grep -c 'macOS') -gt 0 ]] && install_macos_msu_phase="DOWNLOADING"
		elif [[ $(echo "${log_line}" | grep -c 'Downloading:') -gt 0 ]] && [[ "${install_macos_msu_phase}" == "DOWNLOADING" ]]; then
			install_macos_msu_complete_percent=$(echo "${log_line}" | sed -e 's/Downloading: //' -e 's/\.[0-9][0-9]//' | tr -d '\n' | tr -d '\r')
			install_macos_msu_complete_percent=${install_macos_msu_complete_percent#0}
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_complete_percent is: ${install_macos_msu_complete_percent}"
			if [[ $install_macos_msu_complete_percent -ge 60 ]]; then
				log_echo_replace_line "${macos_msu_title_downloaded} download progress: 100%\n"
				log_super "softwareupdate: ${macos_msu_title_downloaded} download complete, now preparing..."
				log_msu "**** TIMESTAMP ****"
				install_macos_msu_phase="PREPARING"
			elif [[ $install_macos_msu_complete_percent -gt $install_macos_msu_complete_percent_previous ]]; then
				install_macos_msu_complete_percent_display=$( (echo "$install_macos_msu_complete_percent * 1.69" | bc) | cut -d '.' -f1)
				log_echo_replace_line "${macos_msu_title_downloaded} download progress: ${install_macos_msu_complete_percent_display}%"
				install_macos_msu_complete_percent_previous=$install_macos_msu_complete_percent
			fi
		elif [[ $(echo "${log_line}" | grep -c 'Downloading:') -gt 0 ]] && [[ "${install_macos_msu_phase}" == "PREPARING" ]]; then
			install_macos_msu_complete_percent=$(echo "${log_line}" | sed -e 's/Downloading: //' -e 's/\.[0-9][0-9]//' | tr -d '\n' | tr -d '\r')
			install_macos_msu_complete_percent=${install_macos_msu_complete_percent#0}
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_complete_percent is: ${install_macos_msu_complete_percent}"
			if [[ $install_macos_msu_complete_percent -ge 100 ]]; then
				log_echo_replace_line "${macos_msu_title_downloaded} preparing progress: 100%\n"
				log_msu "**** TIMESTAMP ****"
				install_macos_msu_start_error="FALSE"
				install_macos_msu_start_timeout="FALSE"
				install_macos_msu_timeout_error="FALSE"
				break
			elif [[ $install_macos_msu_complete_percent -gt $install_macos_msu_complete_percent_previous ]]; then
				install_macos_msu_complete_percent_display=$(((install_macos_msu_complete_percent - 60) * 2))
				log_echo_replace_line "${macos_msu_title_downloaded} preparing progress: ${install_macos_msu_complete_percent_display}%"
				install_macos_msu_complete_percent_previous=$install_macos_msu_complete_percent
			fi
		elif [[ $(echo "${log_line}" | grep -c 'Downloaded') -gt 0 ]]; then
			macos_msu_title_downloaded=$(echo "${log_line}" | sed -e 's/://' -e 's/Downloaded //')
			log_msu "**** TIMESTAMP ****"
			install_macos_msu_start_error="FALSE"
			install_macos_msu_start_timeout="FALSE"
			install_macos_msu_timeout_error="FALSE"
			break
		fi
	done < <(tail -n1 -F "${MSU_WORKFLOW_LOG}" | tr -u '%' '\n')
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_start_error is: ${install_macos_msu_start_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_start_timeout is: ${install_macos_msu_start_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_msu_timeout_error is: ${install_macos_msu_timeout_error}"
	
	# If the softwareupdate installation workflow completed, then prepare for restart.
	if [[ "${install_macos_msu_start_error}" == "FALSE" ]] && [[ "${install_macos_msu_start_timeout}" == "FALSE" ]] && [[ "${install_macos_msu_timeout_error}" == "FALSE" ]]; then
		/usr/libexec/PlistBuddy -c "Add :WorkflowRestartValidate bool true" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
		[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && /usr/libexec/PlistBuddy -c "Delete :WorkflowScheduledInstall" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - UPDATE/UPGRADE MACOS VIA SOFTWAREUPDATE COMPLETED ****"
		log_super "softwareupdate: macOS update/upgrade is prepared and ready for restart!"
	else # Some part of the softwareupdate installation workflow failed.
		if [[ "${install_macos_msu_start_error}" == "TRUE" ]]; then
			log_msu "Error: The softwareupdate process was unable to reach macOS software update servers or find the requested macOS update/upgrade."
			log_super "Error: The softwareupdate process was unable to reach macOS software update servers or find the requested macOS update/upgrade."
		elif [[ "${install_macos_msu_start_timeout}" == "TRUE" ]]; then
			log_msu "Error: Installation of macOS update/upgrade via softwareupdate failed to start downloading/preparing after waiting for ${install_macos_msu_timeout_seconds} seconds."
			log_super "Error: Installation of macOS update/upgrade via softwareupdate failed to start downloading/preparing after waiting for ${install_macos_msu_timeout_seconds} seconds."
		else # ${install_macos_msu_timeout_error}" == "TRUE"
			log_msu "Error: Installation of macOS update/upgrade via softwareupdate failed while downloading/preparing, as indicated by no progress after waiting for ${install_macos_msu_timeout_seconds} seconds."
			log_super "Error: Installation of macOS update/upgrade via softwareupdate failed while downloading/preparing, as indicated by no progress after waiting for ${install_macos_msu_timeout_seconds} seconds."
		fi
		log_msu "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - UPDATE/UPGRADE MACOS VIA SOFTWAREUPDATE FAILED ****"
		kill -9 "${install_macos_msu_pid}" >/dev/null 2>&1
		kick_softwareupdated
	
		# Handle workflow failure options.
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_msu "Error: Installation of macOS update/upgrade via softwareupdate failed, install now workflow can not continue."
			log_super "Error: Installation of macOS update/upgrade via softwareupdate failed, install now workflow can not continue."
			log_status "Inactive Error: Installation of macOS update/upgrade via softwareupdate failed, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
			exit_error
		else # Default super workflow.
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_msu "Error: Installation of macOS update/upgrade via softwareupdate failed, trying again in ${deferral_timer_minutes} minutes."
			log_super "Error: Installation of macOS update/upgrade via softwareupdate failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Installation of macOS update/upgrade via softwareupdate failed, trying again in ${deferral_timer_minutes} minutes."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_failed
			set_auto_launch_deferral
		fi
	fi
}

# Install macOS major upgrade via macOS installer application, and also save responses to ${SUPER_LOG}, ${INSTALLER_WORKFLOW_LOG}, and ${SUPER_LOCAL_PLIST}.
install_macos_app() {
	# If ${test_mode_option} then it's not necessary to continue this function.
	if [[ "${test_mode_option}" == "TRUE" ]]; then
		[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
		log_super "Test Mode: Skipping the macOS major upgrade via insaller workflow."
		if [[ "${current_user_account_name}" != "FALSE" ]]; then
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the macOS major upgrade via insaller preparation notification..."
			sleep "${test_mode_timeout_seconds}"
			notification_restart
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the restart notification..."
			sleep "${test_mode_timeout_seconds}"
			killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
		fi
		# Reset various items after test macOS update is complete.
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null
		reset_schedule_zero_date
		reset_deadline_counters
		return 0
	fi
	
	# Start with log and status updates.
	log_super "startosinstall: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} install upgrade workflow, check ${INSTALLER_WORKFLOW_LOG} for more detail."
	log_status "Running: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} install upgrade workflow."
	log_installer "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} START ****"
	
	# Background the startosinstall process and send to ${INSTALLER_WORKFLOW_LOG}.
	if [[ "${mac_cpu_architecture}" == "arm64" ]]; then # Apple Silicon.
		"/Applications/Install ${macos_installer_title}.app/Contents/Resources/startosinstall" --agreetolicense --forcequitapps --user "${auth_local_account}" --stdinpass <<<"${auth_local_password}" >>"${INSTALLER_WORKFLOW_LOG}" 2>&1 &
	else # Intel.
		"/Applications/Install ${macos_installer_title}.app/Contents/Resources/startosinstall" --agreetolicense --forcequitapps >>"${INSTALLER_WORKFLOW_LOG}" 2>&1 &
	fi
	local install_macos_app_pid
	install_macos_app_pid="$!"
	
	# Watch ${INSTALLER_WORKFLOW_LOG} while waiting for the startosinstall process to complete.
	# Note this while read loop has a timeout based on ${TIMEOUT_START_SECONDS} then changes to ${TIMEOUT_INSTALLER_WORKFLOW_SECONDS}.
	local install_macos_app_start_error
	install_macos_app_start_error="TRUE"
	local install_macos_app_start_timeout
	install_macos_app_start_timeout="TRUE"
	local install_macos_app_timeout
	install_macos_app_timeout="TRUE"
	local install_macos_app_timeout_seconds
	install_macos_app_timeout_seconds="${TIMEOUT_START_SECONDS}"
	local install_macos_app_phase
	install_macos_app_phase="START"
	local install_macos_app_complete_percent
	install_macos_app_complete_percent=0
	local install_macos_app_complete_percent_previous
	install_macos_app_complete_percent_previous=0
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_app_timeout_seconds is: ${install_macos_app_timeout_seconds}"
	while read -t "${install_macos_app_timeout_seconds}" -r log_line; do
		# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
		if [[ $(echo "${log_line}" | grep -c 'Preparing to run') -gt 0 ]]; then
			log_super "startosinstall: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} preparing installation..."
			log_installer "**** TIMESTAMP ****"
			install_macos_app_phase="PREPARING"
			install_macos_app_timeout_seconds="${TIMEOUT_INSTALLER_WORKFLOW_SECONDS}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_app_timeout_seconds is: ${install_macos_app_timeout_seconds}"
			install_macos_app_start_error="FALSE"
		elif [[ $(echo "${log_line}" | grep -c 'Preparing:') -gt 0 ]] && [[ "${install_macos_app_phase}" == "PREPARING" ]]; then
			install_macos_app_start_timeout="FALSE"
			install_macos_app_complete_percent=$(echo "${log_line}" | sed -e 's/Preparing: //' -e 's/\.[0-9]//' | tr -d '\n' | tr -d '\r')
			install_macos_app_complete_percent=${install_macos_app_complete_percent#0}
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_app_complete_percent is: ${install_macos_app_complete_percent}"
			if [[ $install_macos_app_complete_percent -ge 99 ]]; then
				log_installer "**** TIMESTAMP ****"
				log_echo_replace_line "${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installation preparing progress: 100%\n"
				install_macos_app_timeout="FALSE"
				break
			elif [[ $install_macos_app_complete_percent -gt $install_macos_app_complete_percent_previous ]]; then
				log_echo_replace_line "${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installation preparing progress: ${install_macos_app_complete_percent}%"
				install_macos_app_complete_percent_previous=$install_macos_app_complete_percent
			fi
		elif [[ $(echo "${log_line}" | grep -c -e 'Preparing: 99' -e 'Preparing: 100' -e 'Restarting') -gt 0 ]]; then
			log_installer "**** TIMESTAMP ****"
			log_echo_replace_line "${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installation preparing progress: 100%\n"
			install_macos_app_start_error="FALSE"
			install_macos_app_start_timeout="FALSE"
			install_macos_app_timeout="FALSE"
			break
		fi
	done < <(tail -n1 -F "${INSTALLER_WORKFLOW_LOG}" | tr -u '%' '\n')
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_app_start_error is: ${install_macos_app_start_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_app_start_timeout is: ${install_macos_app_start_timeout}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_macos_app_timeout is: ${install_macos_app_timeout}"
	
	# If the startosinstall workflow completed, then prepare for restart.
	if [[ "${install_macos_app_start_error}" == "FALSE" ]] && [[ "${install_macos_app_start_timeout}" == "FALSE" ]] && [[ "${install_macos_app_timeout}" == "FALSE" ]]; then
		/usr/libexec/PlistBuddy -c "Add :WorkflowRestartValidate bool true" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
		[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && /usr/libexec/PlistBuddy -c "Delete :WorkflowScheduledInstall" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
		log_installer "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL MACOS COMPLETED ****"
		log_super "Status: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} is prepared and ready for restart!"
		[[ "${current_user_account_name}" != "FALSE" ]] && notification_restart
	else # Some part of the startosinstall workflow failed.
		log_installer "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL MACOS FAILED ****"
		kill -9 "${install_macos_app_pid}" >/dev/null 2>&1
		if [[ "${install_macos_app_start_error}" == "TRUE" ]]; then
			log_installer "Error: Installation of macOS major upgrade via installer application failed to start."
			log_super "Error: Installation of macOS major upgrade via installer application failed to start."
		elif [[ "${install_macos_app_start_timeout}" == "TRUE" ]]; then
			log_installer "Error: Installation of macOS major upgrade via installer application failed to start preparing after waiting for ${install_macos_app_timeout_seconds} seconds."
			log_super "Error: Installation of macOS major upgrade via installer application failed to start preparing after waiting for ${install_macos_app_timeout_seconds} seconds."
		else # "${install_macos_app_timeout}" == "TRUE"
			log_installer "Error: Installation of macOS major upgrade via installer application failed to prepare, as indicated by no progress after waiting for ${install_macos_app_timeout_seconds} seconds."
			log_super "Error: Installation of macOS major upgrade via installer application failed to prepare, as indicated by no progress after waiting for ${install_macos_app_timeout_seconds} seconds."
		fi
		
		# Handle workflow failure options.
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_installer "Error: Installation of macOS major upgrade via installer application failed, install now workflow can not continue."
			log_super "Error: Installation of macOS major upgrade via installer application failed, install now workflow can not continue."
			log_status "Inactive Error: Installation of macOS major upgrade via installer application failed, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
			exit_error
		else # Default super workflow.
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_installer "Error: Installation of macOS major upgrade via installer application failed, trying again in ${deferral_timer_minutes} minutes."
			log_super "Error: Installation of macOS major upgrade via installer application failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Installation of macOS major upgrade via installer application failed, trying again in ${deferral_timer_minutes} minutes."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_failed
			set_auto_launch_deferral
		fi
	fi
}

# Download and/or install macOS update/upgrade via MDM push command, and also save responses to ${SUPER_LOG}, ${MDM_COMMAND_LOG}, ${MDM_WORKFLOW_LOG}, and ${SUPER_LOCAL_PLIST}.
push_macos_mdm() {
	# If ${test_mode_option} then it's not necessary to continue this function.
	if [[ "${test_mode_option}" == "TRUE" ]] && [[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]]; then
		log_super "Test Mode: Skipping the download macOS update/upgrade via MDM workflow."
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for install now download notification..."
			sleep "${test_mode_timeout_seconds}"
		fi
		push_macos_mdm_download_error="FALSE"
		return 0
	elif [[ "${test_mode_option}" == "TRUE" ]]; then # [[ "${push_macos_mdm_workflow}" == "INSTALL" ]]
		[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
		log_super "Test Mode: Skipping the install macOS update/upgrade via MDM workflow."
		if [[ "${current_user_account_name}" != "FALSE" ]]; then
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the MDM preparation notification..."
			sleep "${test_mode_timeout_seconds}"
			notification_restart
			log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the restart notification..."
			sleep "${test_mode_timeout_seconds}"
			killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
		fi
		# Reset various items after test macOS update is complete.
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null
		reset_schedule_zero_date
		reset_deadline_counters
		return 0
	fi
	
	# Start with log and status updates.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_workflow is: ${push_macos_mdm_workflow}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_download_required is: ${macos_msu_download_required}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_mdm_failover_to_user_status is: ${auth_mdm_failover_to_user_status}"
	local push_macos_mdm_target_type
	local push_macos_mdm_target_version
	if [[ "${macos_installer_target}" != "FALSE" ]]; then # Target is a macOS major upgrade via installer.
		push_macos_mdm_target_type="INSTALLER"
		push_macos_mdm_target_version="${macos_installer_version}"
		if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]]; then
			log_super "MDM: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} install workflow with user authenticated failover."
			log_status "Running: MDM: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} install workflow with user authenticated failover."
		else
			log_super "MDM: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} install workflow."
			log_status "Running: MDM: Starting ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} install workflow."
		fi
		log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} VIA MDM START ****"
		log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} VIA MDM START ****"
	fi
	if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] || [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then # Target is a macOS update/upgrade via MSU.
		[[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] && push_macos_mdm_target_type="UPGRADE"
		[[ "${macos_msu_minor_update_target}" != "FALSE" ]] && push_macos_mdm_target_type="UPDATE"
		push_macos_mdm_target_version="${macos_msu_version}"
		if [[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]]; then
			if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]]; then
				log_super "MDM: Starting macOS ${macos_msu_version} download workflow with user authenticated failover."
				log_status "Running: MDM: Starting macOS ${macos_msu_version} download workflow with user authenticated failover."
			else
				log_super "MDM: Starting macOS ${macos_msu_version} download workflow."
				log_status "Running: MDM: Starting macOS ${macos_msu_version} download workflow."
			fi
			log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS ${macos_msu_version} VIA MDM START ****"
			log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS ${macos_msu_version} VIA MDM START ****"
		elif [[ "${macos_msu_download_required}" == "TRUE" ]]; then
			if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]]; then
				log_super "MDM: Starting macOS ${macos_msu_version} download and update/upgrade workflow with user authenticated failover."
				log_status "Running: MDM: Starting macOS ${macos_msu_version} download and update/upgrade workflow with user authenticated failover."
			else
				log_super "MDM: Starting macOS ${macos_msu_version} download and update/upgrade workflow."
				log_status "Running: MDM: Starting macOS ${macos_msu_version} download and update/upgrade workflow."
			fi
			log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD AND UPDATE/UPGRADE MACOS ${macos_msu_version} VIA MDM START ****"
			log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD AND UPDATE/UPGRADE MACOS ${macos_msu_version} VIA MDM START ****"
		else # Install workflow.
			if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]]; then
				log_super "MDM: Starting macOS ${macos_msu_version} update/upgrade workflow with user authenticated failover."
				log_status "Running: MDM: Starting macOS ${macos_msu_version} update/upgrade workflow with user authenticated failover."
			else
				log_super "MDM: Starting macOS ${macos_msu_version} update/upgrade workflow."
				log_status "Running: MDM: Starting macOS ${macos_msu_version} update/upgrade workflow."
			fi
			log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - UPDATE/UPGRADE MACOS ${macos_msu_version} VIA MDM START ****"
			log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - UPDATE/UPGRADE MACOS ${macos_msu_version} VIA MDM START ****"
		fi
	fi
	log_super "MDM: check ${MDM_COMMAND_LOG} and ${MDM_WORKFLOW_LOG} for more detail."
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_target_type is: ${push_macos_mdm_target_type}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_target_version is: ${push_macos_mdm_target_version}"
	
	# Validate Jamf Pro API token and update workflow.
	check_jamf_api_access_token
	check_jamf_api_update_workflow
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_error_jamf is: ${auth_error_jamf}"
	
	# Only continue workflow if Jamf Pro API configuration is valid.
	if [[ "${auth_error_jamf}" == "FALSE" ]]; then
		# Start log streaming for MDM push commands and send to ${MDM_COMMAND_LOG}.
		local log_stream_mdm_command_pid
		log stream --style compact --predicate 'subsystem == "com.apple.ManagedClient" AND category == "HTTPUtil"' >> "${MDM_COMMAND_LOG}" &
		log_stream_mdm_command_pid="$!"
		if [[ "${verbose_mode_option}" == "TRUE" ]]; then
			log_super "Verbose Mode: Starting debug log for MDM client command progress at: ${MDM_COMMAND_DEBUG_LOG}"
			local log_stream_mdm_command_debug_pid
			log stream --style compact --predicate 'subsystem == "com.apple.ManagedClient"' >>"${MDM_COMMAND_DEBUG_LOG}" &
			log_stream_mdm_command_debug_pid="$!"
		fi
		
		# Start log streaming for MDM update/upgrade progress and send to ${MDM_WORKFLOW_LOG}.
		local log_stream_mdm_workflow_pid
		log stream --style compact --predicate 'process == "softwareupdated" AND composedMessage CONTAINS "Reported progress"' >>"${MDM_WORKFLOW_LOG}" &
		log_stream_mdm_workflow_pid="$!"
		if [[ "${verbose_mode_option}" == "TRUE" ]]; then
			log_super "Verbose Mode: Starting debug log for MDM update/upgrade workflow progress at: ${MDM_WORKFLOW_DEBUG_LOG}"
			local log_stream_mdm_workflow_debug_pid
			log stream --style compact --predicate 'process == "softwareupdated"' >>"${MDM_WORKFLOW_DEBUG_LOG}" &
			log_stream_mdm_workflow_debug_pid="$!"
		fi
		
		# Send the Jamf Pro API command to update/upgrade and restart via MDM.
		local push_macos_mdm_api_error
		push_macos_mdm_api_error="FALSE"
		local jamf_api_update_url
		local jamf_api_update_json
		if [[ "${jamf_api_update_workflow}" == "NEW" ]]; then # Jamf Pro API new managed update workflow.
			jamf_api_update_url="${jamf_api_url}api/v1/managed-software-updates/plans"
			if { [[ "${push_macos_mdm_target_type}" == "INSTALLER" ]] || [[ "${push_macos_mdm_target_type}" == "UPGRADE" ]]; } && { [[ "${macos_beta_program}" == "TRUE" ]] || [[ "${macos_major_upgrade_latest}" == "TRUE" ]]; }; then
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && jamf_api_update_json='{ "devices": [ { "objectType": "COMPUTER",  "deviceId": "'${jamf_computer_id}'" } ], "config": { "updateAction": "DOWNLOAD_ONLY", "versionType": "LATEST_MAJOR" } }'
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && jamf_api_update_json='{ "devices": [ { "objectType": "COMPUTER",  "deviceId": "'${jamf_computer_id}'" } ], "config": { "updateAction": "DOWNLOAD_INSTALL_RESTART", "versionType": "LATEST_MAJOR" } }'
			elif [[ "${macos_beta_program}" == "TRUE" ]] || [[ "${macos_minor_update_latest}" == "TRUE" ]]; then
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && jamf_api_update_json='{ "devices": [ { "objectType": "COMPUTER",  "deviceId": "'${jamf_computer_id}'" } ], "config": { "updateAction": "DOWNLOAD_ONLY", "versionType": "LATEST_MINOR" } }'
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && jamf_api_update_json='{ "devices": [ { "objectType": "COMPUTER",  "deviceId": "'${jamf_computer_id}'" } ], "config": { "updateAction": "DOWNLOAD_INSTALL_RESTART", "versionType": "LATEST_MINOR" } }'
			else # Non-latest macOS version targets must be called by their specific version number.
				log_super "Warning: Workflow target is not the latest macOS minor update or major upgrade. The Jamf Pro new Managed Software Updates API is unreliable when requesting specific older macOS versions."
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && jamf_api_update_json='{ "devices": [ { "objectType": "COMPUTER",  "deviceId": "'${jamf_computer_id}'" } ], "config": { "updateAction": "DOWNLOAD_ONLY", "versionType": "SPECIFIC_VERSION", "specificVersion": "'${push_macos_mdm_target_version}'" } }'
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && jamf_api_update_json='{ "devices": [ { "objectType": "COMPUTER",  "deviceId": "'${jamf_computer_id}'" } ], "config": { "updateAction": "DOWNLOAD_INSTALL_RESTART", "versionType": "SPECIFIC_VERSION", "specificVersion": "'${push_macos_mdm_target_version}'" } }'
			fi
		else # Jamf Pro API legacy managed update workflow.
			log_super "Warning: Workflow is using the Jamf Pro legacy macOS Managed Software Updates API. Although this API remains stable, it is now deprecated."
			jamf_api_update_url="${jamf_api_url}api/v1/macos-managed-software-updates/send-updates"
			if [[ "${push_macos_mdm_target_type}" == "INSTALLER" ]] || [[ "${push_macos_mdm_target_type}" == "UPGRADE" ]]; then # macOS major upgrade.
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && jamf_api_update_json='{ "deviceIds": ["'${jamf_computer_id}'"], "version": "'${push_macos_mdm_target_version}'", "skipVersionVerification": true, "updateAction": "DOWNLOAD_ONLY" }'
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && jamf_api_update_json='{ "deviceIds": ["'${jamf_computer_id}'"], "version": "'${push_macos_mdm_target_version}'", "skipVersionVerification": true, "updateAction": "DOWNLOAD_AND_INSTALL" }'
			else # macOS minor update.
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && jamf_api_update_json='{ "deviceIds": ["'${jamf_computer_id}'"], "version": "'${push_macos_mdm_target_version}'", "skipVersionVerification": true, "updateAction": "DOWNLOAD_ONLY" }'
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && jamf_api_update_json='{ "deviceIds": ["'${jamf_computer_id}'"], "version": "'${push_macos_mdm_target_version}'", "skipVersionVerification": true, "updateAction": "DOWNLOAD_AND_INSTALL", "forceRestart": true }'
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_api_update_workflow is: ${jamf_api_update_workflow}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_api_update_url is: ${jamf_api_update_url}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_api_update_json is: ${jamf_api_update_json}"
		local curl_response
		curl_response=$(curl --silent --output /dev/null --write-out "%{http_code}" --location --request POST "${jamf_api_update_url}" --header "Authorization: Bearer ${jamf_access_token}" --header 'accept: application/json' --header 'content-type: application/json' --data "${jamf_api_update_json}")
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is:\n${curl_response}"

		# If the Jamf Pro API managed update was not successful then it's not necessary to continue this function.
		if [[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]] || [[ $(echo "${curl_response}" | grep -c '201') -gt 0 ]]; then
			[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && log_super "MDM: Successful download macOS update/upgrade command request."
			[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && log_super "MDM: Successful install macOS update/upgrade command request."
			send_jamf_api_blank_push
		else
			push_macos_mdm_api_error="TRUE"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_api_error is: ${push_macos_mdm_api_error}"
	
	# Only continue workflow if Jamf Pro API managed update command was successful.
	if [[ "${auth_error_jamf}" == "FALSE" ]] && [[ "${push_macos_mdm_api_error}" == "FALSE" ]]; then
		# Some helpfull logging while waiting for Jamf Pro's mandatory 5 minute delay. Note this while read loop has a timeout based on ${TIMEOUT_MDM_COMMAND_SECONDS}.
		local push_macos_mdm_start_error
		push_macos_mdm_start_error="TRUE"
		while read -t "${TIMEOUT_MDM_COMMAND_SECONDS}" -r log_line; do
			# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
			if [[ $(echo "${log_line}" | grep -c 'Received HTTP response (200) \[Error') -gt 0 ]]; then
				log_super "MDM: Workflow error detected."
				log_mdm_command "**** TIMESTAMP ****"
				break
			elif [[ $(echo "${log_line}" | grep -c 'Received HTTP response (200) \[Acknowledged(ScheduleOSUpdateScan)') -gt 0 ]]; then
				log_super "MDM: Received push command \"ScheduleOSUpdateScan\", checking back after Jamf Pro's mandatory 5 minute delay..."
				log_mdm_command "**** TIMESTAMP ****"
				push_macos_mdm_start_error="FALSE"
				pkill -P $$ tail
				break
			fi
		done < <(tail -n1 -F "${MDM_COMMAND_LOG}")
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_start_error is: ${push_macos_mdm_start_error}"
	
	# Only continue workflow if the initial managed update commands were received.
	if [[ "${auth_error_jamf}" == "FALSE" ]] && [[ "${push_macos_mdm_api_error}" == "FALSE" ]] && [[ "${push_macos_mdm_start_error}" == "FALSE" ]]; then
		local push_macos_mdm_start_timeout
		push_macos_mdm_start_timeout="TRUE"
		local timer_end
		timer_end=300
		while [[ "${timer_end}" -ge 0 ]]; do
			log_echo_replace_line "Waiting for Jamf Pro's mandatory 5 minute delay: -$(date -u -r ${timer_end} +%M:%S)"
			timer_end=$((timer_end - 1))
			sleep 1
		done
		log_echo_replace_line "Waiting for Jamf Pro's mandatory 5 minute delay: 00:00\n)"
		log_super "MDM: Jamf Pro's mandatory 5 minute delay should be complete, sending Blank Push..."
		send_jamf_api_blank_push
		if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${push_macos_mdm_workflow}" == "INSTALL" ]]; then
			if [[ "${push_macos_mdm_target_type}" == "INSTALLER" ]]; then
				display_string_prepare_time_estimate="20-25"
				notification_prepare
			else
				notification_restart
			fi
		fi
		
		# Watch ${MDM_COMMAND_LOG} while waiting for the MDM workflow to complete. Note this while read loop has a timeout based on ${TIMEOUT_MDM_COMMAND_SECONDS}.
		while read -t "${TIMEOUT_MDM_COMMAND_SECONDS}" -r log_line; do
			# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
			if [[ $(echo "${log_line}" | grep -c 'Received HTTP response (200) \[Error') -gt 0 ]]; then
				if [[ $(echo "${log_line}" | grep -c 'DeclarativeManagement') -gt 0 ]] && [[ "${macos_version_major}" -lt 14 ]]; then
					log_super "MDM: DDM error detected but it should be ignored by older versions of macOS."
				else
					log_super "MDM: Command error detected."
					log_mdm_command "**** TIMESTAMP ****"
					push_macos_mdm_start_error="TRUE"
					break
				fi
			elif [[ $(echo "${log_line}" | grep -c 'Received HTTP response (200) \[Idle\]') -gt 0 ]]; then
				log_super "MDM: Received blank push."
				log_mdm_command "**** TIMESTAMP ****"
			elif [[ $(echo "${log_line}" | grep -c 'Received HTTP response (200) \[Acknowledged(AvailableOSUpdates)') -gt 0 ]]; then
				log_super "MDM: Received push command \"AvailableOSUpdates\"."
				log_mdm_command "**** TIMESTAMP ****"
			elif [[ $(echo "${log_line}" | grep -c 'Received HTTP response (200) \[Acknowledged(ScheduleOSUpdate)') -gt 0 ]]; then
				kill -9 "${log_stream_mdm_command_pid}" >/dev/null 2>&1
				[[ "${verbose_mode_option}" == "TRUE" ]] && kill -9 "${log_stream_mdm_command_debug_pid}" >/dev/null 2>&1
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD MACOS VIA MDM COMMAND COMPLETED ****"
				[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && log_super "MDM: Received push command \"ScheduleOSUpdate\", local download should start soon..."
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL MACOS VIA MDM COMMAND COMPLETED ****"
				[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && log_super "MDM: Received push command \"ScheduleOSUpdate\", local update/upgrade should start soon..."
				push_macos_mdm_start_timeout="FALSE"
				break
			fi
		done < <(tail -n1 -F "${MDM_COMMAND_LOG}")
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_start_error is: ${push_macos_mdm_start_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_start_timeout is: ${push_macos_mdm_start_timeout}"
	
	# Only continue workflow if the the final (required) 'ScheduleOSUpdate' MDM command was received.
	if [[ "${auth_error_jamf}" == "FALSE" ]] && [[ "${push_macos_mdm_api_error}" == "FALSE" ]] && [[ "${push_macos_mdm_start_error}" == "FALSE" ]] && [[ "${push_macos_mdm_start_timeout}" == "FALSE" ]]; then
		local push_macos_mdm_timeout_error
		push_macos_mdm_timeout_error="TRUE"
		local push_macos_mdm_timeout_seconds
		push_macos_mdm_timeout_seconds="${TIMEOUT_MDM_COMMAND_SECONDS}"
		local push_macos_mdm_phase
		push_macos_mdm_phase="START"
		local push_macos_mdm_complete_percent
		push_macos_mdm_complete_percent=0
		local push_macos_mdm_complete_percent_previous
		push_macos_mdm_complete_percent_previous=0
		local push_macos_mdm_complete_percent_display
		
		# Watch ${MDM_WORKFLOW_LOG} while waiting for the update/upgrade workflow to complete.
		# Note this while read loop has a timeout based on ${TIMEOUT_MDM_COMMAND_SECONDS} then may change to ${TIMEOUT_MDM_WORKFLOW_SECONDS}.
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_target_type is: ${push_macos_mdm_target_type}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_timeout_seconds is: ${push_macos_mdm_timeout_seconds}"
		if [[ "${push_macos_mdm_target_type}" == "UPGRADE" ]] || [[ "${push_macos_mdm_target_type}" == "UPDATE" ]]; then
			while read -t "${push_macos_mdm_timeout_seconds}" -r log_line; do
				# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
				if [[ $(echo "${log_line}" | grep -c 'phase:PREFLIGHT') -gt 0 ]]; then
					if [[ "${push_macos_mdm_phase}" != "PREFLIGHT" ]] && [[ "${push_macos_mdm_phase}" != "DOWNLOADING" ]] && [[ "${push_macos_mdm_phase}" != "PREPARING" ]]; then
						log_super "MDM: ${macos_msu_label} preflight..."
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_timeout_seconds="${TIMEOUT_MDM_WORKFLOW_SECONDS}"
						[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_timeout_seconds is: ${push_macos_mdm_timeout_seconds}"
						push_macos_mdm_phase="PREFLIGHT"
					fi
				elif [[ $(echo "${log_line}" | grep -c 'phase:DOWNLOADING_UPDATE') -gt 0 ]]; then
					if [[ "${push_macos_mdm_phase}" != "DOWNLOADING" ]]; then
						log_super "MDM: ${macos_msu_label} is downloading..."
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_timeout_seconds="${TIMEOUT_MDM_WORKFLOW_SECONDS}"
						[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_timeout_seconds is: ${push_macos_mdm_timeout_seconds}"
						push_macos_mdm_phase="DOWNLOADING"
					fi
					push_macos_mdm_complete_percent=$(echo "${log_line}" | awk '{print $17;}' | sed -e 's/portionComplete:0.//' | cut -c 1-2)
					push_macos_mdm_complete_percent=${push_macos_mdm_complete_percent#0}
					[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_complete_percent is: ${push_macos_mdm_complete_percent}"
					if [[ $push_macos_mdm_complete_percent -ge 60 ]]; then
						log_echo_replace_line "${macos_msu_label} download progress: 100%\n"
					elif [[ $push_macos_mdm_complete_percent -gt $push_macos_mdm_complete_percent_previous ]]; then
						push_macos_mdm_complete_percent_display=$( (echo "$push_macos_mdm_complete_percent * 1.69" | bc) | cut -d '.' -f1)
						log_echo_replace_line "${macos_msu_label} download progress: ${push_macos_mdm_complete_percent_display}%"
						push_macos_mdm_complete_percent_previous=$push_macos_mdm_complete_percent
					fi
				elif [[ $(echo "${log_line}" | grep -c 'phase:PREPARING_UPDATE') -gt 0 ]]; then
					if [[ "${push_macos_mdm_phase}" != "PREPARING" ]]; then
						log_super "MDM: ${macos_msu_label} download complete, now preparing..."
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_timeout_seconds=${TIMEOUT_MDM_WORKFLOW_SECONDS}
						[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_timeout_seconds is: ${push_macos_mdm_timeout_seconds}"
						push_macos_mdm_phase="PREPARING"
					fi
					push_macos_mdm_complete_percent=$(echo "${log_line}" | awk '{print $17;}' | sed -e 's/portionComplete:0.//' | cut -c 1-2)
					push_macos_mdm_complete_percent=${push_macos_mdm_complete_percent#0}
					[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_complete_percent is: ${push_macos_mdm_complete_percent}"
					if [[ $push_macos_mdm_complete_percent -ge 98 ]]; then
						log_echo_replace_line "${macos_msu_label} preparing progress: 100%\n"
						[[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]] && log_super "MDM: ${macos_msu_label} is downloaded and prepared."
						[[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && log_super "MDM: ${macos_msu_label} is downloaded and prepared, system restart is soon..."
						log_mdm_workflow "**** TIMESTAMP ****"
					elif [[ $push_macos_mdm_complete_percent -gt $push_macos_mdm_complete_percent_previous ]]; then
						push_macos_mdm_complete_percent_display=$(((push_macos_mdm_complete_percent - 60) * 2))
						log_echo_replace_line "${macos_msu_label} preparing progress: ${push_macos_mdm_complete_percent_display}%"
						push_macos_mdm_complete_percent_previous=$push_macos_mdm_complete_percent
					fi
				elif [[ $(echo "${log_line}" | grep -c 'phase:PREPARED_COMMITTING_STASH') -gt 0 ]]; then
					log_mdm_workflow "**** TIMESTAMP ****"
					push_macos_mdm_timeout_error="FALSE"
					push_macos_mdm_phase="DONE"
					break
				fi
			done < <(tail -n1 -F "${MDM_WORKFLOW_LOG}")
		else # ${push_macos_mdm_target_type} == "INSTALLER"
			# This while loop is broken into sections to allow for the notification_prepare function to update. Putting this function inside the while loop breaks the tail.
			while read -t "${push_macos_mdm_timeout_seconds}" -r log_line; do
				# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
				if [[ $(echo "${log_line}" | grep -c 'phase:PREFLIGHT') -gt 0 ]]; then
					log_super "MDM: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installer preflight..."
					log_mdm_workflow "**** TIMESTAMP ****"
					push_macos_mdm_timeout_seconds="${TIMEOUT_MDM_WORKFLOW_SECONDS}"
					[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_timeout_seconds is: ${push_macos_mdm_timeout_seconds}"
					push_macos_mdm_timeout_error="FALSE"
					push_macos_mdm_phase="PREFLIGHT"
					break
				fi
			done < <(tail -n1 -F "${MDM_WORKFLOW_LOG}")
			if [[ "${push_macos_mdm_timeout_error}" == "FALSE" ]]; then
				push_macos_mdm_timeout_error="TRUE"
				while read -t "${push_macos_mdm_timeout_seconds}" -r log_line; do
					# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
					if [[ $(echo "${log_line}" | grep -c 'phase:DOWNLOADING_SFR') -gt 0 ]]; then
						log_super "MDM: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} downloading additional items..."
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_phase="DOWNLOADING"
					elif [[ $(echo "${log_line}" | grep -c 'phase:PREPARING_UPDATE') -gt 0 ]]; then
						log_super "MDM: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installer preparing..."
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_timeout_error="FALSE"
						push_macos_mdm_phase="PREPARING"
						break
					fi
				done < <(tail -n1 -F "${MDM_WORKFLOW_LOG}")
			fi
			if [[ "${push_macos_mdm_timeout_error}" == "FALSE" ]] && [[ "${current_user_account_name}" != "FALSE" ]]; then
				display_string_prepare_time_estimate="10-15"
				notification_prepare
			fi
			if [[ "${push_macos_mdm_timeout_error}" == "FALSE" ]]; then
				push_macos_mdm_timeout_error="TRUE"
				while read -t "${push_macos_mdm_timeout_seconds}" -r log_line; do
					# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
					if [[ $(echo "${log_line}" | grep -c 'phase:PREPARED') -gt 0 ]]; then
						log_super "MDM: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installer is prepared, system restart is soon..."
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_timeout_error="FALSE"
						push_macos_mdm_phase="DONE"
						break
					fi
				done < <(tail -n1 -F "${MDM_WORKFLOW_LOG}")
			fi
			{ [[ "${push_macos_mdm_timeout_error}" == "FALSE" ]] && [[ "${current_user_account_name}" != "FALSE" ]]; } && notification_restart
			if [[ "${push_macos_mdm_timeout_error}" == "FALSE" ]]; then
				push_macos_mdm_timeout_error="TRUE"
				while read -t "${push_macos_mdm_timeout_seconds}" -r log_line; do
					# log_super "Debug Mode: Function ${FUNCNAME[0]}: log_line is:\n${log_line}"
					if [[ $(echo "${log_line}" | grep -c 'phase:ACCEPTED') -gt 0 ]] || [[ $(echo "${log_line}" | grep -c 'phase:APPLYING') -gt 0 ]] || [[ $(echo "${log_line}" | grep -c 'phase:APPLYING') -gt 0 ]]; then
						log_mdm_workflow "**** TIMESTAMP ****"
						push_macos_mdm_timeout_error="FALSE"
						push_macos_mdm_phase="DONE"
						break
					fi
				done < <(tail -n1 -F "${MDM_WORKFLOW_LOG}")
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_timeout_error is: ${push_macos_mdm_timeout_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_phase is: ${push_macos_mdm_phase}"
	
	# If the macOS update/upgrade completed, then prepare for restart.
	if [[ "${auth_error_jamf}" == "FALSE" ]] && [[ "${push_macos_mdm_api_error}" == "FALSE" ]] && [[ "${push_macos_mdm_start_error}" == "FALSE" ]] && [[ "${push_macos_mdm_start_timeout}" == "FALSE" ]] && [[ "${push_macos_mdm_timeout_error}" == "FALSE" ]]; then
		kill -9 "${log_stream_mdm_workflow_pid}" >/dev/null 2>&1
		[[ "${verbose_mode_option}" == "TRUE" ]] && kill -9 "${log_stream_mdm_workflow_debug_pid}" >/dev/null 2>&1
		if [[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]]; then
			local push_macos_mdm_download_validation_error
			push_macos_mdm_download_validation_error="TRUE"
			local update_asset_attributes
			update_asset_attributes=$(defaults read /System/Volumes/Update/Update update-asset-attributes 2>/dev/null)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: update_asset_attributes is:\n${update_asset_attributes}"
			local macos_mdm_version_prepared
			macos_mdm_version_prepared=$(echo "${update_asset_attributes}" | grep -w 'OSVersion' | awk -F '"' '{print $2;}')
			if [[ "${macos_version_major}" -ge 13 ]]; then
				local macos_mdm_prepared_version_extra
				macos_mdm_prepared_version_extra=$(echo "${update_asset_attributes}" | grep -w 'ProductVersionExtra' | awk -F '"' '{print $2;}')
				[[ -n "${macos_mdm_prepared_version_extra}" ]] && macos_mdm_version_prepared="${macos_mdm_version_prepared} ${macos_mdm_prepared_version_extra}"
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_mdm_prepared_version_extra is: ${macos_mdm_prepared_version_extra}"
			fi
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_mdm_version_prepared is: ${macos_mdm_version_prepared}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_version is: ${macos_msu_version}"
			if [[ "${macos_mdm_version_prepared}" == "${macos_msu_version}" ]]; then
				push_macos_mdm_download_validation_error="FALSE"
				log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD UPDATE/UPGRADE MACOS VIA MDM COMPLETED ****"
				[[ "${push_macos_mdm_target_type}" == "UPGRADE" ]] && log_super "MDM: ${macos_msu_label} upgrade is downloaded and prepared."
				[[ "${push_macos_mdm_target_type}" == "UPDATE" ]] && log_super "MDM: ${macos_msu_label} upgrade is downloaded and prepared."
				push_macos_mdm_download_error="FALSE"
				macos_msu_download_required="FALSE"
				defaults write "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded -string "${macos_msu_label}"
				defaults write "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded -string "${mac_last_startup}"
			fi
		else # Install workflow at this point is a success.
			/usr/libexec/PlistBuddy -c "Add :WorkflowRestartValidate bool true" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
			[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && /usr/libexec/PlistBuddy -c "Delete :WorkflowScheduledInstall" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
			log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL UPDATE/UPGRADE MACOS VIA MDM COMPLETED ****"
			[[ "${push_macos_mdm_target_type}" == "UPGRADE" ]] && log_super "MDM: ${macos_msu_label} upgrade is prepared and ready for restart!"
			[[ "${push_macos_mdm_target_type}" == "UPDATE" ]] && log_super "MDM: ${macos_msu_label} update is prepared and ready for restart!"
			[[ "${push_macos_mdm_target_type}" == "INSTALLER" ]] && log_super "MDM: ${macos_installer_title} ${macos_installer_version}-${macos_installer_build} installer is prepared and ready for restart!"
			if [[ "${push_macos_mdm_target_type}" == "INSTALLER" ]] && [[ "${current_user_account_name}" != "FALSE" ]]; then
				log_super "MDM: Forcing logout for current user: ${current_user_account_name}."
				launchctl bootout "user/${current_user_id}" &
				disown %
			fi
		fi
	fi
	
	# Handle MDM workflow failures.
	if [[ "${auth_error_jamf}" == "TRUE" ]] || [[ "${push_macos_mdm_api_error}" == "TRUE" ]] || [[ "${push_macos_mdm_start_error}" == "TRUE" ]] || [[ "${push_macos_mdm_start_timeout}" == "TRUE" ]] || [[ "${push_macos_mdm_timeout_error}" == "TRUE" ]] || [[ "${push_macos_mdm_download_validation_error}" == "TRUE" ]]; then
		kill -9 "${log_stream_mdm_command_pid}" >/dev/null 2>&1
		[[ "${verbose_mode_option}" == "TRUE" ]] && kill -9 "${log_stream_mdm_command_debug_pid}" >/dev/null 2>&1
		kill -9 "${log_stream_mdm_workflow_pid}" >/dev/null 2>&1
		[[ "${verbose_mode_option}" == "TRUE" ]] && kill -9 "${log_stream_mdm_workflow_debug_pid}" >/dev/null 2>&1
		if [[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]]; then
			log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD UPDATE/UPGRADE MACOS VIA MDM FAILED ****"
			log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - DOWNLOAD UPDATE/UPGRADE MACOS VIA MDM FAILED ****"
			push_macos_mdm_download_error="TRUE"
			macos_msu_download_required="TRUE"
			defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULabelDownloaded 2>/dev/null
			defaults delete "${SUPER_LOCAL_PLIST}" MacOSMSULastStartupDownloaded 2>/dev/null
		else # [[ "${push_macos_mdm_workflow}" == "INSTALL" ]]
			log_mdm_command "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL UPDATE/UPGRADE MACOS VIA MDM FAILED ****"
			log_mdm_workflow "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL UPDATE/UPGRADE MACOS VIA MDM FAILED ****"
		fi
		if [[ "${auth_error_jamf}" == "TRUE" ]]; then
			log_mdm_command "Error: Failed to validate Jamf Pro API configuration. Verify Jamf Pro API configuration: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials"
			log_mdm_workflow "Error: Failed to validate Jamf Pro API configuration. Verify Jamf Pro API configuration: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials"
			log_super "Error: Failed to validate Jamf Pro API configuration. Verify Jamf Pro API configuration: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials"
		elif [[ "${push_macos_mdm_api_error}" == "TRUE" ]]; then
			log_mdm_command "Error: Failed to send MDM download/install macOS request. Verify that this account has appropriate privileges: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials#jamf-pro-api-account-privileges"
			log_mdm_workflow "Error: Failed to send MDM download/install macOS request. Verify that this account has appropriate privileges: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials#jamf-pro-api-account-privileges"
			log_super "Error: Failed to send MDM download/install macOS request. Verify that this account has appropriate privileges: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials#jamf-pro-api-account-privileges"
		elif [[ "${push_macos_mdm_start_error}" == "TRUE" ]]; then
			log_mdm_command "Error: Push workflow for download/install macOS via MDM failed."
			log_mdm_workflow "Error: Push workflow for download/install macOS via MDM failed."
			log_super "Error: Push workflow for download/install macOS via MDM failed."
		elif [[ "${push_macos_mdm_start_timeout}" == "TRUE" ]]; then
			log_mdm_command "Error: Push workflow for download/install macOS via MDM failed to complete, as indicated by no progress after waiting for ${TIMEOUT_MDM_COMMAND_SECONDS} seconds."
			log_mdm_workflow "Error: Push workflow for download/install macOS via MDM failed to complete, as indicated by no progress after waiting for ${TIMEOUT_MDM_COMMAND_SECONDS} seconds."
			log_super "Error: Push workflow for download/install macOS via MDM failed to complete, as indicated by no progress after waiting for ${TIMEOUT_MDM_COMMAND_SECONDS} seconds."
		elif [[ "${push_macos_mdm_timeout_error}" == "TRUE" ]]; then
			log_mdm_workflow "Error: Download/install of macOS via MDM failed to complete, as indicated by no progress after waiting for ${push_macos_mdm_timeout_seconds} seconds."
			log_super "Error: Download/install of macOS via MDM failed to complete, as indicated by no progress after waiting for ${push_macos_mdm_timeout_seconds} seconds."
		else # ${push_macos_mdm_download_validation_error}
			if [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]]; then
				log_msu "Error: Downloaded macOS major upgrade version of ${macos_mdm_version_prepared} doesn't match expected version ${macos_msu_version}."
				log_super "Error: Downloaded macOS major upgrade version of ${macos_mdm_version_prepared} doesn't match expected version ${macos_msu_version}."
			else # "${macos_msu_minor_update_target}" != "FALSE"
				log_msu "Error: Downloaded macOS minor update version of ${macos_mdm_version_prepared} doesn't match expected version ${macos_msu_version}."
				log_super "Error: Downloaded macOS mintor update version of ${macos_mdm_version_prepared} doesn't match expected version ${macos_msu_version}."
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: push_macos_mdm_download_error is: ${push_macos_mdm_download_error}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_download_required is: ${macos_msu_download_required}"
		
		# Handle workflow failure options.
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]]; then # User authentication MDM failover option enabled.
				log_super "Warning: Download/install of macOS via MDM failed, failing over to user authenticated workflow."
				workflow_macos_auth="FAILOVER"
				if [[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]]; then
					workflow_download_macos
				else # [[ "${push_macos_mdm_workflow}" == "INSTALL" ]]
					unset install_jamf_policy_triggers_option
					workflow_install_active_user
				fi
				return 0
			else # No user authentication MDM failover option.
				log_super "Error: Download/install of macOS via MDM failed, install now workflow can not continue."
				log_status "Inactive Error: Download/install of macOS via MDM failed, install now workflow can not continue."
				[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
				exit_error
			fi
		else # Default super workflow.
			if [[ "${current_user_account_name}" != "FALSE" ]] && [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]]; then
				log_super "Warning: Download/install of macOS via MDM failed, failing over to user authenticated workflow."
				workflow_macos_auth="FAILOVER"
				if [[ "${push_macos_mdm_workflow}" == "DOWNLOAD" ]]; then
					workflow_download_macos
				else # [[ "${push_macos_mdm_workflow}" == "INSTALL" ]]
					unset install_jamf_policy_triggers_option
					workflow_install_active_user
				fi
				return 0
			else # No current user, or no user authentication MDM failover option.
				deferral_timer_minutes="${deferral_timer_error_minutes}"
				log_super "Error: Download/install of macOS via MDM failed, trying again in ${deferral_timer_minutes} minutes."
				log_status "Pending: Download/install of macOS via MDM failed, trying again in ${deferral_timer_minutes} minutes."
				{ [[ "${push_macos_mdm_workflow}" == "INSTALL" ]] && [[ "${current_user_account_name}" != "FALSE" ]]; } && notification_failed
				set_auto_launch_deferral
			fi
		fi
	fi
}

# This is the install workflow for all (non-system) macOS software updates when enforced.
workflow_install_non_system_msu() {
	[[ "${current_user_account_name}" != "FALSE" ]] && notification_non_system_updates
	
	# If ${test_mode_option} then it's not necessary to continue this function.
	if [[ "${test_mode_option}" == "TRUE" ]]; then
		log_super "Test Mode: Skipping the install non-system macOS software updates workflow."
		log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the non-system macOS software updates notification..."
		sleep "${test_mode_timeout_seconds}"
		killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
		return 0
	fi
	
	# Install and check to make sure all updates are complete.
	install_non_system_msu
	check_software_status_required="TRUE"
	workflow_check_software_status
	
	# If we had failures or there are still more non-system updates, then try again.
	if [[ "${install_non_system_msu_error}" == "TRUE" ]] && [[ "${non_system_msu_targets}" == "TRUE" ]]; then
		log_super "Warning: Failed to install all non-system macOS software updates, re-trying installation workflow."
		install_non_system_msu
		check_software_status_required="TRUE"
		workflow_check_software_status
	fi
	
	# Log status of non-system update completion.
	[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
	unset notification_non_system_updates_active
	if [[ "${install_non_system_msu_error}" == "FALSE" ]] && [[ "${non_system_msu_targets}" == "FALSE" ]]; then
		log_super "Status: Completed installation of all non-system macOS software updates!"
		killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
		# For computers managed via Jamf Pro, submit inventory.
		if [[ "${jamf_version_number}" != "FALSE" ]]; then
			if [[ "${auth_error_jamf}" != "TRUE" ]]; then
				log_super "Status: Submitting updated inventory to Jamf Pro. Use --verbose-mode or check /var/log/jamf.log for more detail..."
				if [[ "${verbose_mode_option}" == "TRUE" ]]; then
					local jamf_response
					jamf_response=$("${JAMF_PRO_BINARY}" recon -verbose 2>&1)
					log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_response is:\n${jamf_response}"
				else
					"${JAMF_PRO_BINARY}" recon >/dev/null 2>&1
				fi
			else # There was an earlier Jamf Pro validation error.
				log_super "Warning: Unable to submit inventory to Jamf Pro."
			fi
		fi
	else # Some software updates did not complete
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "Error: Some non-system macOS software updates did not complete, install now workflow can not continue."
			log_status "Inactive Error: Some non-system macOS software updates did not complete, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
			exit_error
		else
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Warning: Some non-system macOS software updates did not complete, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Some non-system macOS software updates did not complete, trying again in ${deferral_timer_minutes} minutes."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_failed
			set_auto_launch_deferral
		fi
	fi
}

# This is the install and restart workflow when a user is not logged in.
workflow_install_no_user() {
	local workflow_install_macos_no_user_error
	workflow_install_macos_no_user_error="FALSE"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_target is: ${macos_installer_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_major_upgrade_target is: ${macos_msu_major_upgrade_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_minor_update_target is: ${macos_msu_minor_update_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_macos_auth is: ${workflow_macos_auth}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_now_active is: ${workflow_install_now_active}"
	
	# A macOS update/upgrade is targeted.
	if [[ "${macos_installer_target}" != "FALSE" ]] || [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] || [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then
		# Check to make sure system has enough available storage space.
		check_storage_available
		if [[ "${check_storage_available_error}" == "TRUE" ]]; then
			workflow_install_macos_no_user_error="TRUE"
		elif [[ "${storage_ready}" == "FALSE" ]]; then
			log_super "Status: Current available storage is at ${storage_available_gigabytes} GBs which is below the ${storage_required_gigabytes} GBs that is required for download."
			workflow_install_macos_no_user_error="TRUE"
		fi
		
		# Check to make sure system is plugged into AC power or that the current battery level is above ${power_required_battery_percent}.
		check_power_required
		if [[ "${check_power_required_error}" == "TRUE" ]]; then
			workflow_install_macos_no_user_error="TRUE"
		elif [[ "${power_ready}" == "FALSE" ]]; then
			log_super "Status: Current battery level is at ${power_battery_percent}% which is below the minimum required level of ${power_required_battery_percent}%."
			workflow_install_macos_no_user_error="TRUE"
		fi
		
		# If (no errors) a target is a macOS major upgrade via installer and a download is required.
		if [[ "${workflow_install_macos_no_user_error}" == "FALSE" ]] && [[ "${macos_installer_target}" != "FALSE" ]] && [[ "${macos_installer_download_required}" == "TRUE" ]]; then
			download_macos_installer
			[[ "${download_macos_installer_error}" == "TRUE" ]] && workflow_install_macos_no_user_error="TRUE"
		fi
		
		# If (no errors) the MDM workflow is expected, check for MDM service and bootstrap token.
		if [[ "${workflow_install_macos_no_user_error}" == "FALSE" ]] && [[ "${workflow_macos_auth}" == "JAMF" ]]; then
			check_mdm_service
			if [[ "${auth_error_mdm}" == "FALSE" ]]; then
				check_bootstrap_token_escrow
				if [[ "${auth_error_bootstrap_token}" == "TRUE" ]]; then
					log_super "Error: Can not use MDM workflow because this computer's bootstrap token escrow is not valid."
					workflow_install_macos_no_user_error="TRUE"
				fi
			else # MDM service is unavailable.
				log_super "Error: Can not use MDM workflow because the MDM service is not available."
				workflow_install_macos_no_user_error="TRUE"
			fi
		fi
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_macos_no_user_error is: ${workflow_install_macos_no_user_error}"
		
		# If (no errors) computers with Apple silicon, get saved authentication.
		if [[ "${workflow_install_macos_no_user_error}" == "FALSE" ]] && [[ "${mac_cpu_architecture}" == "arm64" ]] && [[ "${workflow_macos_auth}" != "USER" ]] && [[ "${workflow_macos_auth}" != "FAILOVER" ]]; then
			get_saved_authentication
			[[ "${auth_error_saved}" == "TRUE" ]] && workflow_install_macos_no_user_error="TRUE"
		fi
		
		# If no errors, then start the appropriate macOS update/upgrade workflow.
		if [[ "${workflow_install_macos_no_user_error}" == "FALSE" ]]; then
			if [[ "${workflow_macos_auth}" == "LOCAL" ]]; then
				[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
				if [[ "${macos_installer_target}" != "FALSE" ]]; then # Target is a macOS major upgrade via installer.
					install_macos_app
				else # Target is a macOS upgrade/update via MSU.
					install_macos_msu
				fi
			elif [[ "${workflow_macos_auth}" == "JAMF" ]]; then
				[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
				push_macos_mdm_workflow="INSTALL"
				push_macos_mdm
				unset push_macos_mdm_workflow
			else # Apple Silicon with no saved update/upgrade credentials can not enforce macOS upgrade/update.
				log_super "Error: No saved Apple silicon credentials and no active logged in user."
				workflow_install_macos_no_user_error="TRUE"
			fi
		fi
	elif [[ "${workflow_target}" == "Non-system Software Updates" ]]; then
		workflow_install_non_system_msu
	else # Workflows when there are no macOS updates/upgrades.
		if [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then # If requested, restart without updates.
			[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
			defaults write "${SUPER_LOCAL_PLIST}" WorkflowRestartValidate -bool true
			[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
			log_super "Status: Restarting computer in one minute..."
			shutdown -o -r +1 >/dev/null 2>&1 &
			disown -a
		else # Option to restart without updates is not enabled.
			if [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]] && [[ -n "${install_jamf_policy_triggers_option}" ]]; then
				run_jamf_policy_triggers
				[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
			else
				log_super "Warning: When no macOS update/upgrade is available you must also specify the --workflow-restart-without-updates option to restart automatically."
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_macos_no_user_error is: ${workflow_install_macos_no_user_error}"
	
	# Handle workflow failure options.
	if [[ "${workflow_install_macos_no_user_error}" == "TRUE" ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_super "Error: macOS update/upgrade workflow failed, install now workflow can not continue."
			log_status "Inactive Error: macOS update/upgrade workflow failed, install now workflow can not continue."
			exit_error
		else # Default super workflow.
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Error: macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
}

# This is the install and restart workflow when a user is logged in.
workflow_install_active_user() {
	local workflow_install_macos_active_user_error
	workflow_install_macos_active_user_error="FALSE"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_target is: ${macos_installer_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_major_upgrade_target is: ${macos_msu_major_upgrade_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_minor_update_target is: ${macos_msu_minor_update_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_macos_auth is: ${workflow_macos_auth}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_now_active is: ${workflow_install_now_active}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_mdm_failover_to_user_status is: ${auth_mdm_failover_to_user_status}"
	
	# A macOS update/upgrade is targeted.
	if [[ "${macos_installer_target}" != "FALSE" ]] || [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]] || [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then
		# Check to make sure system has enough available storage space.
		check_storage_available
		if [[ "${check_storage_available_error}" == "FALSE" ]]; then
			if [[ "${storage_ready}" == "FALSE" ]]; then
				dialog_insufficient_storage
				[[ "${dialog_insufficient_storage_error}" == "TRUE" ]] && workflow_install_macos_active_user_error="TRUE"
			fi
		else # "${check_storage_available_error}" == "TRUE"
			workflow_install_macos_active_user_error="TRUE"
		fi
		
		# Check to make sure system is plugged into AC power or that the current battery level is above ${power_required_battery_percent}.
		check_power_required
		if [[ "${check_power_required_error}" == "FALSE" ]]; then
			if [[ "${power_ready}" == "FALSE" ]]; then
				dialog_power_required
				[[ "${dialog_power_required_error}" == "TRUE" ]] && workflow_install_macos_active_user_error="TRUE"
			fi
		else # "${check_power_required_error}" == "TRUE"
			workflow_install_macos_active_user_error="TRUE"
		fi
		
		# If (no errors) an MDM workflow is expected, first check for MDM service, bootstrap token, and possibly failover to user authentication workflow.
		if [[ "${workflow_install_macos_active_user_error}" == "FALSE" ]] && [[ "${workflow_macos_auth}" == "JAMF" ]]; then
			check_mdm_service
			if [[ "${auth_error_mdm}" == "TRUE" ]]; then
				if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]] || [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ERROR') -gt 0 ]] || { [[ "${workflow_install_now_active}" == "TRUE" ]] && [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'INSTALLNOW') -gt 0 ]]; }; then
					log_super "Warning: MDM service is not available, failing over to user authenticated install workflow."
					workflow_macos_auth="FAILOVER"
				else
					log_super "Error: Can not use MDM workflow because the MDM service is not available."
					workflow_install_macos_active_user_error="TRUE"
				fi
			else # MDM service is available.
				check_bootstrap_token_escrow
				if [[ "${auth_error_bootstrap_token}" == "TRUE" ]]; then
					if [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]] || [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ERROR') -gt 0 ]] || { [[ "${workflow_install_now_active}" == "TRUE" ]] && [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'INSTALLNOW') -gt 0 ]]; }; then
						log_super "Warning: Missing or invalid bootstrap token escrow, failing over to user authenticated install workflow."
						workflow_macos_auth="FAILOVER"
					else
						log_super "Error: Can not use MDM workflow because this computer's bootstrap token is not escrowed."
						workflow_install_macos_active_user_error="TRUE"
					fi
				fi
			fi
		fi
		
		# If (no errors) computers with Apple silicon, get authentication.
		if [[ "${workflow_install_macos_active_user_error}" == "FALSE" ]] && [[ "${mac_cpu_architecture}" == "arm64" ]] && [[ "${workflow_macos_auth}" != "FALSE" ]]; then
			if [[ "${workflow_macos_auth}" == "LOCAL" ]] || [[ "${workflow_macos_auth}" == "JAMF" ]]; then
				get_saved_authentication
				if [[ "${auth_error_saved}" == "TRUE" ]]; then
					if [[ "${auth_credential_failover_to_user_option}" == "TRUE" ]] || [[ "${auth_ask_user_to_save_password}" == "TRUE" ]]; then
						log_super "Warning: Saved authentication error, failing over to user authenticated installation workflow."
						workflow_macos_auth="FAILOVER"
						[[ "${dialog_user_auth_valid}" != "TRUE" ]] && dialog_user_auth
						[[ "${dialog_user_auth_error}" == "TRUE" ]] && workflow_install_macos_active_user_error="TRUE"
					else
						log_super "Error: Unable to use saved authentication for installation and the --auth-credential-failover-to-user option is not enabled."
						workflow_install_macos_active_user_error="TRUE"
					fi
				fi
			else # [[ "${workflow_macos_auth}" == "USER" ]] || [[ "${workflow_macos_auth}" == "FAILOVER" ]]
				[[ "${dialog_user_auth_valid}" != "TRUE" ]] && dialog_user_auth
				[[ "${dialog_user_auth_error}" == "TRUE" ]] && workflow_install_macos_active_user_error="TRUE"
			fi
		fi
		
		# If no errors, then start the appropriate macOS update/upgrade workflow.
		if [[ "${workflow_install_macos_active_user_error}" == "FALSE" ]]; then
			if [[ "${workflow_macos_auth}" == "LOCAL" ]] || [[ "${workflow_macos_auth}" == "USER" ]] || [[ "${workflow_macos_auth}" == "FAILOVER" ]]; then
				if [[ "${macos_installer_target}" != "FALSE" ]]; then # Target is a macOS major upgrade via installer.
					display_string_prepare_time_estimate="15-25"
					notification_prepare
					[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
					install_macos_app
				else # Target is a macOS upgrade/update via MSU.
					[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
					install_macos_msu
				fi
			else # [[ "${workflow_macos_auth}" == "JAMF" ]]
				if [[ "${macos_installer_target}" != "FALSE" ]]; then  # Target is a macOS major upgrade via installer.
					display_string_prepare_time_estimate="25-30"
				else # Target is a macOS upgrade/update via MSU.
					display_string_prepare_time_estimate="5"
				fi
				notification_prepare
				[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
				push_macos_mdm_workflow="INSTALL"
				push_macos_mdm
				unset push_macos_mdm_workflow
			fi
		fi
	elif [[ "${workflow_target}" == "Non-system Software Updates" ]]; then
		workflow_install_non_system_msu
	else # Workflows when there are no macOS updates/upgrades.
		if [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then # If requested, restart without updates.
			[[ -n "${install_jamf_policy_triggers_option}" ]] && run_jamf_policy_triggers
			notification_restart
			if [[ "${test_mode_option}" != "TRUE" ]]; then
				defaults write "${SUPER_LOCAL_PLIST}" WorkflowRestartValidate -bool true
				[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
				log_super "Status: Restarting computer in one minute..."
				shutdown -o -r +1 >/dev/null 2>&1 &
				disown -a
			else # Test mode.
				log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the restart notification..."
				sleep "${test_mode_timeout_seconds}"
				killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
			fi
		else # Option to restart without updates is not enabled.
			if [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]] && [[ -n "${install_jamf_policy_triggers_option}" ]]; then
				run_jamf_policy_triggers
				[[ "${workflow_scheduled_install_active}" == "TRUE" ]] && defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
			else
				log_super "Warning: When no macOS update/upgrade is available you must also specify the --workflow-restart-without-updates option to restart automatically."
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_install_macos_active_user_error is: ${workflow_install_macos_active_user_error}"
	
	# Handle workflow failure options.
	if [[ "${workflow_install_macos_active_user_error}" == "TRUE" ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_super "Error: macOS update/upgrade workflow failed, install now workflow can not continue."
			log_status "Inactive Error: macOS update/upgrade workflow failed, install now workflow can not continue."
			notification_install_now_failed
			exit_error
		else # Default super workflow.
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Error: macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			notification_failed
			set_auto_launch_deferral
		fi
	fi
}

# This function checks the macOS upgrade/update status after a previous super macOS upgrade/update restart.
workflow_restart_validate() {
	log_status "Running: Restart validation workflow."
	if [[ "${workflow_disable_update_check_option}" != "TRUE" ]]; then # Skip software updates/upgrade mode option.
		check_software_status_required="TRUE"
		workflow_check_software_status
	fi
	
	# Install any non-system macOS software updates.
	if [[ "${non_system_msu_targets}" == "TRUE" ]]; then
		install_non_system_msu
		if [[ "${install_non_system_msu_error}" != "TRUE" ]]; then
			log_super "Status: Completed installation of all non-system macOS software updates!"
		else
			log_super "Warning: Failed to install all non-system macOS software updates."
		fi
		check_software_status_required="TRUE"
		workflow_check_software_status
	fi
	
	# Log status of updates/upgrade completion.
	if [[ "${macos_installer_target}" == "FALSE" ]] && [[ "${macos_msu_major_upgrade_target}" == "FALSE" ]] && [[ "${macos_msu_minor_update_target}" == "FALSE" ]] && [[ "${non_system_msu_targets}" == "FALSE" ]]; then
		log_super "Status: All available and enabled macOS software updates/upgrades completed!"
		check_software_status_required="FALSE"
	elif [[ "${macos_installer_target}" == "FALSE" ]] && [[ "${macos_msu_major_upgrade_target}" == "FALSE" ]] && [[ "${macos_msu_minor_update_target}" == "FALSE" ]] && [[ "${non_system_msu_targets}" == "TRUE" ]]; then
		deferral_timer_minutes="${DEFERRAL_TIMER_RESTART_VALIDATION_ERROR_MINUTES}"
		log_super "Error: Some non-system macOS software updates remain available for installation, trying restart validation workflow again in ${deferral_timer_minutes} minutes."
		log_status "Pending: Some non-system macOS software updates remain available for installation, trying restart validation workflow again in ${deferral_timer_minutes} minutes."
		set_auto_launch_deferral
	else
		log_super "Warning: Some macOS software updates/upgrades did not complete after last restart, continuing workflow."
	fi
	
	# For computers managed via Jamf Pro, submit inventory and check for policies.
	if [[ "${jamf_version_number}" != "FALSE" ]]; then
		if [[ "${auth_error_jamf}" != "TRUE" ]]; then
			log_super "Status: Submitting updated inventory to Jamf Pro. Use --verbose-mode or check /var/log/jamf.log for more detail..."
			local jamf_response
			if [[ "${verbose_mode_option}" == "TRUE" ]]; then
				jamf_response=$("${JAMF_PRO_BINARY}" recon -verbose 2>&1)
				log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_response is:\n${jamf_response}"
			else
				"${JAMF_PRO_BINARY}" recon >/dev/null 2>&1
			fi
			sleep 5
			log_super "Status: Running Jamf Pro check-in policies. Use --verbose-mode or check /var/log/jamf.log for more detail..."
			if [[ "${verbose_mode_option}" == "TRUE" ]]; then
				jamf_response=$("${JAMF_PRO_BINARY}" policy -verbose 2>&1)
				log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_response is:\n${jamf_response}"
			else
				"${JAMF_PRO_BINARY}" policy >/dev/null 2>&1
			fi
		else # There was an earlier Jamf Pro validation error.
			deferral_timer_minutes="${DEFERRAL_TIMER_RESTART_VALIDATION_ERROR_MINUTES}"
			log_super "Error: Unable to submit inventory or perform check-in via Jamf Pro, trying restart validation workflow again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Unable to submit inventory or perform check-in via Jamf Pro, trying restart validation workflow again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Local preference file after workflow_restart_validate: ${SUPER_LOCAL_PLIST}:\n$(defaults read "${SUPER_LOCAL_PLIST}" 2>/dev/null)"
}

# MARK: *** Jamf Pro ***
################################################################################

# Validate connectivity to Jamf Pro service and set ${jamf_version_number}, ${jamf_management_url}, and ${jamf_api_url}.
check_jamf_management_framework() {
	jamf_version_number="FALSE"
	auth_error_jamf="FALSE"
	if [[ -f "${JAMF_PRO_BINARY}" ]]; then
		jamf_version_number_full=$("${JAMF_PRO_BINARY}" -version | sed -e 's/version=//' -e 's/-.*//')
		jamf_version_number_major=$(echo "${jamf_version_number_full}" | cut -d'.' -f1) # Expected output: 10, 11
		jamf_version_number_minor=$(echo "${jamf_version_number_full}" | cut -d'.' -f2) # Expected output: 0, 30, 31, 32, etc.
		jamf_version_number="${jamf_version_number_major}$(printf "%02d" "${jamf_version_number_minor}")" # Expected output: 1048, 1100, etc.
		if [[ "${mac_cpu_architecture}" == "arm64" ]] && [[ "${jamf_version_number}" -lt 1038 ]]; then
			log_super "Error: super requires Jamf Pro version 10.38 or later, the currently installed version of Jamf Pro ${jamf_version_number_major}.${jamf_version_number_minor} is not supported."
			auth_error_jamf="TRUE"
		elif [[ "${mac_cpu_architecture}" != "arm64" ]] && [[ "${jamf_version_number}" -lt 1000 ]]; then
			log_super "Error: super requires Jamf Pro version 10.00 or later, the currently installed version of Jamf Pro ${jamf_version_number_major}.${jamf_version_number_minor} is not supported."
			auth_error_jamf="TRUE"
		else # Jamf Pro version is supported.
			local jamf_response
			jamf_response=$("${JAMF_PRO_BINARY}" checkJSSConnection -retry 1 2>/dev/null)
			if [[ $(echo "${jamf_response}" | grep -c 'available') -gt 0 ]]; then
				jamf_management_url=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
				log_super "Status: Managed by Jamf Pro ${jamf_version_number_full} hosted at: ${jamf_management_url}"
				jamf_api_url="${jamf_management_url}"
			else
				log_super "Error: Jamf Pro service is unavailable with response:\n${jamf_response}"
				auth_error_jamf="TRUE"
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_version_number is: ${jamf_version_number}"
	
	# Check for ${auth_jamf_custom_url} and sets ${jamf_api_url} accordingly.
	if [[ "${jamf_version_number}" != "FALSE" ]] && [[ "${auth_error_jamf}" != "TRUE" ]] && [[ -n "${auth_jamf_custom_url}" ]]; then
		local curl_response
		curl_response=$(curl -Is "${auth_jamf_custom_url}" | head -n 1)
		if [[ $(echo "${curl_response}" | grep -c 'HTTP') -gt 0 ]] && [[ $(echo "${curl_response}" | grep -c -e '400' -e '40[4-9]' -e '4[1-9][0-9]' -e '5[0-9][0-9]') -eq 0 ]]; then
			jamf_api_url="${auth_jamf_custom_url}"
			log_super "Status: Using custom Jamf Pro API URL hosted at ${jamf_api_url}."
		else
			log_super "Error: Custom Jamf Pro API URL is unavailable: ${curl_response}"
			auth_error_jamf="TRUE"
		fi
	fi
}

# Use preferences derived ${auth_jamf_computer_id_option} or a jamf recon to resolve the computer's ${jamf_computer_id}.
get_jamf_api_computer_id() {
	unset jamf_computer_id
	if [[ -n "${auth_jamf_computer_id_option}" ]]; then
		jamf_computer_id="${auth_jamf_computer_id_option}"
	else # Resolve the computer's Jamf Pro ID via jamf recon.
		log_super "Warning: Running Jamf Pro inventory to resolve the Jamf Pro Computer ID. To avoid this step use a configuration profile as covered in the super Wiki: https://github.com/Macjutsu/super/wiki/"
		local jamf_response
		local jamf_return
		jamf_response=$("${JAMF_PRO_BINARY}" recon -verbose)
		jamf_return="$?"
		if [[ "${jamf_return}" -eq 0 ]]; then
			jamf_computer_id=$(echo "${jamf_response}" | grep '<computer_id>' | sed -e 's/[^0-9]*//g')
		else
			log_super "Error: Jamf Pro inventory collection failed."
			auth_error_jamf="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_response is:\n${jamf_response}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_return is: ${jamf_return}"
		fi
	fi
	# A bit of error checking to make sure it's a regular number.
	if [[ "${jamf_computer_id}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
		defaults write "${SUPER_LOCAL_PLIST}" AuthJamfComputerID -string "${jamf_computer_id}"
	else
		log_super "Error: Unable to resolve Jamf Pro Computer ID."
		auth_error_jamf="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_computer_id is: ${jamf_computer_id}"
}

# Attempt to acquire a ${jamf_access_token} via ${auth_jamf_client} and ${auth_jamf_secret} credentials or via ${auth_jamf_account} and ${auth_jamf_password} credentials.
get_jamf_api_access_token() {
	local curl_response
	if [[ -n "${auth_jamf_client}" ]]; then
		curl_response=$(curl --silent --location --request POST "${jamf_api_url}api/oauth/token" --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=${auth_jamf_client}" --data-urlencode "grant_type=client_credentials" --data-urlencode "client_secret=${auth_jamf_secret}")
	else # Legacy ${auth_jamf_account} authentication.
		curl_response=$(curl --silent --location --request POST "${jamf_api_url}api/v1/auth/token" --user "${auth_jamf_account}:${auth_jamf_password}")
	fi
	if [[ $(echo "${curl_response}" | grep -c 'token') -gt 0 ]]; then
		if [[ -n "${auth_jamf_client}" ]]; then
			if [[ "${macos_version_major}" -ge 12 ]]; then
				jamf_access_token=$(echo "${curl_response}" | plutil -extract access_token raw -)
			else # macOS 11.
				jamf_access_token=$(echo "${curl_response}" | awk -F '"' '{print $4;}' | xargs)
			fi
		else # Legacy ${auth_jamf_account} authentication.
			if [[ "${macos_version_major}" -ge 12 ]]; then
				jamf_access_token=$(echo "${curl_response}" | plutil -extract token raw -)
			else # macOS 11.
				jamf_access_token=$(echo "${curl_response}" | grep 'token' | awk -F '"' '{print $4;}' | xargs)
			fi
		fi
	else # There was no access token.
		if [[ -n "${auth_jamf_client}" ]]; then
			log_super "Auth Error: Response from Jamf Pro API access token request did not contain a token. Verify the --auth-jamf-client=ClientID and --auth-jamf-secret=ClientSecret values."
			auth_error_jamf="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_client is: ${auth_jamf_client}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_secret is: ${auth_jamf_secret}"
		else # Legacy ${auth_jamf_account} authentication.
			log_super "Auth Error: Response from Jamf Pro API access token request did not contain a token. Verify the --auth-jamf-account=AccountName and --auth-jamf-password=Password values."
			auth_error_jamf="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_account is: ${auth_jamf_account}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_jamf_password is: ${auth_jamf_password}"
		fi
		auth_error_jamf="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_api_url is: ${jamf_api_url}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is:\n${curl_response}"
	fi
}

# Use ${jamf_access_token} to attempt a Blank Push request to the Jamf Pro API at ${jamf_api_url}.
send_jamf_api_blank_push() {
	jamf_blank_push_response=$(curl --silent --output /dev/null --write-out "%{http_code}" --location --request POST "${jamf_api_url}JSSResource/computercommands/command/BlankPush/id/${jamf_computer_id}" --header "Authorization: Bearer ${jamf_access_token}")
}

# Validate that the account ${auth_jamf_account} and ${auth_jamf_password} are valid credentials and has appropriate permissions to send MDM push commands. If not set ${auth_error_jamf}.
check_jamf_api_credentials() {
	auth_error_jamf="FALSE"
	[[ -z "${jamf_computer_id}" ]] && get_jamf_api_computer_id
	[[ "${auth_error_jamf}" == "TRUE" ]] && return 0
	get_jamf_api_access_token
	[[ "${auth_error_jamf}" == "TRUE" ]] && return 0
	send_jamf_api_blank_push
	[[ "${auth_error_jamf}" == "TRUE" ]] && return 0
	if [[ "${jamf_blank_push_response}" != 201 ]]; then
		log_super "Auth Error: Unable to request Blank Push via the Jamf Pro API. Verify that the provided Jamf Pro credentials has appropriate privileges: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials#jamf-pro-api-account-privileges"
		auth_error_jamf="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_blank_push_response is:\n${jamf_blank_push_response}"
	fi
}

# Validate existing ${jamf_access_token} and if found invalid, a new token is requested and again validated.
check_jamf_api_access_token() {
	auth_error_jamf="FALSE"
	[[ -z "${jamf_computer_id}" ]] && get_jamf_api_computer_id
	[[ "${auth_error_jamf}" == "TRUE" ]] && return 0
	local curl_response
	if [[ -n "${jamf_access_token}" ]]; then
		curl_response=$(curl --silent --output /dev/null --write-out "%{http_code}" --location --request GET "${jamf_api_url}api/v1/auth" --header "Authorization: Bearer ${jamf_access_token}")
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is:\n${curl_response}"
	fi
	if [[ "${curl_response}" -ne 200 ]]; then
		get_jamf_api_access_token
		[[ "${auth_error_jamf}" == "TRUE" ]] && return 0
		curl_response=$(curl --silent --output /dev/null --write-out "%{http_code}" --location --request GET "${jamf_api_url}api/v1/auth" --header "Authorization: Bearer ${jamf_access_token}")
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is:\n${curl_response}"
		if [[ "${curl_response}" -ne 200 ]]; then
			log_super "Auth Error: Unable to validate Jamf Pro API access token."
			auth_error_jamf="TRUE"
		fi
	fi
}

# Validate if Jamf Pro 10.48 or later is using "the new software updates experience" and set ${jamf_api_update_workflow} accordingly.
check_jamf_api_update_workflow() {
	jamf_api_update_workflow="LEGACY"
	if [[ "${jamf_version_number}" -ge 1048 ]]; then
		local curl_response
		curl_response=$(curl --silent --write-out "%{http_code}" --location --request GET "${jamf_api_url}api/v1/managed-software-updates/plans/feature-toggle" --header "Authorization: Bearer ${jamf_access_token}" --header "Content-Type: application/json")
		if [[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]]; then
			if [[ $(echo "${curl_response}" | grep -e 'toggle' | grep -c 'true') -gt 0 ]]; then
				jamf_api_update_workflow="NEW"
			fi
		else
			log_super "Error: Unable to validate Jamf Pro API software update workflow type. Verify that the provided Jamf Pro credentials has appropriate privileges: https://github.com/Macjutsu/super/wiki/Apple-Silicon-Jamf-Pro-API-Credentials#jamf-pro-api-account-privileges"
			auth_error_jamf="TRUE"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is: ${curl_response}"
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_api_update_workflow is: ${jamf_api_update_workflow}"
}

# Invalidate and remove from local memory the ${jamf_access_token}.
delete_jamf_api_access_token() {
	local curl_response
	curl_response=$(curl --silent --output /dev/null --write-out "%{http_code}" --location --request POST --url "${jamf_api_url}api/v1/auth/invalidate-token" --header "Authorization: Bearer ${jamf_access_token}")
	if [[ "${curl_response}" -eq 204 ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Jamf Pro API access token successfully invalidated."
		unset jamf_access_token
	elif [[ "${curl_response}" -eq 401 ]]; then
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Jamf Pro API access token already invalid."
		unset jamf_access_token
	else
		log_super "Error: Invalidating Jamf Pro API access token."
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is:\n${curl_response}"
	fi
}

# Install any optional ${install_jamf_policy_triggers_option}.
run_jamf_policy_triggers() {
	jamf_policy_error="FALSE"
	log_super "Status: Installing Jamf Pro Policy triggers. Use --verbose-mode or check /var/log/jamf.log for more detail..."
	log_status "Running: Installing Jamf Pro Policy triggers."
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=','
	local jamf_policy_triggers_array
	read -r -a jamf_policy_triggers_array <<<"${install_jamf_policy_triggers_option}"
	for jamf_policy_trigger in "${jamf_policy_triggers_array[@]}"; do
		[[ "${current_user_account_name}" != "FALSE" ]] && notification_jamf_pro_policy
		if [[ "${test_mode_option}" != "TRUE" ]]; then
			log_super "Status: Jamf Pro Policy with Trigger \"${jamf_policy_trigger}\" is starting..."
			local jamf_response
			local jamf_return
			if [[ "${verbose_mode_option}" == "TRUE" ]]; then
				jamf_response=$("${JAMF_PRO_BINARY}" policy -event "${jamf_policy_trigger}" -verbose 2>&1)
				jamf_return="$?"
				log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_response is:\n${jamf_response}"
				log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_return is: ${jamf_return}"
			else
				"${JAMF_PRO_BINARY}" policy -event "${jamf_policy_trigger}" >/dev/null 2>&1
				jamf_return="$?"
			fi
			if [[ "${jamf_return}" -ne 0 ]]; then
				log_super "Error: Jamf Pro Policy with Trigger \"${jamf_policy_trigger}\" failed!"
				jamf_policy_error="TRUE"
			else
				log_super "Status: Jamf Pro Policy with Trigger \"${jamf_policy_trigger}\" was successful."
			fi
		else
			log_super "Test Mode: Skipping Jamf Pro Policy with Trigger: ${jamf_policy_trigger}."
			if [[ "${current_user_account_name}" != "FALSE" ]]; then
				log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the Jamf Pro Policy notification..."
				sleep "${test_mode_timeout_seconds}"
			fi
		fi
	done
	IFS="${previous_ifs}"
	{ [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]] && [[ "${current_user_account_name}" != "FALSE" ]]; } && killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
	
	# Wrap-up Jamf Pro Policies workflow.
	if [[ "${jamf_policy_error}" != "TRUE" ]]; then
		log_super "Status: All Jamf Pro Policies completed."
	else # Handle workflow failure options.
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then # Install now workflow mode.
			log_super "Error: Some Jamf Pro Policies failed, install now workflow can not continue."
			log_status "Inactive Error: Some Jamf Pro Policies failed, install now workflow can not continue."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
			exit_error
		else # Default super workflow.
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Error: macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: macOS update/upgrade workflow failed, trying again in ${deferral_timer_minutes} minutes."
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_failed
			set_auto_launch_deferral
		fi
	fi
}

# MARK: *** User Interface Management ***
################################################################################

# Set language strings for dialogs and notifications.
set_display_strings_language() {
	#### Langauge for the restart button in dialogs.
	display_string_restart_now_button="Restart Now"
	
	#### Langauge for the install button in dialogs.
	display_string_install_now_button="Install Now"
	
	#### Langauge for the download button in dialogs.
	display_string_download_now_button="Download Now"
	
	#### Language for the defer button in dialogs when the deferral time is sometime today.
	display_string_defer_today_button="Defer"
	
	#### Language for the defer button in dialogs when the deferral time is after tomorrow.
	display_string_defer_tomorrow_button="Defer Until Tomorrow"
	
	#### Language for the defer button in dialogs when the deferral time is after tomorrow.
	display_string_defer_future_button="Defer Until"
	
	#### Language for the user schedule restart button in dialogs.
	display_string_schedule_restart_button="Schedule Restart"
	
	#### Language for the user schedule installation button in Jamf Pro Policy dialogs.
	display_string_schedule_install_button="Schedule Installation"
	
	#### Language for the user reschedule button in dialogs.
	display_string_reschedule_button="Reschedule"
	
	#### Language for the cancel button in certain dialogs and notifications.
	display_string_cancel_button="Cancel"
	
	#### Language for the OK button in certain dialogs and notifications.
	display_string_ok_button="OK"
	
	### Language for various deferral timer durations.
	display_string_minutes="Minutes"
	display_string_hour="Hour"
	display_string_hours="Hours"
	display_string_and="and"
	
	#### This code generates the ${display_string_workflow_title} variable to include the appropriate upgrade workflow title .
	if [[ "${workflow_target}" == "Non-system Software Updates" ]]; then
		display_string_workflow_title="Apple Software Updates"
	elif [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers With Restart" ]]; then
		display_string_workflow_title="Jamf Pro Policies"
	elif [[ "${workflow_target}" == "Restart Without Updates" ]]; then
		display_string_workflow_title="Management"
	else # Standard macOS update/upgrade workflows removes the build number to simplify the dialogs.
		# shellcheck disable=SC2001
		display_string_workflow_title=$(echo "${workflow_target}" | sed -e 's/-.*//')
	fi
	
	#### Useful display variables and info:
	# ${display_string_workflow_title} is the workflow title that may include the target macOS version number.
	# ${jamf_policy_trigger} is the trigger name of the currently running Jamf Pro Policy.
	# ${storage_available_gigabytes} is the number of gigabytes of currently available storage.
	# ${storage_required_gigabytes} is the number of gigabytes required for the current macOS update/upgrade workflow.
	# ${display_string_deadline_count} is the current number of user soft/hard deferrals.
	# ${display_string_deadline_count_maximum} is the maximum number of user soft/hard deferrals.
	# ${deadline_days_soft} is the maximum number of deferral days before a soft deadline.
	# ${deadline_days_hard} is the maximum number of deferral days before a hard deadline.
	# ${display_string_schedule_zero_date} is the date:time of a zero date that is used for calculating deferral deadlines and scheduled installations.
	# ${display_string_scheduled_install} is the date:time of a scheduled installation.
	# ${display_string_deadline} is the soonest date or date and time based on evaluating both the maximum date and days deferral deadlines.
	# ${display_string_prepare_time_estimate} is a estimated number of minutes that an update/upgrade process needs for preparation before a restart.
	# ${current_user_real_name} is the current users full (display friendly) name.
	# See ${DISPLAY_STRING_FORMAT_DATE} and ${DISPLAY_STRING_FORMAT_TIME} in the set_defaults() function to adjust how the date:time is shown.
	# For body text note that IBM Notifier interprets "\n" as a return.
	
	#### Language for notification_install_now_start(), a non-interactive notification informing the user that the install now workflow has started.
	display_string_install_now_start_title="Software Update Workflow Starting"
	display_string_install_now_start_body="The software update workflow has started, and you will be notified if this computer needs to restart.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the macOS software update process."
	
	#### Language for notification_install_now_download(), a non-interactive notification informing the user that the install now workflow is downloading the macOS update/upgrade.
	display_string_install_now_download_title="Downloading ${display_string_workflow_title}"
	display_string_install_now_download_body="The ${display_string_workflow_title} is downloading from Apple. This may take a while, but you will be notified before this computer automatically restarts.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the update/upgrade process."
	
	#### Language for notification_install_now_up_to_date(), a non-interactive notification informing the user that the install now workflow doesn't have anything else to do.
	display_string_install_now_up_to_date_title="Update Workflow Complete"
	display_string_install_now_up_to_date_body="All software is already up to date or is the latest version allowed by management."
	
	#### Language for notification_install_now_failed(), a non-interactive notification informing the user that the install now workflow has failed.
	# This is used for all update/upgrade workflows if they fail to start or timeout after a pending restart notification has been shown.
	display_string_install_now_failed_title="${display_string_workflow_title} Failed"
	display_string_install_now_failed_body="${display_string_workflow_title} installation failed to complete.\n\nYou can try again or consider contacting your technical support team if you're experiencing consistent failures."
	
	#### Language for notification_jamf_pro_policy(), a non-interactive notification informing the user that a Jamf Pro Policy has started.
	# This is used for both non-deadline and deadline workflows.
	display_string_jamf_pro_policy_title="Running Jamf Pro Policy ${jamf_policy_trigger}"
	display_string_jamf_pro_policy_default_body="During this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the process."
	display_string_jamf_pro_policy_deadline_schedule_body="A scheduled installation date of ${display_string_scheduled_install} has passed.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the process."
	display_string_jamf_pro_policy_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the process."
	display_string_jamf_pro_policy_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the process."
	
	#### Language for notification_prepare(), a non-interactive notification informing the user that a update/upgrade preparation process has started.
	# This is used for both non-deadline and deadline workflows.
	display_string_prepare_title="${display_string_workflow_title} System Restart"
	display_string_prepare_default_body="A required software update will automatically restart this computer in about ${display_string_prepare_time_estimate} minutes.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the update process."
	display_string_prepare_deadline_schedule_body="A scheduled installation date of ${display_string_scheduled_install} has passed.\n\nA required software update will automatically restart this computer in about ${display_string_prepare_time_estimate} minutes.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the update process."
	display_string_prepare_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nA required software update will automatically restart this computer in about ${display_string_prepare_time_estimate} minutes.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the update process."
	display_string_prepare_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nA required software update will automatically restart this computer in about ${display_string_prepare_time_estimate} minutes.\n\nDuring this time you can continue to use the computer or lock the screen, but please do not restart or sleep the computer as it will prolong the update process."
	
	#### Language for notification_restart(), a non-interactive notification informing the user that the computer is going to restart very soon.
	# This is used for all softwareupdate workflows and near the end of the MDM workflow.
	# This is used for both non-deadline and deadline workflows.
	display_string_restart_title="${display_string_workflow_title} System Restart"
	display_string_restart_default_body="This computer will automatically restart very soon.\n\nSave any open documents now."
	display_string_restart_deadline_schedule_body="A scheduled installation date of ${display_string_scheduled_install} has passed.\n\nThis computer will automatically restart very soon.\n\nSave any open documents now."
	display_string_restart_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nThis computer will automatically restart very soon.\n\nSave any open documents now."
	display_string_restart_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nThis computer will automatically restart very soon.\n\nSave any open documents now."
	
	#### Language for notification_non_system_updates(), a non-interactive notification informing the user that the workflow is installing non-system macOS software updates.
	display_string_non_system_updates_title="Installing ${display_string_workflow_title} (No Restart)"
	display_string_non_system_updates_body="Required macOS software updates are now installing.\n\nThe computer will not restart but some Apple applications (like Safari) may automatically restart.\n\nThis should only take a few minutes, but please do not restart or sleep the computer as it will prolong the update process."
	
	#### Language for notification_failed(), a non-interactive notification informing the user that the managed update/upgrade process has failed.
	# This is used for all update/upgrade workflows if they fail to start or timeout after a pending restart notification has been shown.
	display_string_failed_title="${display_string_workflow_title} Failed"
	display_string_failed_body="${display_string_workflow_title} installation failed to complete.\n\nYou will be notified later when the installation is attempted again."
	
	#### Language for dialog_insufficient_storage(), a dialog informing the user that there is insufficient storage for macOS update/upgrade.
	# This is used for both non-deadline and deadline workflows.
	display_string_insufficient_storage_title="Insufficient Storage For ${display_string_workflow_title}"
	display_string_insufficient_storage_timeout="* Please remove unecessary items in"
	display_string_insufficient_storage_default_body="A required macOS update needs ${storage_required_gigabytes} GBs of storage space and only ${storage_available_gigabytes} GBs is available.\n\nPlease use the storage settings (shown behind this notification) to remove unnecessary items."
	display_string_insufficient_storage_deadline_schedule_body="A scheduled installation date of ${display_string_scheduled_install} has passed.\n\nA required macOS update needs ${storage_required_gigabytes} GBs of storage space and only ${storage_available_gigabytes} GBs is available.\n\nPlease use the storage settings (shown behind this notification) to remove unnecessary items."
	display_string_insufficient_storage_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nA required macOS update needs ${storage_required_gigabytes} GBs of storage space and only ${storage_available_gigabytes} GBs is available.\n\nPlease use the storage settings (shown behind this notification) to remove unnecessary items."
	display_string_insufficient_storage_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nA required macOS update needs ${storage_required_gigabytes} GBs of storage space and only ${storage_available_gigabytes} GBs is available.\n\nPlease use the storage settings (shown behind this notification) to remove unnecessary items."
	
	#### Language for dialog_power_required(), a dialog notification informing the user that they need to plug the computer into AC power.
	# This is used for both non-deadline and deadline workflows.
	display_string_power_required_title="${display_string_workflow_title} Requires Power Source"
	display_string_power_required_timeout="* Please connect power supply in"
	display_string_power_required_default_body="You must connect this computer to a power supply in order to install the required macOS update."
	display_string_power_required_deadline_schedule_body="A scheduled installation date of ${display_string_scheduled_install} has passed.\n\nYou must connect this computer to a power supply in order to install the required macOS update."
	display_string_power_required_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nYou must connect this computer to a power supply in order to install the required macOS update."
	display_string_power_required_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nYou must connect this computer to a power supply in order to install the required macOS update."
	
	#### Language for dialog_user_choice(), an interactive dialog giving the user a choice to schedule, defer, or restart.
	display_string_user_choice_restart_title="${display_string_workflow_title} Requires System Restart"
	display_string_user_choice_install_title="${display_string_workflow_title} Requires Installation (No Restart)"
	display_string_user_choice_timeout="* Please make selection in"
	display_string_user_choice_menu_title="Defer software update for:"
	display_string_user_choice_default_body="• No deadline date and unlimited deferrals.\n"
	display_string_user_choice_date_body="• Deferral available until ${display_string_deadline}.\n"
	display_string_user_choice_count_body="• ${display_string_deadline_count} out of ${display_string_deadline_count_maximum} deferrals remaining.\n"
	display_string_user_choice_date_count_body="• Deferral available until ${display_string_deadline}.\n\n• ${display_string_deadline_count} out of ${display_string_deadline_count_maximum} deferrals remaining.\n"
	
	#### Language for dialog_user_schedule(), an interactive dialog allowing the user to schedule an installation.
	display_string_user_schedule_restart_title="${display_string_workflow_title} Scheduled System Restart"
	display_string_user_schedule_install_title="${display_string_workflow_title} Scheduled Installation (No Restart)"
	display_string_user_schedule_timeout="* Please make selection in"
	display_string_user_schedule_calendar_title="Select schedule below:"
	display_string_user_schedule_default_body="• Select a date and time to sechedule this event."
	display_string_user_schedule_date_body="• Schedule available until ${display_string_deadline}.\n\n• Select a date and time to sechedule this event."
	
	#### Language for dialog_schedule_reminder(), an interactive dialog that notifies the user of a pending scheduled installation and optionally allows for rescheduling.
	display_string_schedule_reminder_restart_title="${display_string_workflow_title} Scheduled System Restart Reminder"
	display_string_schedule_reminder_install_title="${display_string_workflow_title} Scheduled Installation (No Restart) Reminder"
	display_string_schedule_reminder_restart_timeout="* Automatic restart in"
	display_string_schedule_reminder_install_timeout="* Automatic installation in"
	display_string_schedule_reminder_default_body="• This event is scheduled for ${display_string_scheduled_install}."
	display_string_schedule_reminder_reschedule_date_body="• This event is scheduled for ${display_string_scheduled_install}\n\n• Reschedule available until ${display_string_deadline}."
	display_string_schedule_reminder_adjusted_body="The date and time you selected was adjusted to coordinate with scheduling requirements.\n\n• This event is scheduled for ${display_string_scheduled_install}."
	display_string_schedule_reminder_adjusted_reschedule_date_body="The date and time you selected was adjusted to coordinate with scheduling requirements.\n\n• This event is scheduled for ${display_string_scheduled_install}.\n\n• Reschedule available until ${display_string_deadline}."
	
	#### Language for dialog_soft_deadline(), an interactive dialog when a soft deadline has passed, giving the user only one button to continue the workflow.
	display_string_soft_deadline_restart_title="${display_string_workflow_title} Requires System Restart"
	display_string_soft_deadline_install_title="${display_string_workflow_title} Requires Installation (No Restart)"
	display_string_soft_deadline_restart_timeout="* Automatic restart in"
	display_string_soft_deadline_install_timeout="* Automatic installation in"
	display_string_soft_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times."
	display_string_soft_deadline_date_body="The deferment deadline has passed:\n${display_string_deadline}."
	
	#### Language for dialog_user_auth(), an interactive dialog to collect user credentials for macOS update/upgrade workflow
	display_string_user_auth_title="${display_string_workflow_title} Requires Authentication"
	display_string_user_auth_timeout="* Please enter password in"
	display_string_user_auth_default_body="You must enter the password for user \"${current_user_real_name}\" to install ${display_string_workflow_title}.\n"
	display_string_user_auth_download_body="You must enter the password for user \"${current_user_real_name}\" to download and prepare ${display_string_workflow_title}.\n"
	display_string_user_auth_schedule_body="You must enter the password for user \"${current_user_real_name}\" to schedule the installation of ${display_string_workflow_title}.\n"
	display_string_user_auth_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nYou must enter the password for user \"${current_user_real_name}\" to install the ${display_string_workflow_title}.\n"
	display_string_user_auth_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nYou must enter the password for user \"${current_user_real_name}\" to install the ${display_string_workflow_title}.\n"
	display_string_user_auth_password_title="Enter Password Here:"
	display_string_user_auth_password_placeholder="Password Required"
	display_string_user_auth_retry_default_body="You must enter the password for user \"${current_user_real_name}\" to install ${display_string_workflow_title}.\n"
	display_string_user_auth_retry_download_body="You must enter the password for user \"${current_user_real_name}\" to download and prepare ${display_string_workflow_title}.\n"
	display_string_user_auth_retry_schedule_body="You must enter the password for user \"${current_user_real_name}\" to schedule the installation of ${display_string_workflow_title}.\n"
	display_string_user_auth_retry_deadline_count_body="You have deferred the maximum number of ${display_string_deadline_count_maximum} times.\n\nYou must enter the password for user \"${current_user_real_name}\" to install the ${display_string_workflow_title}.\n"
	display_string_user_auth_retry_deadline_date_body="The deferment deadline of ${display_string_deadline} has passed.\n\nYou must enter the password for user \"${current_user_real_name}\" to install the ${display_string_workflow_title}.\n"
	display_string_user_auth_retry_password_title="Authentication Failed - Try Password Again:"
	display_string_user_auth_retry_password_placeholder="Password Required"
	
	#### The following code sets the appropriate ${display_icon} for macOS light or dark mode but it does not affect the display strings.
	{ [[ "${current_user_appearance_mode}" == "LIGHT" ]] || [[ -z "${current_user_appearance_mode}" ]]; } && display_icon="${display_icon_light}"
	[[ "${current_user_appearance_mode}" == "DARK" ]] && display_icon="${display_icon_dark}"
}

# Set the ${display_string_defer_button} based on the ${deferral_timer_minutes}.
# This also adjusts ${deferral_timer_minutes} given the ${schedule_workflow_active_option}.
set_deferral_button() {
	# If needed adjust the ${deferral_timer_minutes} for the ${schedule_workflow_active_option} and also write to log.
	if [[ -n "${schedule_workflow_active_option}" ]]; then
		deferral_timer_minutes_schedule_workflow_active_check="${deferral_timer_minutes}"
		set_schedule_workflow_active_adjustments
		if [[ -n "${deferral_timer_minutes_schedule_workflow_active_adjusted}" ]]; then
			deferral_timer_minutes="${deferral_timer_minutes_schedule_workflow_active_adjusted}"
		else
			log_super "Warning: The deferral timer is overriding the schedule workflow active option because no coordinating time frame could be resolved."
		fi
		unset deferral_timer_minutes_schedule_workflow_active_check
		unset deferral_timer_minutes_schedule_workflow_active_adjusted
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_minutes is: ${deferral_timer_minutes}"
	fi
	
	# Set ${display_string_defer_button} with text variations based on length.
	local deferral_timer_epoch_temp
	deferral_timer_epoch_temp=$((workflow_time_epoch + (deferral_timer_minutes * 60)))
	local deferral_timer_days_away
	deferral_timer_days_away=$(((deferral_timer_epoch_temp - $(date -v+0d -v0H -v0M -v0S +%s)) / 86400))
	if [[ "${deferral_timer_minutes}" -lt 60 ]]; then
		display_string_defer_button="${display_string_defer_today_button} ${deferral_timer_minutes} ${display_string_minutes}"
	elif [[ "${deferral_timer_minutes}" -eq 60 ]]; then
		display_string_defer_button="${display_string_defer_today_button} 1 ${display_string_hour}"
	elif [[ "${deferral_timer_minutes}" -gt 60 ]] && [[ "${deferral_timer_minutes}" -lt 120 ]]; then
		display_string_defer_button="${display_string_defer_today_button} 1 ${display_string_hour} ${display_string_and} $((deferral_timer_minutes - 60)) ${display_string_minutes}"
	elif [[ "${deferral_timer_minutes}" -ge 120 ]] && [[ "${deferral_timer_minutes}" -lt 1440 ]] && [[ $deferral_timer_days_away -lt 1 ]]; then
		[[ $((deferral_timer_minutes % 60)) -eq 0 ]] && display_string_defer_button="${display_string_defer_today_button} $((deferral_timer_minutes / 60)) ${display_string_hours}"
		[[ $((deferral_timer_minutes % 60)) -ne 0 ]] && display_string_defer_button="${display_string_defer_today_button} $((deferral_timer_minutes / 60)) ${display_string_hours} ${display_string_and} $((deferral_timer_minutes % 60)) ${display_string_minutes}"
	elif [[ $deferral_timer_days_away -eq 1 ]]; then
		display_string_defer_button="${display_string_defer_tomorrow_button}"
	else
		display_string_defer_button="${display_string_defer_future_button} $(date -r "${deferral_timer_epoch_temp}" "+${DISPLAY_STRING_FORMAT_DATE}")"
	fi
}

# Set the ${deferral_timer_menu_minutes_array[*]} and ${display_string_deferral_menu} based on the ${deferral_timer_menu_minutes}.
# This also adjusts ${deferral_timer_menu_minutes} given the ${schedule_workflow_active_option}.
set_deferral_menu() {
	local previous_ifs
	previous_ifs="${IFS}"
	IFS=','
	read -r -a deferral_timer_menu_minutes_array <<<"${deferral_timer_menu_minutes}"
	
	# If needed adjust the ${deferral_timer_menu_minutes} for the ${schedule_workflow_active_option}.
	if [[ -n "${schedule_workflow_active_option}" ]]; then
		local deferral_time_menu_adjusted_array
		deferral_time_menu_adjusted_array=()
		local deferral_timer_menu_adjusted
		deferral_timer_menu_adjusted="FALSE"
		for deferral_timer_menu_item in "${deferral_timer_menu_minutes_array[@]}"; do
			deferral_timer_menu_schedule_workflow_active_check="${deferral_timer_menu_item}"
			set_schedule_workflow_active_adjustments
			[[ -n "${deferral_timer_minutes_schedule_workflow_active_adjusted}" ]] && deferral_time_menu_adjusted_array+=("${deferral_timer_minutes_schedule_workflow_active_adjusted}")
			deferral_timer_menu_adjusted="TRUE"
			unset deferral_timer_menu_schedule_workflow_active_check
			unset deferral_timer_minutes_schedule_workflow_active_adjusted
		done
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_menu_adjusted is: ${deferral_timer_menu_adjusted}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_time_menu_adjusted_array is: ${deferral_time_menu_adjusted_array[*]}"
		if [[ "${deferral_timer_menu_adjusted}" == "TRUE" ]]; then
			if [[ ${#deferral_time_menu_adjusted_array[@]} -gt 1 ]]; then
				deferral_timer_menu_minutes=$(echo "${deferral_time_menu_adjusted_array[*]}" | tr ',' '\n' | uniq | tr '\n' ',' | sed -e 's/,$//')
				log_super "Warning: The deferral timer menu list has been adjusted to ${deferral_timer_menu_minutes} minutes to coordinate with schedule workflow active time frames."
				read -r -a deferral_timer_menu_minutes_array <<<"${deferral_timer_menu_minutes}"
			else
				unset deferral_timer_menu_minutes
				unset deferral_timer_menu_minutes_array
				log_super "Warning: Not showing the deferral timer menu because no coordinating time frames could be resolved."
			fi
		else
			log_super "Warning: Deferral timer menu items are overriding the schedule workflow active option because no coordinating time frames could be resolved."
		fi
	fi
	
	# If there is still a ${deferral_timer_menu_minutes} then set the ${display_string_deferral_menu} variations.
	if [[ -n "${deferral_timer_menu_minutes}" ]]; then
		local deferral_timer_menu_display_array
		read -r -a deferral_timer_menu_display_array <<<"${deferral_timer_menu_minutes}"
		local deferral_timer_epoch_temp
		local deferral_timer_days_away
		for array_index in "${!deferral_timer_menu_display_array[@]}"; do
			deferral_timer_epoch_temp=$((workflow_time_epoch + (deferral_timer_menu_minutes_array[array_index] * 60)))
			deferral_timer_days_away=$(((deferral_timer_epoch_temp - $(date -v+0d -v0H -v0M -v0S +%s)) / 86400))
			if [[ "${deferral_timer_menu_minutes_array[array_index]}" -lt 60 ]]; then
				deferral_timer_menu_display_array[array_index]="${display_string_defer_today_button} ${deferral_timer_menu_minutes_array[array_index]} ${display_string_minutes}"
			elif [[ "${deferral_timer_menu_minutes_array[array_index]}" -eq 60 ]]; then
				deferral_timer_menu_display_array[array_index]="${display_string_defer_today_button} 1 ${display_string_hour}"
			elif [[ "${deferral_timer_menu_minutes_array[array_index]}" -gt 60 ]] && [[ "${deferral_timer_menu_minutes_array[array_index]}" -lt 120 ]]; then
				deferral_timer_menu_display_array[array_index]="${display_string_defer_today_button} 1 ${display_string_hour} ${display_string_and} $((deferral_timer_menu_minutes_array[array_index] - 60)) ${display_string_minutes}"
			elif [[ "${deferral_timer_menu_minutes_array[array_index]}" -ge 120 ]] && [[ "${deferral_timer_menu_minutes_array[array_index]}" -lt 1440 ]] && [[ $deferral_timer_days_away -lt 1 ]]; then
				[[ $((deferral_timer_menu_minutes_array[array_index] % 60)) -eq 0 ]] && deferral_timer_menu_display_array[array_index]="${display_string_defer_today_button} $((deferral_timer_menu_minutes_array[array_index] / 60)) ${display_string_hours}"
				[[ $((deferral_timer_menu_minutes_array[array_index] % 60)) -ne 0 ]] && deferral_timer_menu_display_array[array_index]="${display_string_defer_today_button} $((deferral_timer_menu_minutes_array[array_index] / 60)) ${display_string_hours} ${display_string_and} $((deferral_timer_menu_minutes_array[array_index] % 60)) ${display_string_minutes}"
			elif [[ $deferral_timer_days_away -eq 1 ]]; then
				deferral_timer_menu_display_array[array_index]="${display_string_defer_tomorrow_button}"
			else
				deferral_timer_menu_display_array[array_index]="${display_string_defer_future_button} $(date -r "${deferral_timer_epoch_temp}" "+${DISPLAY_STRING_FORMAT_DATE}")"
			fi
		done
		IFS=$'\n'
		display_string_deferral_menu="${deferral_timer_menu_display_array[*]}"
		display_string_defer_button="${display_string_defer_today_button}"
	fi
	IFS="${previous_ifs}"
}

# Set the ${display_help_button_string} and ${display_warning_button_string} options for the ${ibm_notifier_array}.
set_display_strings_optional_buttons() {
	local curl_response
	if [[ -n "${display_help_button_string}" ]]; then
		if [[ $(echo "${display_help_button_string}" | grep -c '^http://\|^https://\|^mailto:\|^jamfselfservice://') -gt 0 ]]; then
			if [[ $(echo "${display_help_button_string_option}" | grep -c '^http://\|^https://') -gt 0 ]]; then
				curl_response=$(curl -Is "${display_help_button_string_option}" | head -1)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is: ${curl_response}"
				if [[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]] || [[ $(echo "${curl_response}" | grep -c '302') -gt 0 ]]; then
					ibm_notifier_array+=(-help_button_cta_type link -help_button_cta_payload "${display_help_button_string}")
				else
					log_super "Warning: Help button not shown because URL is unreachable: ${display_help_button_string}"
				fi
			else
				ibm_notifier_array+=(-help_button_cta_type link -help_button_cta_payload "${display_help_button_string}")
			fi
		else
			ibm_notifier_array+=(-help_button_cta_type infopopup -help_button_cta_payload "${display_help_button_string}")
		fi
	fi
	if [[ -n "${display_warning_button_string}" ]]; then
		if [[ $(echo "${display_warning_button_string}" | grep -c '^http://\|^https://\|^mailto:\|^jamfselfservice://') -gt 0 ]]; then
			if [[ $(echo "${display_warning_button_string_option}" | grep -c '^http://\|^https://') -gt 0 ]]; then
				curl_response=$(curl -Is "${display_warning_button_string_option}" | head -1)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is: ${curl_response}"
				if [[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]] || [[ $(echo "${curl_response}" | grep -c '302') -gt 0 ]]; then
					ibm_notifier_array+=(-warning_button_cta_type link -warning_button_cta_payload "${display_warning_button_string}")
				else
					log_super "Warning: Warning button not shown because URL is unreachable: ${display_warning_button_string}"
				fi
			else
				ibm_notifier_array+=(-warning_button_cta_type link -warning_button_cta_payload "${display_warning_button_string}")
			fi
		else
			ibm_notifier_array+=(-warning_button_cta_type infopopup -warning_button_cta_payload "${display_warning_button_string}")
		fi
	fi
}

# Open ${IBM_NOTIFIER_BINARY} for non-interactive notifications using the ${ibm_notifier_array} options.
open_notification_ibm_notifier() {
	# Append any additional display options to the ${ibm_notifier_array}.
	set_display_strings_optional_buttons
	{ [[ "${display_unmovable_status}" == "TRUE" ]] || [[ "${display_unmovable_status}" == "TEMP" ]]; } && ibm_notifier_array+=(-unmovable)
	{ [[ "${display_hide_background_status}" == "TRUE" ]] || [[ "${display_hide_background_status}" == "TEMP" ]]; } && ibm_notifier_array+=(-background_panel translucent)
	{ [[ "${display_silently_status}" == "TRUE" ]] || [[ "${display_silently_status}" == "TEMP" ]]; } && ibm_notifier_array+=(-silent)
	if [[ "${display_notifications_centered_status}" == "TRUE" ]]; then
		ibm_notifier_array+=(-position center -always_on_top -disable_quit)
	else # The default notification location.
		ibm_notifier_array+=(-position top_right -always_on_top -disable_quit)
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	
	# Kill any previous notifications so new ones can take its place.
	killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
	
	# Start IBM Notifier and wait for for ${notification_response} and ${notification_return}.
	unset notification_response
	unset notification_return
	notification_response=$("${IBM_NOTIFIER_BINARY}" "${ibm_notifier_array[@]}")
	notification_return="$?"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: notification_response is: ${notification_response}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: notification_return is: ${notification_return}"
}

# Open ${IBM_NOTIFIER_BINARY} for interactive dialogs using the ${ibm_notifier_array} options, also handle any ${dialog_timeout_seconds}, ${display_accessory_content}, and ${display_accessory_payload} options, and set ${dialog_response} and ${dialog_return}.
open_dialog_ibm_notifier() {
	# If needed acquire and validate the ${display_accessory_content} option.
	local display_accessory_payload
	local display_accessory_enabled
	display_accessory_enabled="FALSE"
	local curl_response
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_content is: ${display_accessory_content}"
	if [[ -n "${display_accessory_content}" ]] && [[ "${dialog_type}" != "ALERT" ]] && [[ "${dialog_type}" != "SCHEDULE" ]]; then
		if [[ $(echo "${display_accessory_content}" | grep -c '^http://\|^https://') -gt 0 ]]; then
			if [[ "${display_accessory_type}" =~ ^TEXTBOX$|^HTMLBOX$|^HTML$ ]]; then
				display_accessory_payload=$(curl -s -f "${display_accessory_content}")
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_payload is:\n${display_accessory_payload}"
				if [[ -n "${display_accessory_payload}" ]]; then
					display_accessory_enabled="TRUE"
				else
					log_super "Warning: Custom display accessory not shown because URL failed to download: ${display_accessory_content}"
				fi
			else # ${display_accessory_type} is IMAGE or VIDEO or VIDEOAUTO.
				curl_response=$(curl -Is "${display_accessory_content}" | head -1)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: curl_response is: ${curl_response}"
				if [[ $(echo "${curl_response}" | grep -c '200') -gt 0 ]] || [[ $(echo "${curl_response}" | grep -c '302') -gt 0 ]]; then
					display_accessory_payload="${display_accessory_content}"
					display_accessory_enabled="TRUE"
				else
					log_super "Warning: Custom display accessory not shown because URL is unreachable: ${display_accessory_content}"
				fi
			fi
		else # Assume it's a local path.
			if [[ "${display_accessory_type}" =~ ^TEXTBOX$|^HTMLBOX$|^HTML$ ]]; then
				display_accessory_payload=$(<"${display_accessory_content}")
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_payload is:\n${display_accessory_payload}"
				if [[ -n "${display_accessory_payload}" ]]; then
					display_accessory_enabled="TRUE"
				else
					log_super "Warning: Custom display accessory not shown because file path could not be read: ${display_accessory_content}"
				fi
			else # ${display_accessory_type} is IMAGE or VIDEO or VIDEOAUTO.
				if [[ -f "${display_accessory_content}" ]]; then
					display_accessory_payload="${display_accessory_content}"
					display_accessory_enabled="TRUE"
				else
					log_super "Warning: Custom display accessory not shown because file path does not exist: ${display_accessory_content}"
				fi
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_enabled is: ${display_accessory_enabled}"
	
	# Append any additional display accessory options to the ${ibm_notifier_array}.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_type is: ${dialog_type}"
	if [[ "${dialog_type}" == "ALERT" ]]; then
		if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
			ibm_notifier_array+=(-buttonless)
			[[ -n "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-accessory_view_type timer -accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}")
		else # The default alert dialog progress bar.
			[[ -z "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
			[[ -n "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-accessory_view_type timer -accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}" -secondary_accessory_view_type progressbar -secondary_accessory_view_payload "/percent indeterminate")
		fi
	elif [[ "${dialog_type}" == "SCHEDULE" ]]; then
		ibm_notifier_array+=(-accessory_view_type datepicker -accessory_view_payload "${display_accessory_datepicker_payload}")
		[[ -n "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-secondary_accessory_view_type timer -secondary_accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}" )
	else # Remaining ${dialog_type}s can take advantage of ${display_accessory_type}; CHOICE, REMINDER, SOFT, AUTH.
		if [[ "${display_accessory_enabled}" == "TRUE" ]]; then # Custom display accessory enabled.
			[[ "${display_accessory_type}" == "TEXTBOX" ]] && ibm_notifier_array+=(-accessory_view_type whitebox -accessory_view_payload "${display_accessory_payload}")
			[[ "${display_accessory_type}" == "HTMLBOX" ]] && ibm_notifier_array+=(-accessory_view_type htmlwhitebox -accessory_view_payload "${display_accessory_payload}")
			[[ "${display_accessory_type}" == "HTML" ]] && ibm_notifier_array+=(-accessory_view_type html -accessory_view_payload "${display_accessory_payload}")
			[[ "${display_accessory_type}" == "IMAGE" ]] && ibm_notifier_array+=(-accessory_view_type image -accessory_view_payload "${display_accessory_payload}")
			[[ "${display_accessory_type}" == "VIDEO" ]] && ibm_notifier_array+=(-accessory_view_type video -accessory_view_payload "/url ${display_accessory_payload}")
			[[ "${display_accessory_type}" == "VIDEOAUTO" ]] && ibm_notifier_array+=(-accessory_view_type video -accessory_view_payload "/url ${display_accessory_payload} /autoplay")
			if [[ "${dialog_type}" == "CHOICE" ]]; then
				{ [[ -n "${deferral_timer_menu_minutes}" ]] && [[ -z "${dialog_timeout_seconds}" ]]; } && ibm_notifier_array+=(-secondary_accessory_view_type dropdown -secondary_accessory_view_payload "/title ${display_string_user_choice_menu_title} /list ${display_string_deferral_menu} /selected 0")
				{ [[ -z "${deferral_timer_menu_minutes}" ]] && [[ -n "${dialog_timeout_seconds}" ]]; } && ibm_notifier_array+=(-secondary_accessory_view_type timer -secondary_accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}")
				if [[ -n "${deferral_timer_menu_minutes}" ]] && [[ -n "${dialog_timeout_seconds}" ]]; then
					log_super "Warning: Unable to show --dialog-timeout-* countdown due to the --display-accessory-* option. However, there is still a display timeout at ${dialog_timeout_seconds} seconds."
					ibm_notifier_array+=(-secondary_accessory_view_type dropdown -secondary_accessory_view_payload "/title ${display_string_user_choice_menu_title} /list ${display_string_deferral_menu} /selected 0" -timeout "${dialog_timeout_seconds}")
				fi
			elif [[ "${dialog_type}" == "AUTH" ]]; then
				[[ -z "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-secondary_accessory_view_type secureinput -secondary_accessory_view_payload "${display_accessory_secure_payload}")
				if [[ -n "${dialog_timeout_seconds}" ]]; then
					log_super "Warning: Unable to show --dialog-timeout-* countdown due to the --display-accessory-* option. However, there is still a display timeout at ${dialog_timeout_seconds} seconds."
					ibm_notifier_array+=(-secondary_accessory_view_type secureinput -secondary_accessory_view_payload "${display_accessory_secure_payload}" -timeout "${dialog_timeout_seconds}")
				fi
			else # Remaining ${dialog_type}s; REMINDER, SOFT.
				[[ -n "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-secondary_accessory_view_type timer -accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}")
			fi
		else # No custom display accessory.
			if [[ "${dialog_type}" == "CHOICE" ]]; then
				{ [[ -n "${deferral_timer_menu_minutes}" ]] && [[ -z "${dialog_timeout_seconds}" ]]; } && ibm_notifier_array+=(-accessory_view_type dropdown -accessory_view_payload "/title ${display_string_user_choice_menu_title} /list ${display_string_deferral_menu} /selected 0")
				{ [[ -z "${deferral_timer_menu_minutes}" ]] && [[ -n "${dialog_timeout_seconds}" ]]; } && ibm_notifier_array+=(-accessory_view_type timer -accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}")
				{ [[ -n "${dialog_timeout_seconds}" ]] && [[ -n "${deferral_timer_menu_minutes}" ]]; } && ibm_notifier_array+=(-accessory_view_type dropdown -accessory_view_payload "/title ${display_string_user_choice_menu_title} /list ${display_string_deferral_menu} /selected 0" -secondary_accessory_view_type timer -secondary_accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}")
			elif [[ "${dialog_type}" == "AUTH" ]]; then
				ibm_notifier_array+=(-accessory_view_type secureinput -accessory_view_payload "${display_accessory_secure_payload}")
				[[ -n "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-secondary_accessory_view_type timer -secondary_accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}" )
			else # Remaining ${dialog_type}s; REMINDER, SOFT.
				[[ -n "${dialog_timeout_seconds}" ]] && ibm_notifier_array+=(-accessory_view_type timer -accessory_view_payload "${display_string_dialog_timeout} %@" -timeout "${dialog_timeout_seconds}")
			fi
		fi
	fi
	set_display_strings_optional_buttons
	{ [[ "${display_unmovable_status}" == "TRUE" ]] || [[ "${display_unmovable_status}" == "TEMP" ]]; } && ibm_notifier_array+=(-unmovable)
	{ [[ "${display_hide_background_status}" == "TRUE" ]] || [[ "${display_hide_background_status}" == "TEMP" ]]; } && ibm_notifier_array+=(-background_panel translucent)
	{ [[ "${display_silently_status}" == "TRUE" ]] || [[ "${display_silently_status}" == "TEMP" ]]; } && ibm_notifier_array+=(-silent)
	ibm_notifier_array+=(-position center -always_on_top -disable_quit)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	
	# Kill any previous notifications so new ones can take its place.
	killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
	
	# Start IBM Notifier and wait for ${dialog_response} and ${dialog_return}.
	unset dialog_response
	unset dialog_return
	dialog_response=$("${IBM_NOTIFIER_BINARY}" "${ibm_notifier_array[@]}")
	dialog_return="$?"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ "${dialog_type}" != "AUTH" ]]; } && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_response is: ${dialog_response}"
	{ [[ "${verbose_mode_option}" == "TRUE" ]] && [[ "${dialog_type}" == "AUTH" ]]; } && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_response is: ${dialog_response}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_return is: ${dialog_return}"
}

# MARK: *** Install Now Notifications ***
################################################################################

# Display a non-interactive notification informing the user that the install now workflow has started.
notification_install_now_start() {
	set_display_strings_language
	log_super "IBM Notifier: Install now start notification."
	ibm_notifier_array=(-type popup -bar_title "${display_string_install_now_start_title}" -subtitle "${display_string_install_now_start_body}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Handle the ${display_hide_progress_bar_status} option.
	if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
		ibm_notifier_array+=(-buttonless)
	else # The default notification progress bar.
		ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
	fi
	
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	open_notification_ibm_notifier &
}

# Display a non-interactive notification informing the user that the install now workflow is downloading the macOS update/upgrade.
notification_install_now_download() {
	set_display_strings_language
	log_super "IBM Notifier: Install now downloading notification."
	ibm_notifier_array=(-type popup -bar_title "${display_string_install_now_download_title}" -subtitle "${display_string_install_now_download_body}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Handle the ${display_hide_progress_bar_status} option.
	if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
		ibm_notifier_array+=(-buttonless)
	else # The default notification progress bar.
		ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
	fi
	
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	open_notification_ibm_notifier &
}

# Display a non-interactive notification informing the user that macOS is up to date.
notification_install_now_up_to_date() {
	set_display_strings_language
	unset display_hide_progress_bar_status
	log_super "IBM Notifier: Install now macOS software is already up to date notification."
	ibm_notifier_array=(-type popup -bar_title "${display_string_install_now_up_to_date_title}" -subtitle "${display_string_install_now_up_to_date_body}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${display_string_ok_button}")
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	open_notification_ibm_notifier &
	disown -a
}

# Display a non-interactive notification informing the user that the install now workflow has failed.
notification_install_now_failed() {
	set_display_strings_language
	unset display_hide_progress_bar_status
	log_super "IBM Notifier: Install now failure notification."
	ibm_notifier_array=(-type popup -bar_title "${display_string_install_now_failed_title}" -subtitle "${display_string_install_now_failed_body}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${display_string_ok_button}")
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	open_notification_ibm_notifier &
	disown -a
}

# MARK: *** Default Notifications ***
################################################################################

# Display a non-interactive notification informing the user that a Jamf Pro Policy has started.
notification_jamf_pro_policy() {
	set_display_strings_language
	
	# The initial ${ibm_notifier_array} settings for the preparing update notification.
	ibm_notifier_array=(-type popup -bar_title "${display_string_jamf_pro_policy_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Variations for the main body text of the preparing update notification.
	if [[ "${workflow_scheduled_install_now}" == "TRUE" ]]; then
		log_super "IBM Notifier: Running Jamf Pro Policy secheduled installation notification."
		ibm_notifier_array+=(-subtitle "${display_string_jamf_pro_policy_deadline_schedule_body}")
	elif [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]]; then
		log_super "IBM Notifier: Running Jamf Pro Policy deadline date notification."
		ibm_notifier_array+=(-subtitle "${display_string_jamf_pro_policy_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
		log_super "IBM Notifier: Running Jamf Pro Policy deadline count notification."
		ibm_notifier_array+=(-subtitle "${display_string_jamf_pro_policy_deadline_count_body}")
	else # No deadlines, this is the default preparing update notification.
		log_super "IBM Notifier: Running Jamf Pro Policy default notification."
		ibm_notifier_array+=(-subtitle "${display_string_jamf_pro_policy_default_body}")
	fi
	
	# Handle the ${display_hide_progress_bar_status} option.
	if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
		ibm_notifier_array+=(-buttonless)
	else # The default notification progress bar.
		ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
	fi
	
	# Open notification in the background allowing super to continue.
	open_notification_ibm_notifier &
}

# Display a non-interactive notification informing the user that an update/upgrade that requires preparation has started.
notification_prepare() {
	set_display_strings_language
	
	# The initial ${ibm_notifier_array} settings for the preparing update notification.
	ibm_notifier_array=(-type popup -bar_title "${display_string_prepare_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Variations for the main body text of the preparing update notification.
	if [[ "${workflow_scheduled_install_now}" == "TRUE" ]]; then
		log_super "IBM Notifier: Preparing update/upgrade secheduled installation notification showing a ${display_string_prepare_time_estimate} minute estimate."
		ibm_notifier_array+=(-subtitle "${display_string_prepare_deadline_schedule_body}")
	elif [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]]; then
		log_super "IBM Notifier: Preparing update/upgrade deadline date notification showing a ${display_string_prepare_time_estimate} minute estimate."
		ibm_notifier_array+=(-subtitle "${display_string_prepare_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
		log_super "IBM Notifier: Preparing update/upgrade deadline count notification showing a ${display_string_prepare_time_estimate} minute estimate."
		ibm_notifier_array+=(-subtitle "${display_string_prepare_deadline_count_body}")
	else # No deadlines, this is the default preparing update notification.
		log_super "IBM Notifier: Preparing update/upgrade default notification showing a ${display_string_prepare_time_estimate} minute estimate."
		ibm_notifier_array+=(-subtitle "${display_string_prepare_default_body}")
	fi
	
	# Handle the ${display_hide_progress_bar_status} option.
	if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
		ibm_notifier_array+=(-buttonless)
	else # The default notification progress bar.
		ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
	fi
	
	# Open notification in the background allowing super to continue.
	open_notification_ibm_notifier &
}

# Display a non-interactive notification informing the user that the computer going to restart soon.
notification_restart() {
	set_display_strings_language
	
	# The initial ${ibm_notifier_array} settings for the restart notification.
	ibm_notifier_array=(-type popup -bar_title "${display_string_restart_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Variations for the main body text of the restart notification.
	if [[ "${workflow_scheduled_install_now}" == "TRUE" ]]; then
		log_super "IBM Notifier: Restart secheduled installation notification."
		ibm_notifier_array+=(-subtitle "${display_string_restart_deadline_schedule_body}")
	elif [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]]; then
		log_super "IBM Notifier: Restart deadline date notification."
		ibm_notifier_array+=(-subtitle "${display_string_restart_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
		log_super "IBM Notifier: Restart deadline count notification."
		ibm_notifier_array+=(-subtitle "${display_string_restart_deadline_count_body}")
	else # No deadlines, this is the default restart notification.
		log_super "IBM Notifier: Restart default notification."
		ibm_notifier_array+=(-subtitle "${display_string_restart_default_body}")
	fi
	
	# Handle the ${display_hide_progress_bar_status} option.
	if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
		ibm_notifier_array+=(-buttonless)
	else # The default notification progress bar.
		ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
	fi
	
	# Open notification in the background allowing super to continue.
	open_notification_ibm_notifier &
}

# Display a non-interactive notification informing the user that the install now workflow is installing non-system macOS software updates.
notification_non_system_updates() {
	set_display_strings_language
	log_super "IBM Notifier: Installing non-system macOS software updates notification."
	ibm_notifier_array=(-type popup -bar_title "${display_string_non_system_updates_title}" -subtitle "${display_string_non_system_updates_body}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")

	# Handle the ${display_hide_progress_bar_status} option.
	if [[ "${display_hide_progress_bar_status}" == "TRUE" ]] || [[ "${display_hide_progress_bar_status}" == "TEMP" ]]; then
		ibm_notifier_array+=(-buttonless)
	else # The default notification progress bar.
		ibm_notifier_array+=(-accessory_view_type progressbar -accessory_view_payload "/percent indeterminate")
	fi

	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	open_notification_ibm_notifier &
}

# Display a non-interactive notification informing the user that update process has failed.
notification_failed() {
	set_display_strings_language
	set_deferral_button
	unset display_hide_progress_bar_status
	log_super "IBM Notifier: Failure notification."
	ibm_notifier_array=(-type popup -bar_title "${display_string_failed_title}" -subtitle "${display_string_failed_body}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${display_string_defer_button}")
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: ibm_notifier_array is:\n${ibm_notifier_array[*]}"
	open_notification_ibm_notifier &
	disown -a
}

# MARK: *** Interactive Dialogs ***
################################################################################

# Display a dialog informing the user there is insufficient storage for a macOS update/upgrade.
dialog_insufficient_storage() {
	dialog_insufficient_storage_error="FALSE"
	log_super "Warning: Current available storage is at ${storage_available_gigabytes} GBs which is below the ${storage_required_gigabytes} GBs that is required for macOS update/upgrade workflow."
	log_status "Running: Dialog insufficient storage."
	set_display_strings_language
	unset dialog_timeout_seconds
	[[ -n "${dialog_timeout_insufficient_storage_seconds}" ]] && dialog_timeout_seconds="${dialog_timeout_insufficient_storage_seconds}"
	{ [[ -z "${dialog_timeout_insufficient_storage_seconds}" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && dialog_timeout_seconds="${dialog_timeout_default_seconds}"
	
	# The initial ${ibm_notifier_array} settings for the insufficient storage dialog.
	ibm_notifier_array=(-type popup -bar_title "${display_string_insufficient_storage_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Variations for the main body text of the insufficient storage dialog.
	if [[ "${workflow_scheduled_install_now}" == "TRUE" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage secheduled installation dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage secheduled installation dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_insufficient_storage_deadline_schedule_body}")
	elif [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage deadline date dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage deadline date dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_insufficient_storage_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage deadline count dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage deadline count dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_insufficient_storage_deadline_count_body}")
	else # No deadlines, this is the default insufficient storage dialog.
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage default dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Insufficient storage default dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_insufficient_storage_default_body}")
	fi
	[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_insufficient_storage_timeout}"
	
	# Open the appropriate storage assistant and the insufficient storage dialog.
	if [[ "${macos_version_major}" -ge 13 ]]; then
		log_super "Status: Opening the Storage pane of the System Settings.app."
		sudo -u "${current_user_account_name}" open "x-apple.systempreferences:com.apple.settings.Storage" &
	else
		log_super "Status: Opening the Storage Management.app."
		sudo -u "${current_user_account_name}" open "/System/Library/CoreServices/Applications/Storage Management.app" &
	fi
	
	# Manage ${display_unmovable_option}, ${display_hide_background_option}, ${display_silently_option}, and ${display_hide_progress_bar_option}.
	{ [[ "${display_unmovable_status}" != "TRUE" ]] && [[ $(echo "${display_unmovable_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_unmovable_status="TEMP"
	[[ "${display_hide_background_status}" == "TRUE" ]] && display_hide_background_status="TEMPOFF" # Don't want to ever hide the background for this one so the user can try to use the storage optimizer.
	{ [[ "${display_silently_status}" != "TRUE" ]] && [[ $(echo "${display_silently_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_silently_status="TEMP"
	{ [[ "${display_hide_progress_bar_status}" != "TRUE" ]] && [[ $(echo "${display_hide_progress_bar_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_hide_progress_bar_status="TEMP"
	
	# Open the initial insufficient storage dialog.
	dialog_type="ALERT"
	open_dialog_ibm_notifier &
	unset dialog_type
	
	# This handles waiting for available storage along with the ${dialog_timeout_seconds} option.
	local dialog_insufficient_storage_check_timeout
	[[ -n "${dialog_timeout_seconds}" ]] && dialog_insufficient_storage_check_timeout="${dialog_timeout_seconds}"
	[[ -z "${dialog_timeout_seconds}" ]] && dialog_insufficient_storage_check_timeout=1
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: STORAGE_REQUIRED_RECHECK_SECONDS is: ${STORAGE_REQUIRED_RECHECK_SECONDS}"
	while [[ "${dialog_insufficient_storage_check_timeout}" -ge 0 ]]; do
		sleep $STORAGE_REQUIRED_RECHECK_SECONDS
		check_storage_available
		if [[ "${check_storage_available_error}" == "FALSE" ]]; then
			if [[ "${storage_ready}" == "TRUE" ]]; then
				log_super "Status: Current available storage is now at ${storage_available_gigabytes} GBs, the macOS update/upgrade workflow can continue."
				killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
				break
			fi
		else # "${check_storage_available_error}" == "FALSE"
			dialog_insufficient_storage_error="TRUE"
			break
		fi
		[[ -n "${dialog_timeout_seconds}" ]] && dialog_insufficient_storage_check_timeout=$((dialog_insufficient_storage_check_timeout - STORAGE_REQUIRED_RECHECK_SECONDS))
	done
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_insufficient_storage_error is: ${dialog_insufficient_storage_error}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: storage_ready is: ${storage_ready}"
	
	# Reset temporary ${display_unmovable_option}, ${display_hide_background_option}, ${display_silently_option}, and ${display_hide_progress_bar_option}.
	[[ "${display_unmovable_status}" == "TEMP" ]] && unset display_unmovable_status
	[[ "${display_hide_background_status}" == "TEMPOFF" ]] && unset display_hide_background_status
	[[ "${display_silently_status}" == "TEMP" ]] && unset display_silently_status
	[[ "${display_hide_progress_bar_status}" == "TEMP" ]] && unset display_hide_progress_bar_status
	
	# If there still is not sufficient storage, then error.
	if [[ "${dialog_insufficient_storage_error}" == "FALSE" ]] && [[ "${storage_ready}" == "FALSE" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "Error: Waiting for user to make more storage available timed out after ${dialog_timeout_seconds} seconds."
		dialog_insufficient_storage_error="TRUE"
	fi
	[[ "${display_hide_background_status}" == "TEMPOFF" ]] && display_hide_background_status="TRUE"
}

# Display a dialog informing the user they need to plug the computer into AC power.
dialog_power_required() {
	local power_required_charger_connected
	power_required_charger_connected="FALSE"
	dialog_power_required_error="FALSE"
	log_super "Warning: Current battery level is at ${power_battery_percent}% which is below the minimum required level of ${power_required_battery_percent}%."
	log_status "Running: Dialog power required."
	set_display_strings_language
	unset dialog_timeout_seconds
	[[ -n "${dialog_timeout_power_required_seconds}" ]] && dialog_timeout_seconds="${dialog_timeout_power_required_seconds}"
	{ [[ -z "${dialog_timeout_power_required_seconds}" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && dialog_timeout_seconds="${dialog_timeout_default_seconds}"
	
	# The initial ${ibm_notifier_array} settings for the power required dialog.
	ibm_notifier_array=(-type popup -bar_title "${display_string_power_required_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Variations for the main body text of the power required dialog.
	if [[ "${workflow_scheduled_install_now}" == "TRUE" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required secheduled installation dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required secheduled installation dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_power_required_deadline_schedule_body}")
	elif [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required deadline date dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required deadline date dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_power_required_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required deadline count dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required deadline count dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_power_required_deadline_count_body}")
	else # No deadlines, this is the default power required dialog.
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required default dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Power required default dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_power_required_default_body}")
	fi
	[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_power_required_timeout}"
	
	# Manage ${display_unmovable_option}, ${display_hide_background_option}, ${display_silently_option}, and ${display_hide_progress_bar_option}.
	{ [[ "${display_unmovable_status}" != "TRUE" ]] && [[ $(echo "${display_unmovable_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_unmovable_status="TEMP"
	{ [[ "${display_hide_background_status}" != "TRUE" ]] && [[ $(echo "${display_hide_background_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_hide_background_status="TEMP"
	{ [[ "${display_silently_status}" != "TRUE" ]] && [[ $(echo "${display_silently_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_silently_status="TEMP"
	{ [[ "${display_hide_progress_bar_status}" != "TRUE" ]] && [[ $(echo "${display_hide_progress_bar_option}" | grep -c 'ERROR') -gt 0 ]]; } && display_hide_progress_bar_status="TEMP"
	
	# Open the initial power required dialog.
	dialog_type="ALERT"
	open_dialog_ibm_notifier &
	unset dialog_type
	
	# This handles waiting for AC power along with the ${dialog_timeout_power_required_seconds} option.
	local dialog_power_required_check_timeout
	[[ -n "${dialog_timeout_seconds}" ]] && dialog_power_required_check_timeout="${dialog_timeout_seconds}"
	[[ -z "${dialog_timeout_seconds}" ]] && dialog_power_required_check_timeout=1
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: POWER_REQUIRED_RECHECK_SECONDS is: ${POWER_REQUIRED_RECHECK_SECONDS}"
	while [[ "${dialog_power_required_check_timeout}" -ge 0 ]]; do
		sleep $POWER_REQUIRED_RECHECK_SECONDS
		[[ $(pmset -g ps | grep -ic 'AC Power') -ne 0 ]] && power_required_charger_connected="TRUE"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_required_charger_connected: ${power_required_charger_connected}"
		if [[ "${power_required_charger_connected}" == "TRUE" ]]; then
			log_super "Status: AC power detected, the macOS update/upgrade workflow can continue."
			killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
			break
		fi
		[[ -n "${dialog_timeout_seconds}" ]] && dialog_power_required_check_timeout=$((dialog_power_required_check_timeout - POWER_REQUIRED_RECHECK_SECONDS))
	done
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: power_required_charger_connected is: ${power_required_charger_connected}"
	
	# Reset temporary ${display_unmovable_option}, ${display_hide_background_option}, ${display_silently_option}, and ${display_hide_progress_bar_option}.
	[[ "${display_unmovable_status}" == "TEMP" ]] && unset display_unmovable_status
	[[ "${display_hide_background_status}" == "TEMP" ]] && unset display_hide_background_status
	[[ "${display_silently_status}" == "TEMP" ]] && unset display_silently_status
	[[ "${display_hide_progress_bar_status}" == "TEMP" ]] && unset display_hide_progress_bar_status
	
	# If there still is no AC power, then exit.
	if [[ "${power_required_charger_connected}" == "FALSE" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "Error: Waiting for user to connect AC power timed out after ${dialog_timeout_seconds} seconds."
		dialog_power_required_error="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_power_required_error is: ${dialog_power_required_error}"
}

# Display an interactive dialog with schedule, defer, and restart options. This sets ${dialog_user_choice_return} and if ${deferral_timer_menu_minutes} then also sets ${deferral_timer_minutes}.
dialog_user_choice() {
	set_display_strings_language
	log_status "Running: Dialog user choice."
	unset dialog_timeout_seconds
	[[ -n "${dialog_timeout_user_choice_seconds}" ]] && dialog_timeout_seconds="${dialog_timeout_user_choice_seconds}"
	{ [[ -z "${dialog_timeout_user_choice_seconds}" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && dialog_timeout_seconds="${dialog_timeout_default_seconds}"
	[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User choice dialog with a ${dialog_timeout_seconds} second timeout."
	[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User choice dialog with no timeout."
	
	# Set the user choice title and button display strings.
	local display_string_user_choice_title
	local dialog_user_choice_now_button
	local dialog_user_choice_schedule_button
	if [[ "${workflow_target}" == "Non-system Software Updates" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]]; then
		display_string_user_choice_title="${display_string_user_choice_install_title}"
		dialog_user_choice_now_button="${display_string_install_now_button}"
		dialog_user_choice_schedule_button="${display_string_schedule_install_button}"
	else # Default restart workflows.
		display_string_user_choice_title="${display_string_user_choice_restart_title}"
		dialog_user_choice_now_button="${display_string_restart_now_button}"
		dialog_user_choice_schedule_button="${display_string_schedule_restart_button}"
	fi
	
	# Create initial ${ibm_notifier_array} settings for the dialog.
	ibm_notifier_array=(-type popup -bar_title "${display_string_user_choice_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}")
	
	# Body text variations based on deadline options.
	if [[ -n "${display_string_deadline}" ]] && [[ -n "${display_string_deadline_count}" ]]; then # Show both date and maximum deferral count deadlines.
		ibm_notifier_array+=(-subtitle "${display_string_user_choice_date_count_body}")
	elif [[ -n "${display_string_deadline}" ]]; then # Show only date deadline.
		ibm_notifier_array+=(-subtitle "${display_string_user_choice_date_body}")
	elif [[ -n "${display_string_deadline_count}" ]]; then # Show only maximum deferral count deadline.
		ibm_notifier_array+=(-subtitle "${display_string_user_choice_count_body}")
	else # Show no deadlines.
		ibm_notifier_array+=(-subtitle "${display_string_user_choice_default_body}")
	fi
	[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_user_choice_timeout}"
	
	# Display either the deferral menu or just the standard deferral button.
	[[ -n "${deferral_timer_menu_minutes}" ]] && set_deferral_menu
	[[ -z "${display_string_deferral_menu}" ]] && set_deferral_button
	
	# Provide logging for workflow conditions related to the ${scheduled_install_user_choice_option}.
	if [[ "${scheduled_install_user_choice_option}" == "TRUE" ]] && { [[ "${workflow_target}" != "Non-system Software Updates" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers Without Restarting" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers With Restart" ]] && [[ "${workflow_target}" != "Restart Without Updates" ]]; } && { [[ "${workflow_auth_error}" == "TRUE" ]] || [[ "${workflow_macos_auth}" == "USER" ]]; } && { ! [[ "${auth_ask_user_to_save_password}" == "TRUE" ]] && [[ "${auth_user_account_saved}" == "FALSE" ]]; }; then
		log_super "Warning: The --scheduled-install-user-choice option requires valid saved authenticion. This option will not be show in the user choice dialog."
		scheduled_install_user_choice_option="FALSE"
	fi
	
	# Set the user choice buttons including handling of ${scheduled_install_user_choice_option}.
	if [[ "${scheduled_install_user_choice_option}" == "TRUE" ]]; then
		ibm_notifier_array+=(-main_button_label "${display_string_defer_button}" -secondary_button_label "${dialog_user_choice_now_button}" -tertiary_button_label "${dialog_user_choice_schedule_button}" -tertiary_button_cta_type exitlink -tertiary_button_cta_payload "")
	else # Default user choice buttons.
		ibm_notifier_array+=(-main_button_label "${display_string_defer_button}" -secondary_button_label "${dialog_user_choice_now_button}")
	fi
	
	# Manage ${display_unmovable_option}, ${display_hide_background_option}, and ${display_silently_option} options.
	{ [[ "${display_unmovable_status}" != "TRUE" ]] && [[ $(echo "${display_unmovable_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_unmovable_status="TEMP"
	{ [[ "${display_hide_background_status}" != "TRUE" ]] && [[ $(echo "${display_hide_background_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_hide_background_status="TEMP"
	{ [[ "${display_silently_status}" != "TRUE" ]] && [[ $(echo "${display_silently_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_silently_status="TEMP"
	
	# Start the dialog.
	dialog_type="CHOICE"
	open_dialog_ibm_notifier
	unset dialog_type
	
	# Reset temporary ${display_unmovable_option}, ${display_hide_background_option}, and ${display_silently_option} options.
	[[ "${display_unmovable_status}" == "TEMP" ]] && unset display_unmovable_status
	[[ "${display_hide_background_status}" == "TEMP" ]] && unset display_hide_background_status
	[[ "${display_silently_status}" == "TEMP" ]] && unset display_silently_status
	
	# The ${dialog_return} contains the IBM Notifier.app return code. If the user selected a scheduled deferral or the dialog timed out then set ${deferral_timer_minutes}.
	case "${dialog_return}" in
	0)
		if [[ -n "${deferral_timer_menu_minutes}" ]]; then
			dialog_response="$(echo "${dialog_response}" | sed -e 's/[^0-9]*//g' | tr -d '\n')"
			deferral_timer_minutes="${deferral_timer_menu_minutes_array[${dialog_response}]}"
			log_super "Status: User chose to defer for ${deferral_timer_minutes} minutes."
			log_status "Pending: User chose to defer for ${deferral_timer_minutes} minutes."
		else
			log_super "Status: User chose to defer, setting a deferral of ${deferral_timer_minutes} minutes."
			log_status "Pending: User chose to defer, setting a deferral of ${deferral_timer_minutes} minutes."
		fi
		set_auto_launch_deferral
		;;
	2)
		log_super "Status: User chose to install now."
		workflow_install_active_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
		;;
	3)
		log_super "Status: User chose to schedule the installation."
		dialog_user_schedule # This function includes all workflows to facilitate user schedule selection.
		;;
	4 | 255)
		if [[ -n "${deferral_timer_menu_minutes}" ]]; then
			dialog_response="$(echo "${dialog_response}" | sed -e 's/[^0-9]*//g' | tr -d '\n')"
			deferral_timer_minutes="${deferral_timer_menu_minutes_array[${dialog_response}]}"
			log_super "Status: Display timeout automatically chose to defer for ${deferral_timer_minutes} minutes."
			log_status "Pending: Display timeout automatically chose to defer for ${deferral_timer_minutes} minutes."
		else
			log_super "Status: Display timeout automatically chose to defer, using the default deferral of ${deferral_timer_minutes} minutes."
			log_status "Pending: Display timeout automatically chose to defer, using the default deferral of ${deferral_timer_minutes} minutes."
		fi
		set_auto_launch_deferral
		;;
	esac
}

# Display an interactive dialog allowing the user to schedule an installation.
dialog_user_schedule() {
	# First check if the user's password needs to be saved.
	if [[ "${mac_cpu_architecture}" == "arm64" ]] && [[ "${auth_ask_user_to_save_password}" == "TRUE" ]] && [[ "${auth_user_account_saved}" == "FALSE" ]] && [[ "${workflow_target}" != "Non-system Software Updates" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers Without Restarting" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers With Restart" ]] && [[ "${workflow_target}" != "Restart Without Updates" ]]; then
		dialog_user_auth_type="SCHEDULE"
		[[ "${dialog_user_auth_valid}" != "TRUE" ]] && dialog_user_auth
		unset dialog_user_auth_type
		if [[ "${dialog_user_auth_error}" == "TRUE" ]]; then
			deferral_timer_minutes="${deferral_timer_error_minutes}"
			log_super "Error: User authentication for scheduled restart failed, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: User authentication for scheduled restart failed, trying again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
	
	# Start preparing for use schedule dialog.
	set_display_strings_language
	log_status "Running: Dialog user scheduled installation."
	unset dialog_timeout_seconds
	[[ -n "${dialog_timeout_user_schedule_seconds}" ]] && dialog_timeout_seconds="${dialog_timeout_user_schedule_seconds}"
	{ [[ -z "${dialog_timeout_user_schedule_seconds}" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && dialog_timeout_seconds="${dialog_timeout_default_seconds}"
	[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User scheduled install selection dialog with a ${dialog_timeout_seconds} second timeout."
	[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User scheduled install selection dialog with no timeout."
	
	# Set the user schedule title and buttons display strings.
	local display_string_user_schedule_title
	local dialog_user_schedule_button
	if [[ "${workflow_target}" == "Non-system Software Updates" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]]; then
		display_string_user_schedule_title="${display_string_user_schedule_install_title}"
		dialog_user_schedule_button="${display_string_schedule_install_button}"
	else # Default restart workflows.
		display_string_user_schedule_title="${display_string_user_schedule_restart_title}"
		dialog_user_schedule_button="${display_string_schedule_restart_button}"
	fi
	
	# Create initial ${ibm_notifier_array} settings for the dialog.
	ibm_notifier_array=(-type popup -bar_title "${display_string_user_schedule_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${dialog_user_schedule_button}" -secondary_button_label "${display_string_cancel_button}")
	
	# Body text variations based on deadline options, also set ${display_accessory_datepicker_payload}.
	local display_accessory_datepicker_start_epoch
	display_accessory_datepicker_start_epoch=$(($(date +%s) + (DIALOG_USER_SCHEDULE_MINIMUM_SELECTION_MINUTES * 60) + 1))
	local display_accessory_datepicker_start_date
	display_accessory_datepicker_start_date=$(date -j -f %s "${display_accessory_datepicker_start_epoch}" +"%Y/%m/%d %H:%M:%S" | xargs)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_datepicker_start_date is: ${display_accessory_datepicker_start_date}"
	if [[ -n "${deadline_epoch}" ]]; then # Show date deadline.
		ibm_notifier_array+=(-subtitle "${display_string_user_schedule_date_body}")
		local display_accessory_datepicker_end_epoch
		display_accessory_datepicker_end_epoch=$((deadline_epoch + 1))
		local display_accessory_datepicker_end_date
		display_accessory_datepicker_end_date=$(date -j -f %s "${display_accessory_datepicker_end_epoch}" +"%Y/%m/%d %H:%M:%S" | xargs)
		log_super "IBM Notifier: Scheduled install selection starts at ${display_accessory_datepicker_start_date} with a maximum end date of ${display_accessory_datepicker_end_date}."
		display_accessory_datepicker_payload="/title ${display_string_user_schedule_calendar_title} /preselection ${display_accessory_datepicker_start_date} /start_date ${display_accessory_datepicker_start_date} /end_date ${display_accessory_datepicker_end_date} /style compact"
	else # Show no deadlines.
		ibm_notifier_array+=(-subtitle "${display_string_user_schedule_default_body}")
		log_super "IBM Notifier: Scheduled install selection starts at ${display_accessory_datepicker_start_date} with no maximum end date."
		display_accessory_datepicker_payload="/title ${display_string_user_schedule_calendar_title} /preselection ${display_accessory_datepicker_start_date} /start_date ${display_accessory_datepicker_start_date} /style compact"
	fi
	[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_user_schedule_timeout}"
	
	# Manage ${display_unmovable_option}, ${display_hide_background_option}, and ${display_silently_option} options.
	{ [[ "${display_unmovable_status}" != "TRUE" ]] && [[ $(echo "${display_unmovable_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_unmovable_status="TEMP"
	{ [[ "${display_hide_background_status}" != "TRUE" ]] && [[ $(echo "${display_hide_background_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_hide_background_status="TEMP"
	{ [[ "${display_silently_status}" != "TRUE" ]] && [[ $(echo "${display_silently_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_silently_status="TEMP"
	
	# Start the dialog.
	dialog_type="SCHEDULE"
	open_dialog_ibm_notifier
	unset dialog_type
	
	# Reset temporary ${display_unmovable_option}, ${display_hide_background_option}, and ${display_silently_option} options.
	[[ "${display_unmovable_status}" == "TEMP" ]] && unset display_unmovable_status
	[[ "${display_hide_background_status}" == "TEMP" ]] && unset display_hide_background_status
	[[ "${display_silently_status}" == "TEMP" ]] && unset display_silently_status

	# The ${dialog_return} contains the IBM Notifier.app return code. If the user selected a scheduled restart then prepare and call the set_scheduled_install_deferral() function or if the dialog timed out then set ${deferral_timer_minutes}.
	case "${dialog_return}" in
	0)
		local dialog_user_schedule_selection
		local dialog_user_schedule_selection_epoch
		if [[ $(echo "${dialog_response}" | grep -Ec 'am|pm') -gt 0 ]]; then
			dialog_user_schedule_selection=$(echo "${dialog_response}" | tr '[:space:]' ':' | sed -e 's/[0-9][0-9]:am:$/00:am/' -e 's/[0-9][0-9]:pm:$/00:pm/')
			dialog_user_schedule_selection_epoch=$(date -j -f %Y-%m-%d:%I:%M:%S:%p "${dialog_user_schedule_selection}" +%s)
		else # Default 24h time.
			dialog_user_schedule_selection=$(echo "${dialog_response}" | tr '[:space:]' ':' | sed -e 's/[0-9][0-9]:$/00/')
			dialog_user_schedule_selection_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${dialog_user_schedule_selection}" +%s)
		fi
		local dialog_user_schedule_minimum_selection_epoch
		dialog_user_schedule_minimum_selection_epoch=$(($(date +%s) + 121))
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_user_schedule_selection is: ${dialog_user_schedule_selection}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_user_schedule_selection_epoch is: ${dialog_user_schedule_selection_epoch}"
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_user_schedule_minimum_selection_epoch is: ${dialog_user_schedule_minimum_selection_epoch}"
		if [[ $dialog_user_schedule_selection_epoch -lt $dialog_user_schedule_minimum_selection_epoch ]];then
			log_super "Warning: Adjusting user selected scheduled installation because it's in the past or less than two minutes from now."
			workflow_scheduled_install=$(date -r "${dialog_user_schedule_minimum_selection_epoch}" +%Y-%m-%d:%H:%M)
		fi
		if [[ -n "${deadline_epoch}" ]] && [[ $dialog_user_schedule_selection_epoch -gt $display_accessory_datepicker_end_epoch ]];then
			log_super "Warning: Adjusting user selected scheduled installation because it's past the current workflow deadline."
			workflow_scheduled_install=$(date -r "${display_accessory_datepicker_end_epoch}" +%Y-%m-%d:%H:%M)
		fi
		[[ -z "${workflow_scheduled_install}" ]] && workflow_scheduled_install=$(date -r "${dialog_user_schedule_selection_epoch}" +%Y-%m-%d:%H:%M)
		log_super "Status: User chose to schedule installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install}."
		if [[ -n "${schedule_workflow_active_option}" ]]; then
			set_schedule_workflow_active_adjustments
			if [[ -n "${workflow_scheduled_install_adjusted}" ]]; then
				workflow_scheduled_install="${workflow_scheduled_install_adjusted}"
				[[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]] && log_super "Status: Setting new user selected scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} which is the start of a workflow active time frame that closest matches the user's choice."
			else
				log_super "Warning: The current user selected scheduled installation for $(date -j -f %Y-%m-%d "${workflow_scheduled_install:0:10}" +%a | tr '[:lower:]' '[:upper:]') ${workflow_scheduled_install} is overriding the schedule workflow active option because no coordinating time frame could be resolved."
			fi
		fi
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall -string "${workflow_scheduled_install}"
		workflow_scheduled_install_epoch=$(date -j -f %Y-%m-%d:%H:%M:%S "${workflow_scheduled_install}:00" +%s)
		local display_string_scheduled_install_only_date
		display_string_scheduled_install_only_date=$(date -r "${workflow_scheduled_install_epoch}" "+${DISPLAY_STRING_FORMAT_DATE}")
		local display_string_scheduled_install_only_time
		display_string_scheduled_install_only_time=$(date -r "${workflow_scheduled_install_epoch}" "+${DISPLAY_STRING_FORMAT_TIME}" | sed 's/^ *//g')
		if [[ $(date -r "${workflow_scheduled_install_epoch}" +%H:%M) == "00:00" ]]; then
			display_string_scheduled_install="${display_string_scheduled_install_only_date}"
		else
			display_string_scheduled_install="${display_string_scheduled_install_only_date}${DISPLAY_STRING_FORMAT_DATE_TIME_SEPARATOR}${display_string_scheduled_install_only_time}"
		fi
		scheduled_install_user_choice_active="TRUE"
		set_scheduled_install_deferral
		dialog_schedule_reminder &
		disown -a
		set_auto_launch_deferral
		;;
	2)
		log_super "Status: User chose to cancel schedule selection."
		dialog_user_choice # This function includes all workflows to facilitate user choices.
		;;
	4 | 255)
		log_super "Status: Display timeout automatically chose to defer, using the default deferral of ${deferral_timer_minutes} minutes."
		log_status "Pending: Display timeout automatically chose to defer, using the default deferral of ${deferral_timer_minutes} minutes."
		set_auto_launch_deferral
		;;
	esac
}

# Display an interactive dialog that reminds the user of a pending scheduled installation and optionally allows for rescheduling.
dialog_schedule_reminder() {
	set_display_strings_language
	
	# Set the schedule reminder title and button display strings.
	local display_string_schedule_reminder_title
	local dialog_schedule_reminder_now_button
	local dialog_schedule_reminder_dialog_timeout
	if [[ "${workflow_target}" == "Non-system Software Updates" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]]; then
		display_string_schedule_reminder_title="${display_string_schedule_reminder_install_title}"
		dialog_schedule_reminder_now_button="${display_string_install_now_button}"
		dialog_schedule_reminder_dialog_timeout="${display_string_schedule_reminder_install_timeout}"
	else # Default restart workflows.
		display_string_schedule_reminder_title="${display_string_schedule_reminder_restart_title}"
		dialog_schedule_reminder_now_button="${display_string_restart_now_button}"
		dialog_schedule_reminder_dialog_timeout="${display_string_schedule_reminder_restart_timeout}"
	fi
	
	# There is an automatic timeout behavior if the scheduled install is about to start.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_final_reminder is: ${scheduled_install_final_reminder}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_active is: ${scheduled_install_user_choice_active}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: scheduled_install_user_choice_adjusted is: ${scheduled_install_user_choice_adjusted}"
	if [[ "${scheduled_install_final_reminder}" == "TRUE" ]]; then
		log_super "IBM Notifier: Scheduled installation final warning dialog with a ${workflow_scheduled_install_difference} second timeout."
		
		# Create initial ${ibm_notifier_array} settings for the dialog.
		if [[ "${scheduled_install_user_choice_option}" == "TRUE" ]] && [[ "${scheduled_install_user_choice_active}" == "TRUE" ]]; then
			{ [[ -z "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" != "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_default_body}" -main_button_label "${dialog_schedule_reminder_now_button}" -secondary_button_label "${display_string_reschedule_button}")
			{ [[ -n "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" != "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_reschedule_date_body}" -main_button_label "${dialog_schedule_reminder_now_button}" -secondary_button_label "${display_string_reschedule_button}")
			{ [[ -z "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_adjusted_body}" -main_button_label "${dialog_schedule_reminder_now_button}" -secondary_button_label "${display_string_reschedule_button}")
			{ [[ -n "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_adjusted_reschedule_date_body}" -main_button_label "${dialog_schedule_reminder_now_button}" -secondary_button_label "${display_string_reschedule_button}")
		else # Default scheduled restart warning dialog.
			[[ "${scheduled_install_user_choice_adjusted}" != "TRUE" ]] && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_default_body}" -main_button_label "${dialog_schedule_reminder_now_button}")
			[[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]] && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_adjusted_body}" -main_button_label "${dialog_schedule_reminder_now_button}")
		fi
		local dialog_timeout_seconds_previous
		[[ -n "${dialog_timeout_seconds}" ]] && dialog_timeout_seconds_previous="${dialog_timeout_seconds}"
		dialog_timeout_seconds=$((workflow_scheduled_install_difference + 1))
		display_string_dialog_timeout="${dialog_schedule_reminder_dialog_timeout}"
		
		# Start the dialog.
		dialog_type="REMINDER"
		open_dialog_ibm_notifier
		unset dialog_type
		[[ -n "${dialog_timeout_seconds_previous}" ]] && dialog_timeout_seconds="${dialog_timeout_seconds_previous}"
		
		# The ${dialog_return} contains the IBM Notifier.app return code. If the user selected a scheduled restart or the dialog timed out then set ${deferral_timer_minutes}.
		case "${dialog_return}" in
		0)
			log_super "Status: User chose to install now."
			;;
		2)
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
			log_super "Status: User chose to reschedule, removing previously scheduled installation and restarting super..."
			restart_super_sleep_seconds=1
			restart_super
			;;
		4 | 255)
			log_super "Status: Schedule reminder dialog closed due to timeout."
			;;
		esac
	else # The schedule installation is not about to start so this dialog can exit normally or reschedule.
		unset dialog_timeout_seconds
		log_super "IBM Notifier: Scheduled installation warning dialog (this dialog has no timeout)."
		
		# Create initial ${ibm_notifier_array} settings for the dialog.
		if [[ "${scheduled_install_user_choice_option}" == "TRUE" ]] && [[ "${scheduled_install_user_choice_active}" == "TRUE" ]]; then
			{ [[ -z "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" != "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_default_body}" -main_button_label "${display_string_ok_button}" -secondary_button_label "${display_string_reschedule_button}")
			{ [[ -n "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" != "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_reschedule_date_body}" -main_button_label "${display_string_ok_button}" -secondary_button_label "${display_string_reschedule_button}")
			{ [[ -z "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_adjusted_body}" -main_button_label "${display_string_ok_button}" -secondary_button_label "${display_string_reschedule_button}")
			{ [[ -n "${display_string_deadline}" ]] && [[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]]; } && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_adjusted_reschedule_date_body}" -main_button_label "${display_string_ok_button}" -secondary_button_label "${display_string_reschedule_button}")
		else # Default scheduled restart warning dialog.
			[[ "${scheduled_install_user_choice_adjusted}" != "TRUE" ]] && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_default_body}" -main_button_label "${display_string_ok_button}")
			[[ "${scheduled_install_user_choice_adjusted}" == "TRUE" ]] && ibm_notifier_array=(-type popup -bar_title "${display_string_schedule_reminder_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -subtitle "${display_string_schedule_reminder_adjusted_body}" -main_button_label "${display_string_ok_button}")
		fi
		
		# Start the dialog.
		dialog_type="REMINDER"
		open_dialog_ibm_notifier
		unset dialog_type
		
		# The ${dialog_return} contains the IBM Notifier.app return code. If the user selected a scheduled restart or the dialog timed out then set ${deferral_timer_minutes}.
		case "${dialog_return}" in
		0)
			log_super "Background Schedule Reminder Dialog: User dismissed the dialog."
			;;
		2)
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
			log_super "Background Schedule Reminder Dialog: User chose to reschedule, removing previously scheduled installation and restarting super..."
			restart_super_sleep_seconds=1
			restart_super
			;;
		4 | 255)
			log_super "Background Schedule Reminder Dialog: Closed due to timeout."
			;;
		esac
		exit 0
	fi
}

# Display an interactive dialog when a soft deadline has passed, giving the user only one button to continue the workflow.
dialog_soft_deadline() {
	set_display_strings_language
	log_status "Running: Dialog soft deadline."
	unset dialog_timeout_seconds
	[[ -n "${dialog_timeout_soft_deadline_seconds}" ]] && dialog_timeout_seconds="${dialog_timeout_soft_deadline_seconds}"
	{ [[ -z "${dialog_timeout_soft_deadline_seconds}" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && dialog_timeout_seconds="${dialog_timeout_default_seconds}"
	
	# Set the soft deadline title and button display strings.
	local display_string_soft_deadline_title
	local dialog_soft_deadline_button
	if [[ "${workflow_target}" == "Non-system Software Updates" ]] || [[ "${workflow_target}" == "Jamf Pro Policy Triggers Without Restarting" ]]; then
		display_string_soft_deadline_title="${display_string_soft_deadline_install_title}"
		dialog_soft_deadline_button="${display_string_install_now_button}"
		[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_soft_deadline_install_timeout}"
	else # Default restart workflows.
		display_string_soft_deadline_title="${display_string_soft_deadline_restart_title}"
		dialog_soft_deadline_button="${display_string_restart_now_button}"
		[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_soft_deadline_restart_timeout}"
	fi
	
	# Create initial ${ibm_notifier_array} settings for the dialog.
	ibm_notifier_array=(-type popup -bar_title "${display_string_soft_deadline_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${dialog_soft_deadline_button}")
	
	# Variations for the main body text of the soft deadline dialog.
	if [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "SOFT" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Soft deadline date dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Soft deadline date dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_soft_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Soft deadline count dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: Soft deadline count dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_soft_deadline_count_body}")
	fi
	
	# Start the dialog.
	dialog_type="SOFT"
	open_dialog_ibm_notifier
	unset dialog_type
	
	# The ${dialog_return} contains the IBM Notifier.app return code.
	case "${dialog_return}" in
	0)
		log_super "Status: User chose to restart."
		;;
	255)
		log_super "Status: Display timeout automatically chose to restart."
		;;
	esac
}

# Display an interactive IBM Notifier dialog to collect user credentials for macOS update/upgrade workflow.
dialog_user_auth() {
	dialog_user_auth_error="FALSE"
	
	# First, check to make sure the current user is a valid volume owner.
	if [[ "${current_user_is_volume_owner}" == "FALSE" ]]; then
		log_super "Error: Current user is not a volume owner: ${current_user_account_name}"
		dialog_user_auth_error="TRUE"
		return 0
	fi
	
	# The initial ${ibm_notifier_array} and variations for the main body text for the user authentication dialog.
	set_display_strings_language
	log_status "Running: Dialog user authentication."
	unset dialog_timeout_seconds
	[[ -n "${dialog_timeout_user_auth_seconds}" ]] && dialog_timeout_seconds="${dialog_timeout_user_auth_seconds}"
	{ [[ -z "${dialog_timeout_user_auth_seconds}" ]] && [[ -n "${dialog_timeout_default_seconds}" ]]; } && dialog_timeout_seconds="${dialog_timeout_default_seconds}"
	local dialog_user_auth_button
	if [[ "${dialog_user_auth_type}" == "DOWNLOAD" ]]; then
		dialog_user_auth_button="${display_string_download_now_button}"
	elif [[ "${dialog_user_auth_type}" == "SCHEDULE" ]]; then
		dialog_user_auth_button="${display_string_schedule_restart_button}"
	else # Installation workflow.
		dialog_user_auth_button="${display_string_restart_now_button}"
	fi
	
	# The initial ${ibm_notifier_array} settings for the initial run of the user authentication dialog.
	ibm_notifier_array=(-type popup -bar_title "${display_string_user_auth_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${dialog_user_auth_button}")
	
	# Variations for the main body text of the initial run of the user authentication dialog.
	if [[ "${dialog_user_auth_type}" == "DOWNLOAD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication download update/upgrade dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication download update/upgrade dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_user_auth_download_body}")
	elif [[ "${dialog_user_auth_type}" == "SCHEDULE" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication secheduled installation dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication secheduled installation dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_user_auth_schedule_body}")
	elif [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]] || [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication deadline date dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication deadline date dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_user_auth_deadline_date_body}")
	elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication deadline count dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication deadline count dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_user_auth_deadline_count_body}")
	else # No deadlines, this is the default user authentication dialog.
		[[ -n "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication default dialog with a ${dialog_timeout_seconds} second timeout."
		[[ -z "${dialog_timeout_seconds}" ]] && log_super "IBM Notifier: User authentication default dialog with no timeout."
		ibm_notifier_array+=(-subtitle "${display_string_user_auth_default_body}")
	fi
	display_accessory_secure_payload="/title ${display_string_user_auth_password_title} /placeholder ${display_string_user_auth_password_placeholder} /required"
	[[ -n "${dialog_timeout_seconds}" ]] && display_string_dialog_timeout="${display_string_user_auth_timeout}"
	
	# Manage ${display_unmovable_option}, ${display_hide_background_option}, and ${display_silently_option} options.
	{ [[ "${display_unmovable_status}" != "TRUE" ]] && [[ $(echo "${display_unmovable_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_unmovable_status="TEMP"
	{ [[ "${display_hide_background_status}" != "TRUE" ]] && [[ $(echo "${display_hide_background_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_hide_background_status="TEMP"
	{ [[ "${display_silently_status}" != "TRUE" ]] && [[ $(echo "${display_silently_option}" | grep -c 'DIALOG') -gt 0 ]]; } && display_silently_status="TEMP"
	
	# Open the user authentication dialog including handling of the ${dialog_timeout_seconds} and user password validation.
	dialog_type="AUTH"
	dialog_user_auth_valid="FALSE"
	local dialog_user_auth_timeout
	dialog_user_auth_timeout="FALSE"
	local dialog_user_auth_attempt
	dialog_user_auth_attempt=0
	while true; do
		if [[ "${dialog_user_auth_attempt}" -eq 1 ]]; then
			# Re-create ${ibm_notifier_array} settings for the user authentication dialog when the user authentication fails.
			ibm_notifier_array=(-type popup -bar_title "${display_string_user_auth_title}" -icon_path "${display_icon}" -icon_width "${display_icon_size}" -icon_height "${display_icon_size}" -main_button_label "${dialog_user_auth_button}")
			if [[ "${dialog_user_auth_type}" == "DOWNLOAD" ]]; then
				ibm_notifier_array+=(-subtitle "${display_string_user_auth_retry_download_body}")
			elif [[ "${dialog_user_auth_type}" == "SCHEDULE" ]]; then
				ibm_notifier_array+=(-subtitle "${display_string_user_auth_retry_schedule_body}")
			elif [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_date_status}" == "HARD" ]] || [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "HARD" ]]; then
				ibm_notifier_array+=(-subtitle "${display_string_user_auth_retry_deadline_date_body}")
			elif [[ "${deadline_count_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then
				ibm_notifier_array+=(-subtitle "${display_string_user_auth_retry_deadline_count_body}")
			else # No deadlines, this is the default user authentication dialog.
				ibm_notifier_array+=(-subtitle "${display_string_user_auth_retry_default_body}")
			fi
			display_accessory_secure_payload="/title ${display_string_user_auth_retry_password_title} /placeholder ${display_string_user_auth_retry_password_placeholder} /required"
		fi
		open_dialog_ibm_notifier
		((dialog_user_auth_attempt++))
		if [[ "${dialog_return}" -eq 0 ]]; then
			if [[ $(dscl /Local/Default -authonly "${current_user_account_name}" "${dialog_response}" 2>&1) == "" ]]; then
				auth_local_account="${current_user_account_name}"
				auth_local_password="${dialog_response}"
				dialog_user_auth_valid="TRUE"
				break
			fi
		elif [[ "${dialog_return}" -eq 4 ]]; then
			dialog_user_auth_timeout="TRUE"
			break
		else # If ${dialog_return} contains any other error code.
			break
		fi
	done
	unset dialog_type
	
	# Reset temporary ${display_unmovable_option}, ${display_hide_background_option}, and ${display_silently_option} options.
	[[ "${display_unmovable_status}" == "TEMP" ]] && unset display_unmovable_status
	[[ "${display_hide_background_status}" == "TEMP" ]] && unset display_hide_background_status
	[[ "${display_silently_status}" == "TEMP" ]] && unset display_silently_status
	
	# If user authentication was successful then evaluate options to save password or fix bootstrap token.
	if [[ "${dialog_user_auth_valid}" == "TRUE" ]]; then
		log_super "Status: Credentials verified for current user: ${auth_local_account}"
		if [[ "${auth_ask_user_to_save_password}" -eq 1 ]] || [[ "${auth_ask_user_to_save_password}" == "TRUE" ]]; then
			local auth_user_save_password_response
			auth_user_save_password_response=$(launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security add-generic-password -a "super_auth_user_password" -s "Super Update Service" -w "${auth_local_password}" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" 2>&1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_save_password_response is: ${auth_user_save_password_response}"
			local auth_user_password_keychain
			auth_user_password_keychain=$(launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security find-generic-password -w -a "super_auth_user_password" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" 2>&1)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_local_password is: ${auth_local_password}"
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_echo "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: auth_user_password_keychain is: ${auth_user_password_keychain}"
			if [[ "${auth_local_password}" == "${auth_user_password_keychain}" ]]; then
				log_super "Status: Saved new --auth-ask-user-to-save-password credentials for current user: ${auth_local_account}"
			else
				log_super "Warning: Unable to validate keychain item for --auth-ask-user-to-save-password, deleting keychain item."
				launchctl asuser "${current_user_id}" sudo -u "${current_user_account_name}" security delete-generic-password -a "super_auth_user_password" "/Users/${current_user_account_name}/Library/Keychains/login.keychain" >/dev/null 2>&1
			fi
		elif [[ "${mdm_enrolled}" == "TRUE" ]] && [[ "${auth_error_bootstrap_token}" == "TRUE" ]] && { [[ "${auth_mdm_failover_to_user_status}" == "TRUE" ]] || [[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'ERROR') -gt 0 ]]; }; then
			bootstrap_token_attempt_fix="TRUE"
			if [[ "${current_user_is_admin}" == "FALSE" ]]; then
				log_super "Warning: Local user account \"${auth_local_account}\" can not be used to escrow bootstrap token because they are not a local admin."
				bootstrap_token_attempt_fix="FALSE"
			fi
			if [[ "${current_user_has_secure_token}" == "FALSE" ]]; then
				log_super "Warning: Local user account \"${auth_local_account}\" can not be used to escrow bootstrap token because they do not have a secure token."
				bootstrap_token_attempt_fix="FALSE"
			fi
			if [[ "${auth_error_mdm}" == "TRUE" ]]; then
				log_super "Warning: Can not escrow bootstrap token because the MDM service is not available."
				bootstrap_token_attempt_fix="FALSE"
			fi
			if [[ "${bootstrap_token_attempt_fix}" == "TRUE" ]]; then
				log_super "Status: Attempting to use the credentials from user \"${auth_local_account}\" to escrow bootstrap token..."
				local profiles_response
				profiles_response=$(profiles install -type bootstraptoken -user "${auth_local_account}" -password "${auth_local_password}" 2>&1)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: profiles_response is: ${profiles_response}"
				check_bootstrap_token_escrow
			fi
		fi
	else # The user authentication dialog timed out or failed.
		if [[ "${dialog_user_auth_timeout}" == "TRUE" ]]; then
			log_super "Error: Waiting for user authentication timed out after ${dialog_timeout_seconds} seconds."
		else
			log_super "Error: User authentication failed."
		fi
		dialog_user_auth_error="TRUE"
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: dialog_user_auth_error is: ${dialog_user_auth_error}"
}

# MARK: *** Main Workflow ***
################################################################################

main() {
	# Initial super workflow preparations.
	set_defaults
	get_options "$@"
	workflow_startup
	workflow_time_epoch=$(date +%s)
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Setting new workflow_time_epoch to: ${workflow_time_epoch}"
	[[ -n "${schedule_workflow_active_option}" ]] && check_schedule_workflow_active
	
	# If restarting from a macOS update/upgrade this workflow starts before all others.
	if [[ "${workflow_restart_validate_active}" == "TRUE" ]]; then
		[[ "${schedule_workflow_active_deferral}" == "TRUE" ]] && log_super "Warning: The restart validation workflow is temporarily ignoring a workflow active deferral."
		log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - RESTART VALIDATION WORKFLOW ****"
		workflow_restart_validate # This function will automatically defer if there are any errors.
		# At this point the workflow_restart_validate() function was succesfull, so reset for future workflow runs.
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowRestartValidate 2>/dev/null
		unset workflow_restart_validate_active
		defaults write "${SUPER_LOCAL_PLIST}" MacLastStartup -string "${mac_last_startup}"
		workflow_time_epoch=$(date +%s)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Setting new workflow_time_epoch to: ${workflow_time_epoch}"
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowTarget 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowScheduledInstall 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null
		reset_schedule_zero_date
		reset_deadline_counters
		# Handle the ${workflow_reset_super_after_completion_active} workflow option.
		if [[ "${workflow_reset_super_after_completion_active}" == "TRUE" ]]; then
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletion 2>/dev/null
			defaults write "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletionNow -bool true
			log_super "Status: Workflow complete, restarting via LaunchDeamon to reset super..."
			restart_super_sleep_seconds=5
			restart_super
		fi
		# At this point the ${workflow_auth_error} condition is a workflow-stopper, so try again later.
		if [[ "${workflow_auth_error}" == "TRUE" ]]; then
			deferral_timer_minutes="${DEFERRAL_TIMER_RESTART_VALIDATION_ERROR_MINUTES}"
			log_super "Workflow Error: Configured authentication workflow is not currently possible, trying again in ${deferral_timer_minutes} minutes."
			log_status "Pending: Configured authentication workflow is not currently possible, trying again in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
	
	# If requested then reset various counters.
	{ [[ "${scheduled_install_delete_all_option}" == "TRUE" ]] || [[ "${deadline_days_restart_all_option}" == "TRUE" ]]; } && reset_schedule_zero_date
	[[ "${deadline_count_restart_all_option}" == "TRUE" ]] && reset_deadline_counters
	
	# Check for software update/upgrades workflow.
	macos_installer_target="FALSE"
	macos_msu_major_upgrade_target="FALSE"
	macos_msu_minor_update_target="FALSE"
	non_system_msu_targets="FALSE"
	workflow_target="FALSE"
	if [[ "${workflow_disable_update_check_option}" == "TRUE" ]]; then # Skip software updates/upgrade mode option.
		log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - NOT CHECKING FOR SOFTWARE UPDATES/UPGRADES ****"
		{ [[ "${workflow_disable_relaunch_option}" != "TRUE" ]] && [[ -z "${install_jamf_policy_triggers_option}" ]] && [[ "${workflow_restart_without_updates_option}" != "TRUE" ]]; } && log_super "Warning: When using the --workflow-disable-update-check option consider also using the --workflow-disable-relaunch option to prevent super from unecissarily re-launching."
		if [[ "${test_mode_option}" == "TRUE" ]]; then
			log_super "Test Mode: Simulating skip updates workflow."
			if [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]]; then
				log_super "Test Mode: Simulating install Jamf Pro Policy Triggers without restarting workflow."
			elif [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then
				log_super "Test Mode: Simulating restart without updates workflow."
			else
				log_super "Warning: When using the --workflow-disable-update-check option you need to also use the --install-jamf-policy-triggers-without-restarting or --workflow-restart-without-updates options to simulate notification and dialog workflows."
			fi
		fi
	else # Default software update/upgrade workflows.
		if [[ "${test_mode_option}" != "TRUE" ]]; then # Default workflow starts by checking for updates/upgrades.
			log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - CHECK FOR SOFTWARE UPDATES/UPGRADES ****"
			workflow_check_software_status
			check_macos_downloads
			workflow_time_epoch=$(date +%s)
			[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Setting new workflow_time_epoch to: ${workflow_time_epoch}"
		else # Test mode.
			if [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then
				log_super "Test Mode: Simulating restart without updates workflow."
			elif [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]]; then
				log_super "Test Mode: Simulating install Jamf Pro Policy Triggers without restarting workflow."
			elif [[ "${install_non_system_updates_without_restarting_option}" == "TRUE" ]]; then
				non_system_msu_targets="TRUE"
				log_super "Test Mode: Simulating install non-system updates workflow."
			elif [[ "${install_macos_major_upgrades}" == "TRUE" ]]; then
				if [[ "${macos_version_number}" -lt 1203 ]]; then
					macos_installer_target="Title:${macos_title},Version:${macos_version_major}.${macos_version_minor},Build:${macos_build},Size:14633014395" 
					macos_installer_title="${macos_title}"
					macos_installer_version="${macos_version_major}.${macos_version_minor}"
					macos_installer_build="${macos_build}"
					macos_installer_size=15
					macos_installer_download_required="TRUE"
				else
					macos_msu_major_upgrade_target="Title:${macos_title} ${macos_version_major}.${macos_version_minor},Build:${macos_build},Version:${macos_version_major}.${macos_version_minor}"
					macos_msu_label="${macos_version_full}"
					macos_msu_title="${macos_title}"
					macos_msu_version="${macos_version_major}.${macos_version_minor}"
					macos_msu_build="${macos_build}"
					macos_msu_size=15
					macos_msu_download_required="TRUE"
				fi
				log_super "Test Mode: Simulating macOS ${macos_msu_version} upgrade workflow."
			else # Simulate a macOS update.
				macos_msu_minor_update_target="Title:${macos_title} ${macos_version_major}.${macos_version_minor},Build:${macos_build},Version:${macos_version_major}.${macos_version_minor}"
				macos_msu_label="${macos_version_full}"
				macos_msu_title="${macos_title}"
				macos_msu_version="${macos_version_major}.${macos_version_minor}"
				macos_msu_build="${macos_build}"
				macos_msu_size=5
				macos_msu_download_required="TRUE"
				log_super "Test Mode: Simulating a macOS ${macos_msu_version} update workflow."
			fi
		fi
	fi
	
	# At this point all available updates/upgrades have been evaluated.
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_installer_target is: ${macos_installer_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_major_upgrade_target is: ${macos_msu_major_upgrade_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: macos_msu_minor_update_target is: ${macos_msu_minor_update_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: non_system_msu_targets is: ${non_system_msu_targets}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_restart_without_updates_option is: ${workflow_restart_without_updates_option}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: install_jamf_policy_triggers_without_restarting_option is: ${install_jamf_policy_triggers_without_restarting_option}"
	delete_unneeded_macos_installers # This function includes internal test mode logic.
	
	# Prepare workflow for specific ${workflow_target} and, if needed, set ${display_accessory_content}.
	workflow_target="FALSE"
	if [[ "${macos_installer_target}" != "FALSE" ]]; then
		workflow_target="${macos_installer_title} ${macos_installer_version}-${macos_build}"
		workflow_target_log_string="${workflow_target} MAJOR UPGRADE VIA INSTALLER"
		if [[ -n "${display_accessory_macos_major_upgrade}" ]]; then
			display_accessory_content="${display_accessory_macos_major_upgrade}"
		elif [[ -n "${display_accessory_default}" ]]; then
			display_accessory_content="${display_accessory_default}"
		fi
	elif [[ "${macos_msu_major_upgrade_target}" != "FALSE" ]]; then
		workflow_target="${macos_msu_title} ${macos_msu_version}-${macos_msu_build}"
		workflow_target_log_string="${workflow_target} MAJOR UPGRADE VIA SOFTWAREUPDATE"
		if [[ -n "${display_accessory_macos_major_upgrade}" ]]; then
			display_accessory_content="${display_accessory_macos_major_upgrade}"
		elif [[ -n "${display_accessory_default}" ]]; then
			display_accessory_content="${display_accessory_default}"
		fi
	elif [[ "${macos_msu_minor_update_target}" != "FALSE" ]]; then
		if [[ $(echo "${macos_msu_minor_update_target}" | grep -c '(') -gt 0 ]] && [[ "${install_rapid_security_responses_option}" != "TRUE" ]]; then
			log_super "Warning: The default workflow ignores macOS Rapid Security Response (RSR) updates. Use the --install-rapid-security-responses option to always install macOS RSR updates as soon as they are available."
		else
			workflow_target="${macos_msu_title} ${macos_msu_version}-${macos_msu_build}"
			workflow_target_log_string="${workflow_target} MINOR UPDATE VIA SOFTWAREUPDATE"
			if [[ -n "${display_accessory_macos_minor_update}" ]]; then
				display_accessory_content="${display_accessory_macos_minor_update}"
			elif [[ -n "${display_accessory_default}" ]]; then
				display_accessory_content="${display_accessory_default}"
			fi
		fi
	elif [[ "${non_system_msu_targets}" == "TRUE" ]]; then
		if [[ "${install_non_system_updates_without_restarting_option}" != "TRUE" ]]; then
			log_super "Warning: The default workflow ignores non-system software updates if there is no macOS update/upgrade available. Use the --install-non-system-updates-without-restarting option to always install non-system updates as soon as they are available."
		else
			workflow_target="Non-system Software Updates"
			workflow_target_log_string="NON-SYSTEM SOFTWARE UPDATES WITHOUT RESTARTING"
			workflow_macos_auth="FALSE"
			if [[ "${workflow_only_download_active}" == "TRUE" ]]; then
				log_super "Warning: The --install-non-system-updates-without-restarting option is currently overriding the --only-download option."
				workflow_only_download_active="FALSE"
			fi
			if [[ -n "${display_accessory_non_system_updates}" ]]; then
				display_accessory_content="${display_accessory_non_system_updates}"
			elif [[ -n "${display_accessory_default}" ]]; then
				display_accessory_content="${display_accessory_default}"
			fi
		fi
	elif [[ "${install_jamf_policy_triggers_without_restarting_option}" == "TRUE" ]]; then
		workflow_target="Jamf Pro Policy Triggers Without Restarting"
		workflow_target_log_string="JAMF PRO POLICY TRIGGERS WITHOUT RESTARTING"
		workflow_macos_auth="FALSE"
		if [[ "${workflow_only_download_active}" == "TRUE" ]]; then
			log_super "Warning: The --install-jamf-policy-triggers-without-restarting option is currently overriding the --only-download option."
			workflow_only_download_active="FALSE"
		fi
		if [[ -n "${display_accessory_jamf_policy_triggers}" ]]; then
			display_accessory_content="${display_accessory_jamf_policy_triggers}"
		elif [[ -n "${display_accessory_default}" ]]; then
			display_accessory_content="${display_accessory_default}"
		fi
	elif [[ "${workflow_restart_without_updates_option}" == "TRUE" ]]; then
		workflow_macos_auth="FALSE"
		if [[ "${workflow_only_download_active}" == "TRUE" ]]; then
			log_super "Warning: The --workflow-restart-without-updates option is currently overriding the --only-download option."
			workflow_only_download_active="FALSE"
		fi
		if [[ -n "${install_jamf_policy_triggers_option}" ]]; then 
			workflow_target="Jamf Pro Policy Triggers With Restart"
			workflow_target_log_string="JAMF PRO POLICY TRIGGERS WITH RESTART"
			if [[ -n "${display_accessory_jamf_policy_triggers}" ]]; then
				display_accessory_content="${display_accessory_jamf_policy_triggers}"
			elif [[ -n "${display_accessory_default}" ]]; then
				display_accessory_content="${display_accessory_default}"
			fi
		else
			workflow_target="Restart Without Updates"
			workflow_target_log_string="RESTART WITHOUT UPDATES/UPGRADES"
			if [[ -n "${display_accessory_restart_without_updates}" ]]; then
				display_accessory_content="${display_accessory_restart_without_updates}"
			elif [[ -n "${display_accessory_default}" ]]; then
				display_accessory_content="${display_accessory_default}"
			fi
		fi
	fi
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_target is: ${workflow_target}"
	[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: display_accessory_content is: ${display_accessory_content}"
	
	# Check for zero date, scheduled installations, and log workflow.
	if [[ "${workflow_target}" != "FALSE" ]]; then
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - INSTALL NOW ${workflow_target_log_string} ****"
		elif [[ "${workflow_only_download_active}" == "TRUE" ]]; then
			log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - ONLY DOWNLOAD ${workflow_target_log_string} ****"
		else # Workflows that may leverage schedules, deferrals, or deadlines.
			check_schedule_zero_date
			check_scheduled_install
			if [[ "${workflow_scheduled_install_active}" == "TRUE" ]]; then
				log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - SCHEDULED RESTART ${workflow_target_log_string} ****"
			else # Default super workflow.
				log_super "**** S.U.P.E.R.M.A.N. ${SUPER_VERSION} - ${workflow_target_log_string} ****"
			fi
		fi
		defaults write "${SUPER_LOCAL_PLIST}" WorkflowTarget -string "${workflow_target}"
	else # No software updates/upgrade needed so reset any leftovers.
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowTarget 2>/dev/null
		defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null
		reset_schedule_zero_date
		reset_deadline_counters
	fi
	
	# If set, handle the ${schedule_workflow_active_option} before the any installation or restart workflow starts.
	if [[ "${workflow_target}" != "FALSE" ]] && [[ -n "${schedule_workflow_active_option}" ]]; then
		if [[ "${schedule_workflow_active_deferral}" == "TRUE" ]]; then
			if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
				log_super "Warning: The --workflow-install-now option is currently overriding a schedule workflow active deferral."
			elif [[ "${workflow_scheduled_install_active}" == "TRUE" ]]; then
				[[ "${workflow_scheduled_install_now}" == "TRUE" ]] && log_super "Warning: A scheduled installation is currently overriding a schedule workflow active deferral."
				[[ "${workflow_scheduled_install_now}" != "TRUE" ]] && log_super "Warning: A scheduled installation reminder is currently overriding a schedule workflow active deferral."
			else # Schedule workflow active should force a deferral.
				deferral_timer_minutes=$(((schedule_workflow_active_next_start_epoch - workflow_time_epoch) / 60 ))
				log_super "Status: Automatic schedule workflow active deferral until ${schedule_workflow_active_next_start}, deferring for ${deferral_timer_minutes} minutes."
				log_status "Pending: Automatic schedule workflow active deferral until ${schedule_workflow_active_next_start}, deferring for ${deferral_timer_minutes} minutes."
				set_auto_launch_deferral
			fi
		else # The workflow can continue.
			log_super "Status: Current schedule workflow active time frame ends at ${schedule_workflow_active_current_end}."
		fi
	fi
	
	# This is the main logic for starting all installation or restart workflows.
	if [[ "${workflow_target}" != "FALSE" ]]; then
		workflow_time_epoch=$(date +%s)
		[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Setting new workflow_time_epoch to: ${workflow_time_epoch}"
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			if [[ "${current_user_account_name}" == "FALSE" ]]; then # A normal user is not logged in, start installations immediately.
				workflow_install_no_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
			else # A normal user is currently logged in.
				[[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'INSTALLNOW') -gt 0 ]] && auth_mdm_failover_to_user_status="TRUE"
				if [[ "${workflow_macos_auth}" == "USER" ]]; then # Apple silicon computer in need of user authentication.
					[[ "${dialog_user_auth_valid}" != "TRUE" ]] && dialog_user_auth
					if [[ "${dialog_user_auth_error}" == "TRUE" ]]; then
						log_super "Error: No valid Apple slicon authentication, install now workflow can not continue."
						log_status "Inactive Error: No valid Apple slicon authentication, install now workflow can not continue."
						[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_failed
						exit_error
					fi
				fi
				{ [[ "${workflow_target}" != "Non-system Software Updates" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers Without Restarting" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers With Restart" ]] && [[ "${workflow_target}" != "Restart Without Updates" ]]; } && workflow_download_macos # This function only downloads if needed and includes internal storage checks and test mode logic.
				workflow_install_active_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
			fi
		elif [[ "${workflow_scheduled_install_active}" == "TRUE" ]]; then
			if [[ "${workflow_scheduled_install_now}" == "TRUE" ]]; then
				if [[ "${current_user_account_name}" == "FALSE" ]]; then # A normal user is not logged in, start installations immediately.
					workflow_install_no_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
				else # A normal user is currently logged in.
					workflow_install_active_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
				fi
			else # It's not time yet for a scheduled installation.
				set_scheduled_install_deferral
				if [[ "${current_user_account_name}" != "FALSE" ]]; then # This will background the schedule reminder dialog, but super will still exit.
					check_deadlines_days_date
					if [[ "${scheduled_install_suppress_reminder}" != "TRUE" ]]; then
						dialog_schedule_reminder &
						disown -a
					fi
				fi
				set_auto_launch_deferral
			fi
		elif [[ "${workflow_only_download_active}" == "TRUE" ]]; then # Only download workflow doesn't matter if the user is logged in.
			if [[ "${current_user_account_name}" == "FALSE" ]]; then # A normal user is not logged in, the only download workflow can not continue.
				deferral_timer_minutes="${deferral_timer_error_minutes}"
				log_super "Error: No current active user, due to limitations in macOS the only download workflow can not continue, trying again in ${deferral_timer_minutes} minutes."
				log_status "Pending: No current active user, due to limitations in macOS the only download workflow can not continue, trying again in ${deferral_timer_minutes} minutes."
				set_auto_launch_deferral
			else # A normal user is currently logged in.
				workflow_download_macos # This function only downloads if needed and includes internal storage checks and test mode logic.
				workflow_time_epoch=$(date +%s)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Setting new workflow_time_epoch to: ${workflow_time_epoch}"
			fi
		else # Default super workflow, can run with or without logged in user.
			if [[ "${current_user_account_name}" == "FALSE" ]]; then # A normal user is not logged in, start installations immediately.
				workflow_install_no_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
			else # A normal user is currently logged in so complete any macOS downloads first.
				{ [[ "${workflow_target}" != "Jamf Pro Policy Triggers Without Restarting" ]] && [[ "${workflow_target}" != "Jamf Pro Policy Triggers With Restart" ]] && [[ "${workflow_target}" != "Restart Without Updates" ]]; } && workflow_download_macos # This function only downloads if needed and includes internal storage checks and test mode logic.
				workflow_time_epoch=$(date +%s)
				[[ "${verbose_mode_option}" == "TRUE" ]] && log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: Setting new workflow_time_epoch to: ${workflow_time_epoch}"
				[[ "${workflow_download_macos_check_user}" == "TRUE" ]] && check_current_user # The download may have taken a while so another check to make sure the user is still logged in.
				if [[ "${current_user_account_name}" == "FALSE" ]]; then
					workflow_install_no_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
					return 0
				fi
				# Check deadlines.
				check_deadlines_days_date
				# User Focus only needs to be checked if there are no date or day deadlines.
				if [[ "${deadline_date_status}" == "FALSE" ]] && [[ "${deadline_days_status}" == "FALSE" ]]; then
					check_user_focus
				else # At this point any date or days deadline would rule out any ${user_focus_active} option.
					user_focus_active="FALSE"
				fi
				check_deadlines_count
				# Manage various workflow options when any deadline is active.
				if [[ "${deadline_date_status}" == "HARD" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_count_status}" == "HARD" ]] || [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "SOFT" ]]; then
					[[ $(echo "${display_unmovable_option}" | grep -c 'DEADLINE') -gt 0 ]] && display_unmovable_status="TRUE"
					[[ $(echo "${display_hide_background_option}" | grep -c 'DEADLINE') -gt 0 ]] && display_hide_background_status="TRUE"
					[[ $(echo "${display_silently_option}" | grep -c 'DEADLINE') -gt 0 ]] && display_silently_status="TRUE"
					[[ $(echo "${display_notifications_centered_option}" | grep -c 'DEADLINE') -gt 0 ]] && display_notifications_centered_status="TRUE"
					[[ $(echo "${display_hide_progress_bar_option}" | grep -c 'DEADLINE') -gt 0 ]] && display_hide_progress_bar_status="TRUE"
					[[ $(echo "${auth_mdm_failover_to_user_option}" | grep -c 'DEADLINE') -gt 0 ]] && auth_mdm_failover_to_user_status="TRUE"
				fi
				# At this point all deferral and deadline options have been evaluated.
				if [[ "${deadline_date_status}" == "HARD" ]] || [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then # A hard deadline has passed, similar to no logged in user but with a notification.
					workflow_install_active_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
				elif [[ "${deadline_date_status}" == "SOFT" ]] || [[ "${deadline_days_status}" == "SOFT" ]] || [[ "${deadline_count_status}" == "SOFT" ]]; then # A soft deadline has passed.
					[[ "${workflow_macos_auth}" != "USER" ]] && dialog_soft_deadline
					workflow_install_active_user # This function includes internal power, storage, and Apple silicon authentication checks. Sub-functions include test mode logic.
				elif [[ "${user_focus_active}" == "TRUE" ]]; then # No deadlines have passed but a process has told the display to not sleep or the user has enabled Focus or Do Not Disturb.
					deferral_timer_minutes="${deferral_timer_focus_minutes}"
					log_status "Pending: Automatic user focus deferral, trying again in ${deferral_timer_minutes} minutes."
					set_auto_launch_deferral
				else # Logically, this is the only time the choice dialog is shown.
					dialog_user_choice # This function includes all workflows to facilitate user choices.
				fi
			fi
		fi
	fi
	
	# At this point super is about to exit, so wrap up for different workflow exit modes.
	if [[ $(/usr/libexec/PlistBuddy -c "Print :WorkflowRestartValidate" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null) == "true" ]]; then # An update/upgrade is about to restart the computer.
		log_super "Exit: System restart is imminent and the super restart validation workflow is scheduled to automatically relaunch at next startup."
		log_status "Pending: System restart is imminent and the super restart validation workflow is scheduled to automatically relaunch at next startup."
	else # The super workflow completed but not for a macOS update/upgrade workflow.
		if [[ "${workflow_target}" != "FALSE" ]]; then
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowDownloadMacOSAuthRequired 2>/dev/null
			reset_schedule_zero_date
			reset_deadline_counters
		fi
		# Wrap-up for the ${workflow_install_now_active} if there were no updates/upgrades.
		if [[ "${workflow_install_now_active}" == "TRUE" ]]; then
			[[ "${current_user_account_name}" != "FALSE" ]] && notification_install_now_up_to_date
			if [[ "${test_mode_option}" == "TRUE" ]]; then
				log_super "Test Mode: Pausing ${test_mode_timeout_seconds} seconds for the install now up to date notification..."
				sleep "${test_mode_timeout_seconds}"
				killall -9 "IBM Notifier" "IBM Notifier Popup" >/dev/null 2>&1
			fi
		fi
		# Wrap-up for ${workflow_only_download_active}.
		if [[ "${workflow_only_download_active}" == "TRUE" ]] && [[ "${workflow_download_macos_error}" == "FALSE" ]]; then
			if [[ "${jamf_version_number}" != "FALSE" ]]; then
				if [[ "${auth_error_jamf}" != "TRUE" ]]; then
					log_super "Status: Submitting updated inventory to Jamf Pro. Use --verbose-mode or check /var/log/jamf.log for more detail..."
					if [[ "${verbose_mode_option}" == "TRUE" ]]; then
						local jamf_response
						jamf_response=$("${JAMF_PRO_BINARY}" recon -verbose 2>&1)
						log_super "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: jamf_response is:\n${jamf_response}"
					else
						"${JAMF_PRO_BINARY}" recon >/dev/null 2>&1
					fi
				else # There was an earlier Jamf Pro validation error.
					deferral_timer_minutes="${deferral_timer_error_minutes}"
					log_super "Error: Unable to submit inventory to Jamf Pro, trying again in ${deferral_timer_minutes} minutes."
					log_status "Pending: Unable to submit inventory to Jamf Pro, trying again in ${deferral_timer_minutes} minutes."
					set_auto_launch_deferral
				fi
			fi
		fi
		# Handle the ${workflow_reset_super_after_completion_active} workflow option.
		if [[ "${workflow_reset_super_after_completion_active}" == "TRUE" ]]; then
			defaults delete "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletion 2>/dev/null
			defaults write "${SUPER_LOCAL_PLIST}" WorkflowResetSuperAfterCompletionNow -bool true
			log_super "Status: Workflow complete, restarting via LaunchDeamon to reset super..."
			restart_super_sleep_seconds=5
			restart_super
		fi
		# Logic for ${workflow_disable_relaunch_option} and ${deferral_timer_workflow_relaunch_minutes}.
		if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
			log_super "Status: Full super workflow complete! Automatic relaunch is disabled."
			log_status "Inactive: Full super workflow complete! Automatic relaunch is disabled."
			/usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${SUPER_LOCAL_PLIST}.plist" 2> /dev/null
		else # Default super workflow automatically relaunches.
			deferral_timer_minutes="${deferral_timer_workflow_relaunch_minutes}"
			log_super "Status: Full super workflow complete! The super workflow is scheduled to automatically relaunch in ${deferral_timer_minutes} minutes."
			log_status "Pending: Full super workflow complete! The super workflow is scheduled to automatically relaunch in ${deferral_timer_minutes} minutes."
			set_auto_launch_deferral
		fi
	fi
}

main "$@"
exit_clean

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# MAIN SCRIPT EXECUTION
# # # # # # #_# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Start logging
superPID=$$
log "S.U.P.E.R.M.A.N. v${superVersion} started"

# Validate settings and dialog agent
validateSettings
validateDialog

# Example Usage:
# The rest of the `super` script would call these functions based on its logic.
# Here is a simple test case to demonstrate how the functions would be used.

log "--- Running swiftDialog Demo ---"

# Demo 1: Simple Notification
dialogTitle="Hello from S.U.P.E.R.M.A.N."
dialogMessage="This is a test notification using swiftDialog."
dialogIcon="SF=info.circle"
displayNotification

sleep 5

# Demo 2: Standard Dialog with two buttons and a timer
dialogTitle="Action Required"
dialogMessage="This is a test of a standard dialog window. It will time out in 30 seconds."
dialogIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Actions.icns"
dialogButton1="OK"
dialogButton2="Cancel"
dialogTimeout="30"
displayDialog

case $dialogExitCode in
    0)
        log "User clicked OK (Button 1)."
        ;;
    2)
        log "User clicked Cancel (Button 2)."
        ;;
    3)
        log "Dialog timed out."
        ;;
    *)
        log "Dialog closed with an unknown exit code: ${dialogExitCode}"
        ;;
esac

log "S.U.P.E.R.M.A.N. execution finished."

exit 0
