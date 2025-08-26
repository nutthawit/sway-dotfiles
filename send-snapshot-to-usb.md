# How using **Snapper** to create snapshots and then sending them to an external drive

### How It Works: The Theory

The process involves two Btrfs filesystems:
1.  **Source:** Your system's root (or home) partition, managed by Snapper.
2.  **Target:** Your external USB drive, formatted with Btrfs.

You use two key Btrfs commands:
*   `btrfs send`: Creates a binary stream of a snapshot (or the difference between two snapshots). This is done on the source.
*   `btrfs receive`: Reads that binary stream and recreates the snapshot on the target filesystem. This is done on the external drive.

This method is incredibly efficient because `btrfs send` only transfers the data that has changed between snapshots.

---

### Prerequisites

1.  Your **system root** (`/`) or `/home` is on a Btrfs filesystem and you have **Snapper** already configured for it (e.g., `snapper -c root list` shows snapshots).
2.  Your **external USB drive** is formatted as Btrfs and has a dedicated subvolume to receive the snapshots (e.g., `@snapshots_backup`).
3.  The external drive is mounted. We'll assume it's mounted at `/mnt/backup`.

---

### Step-by-Step Guide

#### Step 1: Prepare the External Drive

1.  **Mount your external drive.** Let's use a specific directory.
    ```bash
    sudo mkdir -p /mnt/backup
    sudo mount -o compress=zstd /dev/disk/by-uuid/your-usb-uuid-here /mnt/backup
    ```
    *(Replace `your-usb-uuid-here` with the actual UUID of your USB partition)*

2.  **Create a dedicated subvolume** on the external drive to hold the sent snapshots. This keeps things organized.
    ```bash
    sudo btrfs subvolume create /mnt/backup/@snapshots_backup
    ```

#### Step 2: Create the Initial Backup (Full Seed)

This first step is a full, initial backup. It will send the *first* snapshot you choose to the external drive.

1.  **Identify the snapshot** you want to use as your base. Numbered snapshots (#0) are read-only and perfect for this. List your snapshots:
    ```bash
    snapper -c root list
    ```
    Look for an early, clean snapshot (e.g., `#10`).

2.  **Send the full snapshot** to the external drive. This command creates a read-only pipe: `send` the snapshot from the source and `receive` it on the target.
    ```bash
    sudo btrfs send /path/to/.snapshots/10/snapshot | sudo btrfs receive /mnt/backup/@snapshots_backup/
    ```
    *   **Important:** The path to the source snapshot is usually `/path/to/.snapshots/<number>/snapshot`. The exact path depends on your configuration. Common locations are:
        *   For a `root` config: `/.snapshots/<number>/snapshot`
        *   For a `home` config: `/home/.snapshots/<number>/snapshot`

3.  **Rename the received snapshot** on the external drive. By default, it's named `snapshot`. It's better to rename it to match the source number for clarity.
    ```bash
    sudo mv /mnt/backup/@snapshots_backup/snapshot /mnt/backup/@snapshots_backup/10
    ```

#### Step 3: Create Incremental Backups

Now for the magic. After the initial backup, you only need to send the *differences*.

1.  **Take a new snapshot** with Snapper, or use an existing recent one. Note the numbers. Let's say your last backed-up snapshot is `#10` and you just created a new snapshot `#50`.

2.  **Find the common parent.** To create an incremental send, you need to specify the previous snapshot (the parent) that exists on *both* the source and the target. In this case, it's snapshot `#10`.

3.  **Send the incremental changes.**
    ```bash
    sudo btrfs send -p /path/to/.snapshots/10/snapshot /path/to/.snapshots/50/snapshot | sudo btrfs receive /mnt/backup/@snapshots_backup/
    ```
    *   The `-p` flag specifies the **parent snapshot** to calculate differences from.

4.  **Rename the new incremental snapshot** on the target.
    ```bash
    sudo mv /mnt/backup/@snapshots_backup/snapshot /mnt/backup/@snapshots_backup/50
    ```

This process is very fast and only transfers the changes since snapshot `#10`.

#### Step 4: Automate the Process with a Script

You can create a simple Bash script to automate this. Here's a basic example (`sudo nano /usr/local/bin/snapper-backup.sh`):

```bash
#!/bin/bash

# Configuration
SNAPPER_CONFIG="root" # Your snapper config name
SOURCE_SNAPSHOT_PATH="/.snapshots" # Path to .snapshots
TARGET_MOUNT="/mnt/backup"
TARGET_PATH="$TARGET_MOUNT/@snapshots_backup"

# Check if target is mounted
if ! mountpoint -q "$TARGET_MOUNT"; then
    echo "Error: Target $TARGET_MOUNT is not mounted."
    exit 1
fi

# Get the latest snapshot number on the SOURCE
LATEST_SNAPSHOT_NUM=$(snapper -c "$SNAPPER_CONFIG" list | tail -1 | awk '{print $1}')
LATEST_SNAPSHOT="$SOURCE_SNAPSHOT_PATH/$LATEST_SNAPSHOT_NUM/snapshot"

# Get the latest snapshot number on the TARGET
LAST_BACKUP_NUM=$(ls -1 "$TARGET_PATH" | sort -n | tail -1) 2>/dev/null

if [ -z "$LAST_BACKUP_NUM" ]; then
    echo "No existing backup found. Performing initial send..."
    sudo btrfs send "$LATEST_SNAPSHOT" | sudo btrfs receive "$TARGET_PATH"
    sudo mv "$TARGET_PATH/snapshot" "$TARGET_PATH/$LATEST_SNAPSHOT_NUM"
    echo "Initial backup of snapshot $LATEST_SNAPSHOT_NUM complete."
else
    echo "Last backup is snapshot $LAST_BACKUP_NUM. Performing incremental send..."
    PARENT_SNAPSHOT="$SOURCE_SNAPSHOT_PATH/$LAST_BACKUP_NUM/snapshot"
    sudo btrfs send -p "$PARENT_SNAPSHOT" "$LATEST_SNAPSHOT" | sudo btrfs receive "$TARGET_PATH"
    sudo mv "$TARGET_PATH/snapshot" "$TARGET_PATH/$LATEST_SNAPSHOT_NUM"
    echo "Incremental backup from $LAST_BACKUP_NUM to $LATEST_SNAPSHOT_NUM complete."
fi
```

5.  **Make the script executable:**
    ```bash
    sudo chmod +x /usr/local/bin/snapper-backup.sh
    ```

6.  **Run the script manually** to test it:
    ```bash
    sudo /usr/local/bin/snapper-backup.sh
    ```

#### Step 5: (Optional) Create a Systemd Service or Cron Job

To fully automate, you can have the script run automatically when the external drive is plugged in or on a schedule.

**Example Systemd Service (`/etc/systemd/system/snapper-backup.service`):**
```
[Unit]
Description=Snapper Backup to External Drive
Requires=dev-disk-by\x2duuid-your\x2dusb\x2duuid.device
After=dev-disk-by\x2duuid-your\x2dusb\x2duuid.device

[Service]
Type=oneshot
ExecStart=/usr/local/bin/snapper-backup.sh
```

**Example Systemd Timer (`/etc/systemd/system/snapper-backup.timer`):**
```
[Unit]
Description=Run Snapper Backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable the timer:
```bash
sudo systemctl enable --now snapper-backup.timer
```

### Important Considerations

*   **Read-only Snapshots:** The `btrfs send` command requires the source snapshot to be **read-only**. Snapper creates read-only snapshots by default (numbered ones, not timeline `#0`), so this is usually not an issue.
*   **Never Delete the Parent:** If you delete a parent snapshot on the source that was used for an incremental backup on the target, your chain will be broken. You must manage snapshots carefully or always do a full send if a parent is missing.
*   **Testing Recovery:** The most crucial step of any backup strategy is **testing recovery**. Practice mounting a snapshot from your external drive and restoring a file or directory to ensure the process works.
