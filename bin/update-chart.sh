#!/bin/bash
# Stolen from Weaveworks Flux
# https://github.com/weaveworks/flux/blob/gh-pages/bin/update-chart.sh

set -v
set -e
set -u
set -o pipefail

gh_user=infrastructure-as-code
gh_repo=helm-charts
scratch=$(mktemp -d -t helm-chart.XXXXXXXXXX)
function cleanup {
    rm -rf "${scratch}"
}
trap cleanup EXIT

package="$1"
if [ -z "${package}" ]; then
    echo "expected package name" >&2
    exit 1
fi
dest_dir=$(dirname ${package})

git clone https://github.com/${gh_user}/${gh_repo} "${scratch}"
helm package --destination=${dest_dir} "${scratch}/${package}"
#helm repo index . --url https://${gh_user}.github.io/${gh_repo} --merge index.yaml
