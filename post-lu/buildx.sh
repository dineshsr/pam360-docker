#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

get_latest_version() {
  local url="https://www.manageengine.com/products/passwordmanagerpro/download-free.html"
  local version

  version="$(curl -fsSL "$url" | \
    sed -nr "s/.*The latest PMP version is (.+) \(Build ([0-9]+)\).+/\2 \1/p")"

  if [[ -z "$version" ]]
  then
    {
      echo "Failed to scrape latest version number from the PMP website"
      echo "Resorting to biggest version number on the archive server"
    } >&2
    version=$(list_available_versions | head -1)
  fi

  awk '{ print $1 }' <<< "$version"
}

list_available_versions() {
  curl https://archives2.manageengine.com/passwordmanagerpro/ | \
    sed -nr 's|.*<a href="([0-9.]+)/".*|\1|p' | \
    sort -nr
}

IMAGE=postlu/pmp

EXTRA_BUILD_ARGS=()

while true
do
  case "$1" in
    push|p|--push|-p)
      PUSH=1
      shift
      ;;
    --no-cache|-n)
      NO_CACHE=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [[ -n "$1" ]]
then
  version="$1"
else
  version="$(get_latest_version)"
  LATEST=1
fi

if [[ -z "$version" ]]
then
  echo "Failed to determine version" >&2
  exit 6
fi

EXTRA_BUILD_ARGS+=("--build-arg" "PMP_VERSION=${version}")

if [[ "$GITHUB_ACTIONS" == "true" ]] || [[ -n "$NO_CACHE" ]]
then
  EXTRA_BUILD_ARGS+=("--no-cache")
fi

if [[ -n "$PUSH" ]]
then
  EXTRA_BUILD_ARGS+=("--push")
else
  EXTRA_BUILD_ARGS+=("--load")
fi

if [[ -n "$LATEST" ]]
then
  EXTRA_BUILD_ARGS+=(-t "${IMAGE}:latest")
fi

echo "Building image for PMP version $version"

# TODO linux/386 support
docker buildx build \
  --progress plain \
  --platform "linux/amd64" \
  "${EXTRA_BUILD_ARGS[@]}" \
  -t "${IMAGE}:${version}" \
  .
