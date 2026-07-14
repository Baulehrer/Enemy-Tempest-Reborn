#!/usr/bin/env bash

VERSION_FILE="${ROOT}/launcher/lib/app_version.dart"
APP_VERSION="$(sed -n "s/^const appVersion = '\([^']*\)';$/\1/p" "$VERSION_FILE")"
if [ -z "$APP_VERSION" ]; then
  echo "Could not read app version from $VERSION_FILE" >&2
  exit 2
fi
VERSION="${VERSION:-v${APP_VERSION}}"
