# Sway dotfile

## Prepare btrfs subvolumes

Create nested subvolumes under $HOME (run as normal user) (total 17 subvolumes)
```bash
# run as normal user
cd ~

mv .ssh .ssh-old
btrfs subvolume create .ssh
cp -ar .ssh-old/. .ssh/
#rm -rf .ssh-old

mv .sway-dotfiles .sway-dotfiles-old
btrfs subvolume create .sway-dotfiles
cp -ar .sway-dotfiles-old/. .sway-dotfiles/
#rm -rf .sway-dotfiles-old

mv .cache .cache-old
btrfs subvolume create .cache
cp -ar .cache-old/. .cache/
#rm -rf cache-old

btrfs subvolume create .mozilla
btrfs subvolume create .cargo
btrfs subvolume create Pictures
btrfs subvolume create Downloads
btrfs subvolume create Documents
btrfs subvolume create Musics
btrfs subvolume create Videos
btrfs subvolume create helix
btrfs subvolume create .fzf
btrfs subvolume create bin
btrfs subvolume create .rustup
btrfs subvolume create projects

mkdir ~/.config
btrfs subvolume create .config/helix
btrfs subvolume create .config/cosmic
cd -
```

Append entries to /etc/fstab (rus as root)
```bash
# run as root
BTRFS_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
bash -c 'cat >> /etc/fstab' << EOF
UUID=$BTRFS_UUID /home/tie/.ssh          btrfs   subvol=/home/tie/.ssh,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.mozilla      btrfs   subvol=/home/tie/.mozilla,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.cargo        btrfs   subvol=/home/tie/.cargo,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/Pictures      btrfs   subvol=/home/tie/Pictures,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/Downloads     btrfs   subvol=/home/tie/Downloads,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/Documents     btrfs   subvol=/home/tie/Documents,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/Musics        btrfs   subvol=/home/tie/Musics,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/Videos        btrfs   subvol=/home/tie/Videos,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/helix         btrfs   subvol=/home/tie/helix,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.fzf          btrfs   subvol=/home/tie/.fzf,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.sway-dotfiles          btrfs   subvol=/home/tie/.sway-dotfiles,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.config/helix           btrfs   subvol=/home/tie/.config/helix,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.config/cosmic          btrfs   subvol=/home/tie/.config/cosmic,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/bin           btrfs   subvol=/home/tie/bin,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.rustup       btrfs   subvol=/home/tie/.rustup,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.cache        btrfs   subvol=/home/tie/.cache,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/projects      btrfs   subvol=/home/tie/projects,compress=zstd:1 0 0
EOF

# re-mount
systemctl daemon-reload
mount -a
mount

# veirfy by
# lsblk
```

Setup Snapper [ref](https://sysguides.com/install-fedora-42-with-snapshot-and-rollback-support#3-postinstallation-configuration).
```bash
# install necessary packages
sudo dnf install snapper libdnf5-plugin-actions inotify-tools -y

# integrate snapper with dnf
sudo bash -c "cat > /etc/dnf/libdnf5-plugins/actions.d/snapper.actions" <<'EOF'
# Get snapshot description
pre_transaction::::/usr/bin/sh -c echo\ "tmp.cmd=$(ps\ -o\ command\ --no-headers\ -p\ '${pid}')"

# Creates pre snapshot before the transaction and stores the snapshot number in the "tmp.snapper_pre_number"  variable.
pre_transaction::::/usr/bin/sh -c echo\ "tmp.snapper_pre_number=$(snapper\ create\ -t\ pre\ -c\ number\ -p\ -d\ '${tmp.cmd}')"

# If the variable "tmp.snapper_pre_number" exists, it creates post snapshot after the transaction and removes the variable "tmp.snapper_pre_number".
post_transaction::::/usr/bin/sh -c [\ -n\ "${tmp.snapper_pre_number}"\ ]\ &&\ snapper\ create\ -t\ post\ --pre-number\ "${tmp.snapper_pre_number}"\ -c\ number\ -d\ "${tmp.cmd}"\ ;\ echo\ tmp.snapper_pre_number\ ;\ echo\ tmp.cmd
EOF

# create snapper configs
sudo snapper -c root create-config /
sudo snapper -c root set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo cp ~/.sway-dotfiles/global-configs/snapper-config-root /etc/snapper/configs/root

sudo snapper -c home create-config /home
sudo snapper -c home set-config ALLOW_USERS=$USER SYNC_ACL=yes

sudo snapper -c home_ssh create-config /home/tie/.ssh
sudo snapper -c home_ssh set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_ssh set-config TIMELINE_CREATE=no

sudo snapper -c home_mozilla create-config /home/tie/.mozilla
sudo snapper -c home_mozilla set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_mozilla set-config TIMELINE_CREATE=no

sudo snapper -c home_Pictures create-config /home/tie/Pictures
sudo snapper -c home_Pictures set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Pictures set-config TIMELINE_CREATE=no

sudo snapper -c home_Documents create-config /home/tie/Documents
sudo snapper -c home_Documents set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Documents set-config TIMELINE_CREATE=no

sudo snapper -c home_Downloads create-config /home/tie/Downloads
sudo snapper -c home_Downloads set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Downloads set-config TIMELINE_CREATE=no

sudo snapper -c home_Musics create-config /home/tie/Musics
sudo snapper -c home_Musics set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Musics set-config TIMELINE_CREATE=no

sudo snapper -c home_Videos create-config /home/tie/Videos
sudo snapper -c home_Videos set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Videos set-config TIMELINE_CREATE=no
```

Allow grub to detect and list snapshots in the boot menu
```bash
cd ~
git clone https://github.com/Antynea/grub-btrfs
cd grub-btrfs

sed -i.bkp \
  -e '/^#GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=/a \
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rd.live.overlay.overlayfs=1"' \
  -e '/^#GRUB_BTRFS_GRUB_DIRNAME=/a \
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"' \
  -e '/^#GRUB_BTRFS_MKCONFIG=/a \
GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig' \
  -e '/^#GRUB_BTRFS_SCRIPT_CHECK=/a \
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check' \
  config

sudo make install
sudo systemctl enable --now grub-btrfsd.service
cd ..
rm -rf grub-btrfs
cd ~/.sway-dotfiles
```

Enable automatic timeline snapshots
```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

Prepare /mnt for external snapper backup (run as root)
```bash
# run as root
mkdir /mnt/{old_snapshots,snapper_external_backup}

#############################################
# Attach the USB for use as external backup #
#############################################

# get USB uuid
USB_UUID=$(blkid -s UUID -o value /dev/sdXX)

# append entry to /etc/fstab
bash -c 'cat >> /etc/fstab' << EOF
UUID=$USB_UUID /mnt/snapper_external_backup			  btrfs	  defaults,compress=zstd,nofail 0 0
EOF

systemctl daemon-reload
mount -a
```

## Setup my development environment

Paste global-bashrc file in /etc/bashrc
```bash
sudo mv /etc/bashrc /etc/bashrc.orig
sudo cp ~/.sway-dotfiles/global-configs/global-bashrc /etc/bashrc

source /etc/bashrc
```

Enable rpmfusion
```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

<!-- Optional for swayWM -->
<!-- Install tlp for manage battery -->
<!-- ```bash -->
<!-- sudo dnf install tlp tlp-rdw -y -->

<!-- sudo cp ~/.sway-dotfiles/global-configs/tlp.conf /etc/tlp.conf -->
<!-- sudo systemctl enable tlp.service -->
<!-- sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket -->
<!-- ``` -->

Install utility packages 
```bash
sudo dnf install -y android-file-transfer btop firefox git keepassxc stow @c-development cmake just
sudo dnf copr enable atim/lazygit -y
sudo dnf install -y lazygit

# Optional for swayWM
# sudo dnf install wdisplays -y
```

> `wdisplays` allow precise adjustment of display settings via gui, and you can copy these settings to `~/.config/sway/config` for permanent.

Paste default config for *foot* and *sway*
```bash
# Optional for swayWM
# stow -v default

# restart sway by press key
# super+shift+c

# reopen terminal
```

Create user systemd dir
```bash
mkdir -p ~/.config/systemd/user
```

Install dropbox
```bash
wget https://www.dropbox.com/download?plat=lnx.x86_64 -O /tmp/dropbox.tar.gz
tar -xf /tmp/dropbox.tar.gz -C $HOME

stow -v dropbox
systemctl --user enable --now dropbox
```

> If you have already 3 devices connected, you can't connect more devices, you must clear some device via the browser and the restart the dropbox.service.

Backup user bashrc
```bash
mv ~/.bashrc ~/.bashrc.orig
```

Install cargo 
```bash
sudo dnf install -y mold
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile default --no-modify-path -y

stow -v cargo
source ~/.bashrc
```

> `mold` is a faster drop-in replacement for existing Unix linkers, use to tell cargo to use did linker to build other rust crates.

Build sccache
```bash
sudo dnf install -y openssl-devel openssl
RUSTC_WRAPPER= cargo install sccache --locked --quiet
```

Build helix
```bash
sudo dnf install -y lldb
git clone https://github.com/helix-editor/helix ~/helix
mkdir -p ~/.config/helix/runtime
export HELIX_RUNTIME=~/.config/helix/runtime
cargo install --path ~/helix/helix-term --locked --quiet
mv -v ~/helix/runtime/* ~/.config/helix/runtime/
```

Set language server for rust
```bash
rustup component add rust-analyzer

sudo sed -i 's/EDITOR="vi"/EDITOR="hx"/' /etc/bashrc
sudo sed -i '/EDITOR="hx"/a export HELIX_RUNTIME="~/.config/helix/runtime"' /etc/bashrc
source /etc/bashrc

stow -v --override=.bashrc helix
source ~/.bashrc

# verify by
# hx --health rust
```

Set language server for bash
```bash
sudo dnf install -y nodejs-bash-language-server

# verify by
# hx --health bash
```

Install fzf
```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc
```

Build alacritty
```bash
sudo dnf install -y fontconfig-devel
cargo install alacritty --quiet --locked
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
```

Build bat
```bash
sudo dnf install -y oniguruma-devel
RUSTONIG_SYSTEM_LIBONIG=1 cargo install bat --locked --quiet
```

Build startship
```bash
cargo install starship --quiet --locked
```

Build zoxide
```bash
cargo install zoxide --quiet --locked

# uncomment line to enable zoxide
sudo sed -i '/eval "$(zoxide init bash)"/s/^# *//' /etc/bashrc
```

Activate
```bash
mv ~/.gitconfig ~/.gitconfig.orig
stow -v --override=.bashrc --override=.config/sway/config kdtie
source /etc/bashrc
source ~/.bashrc

# restart sway by press key
# super+shift+c
```

Make some binary available called by sudo
```bash
sudo ln -sv $HOME/.cargo/bin/hx /usr/local/bin/hx
sudo ln -sv $HOME/.cargo/bin/bat /usr/local/bin/bat
sudo ln -sv $HOME/bin/restore-snapshot /usr/local/bin/restore-snapshot
```

## Install required packages and build cosmic-epoch

```bash
# install dependencies
sudo dnf install -y libxkbcommon-devel systemd-devel dbus-devel pkgconf-pkg-config libinput-devel libseat-devel libdisplay-info-devel mesa-libgbm-devel clang llvm-devel pam-devel gstreamer1-devel gstreamer1-plugins-base-devel pipewire-devel flatpak-devel greetd power-profiles-daemon google-noto-sans-thai-fonts glibc-langpack-th

# clone setting
git clone git@github.com:nutthawit/solarized-cosmic-setup.git ~/.config/cosmic

# build
git clone --recurse-submodules https://github.com/pop-os/cosmic-epoch ~/projects/cosmic-epoch
cd ~/projects/cosmic-epoch
sudo ln -s /usr/lib64/libclang.so.20.1 /usr/lib64/libclang.so
just build > build.log 2>&1

# install to /usr
sed -i 's|install rootdir="" prefix="/usr/local": build|install rootdir="" prefix="/usr":|' justfile
sudo just install
cd ~

# enable greetd
sudo cp ~/.sway-dotfiles/global-configs/greetd-config.toml /etc/greetd/config.toml
sudo systemctl enable greetd.service

# set default runlevel to graphic
sudo systemctl set-default graphical.target
```

> `greetd` is required when you need to run `just --no-deps install` to install on /usr/local, not just systemd-sysext
> `power-profiles-daemon`  is a Linux service that manages system power profiles, allowing users to switch between different power modes (e.g., Power Saver, Balanced, and Performance) to optimize battery life or performance. It is commonly used in GNOME-based systems (like Fedora, Ubuntu, and other distributions) as an alternative to older solutions like `tlp` or `cpufreqd`.
> `google-noto-sans-thai-fonts` and `glibc-langpack-thai` for correct display thai font on application

## Post install cosmic-epoch

1. Clone current development repositories
```bash
git clone git@github.com:nutthawit/rust-note.git ~/projects/rust-note
git clone --recurse-submodules https://github.com/pop-os/libcosmic.git ~/projects/libcosmic
```

2. Restore snapshots from external USB
```bash
sudo restore-snapshot -u bff88dbf-0743-457e-91b8-c679909542c4 --snapper-configs home_mozilla
sudo restore-snapshot -u bff88dbf-0743-457e-91b8-c679909542c4 --snapper-configs home_Documents
sudo restore-snapshot -u bff88dbf-0743-457e-91b8-c679909542c4 --snapper-configs home_Pictures
sudo restore-snapshot -u bff88dbf-0743-457e-91b8-c679909542c4 --snapper-configs home_Musics
```

3. Install rust debugger
```bash
sudo dnf install -y rust-lldb
```

## Troubleshooting

Fix `Intel Corporation Dual Band Wi-Fi 6(802.11ax) AX201 160MHz 2x2 [Harrison Peak]` kernel driver wouldn't load [readmore](https://discussion.fedoraproject.org/t/missing-intel-r-wireless-wifi-driver-for-linux/147332/3)
```bash
# run as root
dnf install -y iwlwifi-dvm-firmware iwlwifi-mvm-firmware
modprobe -r iwlwifi
modprobe iwlwifi
dracut -f
reboot
```

Fix authentication failure" when locking screen. [Readmore]("https://github.com/pop-os/cosmic-greeter/issues/126") [Solution]("https://github.com/pop-os/cosmic-greeter/issues/126#issuecomment-2351331240")

```bash
cd /etc/pam.d
sudo ln -s greetd cosmic-greeter
cd ~
```

If `journalctl -xb` show "Failed to resolve user 'cosmic-greeter': No such process"
```bash
# check user cosmic-greeter
id cosmic-greeter

# If no user are create try to test create by
sudo systemd-sysusers --dry-run /usr/lib/sysusers.d/cosmic-greeter.conf

# If no error, just create a user and reboot
sudo systemd-sysusers /usr/lib/sysusers.d/cosmic-greeter.conf
```

## Todo

1. After backup_usb is plugged execute service to auto backup root and home
2. redesign and rewrite script send-snapshot and restore-snapshot to support step 1
