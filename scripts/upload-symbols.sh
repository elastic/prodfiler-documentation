#!/usr/bin/env bash

set -eu

export SHELLOPTS

die() {
    echo -e "$1" >&2
    exit 1
}

usage() {
    local usage="usage: upload-symbols -u user_email -d path/to/deployed/file [-g path/to/debug-file] [-e endpoint] [-p] [-h]
    -p: for Go binaries with a .gopclntab section, ignore missing DWARF symbols.
        WARNING: Use this as a last resort, as cgo frames may not be symbolized as a result. Always provide full DWARF symbols when possible."
    die "$usage"
}

check_requirement() {
    local command="$1"
    type -P "$command" >/dev/null || die "This script requires the command '$command'"
}

check_requirement curl
check_requirement readelf
check_requirement tar
check_requirement gzip
check_requirement objcopy
check_requirement date
check_requirement openssl
check_requirement stat

PRODFILER_UPLOAD_ENDPOINT="https://try.prodfiler.com/api/v1/symbols/upload"
GO_IGNORE_MISSING_DWARF=0

# This script only supports a single file at a time, with an optional debug file.
# Alternative debug files (.gnu_debugaltlink) are not supported by this script.
while getopts "hu:e:d:g:p" OPTION; do
    case $OPTION in
    u)
        USERNAME="$OPTARG"
        ;;
    d)
        DEPLOYED_FILE=$(readlink -f "$OPTARG")
        ;;
    g)
        DEBUG_FILE=$(readlink -f "$OPTARG")
        ;;
    e)
        PRODFILER_UPLOAD_ENDPOINT="$OPTARG"
        ;;
    p)
        GO_IGNORE_MISSING_DWARF=1
        ;;
    h)
        usage
        ;;
    *)
        echo "Unrecognized option: '$OPTION'" >&2
        usage
        ;;
    esac
done

SCRATCH_DIR=$(mktemp -d)

has_debug_symbols() {
    unset retval
    local file="$1"
    # Check that the binary contains DWARF information, by checking for the presence of a DWARF tag.
    tag=$(readelf --debug-dump=info "$file" | grep DW_TAG | head -1)
    if [[ -n "$tag" ]]; then
        return 0
    fi
    if [[ $GO_IGNORE_MISSING_DWARF == 1 ]] && is_go_executable "$file"; then
        echo "Warning: Go symbols found, but no DWARF symbols. Symbolization may be incomplete."
        echo "For a better experience, always provide DWARF symbols if possible."
        return 0
    fi
    return 1
}

has_section() {
    local file="$1"
    local section_list="$2"
    readelf --section-headers "$file" | grep -qF "$section_list"
}

is_go_executable() {
    local section_list file="$1"
    printf -v section_list ".go.buildinfo\n.gopclntab"
    has_section "$file" "$section_list"
}

extract_debug_symbols() {
    unset retval
    local filepath="$1"
    local resultBasename="$2"
    local debugFile
    debugFile="${SCRATCH_DIR}/${resultBasename}"
    echo "Extracting debug symbols from '$filepath' to $debugFile ..."

    objcopy --only-keep-debug "$filepath" "$debugFile"

    retval="$debugFile"
}

partial_hash() {
    unset retval
    local file="$1"
    [[ -f "$file" ]] || die "$file is not a regular file"

    # `file` must not point to a symlink here.
    local filesize
    filesize=$(stat --printf="%s" "$file")

    retval=$(cat \
        <(head -c 4096 "$file") \
        <(tail -c 4096 "$file") \
        <(printf $(printf "%.16x" $filesize | sed 's/\(..\)/\\x\1/g')) \
        | openssl sha256 | awk '{print $NF}')
}

copy_additional_sections() {
    unset retval
    local src="$1"
    local dst="$2"
    local sections=(".eh_frame" ".eh_frame_hdr")
    local section_file section
    local objcopy_args=()

    if has_section "$src" ".gopclntab"; then
        # Golang
        sections+=(".go.buildinfo" ".gopclntab" ".gosymtab")
    elif has_section "$src" ".go.buildinfo"; then
        # Golang/PIE, also symbol tables are needed which should be already
        # copied by extract_debug_symbols()
        sections+=(".go.buildinfo" ".data.rel.ro")
    fi

    # Extract each section from the source, and copy them to the destination.
    # We have to set the "contents" flag for each section, as NOBITS has previously
    # been set by objcopy --only-keep-debug
    for section in "${sections[@]}"; do
        section_file=$(mktemp)
        files+=("$section_file")
        objcopy -O binary --only-section="$section" "$src" "$section_file"

        # If the file is empty, the section probably doesn't exist - skip.
        [[ $(stat --printf="%s" "$section_file") != 0 ]] || continue
        objcopy_args+=("--set-section-flags" "$section=contents" "--update-section" "$section=$section_file")
    done

    objcopy "${objcopy_args[@]}" "$dst"

    rm -f "${files[@]}"
}

build_debug_file() {
    unset retval
    local resultBasename

    resultBasename=$(basename "$DEPLOYED_FILE").debug
    echo $resultBasename

    if [[ -v DEBUG_FILE ]]; then
        if ! has_debug_symbols "$DEBUG_FILE"; then
            die "$DEBUG_FILE has no debug symbols."
        fi
        # Avoid accidental errors leading to uploading code or data segments.
        # Ensure we extract debug symbols only.
        extract_debug_symbols "$DEBUG_FILE" "$resultBasename"
    else
        if ! has_debug_symbols "$DEPLOYED_FILE"; then
            die "$DEPLOYED_FILE has no debug symbols, and no separate debug symbols were provided."
        fi
        extract_debug_symbols "$DEPLOYED_FILE" "$resultBasename"
    fi
}

[[ -v USERNAME ]] || usage
[[ -v DEPLOYED_FILE ]] || usage
readelf --headers "$DEPLOYED_FILE" >/dev/null 2>&1 || die "$DEPLOYED_FILE is not an ELF file"

build_debug_file
DEBUG_FILE="$retval"

if has_section "$DEBUG_FILE" ".gnu_debugaltlink"; then
    die "Alternative debug links are not yet supported"
fi

# Copy additional sections from the deployed file.
copy_additional_sections "$DEPLOYED_FILE" "$DEBUG_FILE"

DEBUG_FILE_BASENAME=$(basename "$DEBUG_FILE")

partial_hash "$DEPLOYED_FILE"
DEPLOYED_FILE_HASH="$retval"
DEPLOYED_FILE_BASENAME=$(basename "$DEPLOYED_FILE")

CONFIG_FILE="${SCRATCH_DIR}/config.json"
TIMESTAMP=$(date +%s)

cat << EOF > "$CONFIG_FILE"
{
    "symbolsPackagingVersion": 2,
    "creationTime": $TIMESTAMP,
    "debugFileAssociations": [
        {
            "deployedFileHash": "$DEPLOYED_FILE_HASH",
            "deployedFileName": "$DEPLOYED_FILE_BASENAME",
            "debugFilePath": "$DEBUG_FILE_BASENAME"
        }
    ]
}
EOF


PACKAGE="${SCRATCH_DIR}/${DEPLOYED_FILE_BASENAME}.symtgz"
tar czf "$PACKAGE" -C "$SCRATCH_DIR" config.json "$DEBUG_FILE_BASENAME"

PACKAGE_BASENAME=$(basename "$PACKAGE")

echo "Uploading $PACKAGE_BASENAME to $PRODFILER_UPLOAD_ENDPOINT..."
MD5=$(openssl md5 -binary "$PACKAGE" | openssl base64)

# -L is necessary to follow the redirect returned by the service.
curl -vfL \
    -X PUT \
    -T "$PACKAGE" \
    -H "User: $USERNAME" \
    -H "Content-MD5: $MD5" \
    -H "x-amz-meta-file-hash: $DEPLOYED_FILE_HASH" \
    "${PRODFILER_UPLOAD_ENDPOINT}/${PACKAGE_BASENAME}"

