#!/bin/bash
#
# Module 06: Network Tools
# Installs network diagnostics, security, and monitoring tools
#

set +e  # Continue on errors

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "${SCRIPT_DIR}/lib/utils.sh"

log_info "Installing network tools..."

# Install network diagnostics
install_network_diagnostics() {
    log_step "Installing network diagnostics..."

    # Basic tools
    install_formula "telnet" "telnet"
    install_formula "netcat" "netcat"
    install_formula "socat" "socat"

    # Ping utilities
    install_formula "mtr" "mtr (better traceroute)"
    install_formula "gping" "gping (graphical ping)"

    # DNS tools
    install_formula "bind" "dig/nslookup (BIND)"
    install_formula "dog" "dog (better dig)"
    install_formula "dnstracer" "dnstracer"

    # HTTP tools
    install_formula "httpie" "HTTPie"
    install_formula "curlie" "curlie (better curl)"

    log_success "Network diagnostics completed"
}

# Install network scanners
install_network_scanners() {
    log_step "Installing network scanners..."

    # nmap
    install_formula "nmap" "nmap"

    # masscan
    install_formula "masscan" "masscan"

    # arp-scan
    install_formula "arp-scan" "arp-scan"

    log_success "Network scanners completed"
}

# Install packet analysis tools
install_packet_analysis() {
    log_step "Installing packet analysis tools..."

    # Wireshark
    install_cask "wireshark" "Wireshark"

    # tcpdump (usually pre-installed)
    install_formula "tcpdump" "tcpdump" || true

    # tshark (Wireshark CLI)
    # Installed with Wireshark

    log_success "Packet analysis tools completed"
}

# Install proxy and tunneling tools
install_proxy_tools() {
    log_step "Installing proxy and tunneling tools..."

    # ngrok
    install_cask "ngrok" "ngrok"

    # cloudflared
    install_formula "cloudflared" "Cloudflare Tunnel"

    # mitmproxy
    install_formula "mitmproxy" "mitmproxy"

    # proxychains
    install_formula "proxychains-ng" "proxychains"

    log_success "Proxy tools completed"
}

# Install SSL/TLS tools
install_ssl_tools() {
    log_step "Installing SSL/TLS tools..."

    # OpenSSL
    install_formula "openssl@3" "OpenSSL 3"

    # SSL testing
    install_formula "testssl" "testssl.sh"
    install_formula "sslyze" "sslyze"

    # Certificate tools
    install_formula "mkcert" "mkcert (local CA)"
    install_formula "cfssl" "cfssl"

    log_success "SSL tools completed"
}

# Install VPN tools
install_vpn_tools() {
    log_step "Installing VPN tools..."

    # WireGuard
    install_formula "wireguard-tools" "WireGuard"

    # OpenVPN
    install_formula "openvpn" "OpenVPN"

    log_success "VPN tools completed"
}

# Install load testing tools
install_load_testing() {
    log_step "Installing load testing tools..."

    # wrk
    install_formula "wrk" "wrk"

    # hey
    install_formula "hey" "hey"

    # vegeta
    install_formula "vegeta" "vegeta"

    # k6
    install_formula "k6" "k6"

    log_success "Load testing tools completed"
}

# Install API testing tools
install_api_tools() {
    log_step "Installing API testing tools..."

    # grpcurl
    install_formula "grpcurl" "grpcurl"

    # websocat
    install_formula "websocat" "websocat"

    log_success "API testing tools completed"
}

# Main
main() {
    install_network_diagnostics
    install_network_scanners
    install_packet_analysis
    install_proxy_tools
    install_ssl_tools
    install_vpn_tools
    install_load_testing
    install_api_tools

    log_success "Network tools completed"
}

main "$@"
