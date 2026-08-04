#!/usr/bin/env nix
#!nix shell --inputs-from . nixpkgs#wireguard-tools nixpkgs#sops --command bash

pushd "$(dirname "$0")" || exit

echo "Generating WireGuard keypair for $1"

wg genkey > "private.$1.secret"
wg pubkey < "private.$1.secret" > "$1.public"
sops -- encrypt --in-place "private.$1.secret"

popd || exit
