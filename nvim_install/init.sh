#!/usr/bin/env bash
set -euo pipefail

NVIM_CONFIG_DIR="$HOME/.config/nvim"

info() { echo -e "\e[1;32m==>\e[0m $1"; }

# === Atualiza pacotes ===
info "Atualizando sistema..."
sudo pacman -Syu --noconfirm

# === Instala pacotes básicos ===
info "Instalando Neovim e ferramentas básicas..."
sudo pacman -S --needed --noconfirm neovim git unzip curl base-devel \
  ripgrep fd tree-sitter gdb cmake make python-pynvim

# === Instala AUR helper se necessário ===
if ! command -v paru &>/dev/null; then
  info "Instalando paru..."
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru
  makepkg -si --noconfirm
  cd -
fi

# === Instala dependências para linguagens low-level ===
info "Instalando toolchains e linguagens low-level..."
sudo pacman -S --needed --noconfirm clang gcc gdb nasm openjdk17 jdk-openjdk

# === Remove config antiga (faz backup) ===
if [ -d "$NVIM_CONFIG_DIR" ]; then
  info "Fazendo backup da config antiga..."
  mv "$NVIM_CONFIG_DIR" "$NVIM_CONFIG_DIR.bak.$(date +%s)"
fi

# === Instala LazyVim ===
info "Instalando LazyVim..."
git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
rm -rf "$NVIM_CONFIG_DIR/.git"

# === Instalação de plugins adicionais ===
info "Adicionando plugins para desenvolvimento low-level..."

cat >> "$NVIM_CONFIG_DIR/lua/plugins/lowlevel.lua" <<'EOF'
return {
  -- Tema
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  -- LSP e autocompletar
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  -- Debugging
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui" },
  { "theHamsta/nvim-dap-virtual-text" },
  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  -- Git
  { "lewis6991/gitsigns.nvim" },
  -- Extra para Assembly
  { "ShinKage/idris2-nvim" }, -- Syntax extra
}
EOF

# === Ajusta tema padrão para Catppuccin ===
mkdir -p "$NVIM_CONFIG_DIR/lua/config"
cat >> "$NVIM_CONFIG_DIR/lua/config/colorscheme.lua" <<'EOF'
vim.cmd.colorscheme("catppuccin")
EOF

# === Instala linguagens no Treesitter ===
info "Adicionando linguagens ao Treesitter..."
cat >> "$NVIM_CONFIG_DIR/lua/config/treesitter.lua" <<'EOF'
require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "c", "cpp", "lua", "vim", "bash", "java"
  },
  highlight = { enable = true },
}
EOF

# === LSP Setup ===
info "Configurando LSP para C/C++, Java e Assembly..."
cat >> "$NVIM_CONFIG_DIR/lua/config/lsp.lua" <<'EOF'
local lspconfig = require("lspconfig")
lspconfig.clangd.setup {}
lspconfig.jdtls.setup {}
-- Assembly não tem LSP completo, mas pode usar syntax highlight via Treesitter
EOF

# === Instala Mason para gerenciar LSPs ===
cat >> "$NVIM_CONFIG_DIR/lua/plugins/mason.lua" <<'EOF'
return {
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup {
      ensure_installed = { "clangd", "jdtls" }
    }
  end
}
EOF

info "Instalação concluída! Abra o Neovim e rode :Lazy sync para baixar plugins."
