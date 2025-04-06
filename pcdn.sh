#!/bin/bash

main() {
    git config core.filemode false
    git pull
    chmod +x ./_pcdn.sh
    ./_pcdn.sh "$@"
}

main "$@"