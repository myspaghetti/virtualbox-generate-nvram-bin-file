#!/bin/bash
# Create binary files that hold NVRAM guid and variable.
# File can be loaded into VirtualBox VM NVRAM through the EFI Internal Shell
# (c) myspaghetti, licensed under GPL2.0 or higher
# url: https://github.com/myspaghetti/virtualbox-generate-nvram-bin-file
# version 0.1

[[ -z "${1}" && "$-" =~ i ]] && printf '
USAGE:
        # import generate_nvram_bin_file function to shell
        . '"${0}"'

        # execute function
        generate_nvram_bin_file "${name}" "${data}" "${guid}"

        # nvramgen is a short alias for generate_nvram_bin_file
        nvramgen "${name}" "${data}" "${guid}"

DEPENDENCIES:
        bash >= 4.3, coreutils, xxd, gzip

EXAMPLES:
generate_nvram_bin_file "system-id" "hAA" "7C436110-AB2A-4BBB-A880-FE41995C9F82"
nvramgen "lang" "$(printf 'en:us' | xxd -p)" "aabbccddeeff00112233445566778899"

'

# input: name data guid (three positional arguments, all required)
# output: function outputs nothing to stdout
#         but writes a binary file named name.bin
function generate_nvram_bin_file() {
    local namestring="${1}" # string of chars
    local filename="${namestring}"
    # represent string as string-of-hex-bytes, add null byte after every byte,
    # terminate string with two null bytes
    local name="$(for (( i=0; i<"${#namestring}"; i++ )); do printf -- "${namestring:${i}:1}" | xxd -p | tr -d '\n'; printf '00'; done; printf '0000' )"
    # size of string in bytes, represented by eight hex digits, big-endian
    local namesize="$(printf "%08x" $(( ${#name} / 2 )) )" 
    # flip four big-endian bytes byte-order to little-endian
    local namesize="$(printf "${namesize}" | xxd -r -p | od -tx4 -N4 -An --endian=little)"
    # strip string-of-hex-bytes representation of data of spaces, "x", "h", etc
    local data="$(printf -- "${2}" | xxd -r -p | xxd -p )"
    # size of data in bytes, represented by eight hex digits, big-endian
    local datasize="$(printf "%08x" $(( ${#data} / 2 )) )" 
    # flip four big-endian bytes byte-order to little-endian
    local datasize="$(printf "${datasize}" | xxd -r -p | od -tx4 -N4 -An --endian=little)"
    # guid string-of-hex-bytes is five fields, 8+4+4+4+12 nibbles long
    # first three are little-endian, last two big-endian
    # for example, 00112233-4455-6677-8899-AABBCCDDEEFF
    # is stored as 33221100-5544-7766-8899-AABBCCDDEEFF
    local g="$( printf -- "${3}" | xxd -r -p | xxd -p )" # strip spaces etc
    local guid="${g:6:2} ${g:4:2} ${g:2:2} ${g:0:2} ${g:10:2} ${g:8:2} ${g:14:2} ${g:12:2} ${g:16:16}"
    # attributes in four bytes little-endian
    local attributes="07 00 00 00"
    # the data structure
    local entry="${namesize} ${datasize} ${name} ${guid} ${attributes} ${data}"
    # calculate crc32 using gzip, flip crc32 bytes into big-endian
    local crc32="$(printf "${entry}" | xxd -r -p | gzip -c | tail -c8 | od -tx4 -N4 -An --endian=big)"
    # save binary data
    printf -- "${entry} ${crc32}" | xxd -r -p - "${filename}.bin"
}

function nvramgen() {
    generate_nvram_bin_file "$@"
}

# Each NVRAM file may contain multiple entries.
# Each entry contains a namesize, datasize, name, guid, attributes, and data.
# Each entry is immediately followed by a crc32 of the entry.
# The script creates each file with only one entry for easier editing.
#
# The hex strings are stripped by xxd, so they can
# look like "0xAB 0xCD" or "hAB hCD" or "AB CD" or "ABCD" or a mix of formats
# and have extraneous characters like spaces or minus signs.

# Load the binary files into VirtualBox VM NVRAM with the
# builtin command dmpstore in the VM EFI Internal Shell, for example:
# dmpstore -all -l fs0:\system-id.bin
#
# DmpStore code is available at this URL:
# https://github.com/mdaniel/virtualbox-org-svn-vbox-trunk/blob/master/src/VBox/Devices/EFI/Firmware/ShellPkg/Library/UefiShellDebug1CommandsLib/DmpStore.c
