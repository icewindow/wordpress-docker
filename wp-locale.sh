#!/bin/bash

set -e

WORDPRESS_ROOT_DIR="/var/www/wordpress"
LANGUAGE_DIR="$WORDPRESS_ROOT_DIR/wp-content/languages"

if [ "$WORDPRESS_LOCALES" == "" ]; then
  echo "ERROR: WORDPRESS_LOCALES is not set"
  exit 1
fi

if [[ (( "$1" != "plugin" || "$1" != "theme" ) && "$#" -ne 2) && "$1" != "core"  ]]; then
	echo "USAGE: $0 (plugin|theme) <slug> | $0 core"
	exit 1
fi

type=$1
slug=$2
slug_param=""

if [ "$type" != "core" ]; then
  slug_param="&slug=$slug"
  type="${type}s"
  LANGUAGE_DIR="$LANGUAGE_DIR/$type"
fi

echo "Downloading $1 language files..."
translation_json=`curl -s -X POST "https://api.wordpress.org/translations/${type}/1.0/" -d "wp_version=${WORDPRESS_VERSION}$slug_param"`

for lang in $WORDPRESS_LOCALES
do
  if [ "$lang" == "en_US" ]; then
    echo "Skip downloading default locale..."
    continue
  fi

  download_url=`echo $translation_json | jq -r '.translations | .[] | select(.language == "'"$lang"'") | .package' 2>/dev/null  `
  if [ "$download_url" == "" ]; then
    echo "Warning: No download link for language ${lang} found, skipping..."
    continue
  fi

  echo "Downloading $lang locale..."
  tmpfile=`mktemp`
  curl -sL $download_url > $tmpfile

  echo "Unpacking $lang locale..."
  unzip -qq -d "$LANGUAGE_DIR" $tmpfile

  rm $tmpfile
done