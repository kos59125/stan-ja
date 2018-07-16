#!/bin/bash

source `dirname $0`/env.sh
target=`get_markdown`

if [ ! -d "${CIRCLE_ARTIFACTS:-.}" ]
then
  mkdir -p "${CIRCLE_ARTIFACTS:-.}"
fi

$PANDOC_PDF \
  --toc \
  -o "${CIRCLE_ARTIFACTS:-.}/stan-reference-2.16.0-ja.pdf" \
  $target
$PANDOC_HTML \
  --toc \
  -o "${CIRCLE_ARTIFACTS:-.}/stan-reference-2.16.0-ja.html" \
  $target

