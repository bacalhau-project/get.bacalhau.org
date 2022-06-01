#!/usr/bin/env bash

# Bacalhau authors (c)

# Original copyright
# https://raw.githubusercontent.com/SAME-Project/SAME-installer-website/main/install_script.sh
# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation and Dapr Contributors.
# Licensed under the MIT License.
# ------------------------------------------------------------

# BACALHAU CLI location
: ${BACALHAU_INSTALL_DIR:="/usr/local/bin"}

# sudo is required to copy binary to BACALHAU_INSTALL_DIR for linux
: ${USE_SUDO:="false"}

# Http request CLI
BACALHAU_HTTP_REQUEST_CLI=curl

# GitHub Organization and repo name to download release
# GITHUB_ORG=bacalhau-project
# GITHUB_REPO=bacalhau-cli
GITHUB_ORG=filecoin-project
GITHUB_REPO=bacalhau

# BACALHAU CLI filename
BACALHAU_CLI_FILENAME=bacalhau

BACALHAU_CLI_FILE="${BACALHAU_INSTALL_DIR}/${BACALHAU_CLI_FILENAME}"

BACALHAU_PUBLIC_KEY=`echo "$(cat <<-END
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA7bXxrECk3tQfKox7MDaN
OAQ+NATnILQ9XFfYHs+4Q04lK1tHpvUEwm9OwidMJKlr+M1f/9rzLYV6RDrv0FuA
xaxGS6xrYwmLiXhDj4KwU3v5e6lHhzupsj+7LNSZ9g+ppCXcw73l5wtNmFojKQDH
vpKDzB2KKqRq7/TRenNwvMD02zuDcjGdgXSeSiyIZ6jCn9Y6pX7nPF4rOxpFSL/w
oSb5q5tVY3ZqyrNx/Bk9mBoX3a8xDqFtthuC6SjIF1t5arLih2yEpq8hOdGyyX1l
uQCYlYuIwsYZL+fj2fFzhqpmrHBB97Npw1bTjnzQ8HQIsxkrMEg9ePFfcRfWw7w6
nWBLD4JOTFOoi9SPB0BdyqvE8B+6FTlT8XbK7/VtheR4yFVHvrnVkGzIm6AnwINc
9yFlS5FbxHh0vzL5G4jTYVZrZ7YaQ/zxgZ/SHE9fcSZv4l+W2vlo1EivtOgy1Ee6
OfDFMvdHyg04qjOGxUzYDxZ4/AL+ywSm1HDXP93Oi8icKXy5OANogW4XZ5hll54g
4EBqSON/HH4eIvyWTfFG+U6DBtD0Qn4gZO9y1KUNbhDQ0Z6LOC/mKgWhPSKRdFJk
L9lmeqYFIvAnBx5rmyE7Hlzqk4pSRfggra0D2ydTV79tUQGlX5wpkwch/s4nRmZb
rZd9rvTsifOjf2jxGGu5N6ECAwEAAQ==
-----END PUBLIC KEY-----
END
)"`

getSystemInfo() {
    ARCH=$(uname -m)
    case $ARCH in
        armv7*) ARCH="arm" ;;
        aarch64) ARCH="arm64" ;;
        x86_64) ARCH="amd64" ;;
    esac

    OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')

    # Most linux distro needs root permission to copy the file to /usr/local/bin
    if [ "$OS" == "linux" ] && [ "$BACALHAU_INSTALL_DIR" == "/usr/local/bin" ]; then
        USE_SUDO="true"
    fi
}

verifySupported() {
    local supported=(linux-amd64 darwin-amd64)
    local current_osarch="${OS}-${ARCH}"

    for osarch in "${supported[@]}"; do
        if [ "$osarch" == "$current_osarch" ]; then
            echo "Your system is ${OS}_${ARCH}"
            return
        fi
    done

    echo "No prebuilt binary for ${current_osarch}"
    exit 1
}

runAsRoot() {
    local CMD="$*"

    if [ $EUID -ne 0 -a $USE_SUDO = "true" ]; then
        CMD="sudo $CMD"
    fi

    $CMD
}

checkHttpRequestCLI() {
    if type "curl" > /dev/null; then
        BACALHAU_HTTP_REQUEST_CLI=curl
    elif type "wget" > /dev/null; then
        BACALHAU_HTTP_REQUEST_CLI=wget
    else
        echo "Either curl or wget is required"
        exit 1
    fi
}

checkExistingBacalhau() {
    if [ -f "$BACALHAU_CLI_FILE" ]; then
        echo -e "\nBACALHAU CLI is detected:"
        $BACALHAU_CLI_FILE --version
        echo -e "Reinstalling BACALHAU CLI - ${BACALHAU_CLI_FILE}..."
    else
        echo -e "No BACALHAU detected. Installing fresh BACALHAU CLI..."
    fi
}

getLatestRelease() {
    local bacalhauReleaseUrl="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/releases"
    local latest_release=""

    if [ "$BACALHAU_HTTP_REQUEST_CLI" == "curl" ]; then
        latest_release=$(curl -s $bacalhauReleaseUrl | grep \"tag_name\" | grep -v rc | awk 'NR==1{print $2}' |  sed -n 's/\"\(.*\)\",/\1/p')
    else
        latest_release=$(wget -q --header="Accept: application/json" -O - $bacalhauReleaseUrl | grep \"tag_name\" | grep -v rc | awk 'NR==1{print $2}' |  sed -n 's/\"\(.*\)\",/\1/p')
    fi

    ret_val=$latest_release
}
# --- create temporary directory and cleanup when done ---
setup_tmp() {
    BACALHAU_TMP_ROOT=$(mktemp -d 2>/dev/null || mktemp -d -t 'bacalhau-install.XXXXXXXXXX')
    cleanup() {
        code=$?
        set +e
        trap - EXIT
        rm -rf ${BACALHAU_TMP_ROOT}
        exit $code
    }
    trap cleanup INT EXIT
}

downloadFile() {
    LATEST_RELEASE_TAG=$1

    BACALHAU_CLI_ARTIFACT="${BACALHAU_CLI_FILENAME}_${LATEST_RELEASE_TAG}_${OS}_${ARCH}.tar.gz"
    BACALHAU_SIG_ARTIFACT="${BACALHAU_CLI_ARTIFACT}.signature.sha256"

    DOWNLOAD_BASE="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download"

    CLI_DOWNLOAD_URL="${DOWNLOAD_BASE}/${LATEST_RELEASE_TAG}/${BACALHAU_CLI_ARTIFACT}"
    SIG_DOWNLOAD_URL="${DOWNLOAD_BASE}/${LATEST_RELEASE_TAG}/${BACALHAU_SIG_ARTIFACT}"

    CLI_TMP_FILE="$BACALHAU_TMP_ROOT/$BACALHAU_CLI_ARTIFACT"
    SIG_TMP_FILE="$BACALHAU_TMP_ROOT/$BACALHAU_SIG_ARTIFACT"

    echo "Downloading $CLI_DOWNLOAD_URL ..."
    if [ "$BACALHAU_HTTP_REQUEST_CLI" == "curl" ]; then
        curl -SsLN "$CLI_DOWNLOAD_URL" -o "$CLI_TMP_FILE"
    else
        wget -q -O "$CLI_TMP_FILE" "$CLI_DOWNLOAD_URL"
    fi

    if [ ! -f "$CLI_TMP_FILE" ]; then
        echo "failed to download $CLI_DOWNLOAD_URL ..."
        exit 1
    fi

    echo "Downloading sig file $SIG_DOWNLOAD_URL ..."
    if [ "$BACALHAU_HTTP_REQUEST_CLI" == "curl" ]; then
        curl -SsLN "$SIG_DOWNLOAD_URL" -o "$SIG_TMP_FILE"
    else
        wget -q -O "$SIG_TMP_FILE" "$SIG_DOWNLOAD_URL"
    fi

    if [ ! -f "$SIG_TMP_FILE" ]; then
        echo "failed to download $SIG_DOWNLOAD_URL ..."
        exit 1
    fi

}

verifyTarBall() {
    echo "ROOT: $BACALHAU_TMP_ROOT"
    echo "Public Key: $BACALHAU_PUBLIC_KEY"
    echo "$BACALHAU_PUBLIC_KEY" > "$BACALHAU_TMP_ROOT/BACALHAU_public_file.pem"
    openssl base64 -d -in $SIG_TMP_FILE -out $SIG_TMP_FILE.decoded
    if openssl dgst -sha256 -verify "$BACALHAU_TMP_ROOT/BACALHAU_public_file.pem" -signature $SIG_TMP_FILE.decoded $CLI_TMP_FILE ; then
        return
    else
        echo "Failed to verify signature of tarball."
        exit 1
    fi
    echo "NOT verifying tarball"
}

expandTarball() {
    echo "Extracting and verifying signature..."
    # echo "Extract tar file - $CLI_TMP_FILE to $BACALHAU_TMP_ROOT"
    tar xzf $CLI_TMP_FILE -C $BACALHAU_TMP_ROOT
}

verifyBin() {
    # openssl base64 -d -in $BACALHAU_TMP_ROOT/bacalhau.signature.sha256 -out $BACALHAU_TMP_ROOT/bacalhau.signature.sha256.decoded
    # if openssl dgst -sha256 -verify "$BACALHAU_TMP_ROOT/BACALHAU_public_file.pem" -signature $BACALHAU_TMP_ROOT/bacalhau.signature.sha256.decoded $BACALHAU_TMP_ROOT/bacalhau; then
    #     return
    # else
    #     echo "Failed to verify signature of bacalhau binary."
    #     exit 1
    # fi
    #echo "NOT verifying Bin"
}


installFile() {
    local tmp_root_bacalhau_cli="$BACALHAU_TMP_ROOT/$BACALHAU_CLI_FILENAME"

    if [ ! -f "$tmp_root_bacalhau_cli" ]; then
        echo "Failed to unpack BACALHAU CLI executable."
        exit 1
    fi

    chmod o+x $tmp_root_bacalhau_cli
    runAsRoot cp "$tmp_root_bacalhau_cli" "$BACALHAU_INSTALL_DIR"

    if [ -f "$BACALHAU_CLI_FILE" ]; then
        echo "$BACALHAU_CLI_FILENAME installed into $BACALHAU_INSTALL_DIR successfully."

        $BACALHAU_CLI_FILE --version
    else
        echo "Failed to install $BACALHAU_CLI_FILENAME"
        exit 1
    fi
}

fail_trap() {
    result=$?
    if [ "$result" != "0" ]; then
        echo "Failed to install BACALHAU CLI"
        echo "For support, go to https://github.com/${GITHUB_ORG}/${GITHUB_REPO}"
    fi
    cleanup
    exit $result
}

cleanup() {
    if [[ -d "${BACALHAU_TMP_ROOT:-}" ]]; then
        rm -rf "$BACALHAU_TMP_ROOT"
    fi
}

installCompleted() {
    echo -e "\nTo get started with BACALHAU, please visit https://github.com/${GITHUB_ORG}/${GITHUB_REPO}"
}

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
trap "fail_trap" EXIT

getSystemInfo
verifySupported
checkExistingBacalhau
checkHttpRequestCLI

if [ -z "$1" ]; then
    echo "Getting the latest BACALHAU CLI..."
    getLatestRelease
else
    ret_val=v$1
fi

echo "Installing $ret_val BACALHAU CLI..."

setup_tmp
downloadFile $ret_val
verifyTarBall
expandTarball
verifyBin
installFile
cleanup

installCompleted
