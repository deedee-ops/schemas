#!/usr/bin/env bash

set -e

git checkout gh-pages
[ -f "${KUBECONFIG}" ] || (echo "Missing kubeconfig" && exit 1)
docker run --rm -it -v "${KUBECONFIG}:/root/.kube/config" -v "$(pwd):/crds" -e PUID=1000 -e PGID=1000 ghcr.io/deedee-ops/crd-extractor
git add -A
git commit -m "$(date)"
git push origin gh-pages
git checkout master
