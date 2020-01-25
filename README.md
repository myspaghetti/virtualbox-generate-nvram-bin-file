# virtualbox-generate-nvram-bin-file
  

## Usage
```
        # import generate_nvram_bin_file function to shell
        . '"${0}"'

        # execute function
        generate_nvram_bin_file "${name}" "${data}" "${guid}"

        # nvramgen is a short alias for generate_nvram_bin_file
        nvramgen "${name}" "${data}" "${guid}"
```

## Dependencies
`bash` >= 4.3, `coreutils`, `xxd`, `gzip`

## Examples
```
generate_nvram_bin_file "system-id" "hAA" "7C436110-AB2A-4BBB-A880-FE41995C9F82"
nvramgen "lang" "$(printf 'en:us' | xxd -p)" "aabbccddeeff00112233445566778899"
```

## Loading the generated binary files into the virtual machine NVRAM
Load the generated binary files into VirtualBox VM NVRAM with the builtin command `dmpstore` in the VM EFI Internal Shell, for example `dmpstore -all -l fs0:\system-id.bin`



DmpStore source code is available at the VirtualBox code repository, [mirrored here](https://github.com/mdaniel/virtualbox-org-svn-vbox-trunk/blob/master/src/VBox/Devices/EFI/Firmware/ShellPkg/Library/UefiShellDebug1CommandsLib/DmpStore.c).



