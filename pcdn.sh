#!/bin/bash

main() {
    git pull
    ./_pcdn.sh "$@"
}

main "$@"