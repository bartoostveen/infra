#!/usr/bin/env bash

pushd "$(dirname "$0")"

echo "Generating WireGuard keypair for $1"

nix run nixpkgs#wireguard-tools genkey > $1.private.secret
nix run nixpkgs#wireguard-tools pubkey < $1.private.secret > $1.public
nix run nixpkgs#sops -- encrypt --in-place $1.private.secret

popd
