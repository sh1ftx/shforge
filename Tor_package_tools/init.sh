#!/bin/bash

# Script de instalação de Tor e ferramentas relacionadas
# Funciona em Debian/Ubuntu, Fedora e Arch Linux

set -e

echo "Detectando distribuição Linux..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Não foi possível detectar a distribuição."
    exit 1
fi

install_tools_debian() {
    echo "Atualizando pacotes..."
    sudo apt update
    sudo apt install -y tor torbrowser-launcher proxychains nmap privoxy
}

install_tools_fedora() {
    echo "Atualizando pacotes..."
    sudo dnf install -y tor torbrowser-launcher proxychains-ng nmap privoxy
}

install_tools_arch() {
    echo "Atualizando pacotes..."
    sudo pacman -Syu --noconfirm tor tor-browser proxychains-ng nmap privoxy
}

configure_tor() {
    echo "Configurando Tor e Privoxy..."

    # Configuração mínima do Tor
    TORRC="/etc/tor/torrc"
    if [ ! -f "$TORRC" ]; then
        sudo touch "$TORRC"
    fi
    sudo tee -a "$TORRC" > /dev/null <<EOL
SocksPort 9050
SocksListenAddress 127.0.0.1
EOL

    # Configuração mínima do Privoxy para Tor
    PRIVOXY="/etc/privoxy/config"
    if [ -f "$PRIVOXY" ]; then
        sudo tee -a "$PRIVOXY" > /dev/null <<EOL
forward-socks5 / 127.0.0.1:9050 .
EOL
    fi

    echo "Ativando e reiniciando serviços..."
    sudo systemctl enable tor privoxy
    sudo systemctl restart tor privoxy

    echo "Instalação completa!"
    echo "Para usar Tor:"
    echo "- Tor Browser: execute 'torbrowser-launcher'"
    echo "- Proxychains: adicione 'proxychains <comando>'"
    echo "- Configuração SOCKS5: 127.0.0.1:9050"
}

case "$DISTRO" in
    ubuntu|debian)
        install_tools_debian
        configure_tor
        ;;
    fedora)
        install_tools_fedora
        configure_tor
        ;;
    arch|manjaro)
        install_tools_arch
        configure_tor
        ;;
    *)
        echo "Distribuição $DISTRO não suportada automaticamente."
        exit 1
        ;;
esac
