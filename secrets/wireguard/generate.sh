#!/usr/bin/env bash

pushd "$(dirname "$0")" || exit

echo "Generating WireGuard keypair for $1"

nix run nixpkgs#wireguard-tools genkey > "private.$1.secret"
nix run nixpkgs#wireguard-tools pubkey < "private.$1.secret" > "$1.public"
nix run nixpkgs#sops -- encrypt --in-place "private.$1.secret"

popd || exit
