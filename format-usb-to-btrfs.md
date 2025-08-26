# Format USB drive with Btrfs

Formatting a USB drive with Btrfs gives you great features like **compression**, **snapshots**, and built-in **data checksumming** to help prevent corruption.

Here is a step-by-step guide to safely format your USB flash drive with the Btrfs filesystem.

---

### **⚠️ Important Warning: This will erase all data on the USB drive!**
**Double-check the device name (`/dev/sdX`) before running any command. Using the wrong device name could erase your main hard drive.**

---

### Step 1: Identify the USB Drive

1.  Plug in your USB drive.
2.  Open a terminal and run `lsblk` *before* and *after* plugging it in to identify the device. Look for the new device that appears.

    ```bash
    lsblk
    ```

    **Example Output:**
    ```
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sda           8:0    0 465.8G  0 disk
    ├─sda1        8:1    0   512M  0 part /boot/efi
    ├─sda2        8:2    0 464.3G  0 part /
    └─sda3        8:3    0   976M  0 part [SWAP]
    sdb           8:16   1  14.9G  0 disk
    └─sdb1        8:17   1  14.9G  0 part /run/media/user/OLD_USB
    ```
    In this example, the system disk is `sda`, and the USB drive is `sdb` with one partition `sdb1`. **Your device name will likely be different** (e.g., `sdc`, `nvme0n1`).

3.  Note the device name (e.g., `/dev/sdb`) and any existing partitions (e.g., `/dev/sdb1`). Also, make sure the device is **not mounted**. If it is (like `sdb1` in the example), unmount it:

    ```bash
    sudo umount /dev/sdb1
    ```

---

### Step 2: (Optional but Recommended) Wipe the Drive

This ensures you start with a clean slate, especially if the drive had previous partitions.

**Use `wipefs` to erase any existing partition tables or signatures:**
```bash
sudo wipefs -a /dev/sdb
```
*(Replace `/dev/sdb` with your device name. Use the whole device, not a partition like `sdb1`)*

---

### Step 3: Create a New Partition Table and Partition

We'll use `parted` for this, a powerful partitioning tool.

1.  Start `parted` on your device:
    ```bash
    sudo parted /dev/sdb
    ```

2.  In the `parted` prompt, create a new **GPT** partition table:
    ```bash
    (parted) mklabel gpt
    ```

3.  Create a new partition that takes up 100% of the available space:
    ```bash
    (parted) mkpart primary btrfs 0% 100%
    ```

4.  Optionally, give the partition a descriptive name:
    ```bash
    (parted) name 1 "MyBtrfsUSB"
    ```

5.  Quit `parted`:
    ```bash
    (parted) quit
    ```

6.  Verify the new partition was created with `lsblk -f` or `sudo parted /dev/sdb print`.

---

### Step 4: Format the Partition with Btrfs

Now, use the `mkfs.btrfs` command on the new **partition** (e.g., `/dev/sdb1`).

**Basic format command:**
```bash
sudo mkfs.btrfs -L "MyUSB" /dev/sdb1
```
*   `-L "MyUSB"` sets a label for the filesystem, which is handy for identification. You can call it whatever you want.

#### **Advanced Format Options (Highly Recommended):**

Btrfs's biggest advantages for a USB drive are **compression** and **data checksumming**. You can enable these features at format time.

```bash
sudo mkfs.btrfs -L "MyUSB" -m single -d single /dev/sdb1
```
*   `-m single`: Sets **metadata** to use **Single** profile. This uses less space on a single drive, which is perfect for a USB.
*   `-d single`: Sets **data** to use **Single** profile. Same reason as above.

To enable **compression** (which saves space and can sometimes speed up reads/writes on slow USB drives), you mount it with a specific option; you don't need to set it at format time.

---

### Step 5: Mount the New Btrfs Filesystem

1.  Create a mount point (directory):
    ```bash
    sudo mkdir -p /mnt/myusb
    ```

2.  Mount the partition **with compression enabled** (e.g., `zstd`, which is a great modern algorithm):
    ```bash
    sudo mount -o compress=zstd /dev/sdb1 /mnt/myusb
    ```

3.  Check that it mounted correctly and see the filesystem details:
    ```bash
    lsblk -f /dev/sdb1
    ```
    You should see `btrfs` in the `FSTYPE` column.

4.  You can now use the drive. Files you copy to `/mnt/myusb` will be transparently compressed.

---

### Step 6: (Optional) Set Up Automatic Mounting via /etc/fstab

To have the USB automatically mount with your preferred options every time you plug it in, add an entry to `/etc/fstab`.

1.  Find the UUID of your new partition (the safest way to identify it):
    ```bash
    lsblk -f /dev/sdb1
    ```
    Copy the long UUID string.

2.  Edit the fstab file:
    ```bash
    sudo nano /etc/fstab
    ```

3.  Add a new line at the bottom. Use the UUID you copied and specify the `compress` option.
    ```
    # Entry for Btrfs USB Drive
    UUID=your-copied-uuid-here   /mnt/myusb   btrfs   defaults,compress=zstd,noatime   0   0
    ```
    *   `noatime`: Impropes performance by not writing file access times.
    *   `0 0`: These values tell the system not to backup (dump) or check the filesystem at boot.

4.  Save the file and exit. To test the fstab entry without rebooting, run:
    ```bash
    sudo umount /mnt/myusb
    sudo mount -a
    ```
    If no errors appear, your fstab entry is correct!

You're all set! Your USB drive is now a modern Btrfs filesystem with all its benefits.
