#!/bin/bash

main() {
    git pull
    chmod +x ./_pcdn.sh
    ./_pcdn.sh "$@"
}

main "$@"