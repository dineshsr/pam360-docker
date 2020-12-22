#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

source .envrc

# http://www.btellez.com/posts/triggering-github-actions-with-webhooks.html

REPO=post-luxembourg/docker-pmp

curl \
  -X POST \
  -H 'Accept: application/vnd.github.everest-preview+json' \
  -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  "https://api.github.com/repos/${REPO}/dispatches" \
  --data '{"event_type": "manual_build"}'
