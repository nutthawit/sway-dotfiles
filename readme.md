# dotfile

> gnome-settings.dconf only support for GNOME 48!

## Create subvolumes

Create nested subvolumes under $HOME (run as normal user) (total 17 subvolumes)

```bash
# run as normal user
cd ~

mv .ssh .ssh-old
btrfs subvolume create .ssh
cp -ar .ssh-old/. .ssh/

mv .dotfile .dotfile-old
btrfs subvolume create .dotfile
cp -ar .dotfile-old/. .dotfile/

mv .cache .cache-old
btrfs subvolume create .cache
cp -ar .cache-old/. .cache/

mv Pictures Pictures-old
btrfs subvolume create Pictures
cp -ar Pictures-old/. Pictures/

mv Downloads Downloads-old
btrfs subvolume create Downloads
cp -ar Downloads-old/. Downloads/

mv Documents Documents-old
btrfs subvolume create Documents
cp -ar Documents-old/. Documents/

mv Music Music-old
btrfs subvolume create Music
cp -ar Music-old/. Music/

mv Videos Videos-old
btrfs subvolume create Videos
cp -ar Videos-old/. Videos/

mv .mozilla .mozilla-old
btrfs subvolume create .mozilla
cp -ar .mozilla-old/. .mozilla

btrfs subvolume create .cargo
btrfs subvolume create helix
btrfs subvolume create .fzf
btrfs subvolume create bin
btrfs subvolume create .rustup
btrfs subvolume create projects

mkdir ~/.config
btrfs subvolume create .config/helix
btrfs subvolume create .config/cosmic
btrfs subvolume create .config/zellij
btrfs subvolume create .config/alacirtty
cd -

# recheck contents of follow dir:
ll ~/.ssh
ll ~/.dotfile
ll ~/.cache

# delete the backup
rm -rf ~/.ssh-old ~/.dotfile-old ~/.cache-old
rm -rf ~/Pictures-old ~/Music-old ~/Downloads-old ~/Documents-old
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
UUID=$BTRFS_UUID /home/tie/Music         btrfs   subvol=/home/tie/Music,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/Videos        btrfs   subvol=/home/tie/Videos,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/helix         btrfs   subvol=/home/tie/helix,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.fzf          btrfs   subvol=/home/tie/.fzf,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.dotfile      btrfs   subvol=/home/tie/.dotfile,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.config/helix           btrfs   subvol=/home/tie/.config/helix,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.config/cosmic          btrfs   subvol=/home/tie/.config/cosmic,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.config/zellij          btrfs   subvol=/home/tie/.config/zellij,compress=zstd:1 0 0
UUID=$BTRFS_UUID /home/tie/.config/alacritty       btrfs   subvol=/home/tie/.config/alacritty,compress=zstd:1 0 0
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

Setup Snapper

[see more on the reference](https://sysguides.com/install-fedora-42-with-snapshot-and-rollback-support#3-postinstallation-configuration).

```bash
# install necessary packages
sudo dnf install -y snapper libdnf5-plugin-actions inotify-tools btrfs-assistant

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
sudo cp ~/.dotfile/global-configs/snapper-config-root /etc/snapper/configs/root

sudo snapper -c home create-config /home
sudo snapper -c home set-config ALLOW_USERS=$USER SYNC_ACL=yes

sudo snapper -c home_mozilla create-config /home/tie/.mozilla
sudo snapper -c home_mozilla set-config ALLOW_USERS=$USER SYNC_ACL=yes

sudo snapper -c home_Documents create-config /home/tie/Documents
sudo snapper -c home_Documents set-config ALLOW_USERS=$USER SYNC_ACL=yes

sudo snapper -c home_ssh create-config /home/tie/.ssh
sudo snapper -c home_ssh set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_ssh set-config TIMELINE_CREATE=no

sudo snapper -c home_Pictures create-config /home/tie/Pictures
sudo snapper -c home_Pictures set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Pictures set-config TIMELINE_CREATE=no

sudo snapper -c home_Downloads create-config /home/tie/Downloads
sudo snapper -c home_Downloads set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Downloads set-config TIMELINE_CREATE=no

sudo snapper -c home_Music create-config /home/tie/Music
sudo snapper -c home_Music set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Music set-config TIMELINE_CREATE=no

sudo snapper -c home_Videos create-config /home/tie/Videos
sudo snapper -c home_Videos set-config ALLOW_USERS=$USER SYNC_ACL=yes
sudo snapper -c home_Videos set-config TIMELINE_CREATE=no
```

Allow GRUB to detect and list snapshots in the boot menu

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

sudo dnf install -y make
sudo make install
sudo systemctl enable --now grub-btrfsd.service
cd ..
rm -rf grub-btrfs
cd ~/.dotfile
```

Enable automatic timeline snapshots

```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

## Setup my desk

Paste global-bashrc file in /etc/bashrc

```bash
sudo mv /etc/bashrc /etc/bashrc.orig
sudo cp ~/.dotfile/global-configs/global-bashrc /etc/bashrc

source /etc/bashrc
```

Enable rpmfusion (optional)

```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# verify by:
# dnf repo list
```

Install utility packages

```bash
sudo dnf install -y android-file-transfer btop firefox git keepassxc stow gnome-tweaks
sudo dnf copr enable atim/lazygit -y
sudo dnf install -y lazygit

# c development setup
# sudo dnf install -y @c-development cmake meson

# rust development setup
# sudo dnf install -y just
```

Install dropbox

```bash
# Create user level systemd directory
mkdir -p ~/.config/systemd/user
wget https://www.dropbox.com/download?plat=lnx.x86_64 -O /tmp/dropbox.tar.gz
tar -xf /tmp/dropbox.tar.gz -C $HOME

stow -v dropbox
systemctl --user enable --now dropbox
```

> If you have already 3 devices connected, you can't connect more devices, you must clear some device via the browser and the restart the dropbox.service.

Install cargo

```bash
sudo dnf install -y mold
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile default --no-modify-path -y

mv ~/.bashrc ~/.bashrc.orig
stow -v cargo
source ~/.bashrc
```

> `mold` is a faster drop-in replacement for existing Unix linkers, use to tell cargo to use did linker to build other rust crates.

Build sccache

```bash
sudo dnf install -y openssl-devel openssal gcc
RUSTC_WRAPPER= cargo install sccache --locked --quiet
```

> gcc is require because build sccache need cc command

Build helix

```bash
sudo dnf install -y lldb gcc-c++
git clone https://github.com/helix-editor/helix ~/helix
mkdir -p ~/.config/helix/runtime
export HELIX_RUNTIME=~/.config/helix/runtime
cargo install --path ~/helix/helix-term --locked --quiet
mv ~/helix/runtime/* ~/.config/helix/runtime/
```

> gcc-c++ is require because build helix need c++ command

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

Set language server for C

```bash
sudo dnf install -y clang-devel bear

# verify by
# hx --health c
```

> clang-devel provide a `clangd`
> bear is a tool that generates a compilation database for clang tooling.

Set language server for Python

```bash
sudo dnf install -y python3-pip
# pip install virtualenvwrapper
# source /home/tie/.local/bin/virtualenvwrapper.sh
# mkvirtualenv kdtie

# install python lsp
pip install -U 'python-lsp-server[all]'

# verify by
# hx --health python
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

# create desktop icon
sudo cp global-configs/alacritty.desktop /usr/share/applications/alacritty.desktop
sudo cp global-configs/alacritty-term.svg /usr/share/applications/alacritty-term.svg

# install fonts
mkdir /tmp/{ibm-font,jetbrain-font} ~/.local/share/fonts

# install JetBrainsMono
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -O /tmp/jetbrain-font/JetBrainsMono.zip
cd /tmp/jetbrain-font
unzip -q JetBrainsMono.zip
cp *.ttf ~/.local/share/fonts/

# install IBMPlexMono
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/IBMPlexMono.zip -O /tmp/ibm-font/IBMPlexMono.zip
cd /tmp/ibm-font
unzip -q IBMPlexMono.zip
cp *.ttf ~/.local/share/fonts/

fc-cache -f
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

Build termusic (optional)

```bash
sudo dnf install protobuf-compiler alsa-lib-devel -y
cargo install termusic termusic-server --quiet --locked
```

Build zellij

```bash
sudo dnf install -y perl-FindBin perl-IPC-Cmd perl-File-Compare
cargo install zellij --quiet --locked
```

Activate the desk

```bash
mv ~/.gitconfig ~/.gitconfig.orig
stow -v --override=.bashrc kdtie
source /etc/bashrc
source ~/.bashrc
```

Make some binary available to called by sudo

```bash
sudo ln -sv $HOME/.cargo/bin/hx /usr/local/bin/hx
sudo ln -sv $HOME/.cargo/bin/bat /usr/local/bin/bat
# sudo ln -sv $HOME/bin/restore-snapshot /usr/local/bin/restore-snapshot
```

## Build cosmic-epoch (Require Retest)

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

# install to /usr !!no real install!!
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
git clone git@github.com:nutthawit/c-note.git ~/projects/c-note
git clone git@github.com:nutthawit/python-note.git ~/project/python-note
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

4. Install python packages (yt-dlp, etc...)
```bash
workon kdtie
pip install yt-dlp
deactive
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

Fix sound couldn't detech device and show dummy output/input
```bash
# check
journalctl -b | grep -i audio

# if the audio problem is directly caused by a missing Sound Open Firmware (SOF) file for your Intel Alder Lake audio controller. The specific error message is: sof-audio-pci-intel-tgl 0000:00:1f.3: SOF firmware and/or topology file not found.

# Install the sof-firmware package
sudo dnf install -y alsa-sof-firmware

# Optional install the troubleshooting tools
#sudo dnf install -y alsa-utils

reboot
```

## Todo

1. After backup_usb is plugged execute service to auto backup root and home
2. redesign and rewrite script send-snapshot and restore-snapshot to support step 1
3. Check upstream of rust-lldb package by looking in rpmfile
4. Test restore root snapshot to ID=34 and install only `alsa-sof-firmware`
5. Install Nerdfont for used in terminal https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
