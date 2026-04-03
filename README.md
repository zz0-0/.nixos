# NixOS Configuration Flake

A complete NixOS and Home Manager configuration using flakes, featuring DankMaterialShell, niri compositor, and comprehensive development environment integration.

## ✨ Features

- **Modern Desktop Environment**: DankMaterialShell with niri compositor
- **Complete Development Setup**: Integrated with devshell flake for language-specific environments
- **Consistent Theming**: Yaru-dark theme with Colloid icons and phinger-cursors
- **AI-Powered Development**: Multiple AI code assistants (Claude, Qwen, GitHub Copilot CLI)
- **Containerized Applications**: Distrobox and Podman for application isolation
- **VS Code Integration**: Automatic settings generation via devshell
- **Modern Terminal**: Wezterm with Fish shell and Starship prompt
- **Wayland Support**: Optimized for Wayland with XWayland fallback

## 📁 Project Structure

```
.nixos/
├── flake.nix                    # Main flake configuration
├── hosts/                       # System-level configurations
│   └── zz/                      # Host-specific configuration
│       ├── default.nix          # Main host configuration
│       ├── hardware-configuration.nix
│       └── modules/             # Modular configuration components
│           ├── boot.nix         # Bootloader configuration
│           ├── dns.nix          # DNS settings
│           ├── fonts.nix        # System fonts
│           ├── hardware/        # Hardware-specific modules
│           │   ├── bluetooth.nix
│           │   └── gpu.nix      # NVIDIA/Intel GPU configuration
│           ├── i18n.nix         # Internationalization
│           ├── network.nix      # Network configuration
│           ├── nix.nix          # Nix package manager settings
│           ├── programs/        # System-wide programs
│           │   └── steam.nix    # Steam gaming setup
│           ├── security.nix     # Security policies
│           ├── services.nix     # System services
│           ├── storage.nix      # Storage configuration
│           └── users.nix        # User accounts
├── home-manager/                # User-level configurations
│   ├── default.nix             # Main home-manager configuration
│   └── modules/                # Home-manager modules
│       ├── packages.nix        # User-installed packages
│       ├── portals.nix         # XDG desktop portals
│       ├── programs/           # User programs
│       │   ├── dms.nix         # DankMaterialShell configuration
│       │   ├── editor.nix      # Zed editor configuration
│       │   ├── git.nix         # Git configuration
│       │   └── niri.nix        # Niri compositor configuration
│       ├── services.nix        # User services
│       ├── shell.nix           # Shell configuration (Fish, Wezterm)
│       ├── theme.nix           # Theming (GTK, QT, cursor)
│       └── xdg.nix             # XDG directory configuration
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

1. **NixOS**: This configuration is designed for NixOS
2. **Flakes**: Enable experimental features:
   ```bash
   echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
   ```
3. **Git**: Clone the repository

### Installation

1. **Backup existing configuration** (if any):
   ```bash
   sudo mv /etc/nixos /etc/nixos.backup
   ```

2. **Clone and set up**:
   ```bash
   sudo git clone https://github.com/zz0-0/nixos /etc/nixos
   cd /etc/nixos
   ```

3. **Build and switch**:
   ```bash
   sudo nixos-rebuild switch --flake .#zz
   ```

4. **Apply home-manager configuration**:
   ```bash
   home-manager switch --flake .#zz
   ```

### Using with Existing NixOS Configuration

If you want to integrate parts of this configuration into your existing setup:

1. **Add as flake input**:
   ```nix
   # flake.nix
   inputs = {
     nixos-config.url = "github:zz0-0/nixos";
     nixos-config.inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. **Import modules**:
   ```nix
   imports = [
     nixos-config.nixosModules.default
   ];
   ```

## ⚙️ Configuration Details

### System Configuration (`hosts/zz/`)

The system configuration includes:

- **Hardware Support**: NVIDIA/Intel hybrid graphics, Bluetooth, and hardware acceleration
- **Security**: Secure boot configuration and security policies
- **Services**: PipeWire audio, printing, power management, and network services
- **Storage**: Filesystem configuration and mount points
- **Users**: User account and group management

Key system modules:
- `nix.nix`: Optimized Nix configuration with GC automation
- `hardware/gpu.nix`: NVIDIA PRIME offloading configuration
- `services.nix`: Systemd services and desktop environment setup

### Home Manager Configuration (`home-manager/`)

User-level configuration includes:

- **Shell Environment**: Fish shell with Starship prompt and direnv
- **Terminal**: Wezterm with modern features
- **Theming**: Consistent dark theme across GTK, QT, and applications
- **Development Tools**: AI code assistants, version control, and editors
- **Desktop Integration**: XDG portals, clipboard management, and Wayland utilities

### Special Modules

#### DankMaterialShell + Niri
- **DankMaterialShell**: Modern shell with material design aesthetics
- **Niri Compositor**: Dynamic tiling Wayland compositor
- **Integration**: Seamless integration between shell and compositor

#### AI Development Environment
- **Claude Code**: Anthropic's coding assistant
- **Qwen Code**: Alibaba's coding AI
- **GitHub Copilot CLI**: GitHub's AI pair programmer
- **OpenCode**: Open-source coding assistant

#### Development Tooling
- **DevShell Integration**: Language-specific environments via separate flake
- **VS Code**: Automatic settings and toolchain configuration
- **Containerization**: Distrobox and Podman for isolated development

## 🎨 Theming

The configuration uses a consistent dark theme:

- **GTK Theme**: Yaru-dark
- **Icon Theme**: Colloid-Dark
- **Cursor Theme**: phinger-cursors-light
- **QT Theme**: Yaru-dark with GTK platform theme
- **Color Scheme**: Prefer-dark across all applications

## 🐠 Shell Environment

- **Default Shell**: Fish with Bash compatibility layer
- **Prompt**: Starship with Git integration
- **Terminal**: Wezterm with GPU acceleration
- **Environment Management**: Direnv with nix-direnv integration
- **Development**: Automatic environment setup via devshell

## 🛠️ Usage

### Switching Configurations

```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#zz

# Update home-manager
home-manager switch --flake .#zz

# Build without switching
sudo nixos-rebuild build --flake .#zz

# Dry run
sudo nixos-rebuild dry-build --flake .#zz
```

### Managing Packages

System packages are managed through NixOS configuration, while user packages are managed through Home Manager. See:
- `hosts/zz/modules/nix.nix` for system package settings
- `home-manager/modules/packages.nix` for user packages

### Development Workflow

1. **Enter language-specific environment**:
   ```bash
   nix develop .#python  # Python environment
   nix develop .#rust    # Rust environment
   ```

2. **VS Code will automatically**:
   - Use correct language server from Nix store
   - Apply formatting on save
   - Use project-specific settings

3. **Containerized applications**:
   ```bash
   distrobox create --image ubuntu:22.04 mydev
   distrobox enter mydev
   ```

## 🔧 Customization

### Changing Hostname

1. Copy `hosts/zz` to `hosts/your-hostname`
2. Update username references in the new directory
3. Update `flake.nix` to reference your new host

### Adapting for Different Usernames

By default, this configuration uses the username `zz`. To use a different username:

1. **Update username references** in configuration files:
   - `flake.nix`: Change `username = "zz";` to your username
   - `hosts/zz/modules/users.nix`: Update user definitions
   - `home-manager/default.nix`: Update `username` and `homeDirectory`

2. **Rename host directory** (optional):
   ```bash
   mv hosts/zz hosts/your-username
   ```
   Update the reference in `flake.nix` accordingly.

3. **Update file permissions** for existing files:
   ```bash
   sudo chown -R your-username:your-username /home/your-username
   ```

Note: Some modules may have hardcoded paths referencing `/home/zz`. Search and replace as needed.

### Adding New Packages

**System packages** (installed for all users):
```nix
# In hosts/zz/modules/nix.nix or create new module
environment.systemPackages = with pkgs; [
  your-package
];
```

**User packages** (installed for specific user):
```nix
# In home-manager/modules/packages.nix
home.packages = with pkgs; [
  your-user-package
];
```

### Creating New Modules

1. Create a new `.nix` file in the appropriate `modules/` directory
2. Export your configuration
3. Import it in the main configuration file (`default.nix`)
4. Rebuild to apply changes

## 🐛 Troubleshooting

### Common Issues

**Issue**: NVIDIA drivers not working
**Solution**: Check `hardware/gpu.nix` and ensure correct PCI bus IDs

**Issue**: DankMaterialShell not starting
**Solution**: Ensure niri is enabled in system configuration

**Issue**: VS Code extensions not using Nix tools
**Solution**: Run `nix develop` in project directory first, then open VS Code

**Issue**: Home-manager not applying changes
**Solution**: Check for backup files (`.backup`) and remove conflicting configurations

### Logs and Debugging

- **System logs**: `journalctl -u display-manager`
- **Niri logs**: Check `~/.local/share/niri/log`
- **DMS logs**: Check `~/.cache/dms/log`
- **Build logs**: Add `--show-trace` to nix commands

## 🔄 Updates and Maintenance

### Updating Inputs

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

### Garbage Collection

Automatic garbage collection runs weekly, keeping last 14 days of generations. Manual cleanup:

```bash
# Remove old generations
sudo nix-env --delete-generations 14d

# Collect garbage
nix-collect-garbage -d
```

### Rollbacks

```bash
# System rollback
sudo nixos-rebuild switch --rollback

# Home-manager rollback
home-manager generations
home-manager switch --generation <ID>
```

## 📄 License

This configuration is available under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [NixOS](https://nixos.org/) and [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Home Manager](https://github.com/nix-community/home-manager)
- [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
- [niri](https://github.com/sodiboo/niri-flake)
- [DevShell](https://github.com/zz0-0/devshell) integration

## 🤝 Contributing

Feel free to fork and adapt this configuration for your own use. To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📞 Support

For issues with this specific configuration:
- Open an issue on the GitHub repository
- Check existing issues for similar problems
- Reference relevant configuration files in your report

For general NixOS questions:
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [NixOS Matrix/IRC channels](https://nixos.org/community/)