
# Define directories and other constants
USERNAME=$(whoami)
ROOT_DIR="/home/$USERNAME"
BACKUP_DIR="$ROOT_DIR/backup"
CBUP_DIR="$BACKUP_DIR/cbup24s"
IBUP_DIR="$BACKUP_DIR/ibup24s"
DBUP_DIR="$BACKUP_DIR/dbup24s"
LOG_FILE="$BACKUP_DIR/backup.log"
CBUP_COUNTER=1 # Counters used to number .tar files
IBUP_COUNTER=1
DBUP_COUNTER=1
SLEEP_TIME=120 # Sleep time in seconds

# Validate the arguments
validate_args() {

    if [ $# -gt 3 ]; then
        echo "Error: Max 3 file types are allowed in arguments"
        exit 1
    fi
    
}

generate_tar_file_name() {
    local prefix=$1 # Prefixes are cbup, ibup or dbup
    local counter=$2
    echo "${prefix}24s-${counter}.tar"
}

# Log the backup operation
log_backup() {
    local msg=$1
    echo "$(date +"%a %d %b %Y %I:%M:%S %p %Z") $msg" >> "$LOG_FILE"
}

# Used for complete backup i.e Step 1
backup_complete() {

    local find_cmd="find $ROOT_DIR -type f ! -path '*/.*'" # Generic command to find files
    local tar_file=$(generate_tar_file_name "cbup" $CBUP_COUNTER) # Dynamically creating the name of the tar file

    # Loop will run if files are specified otherwise all files will be considered
    if  [ $# -gt 0 ]; then
        find_cmd+=" \( "
        for filetype in $*; do
            find_cmd+=" -name '*${filetype}' -o" # Appending file options
        done
        find_cmd=${find_cmd% -o} # Remove trailing -o
        find_cmd+=" \)"
    fi

    eval "$find_cmd" -print0 | tar -czvf "$CBUP_DIR/$tar_file" --null -T - 
    log_backup "$tar_file was created" # eval is used to run the command which is in string form like this. -print0 is used to seperate different files using null seperator. That's why --null option is used after the pipe operation

    CBUP_COUNTER=$((CBUP_COUNTER + 1)) # Increment the counter

}

parse_last_backup_time() {
    local last_backup_info=$1
    echo "$last_backup_info" | awk '{print $1, $2, $3, $4, $5, $6, $7}' 
    # Retrieve the backup time from backup info argument
}

get_last_backup_info() {
    local prefix=$1
    grep "$prefix" "$LOG_FILE" | tail -n 1 # Retrieve the last relevant backup info from backup.log. For e.g retrieve the last line in .log which contains the prefix
}

compare_with_last_backup() {

    local prefix=$1 # contains the prefix with whom's time you have to compare current backup with for e.g in step 4 we compare with cbup (complete backup) and not with any of the incremental ones

    local find_cmd=$2

    # Retrieve last backup info from the log file
    local last_backup_info=$(get_last_backup_info "$prefix")


    # Parse the last backup time
    local last_backup_time=$(parse_last_backup_time "$last_backup_info")

    # Find files newer than the last relevant backup time
    local changed_files=$(eval "$find_cmd -newermt '$last_backup_time' -print") # -print used instead of -print0 to seperate files using \n characters this time


    echo -n "$changed_files" # -n used to not generate a new line character at the end
}

# Function used for every step except step 1. Args vary for every step
backup() {

    local compare_with=$1 # Compare with what type of backup
    local backup_type=$2 # Current backup type (dbup or ibup)
    
    local find_cmd="find $ROOT_DIR -type f ! -path '*/.*'" # Local means these variables are just local to this function

    # Only apply name filters if file types were passed
    if [ $# -gt 2 ]; then
        find_cmd+=" \( "
        shift 2  # Skip the first two arguments because they are compare_with and backup_type
        for filetype in "$@"; do  # Use "$@" to iterate over remaining arguments
            find_cmd+=" -name '*${filetype}' -o"
        done
        find_cmd=${find_cmd% -o} # Remove trailing -o
        find_cmd+=" \)"
    fi


    local changed_files=$( compare_with_last_backup "$compare_with" "$find_cmd" )

    if [ -z "$changed_files" ]; then # If empty string thus no changes to any relevant files
        log_backup "No changes - $backup_type backup was not created"
    else
        local tar_file 
        local backup_dir
        local counter_var

        # Determine the correct directory, counter, and tar file name based on the backup_type
        if [ "$backup_type" == "ibup" ]; then
            counter_var="IBUP_COUNTER"
            backup_dir="$IBUP_DIR"
        elif [ "$backup_type" == "dbup" ]; then
            counter_var="DBUP_COUNTER"
            backup_dir="$DBUP_DIR"
        else
            echo "Unknown: $backup_type"
            return 1
        fi

        # Generate the tar file name
        tar_file=$(generate_tar_file_name "$backup_type" ${!counter_var})

        # Create the tar file with the changed files
        echo "$changed_files" | tar -czvf "$backup_dir/$tar_file" -T -


        log_backup "$tar_file was created"


        # Increment the appropriate counter
        eval "$counter_var=$(( ${!counter_var} + 1 ))"
    fi
}


validate_args $*

# Check if the /backup directory already exists
if [ -d "$BACKUP_DIR" ]; then
    # Remove the existing directory and its contents because its a new fresh run
    rm -rf "$BACKUP_DIR"
fi

# Making required directories
mkdir -p "$BACKUP_DIR"
mkdir -p "$CBUP_DIR"
mkdir -p "$IBUP_DIR"
mkdir -p "$DBUP_DIR"

# Main while loop
while true; do
   
    # step 1
    backup_complete $*
    echo "Step 1 Completed"

    # step 2
    sleep "$SLEEP_TIME"
    backup "cbup" "ibup" $* #backup [compare_with] [backup_type args] [./backups24.sh args]
    echo "Step 2 Completed"

    # step 3
    sleep "$SLEEP_TIME"
    backup "ibup" "ibup" $*
    echo "Step 3 Completed"

    # step 4
    sleep "$SLEEP_TIME"
    backup "cbup" "dbup" $*
    echo "Step 4 Completed"

    # step 5
    sleep "$SLEEP_TIME"
    backup "dbup" "ibup" $*
    echo "Step 5 Completed"

done
