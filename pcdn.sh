#!/bin/bash

main() {
    git reset --hard origin/main >/dev/null 2>&1
    git pull origin main >/dev/null 2>&1
    chmod +x ./_pcdn.sh
    ./_pcdn.sh "$@"
}

main "$@"