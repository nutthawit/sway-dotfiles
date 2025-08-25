# Sway dotfile

## Prerequisite

Paste global-bashrc file in /etc/bashrc
```bash
sudo mv /etc/bashrc /etc/bashrc.orig
sudo cp ~/.sway-dotfiles/global-bashrc /etc/bashrc

source /etc/bashrc
```

Enable rpmfusion
```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

<!-- Install tlp for manage battery -->
<!-- ```bash -->
<!-- sudo dnf install tlp tlp-rdw -y -->

<!-- sudo cp tlp.conf /etc/tlp.conf -->
<!-- sudo systemctl enable tlp.service -->
<!-- sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket -->
<!-- ``` -->

Install utility packages 
```bash
sudo dnf install -y android-file-transfer btop git keepassxc stow wdisplays @c-development cmake just
sudo dnf copr enable atim/lazygit -y
sudo dnf install -y lazygit
```

> `wdisplays` allow precise adjustment of display settings via gui, and you can copy these settings to `~/.config/sway/config` for permanent.

Paste default config for *foot* and *sway*
```bash
stow -v default

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

Create .cargo dir
```bash
mkdir ~/.cargo
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
```

> verify by `hx --health rust`

## Install required packages for snapper

```bash
sudo dnf install -y \
snapper \
ps_mem \
libdnf5-plugin-actions \
btrfs-assistant \
inotify-tools
sudo dnf copr enable peoinas/snap-sync && sudo dnf install snap-sync -y
```

> How to create snapshot [see](https://sysguides.com/install-fedora-42-with-snapshot-and-rollback-support#3-postinstallation-configuration).

## Setup my development environment

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

## Install required packages for build cosmic-epoch

```bash
sudo dnf install -y libxkbcommon-devel systemd-devel dbus-devel pkgconf-pkg-config libinput-devel libseat-devel libdisplay-info-devel mesa-libgbm-devel clang llvm-devel pam-devel gstreamer1-devel gstreamer1-plugins-base-devel pipewire-devel flatpak-devel greetd power-profiles-daemon
```

> `greetd` is required when you need to run `just --no-deps install` to install on /usr/local, not just systemd-sysext
> `power-profiles-daemon`  is a Linux service that manages system power profiles, allowing users to switch between different power modes (e.g., Power Saver, Balanced, and Performance) to optimize battery life or performance. It is commonly used in GNOME-based systems (like Fedora, Ubuntu, and other distributions) as an alternative to older solutions like `tlp` or `cpufreqd`.

## Post install cosmic-epoch

1. Fix authentication failure" when locking screen. [Readmore]("https://github.com/pop-os/cosmic-greeter/issues/126") [Solution]("https://github.com/pop-os/cosmic-greeter/issues/126#issuecomment-2351331240")

```bash
cd /etc/pam.d
sudo ln -s greetd cosmic-greeter
```

2. Apply my cosmic style.

```bash
mv ~/.config/cosmic ~/.config/cosmic.orig
git clone git@github.com:nutthawit/solarized-cosmic-setup.git ~/.config/cosmic
pkill cosmic-session
```

## Todo

