#!/usr/bin/env bash

# @file install_wireguard.sh
# @brief install script wireguard for client and server


# @description check if the user is root then execute the command
#
# @arg $1 a bash command
# @exitcode 0 If successfull.
# @exitcode 1 On failure
exec_root() {
    local command="$*"
    if [[ ! "$#" -eq 0 ]]; then
        if [[ "$UID" -gt 0 ]]; then
            echo "sudo $command"
            sudo $command
        else
            echo "$command"
            $command
        fi
        return 0
    fi
    return 1
}

# @description install package
#
# @args $@ packages to install
# @exitcode 0 If successfull.
# @exitcode 1 On failure
install_package(){
    echo "apt install $@"
    dist_check
    if [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]; then
        for var in "$@"; do
            exec_root "apt-get -qq install -y $var" >/dev/null
        done
        return 0
    fi
    if [ "$DISTRO" == "arch" ]; then
        for var in "$@"; do
            exec_root "pacman -Syu --noconfirm $var" >/dev/null
        done
        return 0
    fi
    if [ "$DISTRO" = 'fedora' ]; then
        for var in "$@"; do
            exec_root "dnf install -y $var" >/dev/null
        done
        return 0
    fi
    if [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "redhat" ]; then
        for var in "$@"; do
            exec_root "yum install -y $var" >/dev/null
        done
        return 0
    fi
	if [ "$OSTYPE" == "Darwin" ]; then
        for var in "$@"; do
			brew install -q -y $var > /dev/null
        done
        return 0
    fi
    return 1
}

# @description install wireguard for server and client
#
# @args $1 packages to install
# @exitcode 0 If successfull.
# @exitcode 1 On failure
install_wireguard () {
    echo "install wireguard"
    sudo apt update
    sudo apt install wireguard
    umask 077
    echo "Private Key"
    wg genkey | sudo tee /etc/wireguard/private.key
    echo "Public Key"
    sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key

    if [ "$1" == "vps" ]; then
        cp /vps/wg0.conf /etc/wireguard/wg0.conf 
    fi

    if [ "$1" == "home" ]; then
        cp /home/wg0.conf /etc/wireguard/wg0.conf 
    fi

    exec_root systemctl enable wg-quick@wg0.service
    exec_root systemctl start wg-quick@wg0.service
}

# @description install caddy
#
# @args $1 packages to install
# @exitcode 0 If successfull.
# @exitcode 1 On failure
install_caddy () {
    echo "install caddy"
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update
    sudo apt install caddy
}