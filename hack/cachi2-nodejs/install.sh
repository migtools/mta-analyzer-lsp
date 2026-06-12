#!/bin/bash

set -euo pipefail

cd ${REMOTE_SOURCES_DIR}

npm ci --no-audit --no-fund

GLOBAL_MODULES=/usr/local/lib/node_modules
mkdir -p ${GLOBAL_MODULES}
cp -a node_modules/typescript ${GLOBAL_MODULES}/
cp -a node_modules/typescript-language-server ${GLOBAL_MODULES}/

ln -sf ../lib/node_modules/typescript/bin/tsc /usr/local/bin/tsc
ln -sf ../lib/node_modules/typescript/bin/tsserver /usr/local/bin/tsserver
ln -sf ../lib/node_modules/typescript-language-server/lib/cli.mjs /usr/local/bin/typescript-language-server

rm -rf ${REMOTE_SOURCES_DIR}
