#!/usr/bin/env bash

echo "Generating current Plasma config..."
old=$(mktemp)
nix run --inputs-from . plasma-manager > "$old"

echo "Done, make your changes now."
echo "Press [ENTER] once change has been made"
read -s -r

echo "Diffing..."
new=$(mktemp)
nix run --inputs-from . plasma-manager > "$new"

git diff "$old" "$new"
rm "$old" "$new"
