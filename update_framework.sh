#!/bin/bash

URL="https://github.com/hakimel/reveal.js/archive/refs/tags/4.1.0.tar.gz"
VERSION="$(basename ${URL} .tar.gz)"

set -ex

# Save current work
STASHED="$(git stash)"

# Download source code
TEMP_DIR="$(mktemp -d /tmp/reveal-XXXXX)"
pushd ${TEMP_DIR}
wget ${URL}
tar xvzf $(basename ${URL})
SOURCE="${TEMP_DIR}/reveal.js-${VERSION}"
popd

# Copy source code
for d in css dist js plugin; do
	git rm -r ${d} || :
	mv ${SOURCE}/${d} ./
	git add ${d}
done

mv ${SOURCE}/demo.html ./reveal_demo.html
mv ${SOURCE}/index.html ./reveal_template.html
mv ${SOURCE}/package.json ./

# Commit update
git commit -am "Update reveal.js to v${VERSION}"

# Clean up
rm -fr ${TEMP_DIR}
if [[ "${STASHED}" != "No local changes to save" ]]; then
	git stash pop
fi
