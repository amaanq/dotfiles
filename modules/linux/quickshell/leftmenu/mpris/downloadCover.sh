#!/usr/bin/env bash

artUrl="$1"
cacheDir="$2"
cacheUrl="$3"

if ! [ -f "$cacheUrl" ]; then
  mkdir -p "$cacheDir"
  curl -sSL "$artUrl" -o "$cacheUrl"
fi
