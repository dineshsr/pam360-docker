#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

IMAGE=postlu/pmp

EXTRA_BUILD_ARGS=()

if [[ "$GITHUB_ACTIONS" == "true" ]]
then
  EXTRA_BUILD_ARGS+=("--no-cache")
fi

docker build "${EXTRA_BUILD_ARGS[@]}" -t "$IMAGE" .

case "$1" in
  push|p|--push|-p)
    docker push "$IMAGE"
    ;;
esac
