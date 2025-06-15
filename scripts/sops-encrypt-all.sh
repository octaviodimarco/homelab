#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

find . -type f -name '*.secret.yaml' | while read -r file; do
    encrypted_file="${file%.yaml}.sops.yaml"

    if [ -f "$encrypted_file" ]; then
        decrypted_temp=$(mktemp)
        sops --decrypt "$encrypted_file" > "$decrypted_temp"

        if cmp -s "$file" "$decrypted_temp"; then
            echo -e "${GREEN}No changes detected. Skipping encryption for file: $file${NC}"
        else
            echo -e "${RED}Changes detected. Re-encrypting file: $file${NC}"
            sops --encrypt "$file" > "$encrypted_file"
        fi

        rm "$decrypted_temp"
    else
        echo -e "${RED}Encrypting file: $file${NC}"
        sops --encrypt "$file" > "$encrypted_file"
    fi
done
