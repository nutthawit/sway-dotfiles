Excellent question. Restoring from a snapshot on your USB drive is a critical skill. The process involves two main scenarios: restoring individual files/folders and restoring an entire system. We'll cover both.

### Prerequisites
1.  Your external USB drive with Btrfs snapshots is connected and mounted.
    ```bash
    sudo mount -o compress=zstd /dev/disk/by-uuid/your-usb-uuid /mnt/backup
    ```
2.  You know the path to the snapshots on the USB. We'll assume they are in `/mnt/backup/@snapshots_backup/`.

---

### Scenario 1: Restoring Individual Files or Directories

This is the most common and easiest scenario. You mount the snapshot read-only and simply copy the files you need back to your system.

#### Step 1: Find the Right Snapshot

List the snapshots on your backup drive to find the one containing the good version of your file.
```bash
ls /mnt/backup/@snapshots_backup/
# Example output: 10  20  30  40  50
```

#### Step 2: Create a Mount Point and Mount the Snapshot

Mount the specific snapshot you need. It's best to mount it read-only to prevent accidental changes.
```bash
sudo mkdir -p /mnt/old_snapshot
sudo mount -o ro,subvol=/@snapshots_backup/50 /dev/disk/by-uuid/your-usb-uuid /mnt/old_snapshot
```
*   `-o ro`: Mounts the snapshot **read-only**.
*   `subvol=/@snapshots_backup/50`: Specifies the exact snapshot subvolume on the USB drive to mount.

#### Step 3: Copy the Files You Need

Now, browse the mounted snapshot and copy the files or directories back to their original location (or a new location).
```bash
# Example: Restore a single file
sudo cp -a /mnt/old_snapshot/home/username/important_document.txt /home/username/important_document.txt.restored

# Example: Restore a whole directory (e.g., .config)
sudo cp -a /mnt/old_snapshot/home/username/.config/ ~/.config.old

# Use `rsync` for more control over large restores
sudo rsync -avh /mnt/old_snapshot/home/username/Documents/ /home/username/Documents/
```
**Always copy to a temporary or differently named location first** to avoid accidentally overwriting good data before you verify the restore was correct.

#### Step 4: Unmount the Snapshot

After copying, unmount the snapshot.
```bash
sudo umount /mnt/old_snapshot
```

---

### Scenario 2: Restoring an Entire System (Advanced)

This process is more complex and typically requires booting from a live USB (like Fedora Media Writer or Ubuntu Live CD) if your system is unbootable. The goal is to replace the broken system subvolume with the good one from the backup.

**⚠️ Warning: This will erase the current state of your system. Use with extreme caution.**

#### Step 1: Boot from a Live USB Environment

1.  Create a live USB of a Linux distribution that includes `btrfs-progs` (most do).
2.  Boot your computer from the live USB.
3.  Open a terminal and become root (`sudo -i`).

#### Step 2: Mount the Partitions

Identify your disks and mount both your system's root partition and your backup USB drive.

```bash
# Identify your disks
lsblk -f

# Mount your system's root Btrfs filesystem
mkdir -p /mnt/system
mount -o subvolid=5 /dev/nvme0n1p2 /mnt/system # Use your correct system partition

# Mount your backup USB drive
mkdir -p /mnt/backup
mount -o compress=zstd /dev/sdb1 /mnt/backup # Use your correct USB partition
```

#### Step 3: Delete the Broken System Subvolume

Your system's root (`)` is likely a subvolume like `@` or `@root`. We need to delete it before restoring.

**First, find its name:**
```bash
btrfs subvolume list /mnt/system
```
Look for the subvolume that has a mount path of `/` (e.g., `ID 256 gen 1234 top level 5 path @`).

**Now, delete it:**
```bash
# !!! BE VERY CERTAIN YOU HAVE THE RIGHT NAME !!!
btrfs subvolume delete /mnt/system/@
```

#### Step 4: Restore the Snapshot from Backup

Use `btrfs send` and `receive` in reverse! Now the USB drive is the *source*, and your system disk is the *target*.

```bash
# Send the snapshot from the USB backup and receive it as the new system subvolume
btrfs send /mnt/backup/@snapshots_backup/50 | btrfs receive /mnt/system/

# Rename the received subvolume to what your system expects (e.g., '@')
mv /mnt/system/snapshot /mnt/system/@
```

#### Step 5: Update Your System's fstab (If Necessary)

If the UUID of your root partition has changed or the subvolume name in your backup is different, you must edit `/mnt/system/@/etc/fstab`.

1.  Find the UUID of your system root partition:
    ```bash
    lsblk -f /dev/nvme0n1p2
    ```
2.  Check the fstab file on the restored system:
    ```bash
    nano /mnt/system/@/etc/fstab
    ```
    Ensure the `UUID=` and `subvol=` options for the root entry are correct.

#### Step 6: Rebuild the Initramfs (Important!)

This step is crucial. The initial RAM filesystem needs to know about the new subvolume layout.
```bash
# Chroot into the restored system to rebuild the initramfs
mount -o bind /dev /mnt/system/@/dev
mount -o bind /proc /mnt/system/@/proc
mount -o bind /sys /mnt/system/@/sys
chroot /mnt/system/@

# Now inside the chroot, rebuild the initramfs for your kernel
dnf reinstall kernel-core # Or for Debian: update-initramfs -u -k all

# Exit the chroot
exit
```

#### Step 7: Unmount Everything and Reboot

```bash
umount -R /mnt/system
umount -R /mnt/backup
reboot
```
Remove the live USB and let the system boot normally. It should now boot into the restored snapshot.

### Summary of Commands for File Restore

| Task | Command |
| :--- | :--- |
| **Mount snapshot from USB** | `sudo mount -o ro,subvol=/@snapshots_backup/50 /dev/sdb1 /mnt/old_snapshot` |
| **Copy files back** | `sudo cp -a /mnt/old_snapshot/path/to/file /destination/` |
| **Unmount snapshot** | `sudo umount /mnt/old_snapshot` |

The key is to always treat snapshots on the USB as read-only archives. Mount them, extract what you need, and then unmount them. This ensures your backup integrity is never compromised.
