#!/usr/bin/env bash
# 
# PREREQUISITES
#
# curl, wget, jq
#
# If your version/tag doesn't match, the script will exit with error.

set -e
set -o pipefail

TOKEN="$TOKEN"              # the token to acesses GITHUB API
REPO="$REPO"                # the name of your <org/repo>
VERSION=$VERSION            # tag name or the word "latest"
FILE="$FILE"                # the name of your release asset file, e.g. artificat-x.x.x.tar.gz
OUTPUT=$OUTPUT              # the output path

usage() { echo "Usage: $0 -t <github token> -r <repo> -v <version> -f <file> -o <output path> -q" 1>&2; exit 1; }

while getopts "qt:v:r:f:o:" o; do
    case "${o}" in
        t) 
            TOKEN=${OPTARG}
            ;;
        v) 
            VERSION=${OPTARG}
            ;;
        r) 
            REPO=${OPTARG}
            ;;
        f) 
            FILE=${OPTARG}
            ;;
        o)
            OUTPUT=${OPTARG}
            ;;
        q)
            QUIET=1
            ;;
        *) 
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# if [ -z "$OUTPUT" ]; then
#    OUTPUT=$FILE
# fi

if [ -z "$TOKEN" ] || [ -z "$VERSION" ] || [ -z "$REPO" ] || [ -z "$FILE" ] || [ -z "$OUTPUT" ]; then
    usage
fi

GITHUB_API="api.github.com"

# alias errcho='>&2 echo'

maybe_echo() {
    if [ -z "$QUIET" ]; then
        echo "$@"
    fi
}

echo_error() {
    >&2 maybe_echo "ERROR: $@"
}

echo_info() {
    maybe_echo "INFO: $@"
}

echo_success() {
    maybe_echo SUCCESS: $@
}

if [ "$VERSION" = "latest" ]; then
  # Github should return the latest release first.
  PARSER=".[0].assets | map(select(.name == \"$FILE\"))[0].id"
else
  PARSER=". | map(select(.tag_name == \"$VERSION\"))[0].assets | map(select(.name == \"$FILE\"))[0].id"
fi


ASSET_ID=`curl -sL -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3.raw" https://$GITHUB_API/repos/$REPO/releases | jq "$PARSER"`

if [ "$ASSET_ID" = "null" ]; then
    # errcho "ERROR: version not found $VERSION"
    echo_error "version '$VERSION' not found"
    exit 1
else
    echo_info "Found version '$VERSION'"
fi

curl -sL \
  --header "Authorization: token $TOKEN" \
  --header 'Accept: application/octet-stream' \
  https://$TOKEN:@$GITHUB_API/repos/$REPO/releases/assets/$ASSET_ID > $OUTPUT/$FILE

  echo_success "Asset '$OUTPUT'/'$FILE' saved successfully."  