# backups24.sh - Automated Backup Script

## Overview

This Bash script is designed to automate the process of backing up files on a Linux system. The script runs continuously in the background, performing full, incremental, and differential backups at regular intervals.

## Features

- **Continuous Operation**: Runs indefinitely in the background, ensuring continuous protection of your files.
- **Supports Multiple File Types**: Accepts up to three file types as arguments, or backs up all file types if none are specified.
- **Complete Backup**: Creates a tarball of all specified file types across the directory tree rooted at `/home/username`.
- **Incremental Backup**: Backs up only files that have changed since the last backup.
- **Differential Backup**: Backs up files that have changed since the last complete backup.
- **Detailed Logging**: All backup activities are logged with timestamps in `backup.log`.

## File Structure

- `backupScript.sh`: The main script that performs the backup operations.
- `backup.log`: The log file where all backup operations and their timestamps are recorded.
- `/home/username/backup/cbup24s/`: Directory where complete backups are stored.
- `/home/username/backup/ibup24s/`: Directory where incremental backups are stored.
- `/home/username/backup/dbup24s/`: Directory where differential backups are stored.

## Usage

### Running the Script

1. 
   ```
   git clone https://github.com/DawarWaqar/BackUpBashScript.git
   ```
2.  ```
    cd BackUpBashScript
    ```
3.  ```
    chmod +x backupScript.sh
    ```
4.  
    ```
    ./backupScript.sh [filetype1] [filetype2] [filetype3]
    ```
    * Replace [filetype1], [filetype2], and [filetype3] with the desired file extensions (e.g., .c, .txt, .pdf).
    * If no file types are specified, the script will back up all files.


## Script Behavior
The script follows a continuous loop, performing the following steps every two minutes:

Step 1 - Complete Backup: Creates a complete backup of the specified file types and stores it in the cbup24s directory.

Step 2 - Incremental Backup: Backs up files modified after the last complete backup and stores them in the ibup24s directory.

Step 3 - Incremental Backup: Backs up files modified after the last incremental backup from Step 2 and stores them in the ibup24s directory.

Step 4 - Differential Backup: Backs up files modified after the last complete backup (from Step 1) and stores them in the dbup24s directory.

Step 5 - Incremental Backup: Backs up files modified after the last differential backup from Step 4 and stores them in the ibup24s directory.

The script then loops back to Step 1, continuing this process indefinitely.

## Sample generated backup.log
```
Sat 10 Aug 2024 06:52:58 PM EDT cbup24s-1.tar was created
Sat 10 Aug 2024 06:55:35 PM EDT No changes - ibup backup was not created
Sat 10 Aug 2024 06:58:17 PM EDT No changes - ibup backup was not created
Sat 10 Aug 2024 07:00:58 PM EDT dbup24s-1.tar was created
Sat 10 Aug 2024 07:03:38 PM EDT No changes - ibup backup was not created
Sat 10 Aug 2024 07:03:47 PM EDT cbup24s-2.tar was created
Sat 10 Aug 2024 07:05:52 PM EDT No changes - ibup backup was not created
Sat 10 Aug 2024 07:07:54 PM EDT No changes - ibup backup was not created
Sat 10 Aug 2024 07:10:03 PM EDT dbup24s-2.tar was created
Sat 10 Aug 2024 07:12:05 PM EDT No changes - ibup backup was not created
```