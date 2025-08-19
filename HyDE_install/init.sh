#!/usr/bin/env bash
set -euo pipefail

# ========================================
# HyDE Auto Installer - Arch Linux
# ========================================

HYDE_DIR="$HOME/HyDE"
SCRIPT_DIR="$HYDE_DIR/Scripts"
USER_PKG_FILE="${1:-}"

# === Funções utilitárias ===
error_exit() { echo "Erro: $1" >&2; exit 1; }
info() { echo -e "\e[1;32m==>\e[0m $1"; }

# === Verificar sudo ===
if ! command -v sudo &>/dev/null; then
  error_exit "O sudo não está instalado. Instale com: pacman -S sudo"
fi

# === Atualização inicial ===
info "Atualizando sistema..."
sudo pacman -Syu --noconfirm

# === Instalar pacotes base ===
info "Instalando pacotes essenciais..."
sudo pacman -S --needed --noconfirm git base-devel xdg-utils networkmanager \
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber sddm

# === Ativar serviços críticos ===
info "Ativando serviços de rede e display manager..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable sddm

# === Checar AUR helper ===
if ! command -v paru &>/dev/null; then
  info "Instalando paru (AUR helper)..."
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru
  makepkg -si --noconfirm
  cd -
fi

# === Clonar HyDE ===
info "Clonando HyDE..."
if [ -d "$HYDE_DIR" ]; then
  info "HyDE já existe, atualizando..."
  git -C "$HYDE_DIR" pull
else
  git clone --depth 1 https://github.com/HyDE-Project/HyDE "$HYDE_DIR"
fi

# === Backup antigo ===
if [ -d "$HOME/.config/hypr" ]; then
  info "Fazendo backup das configs antigas..."
  mv "$HOME/.config/hypr" "$HOME/.config/hypr.bak.$(date +%s)"
fi

# === Executar instalador ===
info "Executando script do HyDE..."
cd "$SCRIPT_DIR"
if [ -n "$USER_PKG_FILE" ] && [ -f "$USER_PKG_FILE" ]; then
  info "Usando lista personalizada de pacotes: $USER_PKG_FILE"
  ./install.sh "$USER_PKG_FILE"
else
  ./install.sh
fi

# === Pós-instalação extra ===
info "Aplicando tema Catppuccin (GTK e ícones)..."
paru -S --needed --noconfirm catppuccin-gtk-theme papirus-icon-theme

gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

info "Configuração concluída!"
echo -e "\n\e[1;34mReinicie seu computador para iniciar o HyDE com Hyprland.\e[0m"
