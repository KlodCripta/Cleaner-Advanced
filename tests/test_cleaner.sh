#!/bin/bash
# Regression tests. Package-manager commands are replaced; no cache is deleted.
set -uo pipefail
SCRIPT=${1:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/cleaner_advanced.sh"}

# Load the functions without starting the interactive application.
source <(sed '/^# ── Avvio/,$d' "$SCRIPT")
language=EN
show_header() { :; }
show_separator() { :; }
pause_return() { :; }
sleep() { :; }
sudo() { printf 'sudo %s\n' "$*"; }
clean_pacman_download_dirs() { printf 'download-clean\n'; }

passed=0
failed=0
check() {
    local label=$1
    shift
    if ( "$@" ); then
        printf 'PASS %s\n' "$label"
        passed=$((passed + 1))
    else
        printf 'FAIL %s\n' "$label"
        failed=$((failed + 1))
    fi
}

multi_helper_available() { declare -F detect_aur_helpers >/dev/null; }
check 'multi-helper detection is available' multi_helper_available
if (( failed )); then
    echo 'Multi-helper support is missing; stopping before functional tests.'
    exit 1
fi

# Control only the external command lookup, not the detection logic.
detect_case() {
    local available=$1 expected=$2
    command() { [[ $1 == -v && " $available " == *" $2 "* ]]; }
    detect_aur_helpers
    [[ ${DETECTED_AUR_HELPERS[*]} == "$expected" ]]
}
check 'no installed helper' detect_case '' ''
check 'one installed helper' detect_case 'yay' 'yay'
check 'all six installed helpers' detect_case 'pakku aura paru yay trizen pikaur' 'paru yay pikaur aura trizen pakku'

select_case() {
    DETECTED_AUR_HELPERS=(paru yay pikaur aura trizen pakku)
    SELECTED_AUR_HELPERS=()
    select_aur_helpers <<< "$1" >/dev/null || return 1
    [[ ${SELECTED_AUR_HELPERS[*]} == "$2" ]]
}
check 'select one helper' select_case '2' 'yay'
check 'select all helpers' select_case '7' 'paru yay pikaur aura trizen pakku'
check 'invalid selection can be corrected' select_case $'wrong\n2' 'yay'
check 'oversized input does not wrap to a valid selection' select_case $'18446744073709551618\n3' 'pikaur'
check 'leading zero input is rejected without arithmetic errors' select_case $'08\n2' 'yay'
cancel_case() {
    DETECTED_AUR_HELPERS=(paru yay)
    SELECTED_AUR_HELPERS=()
    ! select_aur_helpers <<< 0 >/dev/null && [[ ${#SELECTED_AUR_HELPERS[@]} == 0 ]]
}
check 'zero cancels helper selection' cancel_case

# Each helper is an external boundary. Check the arguments the real dispatcher sends.
paru() { printf 'paru %s\n' "$*"; }
yay() { printf 'yay %s\n' "$*"; }
pikaur() { printf 'pikaur %s\n' "$*"; }
aura() { printf 'aura %s\n' "$*"; }
trizen() { printf 'trizen %s\n' "$*"; }
pakku() { printf 'pakku %s\n' "$*"; }
dispatch_case() { [[ $(clean_with_aur_helper "$1") == "$2" ]]; }
check 'paru command' dispatch_case paru 'paru -Sc'
check 'yay command' dispatch_case yay 'yay -Sc'
check 'pikaur command' dispatch_case pikaur 'pikaur -Sc'
check 'aura command' dispatch_case aura 'aura -Cc 1'
check 'trizen command' dispatch_case trizen 'trizen -Sc'
check 'pakku command' dispatch_case pakku 'pakku -Sc'
unknown_case() { ! clean_with_aur_helper unsupported; }
check 'unknown helper rejected' unknown_case

cleaning_case() {
    local output
    yay() { return 7; }
    output=$(run_aur_cleaning paru yay aura)
    [[ $output == *'✓ paru'* && $output == *'✗ yay'* && $output == *'✓ aura'* ]] || return 1
    [[ $(printf '%s\n' "$output" | grep -c '^download-clean$') == 1 ]]
}
check 'failure recorded and following helper still processed' cleaning_case
light_case() { [[ $(light_clean <<< Y) == *'sudo pacman -Sc'* ]]; }
deep_case() { [[ $(deep_clean <<< Y) == *'sudo pacman -Scc'* ]]; }
decline_case() { [[ $(light_clean <<< N) != *'sudo '* ]]; }
check 'light clean arguments' light_case
check 'deep clean arguments' deep_case
check 'declining does not clean' decline_case

no_helper_case() {
    command() { return 1; }
    local output
    output=$(aur_helper_clean)
    [[ $output == *'No supported AUR helper found.'* && $output != *'download-clean'* ]]
}
check 'no helper does not clean anything' no_helper_case
single_helper_case() {
    command() { [[ $2 == yay ]]; }
    local output
    output=$(aur_helper_clean <<< Y)
    [[ $output == *'Detected AUR helper:'* && $output == *'yay -Sc'* && $output != *'Clean all detected'* ]]
}
check 'single helper bypasses selection' single_helper_case
all_helpers_case() {
    command() { return 0; }
    local output
    output=$(aur_helper_clean <<< $'7\nY')
    [[ $output == *'paru -Sc'* && $output == *'yay -Sc'* && $output == *'pikaur -Sc'* && $output == *'aura -Cc 1'* && $output == *'trizen -Sc'* && $output == *'pakku -Sc'* ]]
}
check 'select all through complete AUR flow' all_helpers_case

exit_case() {
    local language_number=$1 output status
    output=$(TERM=xterm timeout 5 bash "$SCRIPT" <<< "$language_number"$'\n0' 2>&1)
    status=$?
    [[ $status == 0 && $output == *"$2"* ]]
}
check 'English then zero exits' exit_case 1 'Exiting Cleaner Advanced'
check 'Italian then zero exits' exit_case 2 'Uscita da Cleaner Advanced'
eof_case() {
    local status
    TERM=xterm timeout 2 bash "$SCRIPT" <<< "$1" >/dev/null 2>&1
    status=$?
    [[ $status == 0 ]]
}
check 'EOF at language selection exits' eof_case ''
check 'EOF at main menu exits' eof_case 2

printf '\n%d passed; %d failed\n' "$passed" "$failed"
(( failed == 0 ))
