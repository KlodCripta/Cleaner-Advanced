#!/bin/bash

# ── Cleaner Advanced v3.0 ─────────────────────────────────────────────────────
# Cache & Package Cleaner for Arch Linux
# Supporto multi-helper AUR: paru, yay, pikaur, aura, trizen, pakku
# Autore: KlodCripta

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
LBLUE='\033[1;34m'
LCYAN='\033[1;36m'
NC='\033[0m'

SUPPORTED_AUR_HELPERS=("paru" "yay" "pikaur" "aura" "trizen" "pakku")
DETECTED_AUR_HELPERS=()
SELECTED_AUR_HELPERS=()

# Intestazione
show_header() {
    clear
    echo -e "${WHITE}"
    echo -e "   ██████╗██╗     ███████╗ █████╗ ███╗   ██╗███████╗██████╗ "
    echo -e "  ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██╔════╝██╔══██╗"
    echo -e "  ██║     ██║     █████╗  ███████║██╔██╗ ██║█████╗  ██████╔╝"
    echo -e "  ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██╔══╝  ██╔══██╗"
    echo -e "  ╚██████╗███████╗███████╗██║  ██║██║ ╚████║███████╗██║  ██║"
    echo -e "   ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝${NC}"
    echo -e "${LBLUE}  ╔═╗╔╦╗╦  ╦╔═╗╔╗╔╔═╗╔═╗╔╦╗${NC}"
    echo -e "${LBLUE}  ╠═╣ ║║╚╗╔╝╠═╣║║║║  ║╣  ║║${NC}"
    echo -e "${LBLUE}  ╩ ╩═╩╝ ╚╝ ╩ ╩╝╚╝╚═╝╚═╝═╩╝${NC}"
    echo
    echo -e "${LCYAN}  ┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${LCYAN}  │  ${WHITE}Cache & Package Cleaner for Arch Linux  ${LCYAN}│ ${WHITE}v3.0 | KlodCripta${LCYAN}  │${NC}"
    echo -e "${LCYAN}  └──────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Conferma azione (evita duplicazione logica)
confirm_action() {
    local answer
    read -r answer || return 1
    [[ $answer == "Y" || $answer == "y" || $answer == "S" || $answer == "s" ]]
}

# Pausa coerente (UX)
pause_return() {
    if [[ $language == "EN" ]]; then
        read -r -p "Press any key to return to the main menu..." -n1 -s
    else
        read -r -p "Premi un tasto per tornare al menu principale..." -n1 -s
    fi
    echo
}

# Separatore grafico
show_separator() {
    echo -e "${LCYAN}  ──────────────────────────────────────────────────────────────${NC}"
}

# Rimuove le directory temporanee download-* dalla cache di pacman.
clean_pacman_download_dirs() {
    if [[ -d /var/cache/pacman/pkg ]]; then
        sudo find /var/cache/pacman/pkg \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -name 'download-*' \
            -exec rm -rf -- {} +
    fi
}

# Rileva tutti gli helper supportati, nell'ordine dell'array.
detect_aur_helpers() {
    local candidate
    DETECTED_AUR_HELPERS=()

    for candidate in "${SUPPORTED_AUR_HELPERS[@]}"; do
        if command -v "$candidate" &> /dev/null; then
            DETECTED_AUR_HELPERS+=("$candidate")
        fi
    done
}

# Ogni helper mantiene il proprio comando e le proprie conferme.
clean_with_aur_helper() {
    local helper="$1"
    case "$helper" in
        paru) paru -Sc ;;
        yay) yay -Sc ;;
        pikaur) pikaur -Sc ;;
        aura)
            # Aura 4: conserva una versione per pacchetto.
            aura -Cc 1
            ;;
        trizen) trizen -Sc ;;
        pakku) pakku -Sc ;;
        *) return 1 ;;
    esac
}

show_aur_summary() {
    local -n success_ref=$1
    local -n failed_ref=$2
    local helper

    echo
    show_separator
    if [[ $language == "EN" ]]; then
        echo -e "${WHITE}  AUR helper cleaning summary:${NC}"
    else
        echo -e "${WHITE}  Riepilogo pulizia AUR helper:${NC}"
    fi
    echo

    for helper in "${success_ref[@]}"; do
        echo -e "${GREEN}  ✓ ${helper}${NC}"
    done
    for helper in "${failed_ref[@]}"; do
        echo -e "${RED}  ✗ ${helper}${NC}"
    done
    echo

    if (( ${#failed_ref[@]} == 0 )); then
        if [[ $language == "EN" ]]; then
            echo -e "${GREEN}  All selected helper commands finished without errors.${NC}"
        else
            echo -e "${GREEN}  Tutti i comandi degli helper selezionati sono terminati senza errori.${NC}"
        fi
    else
        if [[ $language == "EN" ]]; then
            echo -e "${RED}  One or more AUR helpers returned an error.${NC}"
        else
            echo -e "${RED}  Uno o più AUR helper hanno restituito un errore.${NC}"
        fi
    fi
    show_separator
}

run_aur_cleaning() {
    local -a helpers_to_clean=("$@")
    local -a successful_helpers=()
    local -a failed_helpers=()
    local helper

    clean_pacman_download_dirs
    for helper in "${helpers_to_clean[@]}"; do
        echo
        show_separator
        if [[ $language == "EN" ]]; then
            echo -e "${CYAN}  Cleaning: ${WHITE}${helper}${NC}"
        else
            echo -e "${CYAN}  Pulizia: ${WHITE}${helper}${NC}"
        fi
        show_separator
        echo

        if clean_with_aur_helper "$helper"; then
            successful_helpers+=("$helper")
        else
            failed_helpers+=("$helper")
        fi
    done
    show_aur_summary successful_helpers failed_helpers
}

# Mostra un menu soltanto quando sono presenti più helper.
select_aur_helpers() {
    local helper_count=${#DETECTED_AUR_HELPERS[@]}
    local all_choice=$((helper_count + 1))
    local choice i

    while true; do
        show_header
        if [[ $language == "EN" ]]; then
            echo -e "${GREEN}Detected AUR helpers:${NC}"
        else
            echo -e "${GREEN}AUR helper rilevati:${NC}"
        fi
        echo

        for i in "${!DETECTED_AUR_HELPERS[@]}"; do
            echo -e "${CYAN}  [$((i + 1))] ${DETECTED_AUR_HELPERS[$i]}${NC}"
        done
        echo

        if [[ $language == "EN" ]]; then
            echo -e "${WHITE}  [${all_choice}] Clean all detected helpers${NC}"
            echo -e "${CYAN}  [0] Cancel${NC}"
            echo
            echo -e "${CYAN}  Choice: ${NC}"
        else
            echo -e "${WHITE}  [${all_choice}] Pulisci tutti gli helper rilevati${NC}"
            echo -e "${CYAN}  [0] Annulla${NC}"
            echo
            echo -e "${CYAN}  Scelta: ${NC}"
        fi
        read -r choice || return 1

        if [[ $choice == "0" ]]; then
            return 1
        fi
        # Confronta le voci come testo: niente overflow o numeri ottali.
        for i in "${!DETECTED_AUR_HELPERS[@]}"; do
            if [[ $choice == "$((i + 1))" ]]; then
                SELECTED_AUR_HELPERS=("${DETECTED_AUR_HELPERS[$i]}")
                return 0
            fi
        done
        if [[ $choice == "$all_choice" ]]; then
            SELECTED_AUR_HELPERS=("${DETECTED_AUR_HELPERS[@]}")
            return 0
        fi

        if [[ $language == "EN" ]]; then
            echo -e "${RED}Invalid choice!${NC}"
        else
            echo -e "${RED}Scelta non valida!${NC}"
        fi
        sleep 1
    done
}

aur_helper_clean() {
    local helper_count helper_list
    SELECTED_AUR_HELPERS=()
    detect_aur_helpers
    helper_count=${#DETECTED_AUR_HELPERS[@]}
    show_header

    if (( helper_count == 0 )); then
        if [[ $language == "EN" ]]; then
            echo -e "${RED}No supported AUR helper found.${NC}"
            echo -e "${BLUE}Supported helpers: paru, yay, pikaur, aura, trizen, pakku.${NC}"
        else
            echo -e "${RED}Nessun AUR helper supportato trovato.${NC}"
            echo -e "${BLUE}Helper supportati: paru, yay, pikaur, aura, trizen, pakku.${NC}"
        fi
        pause_return
        return
    fi

    if (( helper_count == 1 )); then
        if [[ $language == "EN" ]]; then
            echo -e "${GREEN}Detected AUR helper: ${WHITE}${DETECTED_AUR_HELPERS[0]}${NC}"
            echo -e "${BLUE}The helper cache will be cleaned using its native cleaning command.${NC}"
            echo -e "${CYAN}Proceed? (Y/N)${NC}"
        else
            echo -e "${GREEN}AUR helper rilevato: ${WHITE}${DETECTED_AUR_HELPERS[0]}${NC}"
            echo -e "${BLUE}La cache verrà pulita usando il comando nativo dell'helper.${NC}"
            echo -e "${CYAN}Procedere? (S/N)${NC}"
        fi

        if confirm_action; then
            run_aur_cleaning "${DETECTED_AUR_HELPERS[0]}"
        fi
        pause_return
        return
    fi

    if select_aur_helpers; then
        printf -v helper_list '%s, ' "${SELECTED_AUR_HELPERS[@]}"
        helper_list=${helper_list%, }
        show_header

        if [[ $language == "EN" ]]; then
            echo -e "${GREEN}Selected AUR helper(s): ${WHITE}${helper_list}${NC}"
            echo -e "${BLUE}Each helper will use its own native cache-cleaning command.${NC}"
            if (( ${#SELECTED_AUR_HELPERS[@]} > 1 )); then
                echo -e "${BLUE}Some helpers also invoke pacman's cache cleaning, so pacman prompts may appear more than once.${NC}"
            fi
            echo -e "${CYAN}Proceed? (Y/N)${NC}"
        else
            echo -e "${GREEN}AUR helper selezionati: ${WHITE}${helper_list}${NC}"
            echo -e "${BLUE}Ogni helper userà il proprio comando nativo di pulizia della cache.${NC}"
            if (( ${#SELECTED_AUR_HELPERS[@]} > 1 )); then
                echo -e "${BLUE}Alcuni helper richiamano anche la pulizia della cache di pacman, quindi le relative conferme possono comparire più volte.${NC}"
            fi
            echo -e "${CYAN}Procedere? (S/N)${NC}"
        fi

        if confirm_action; then
            run_aur_cleaning "${SELECTED_AUR_HELPERS[@]}"
        fi
    fi
    pause_return
}

# Funzione per la pulizia leggera
light_clean() {
    show_header
    if [[ $language == "EN" ]]; then
        echo -e "${GREEN}Light Clean selected${NC}"
        echo -e "${CYAN}This command removes old packages from pacman's cache while keeping the currently installed ones.${NC}"
        echo -e "${CYAN}Proceed? (Y/N)${NC}"
    else
        echo -e "${GREEN}Pulizia Leggera selezionata${NC}"
        echo -e "${CYAN}Questo comando rimuove i vecchi pacchetti dalla cache di pacman mantenendo quelli attualmente installati.${NC}"
        echo -e "${CYAN}Procedere? (S/N)${NC}"
    fi

    if confirm_action; then
        clean_pacman_download_dirs
        sudo pacman -Sc
    fi
    pause_return
}

# Funzione per la pulizia profonda
deep_clean() {
    show_header
    if [[ $language == "EN" ]]; then
        echo -e "${GREEN}Deep Clean selected${NC}"
        echo -e "${CYAN}This command removes ALL pacman cache (aggressive).${NC}"
        echo -e "${CYAN}Proceed? (Y/N)${NC}"
    else
        echo -e "${GREEN}Pulizia Profonda selezionata${NC}"
        echo -e "${CYAN}Questo comando rimuove TUTTA la cache di pacman (operazione aggressiva).${NC}"
        echo -e "${CYAN}Procedere? (S/N)${NC}"
    fi

    if confirm_action; then
        clean_pacman_download_dirs
        sudo pacman -Scc
    fi
    pause_return
}

# Menu principale
main_menu() {
    show_header
    if [[ $language == "EN" ]]; then
        echo -e "${LCYAN}  ┌─────────────────────────────┐${NC}"
        echo -e "${LCYAN}  │      ${WHITE}MAIN MENU${LCYAN}               │${NC}"
        echo -e "${LCYAN}  ├─────────────────────────────┤${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[1]${NC} Light Clean              ${LCYAN}│${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[2]${NC} Deep Clean               ${LCYAN}│${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[3]${NC} Clean AUR Helper         ${LCYAN}│${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[0]${NC} Exit                     ${LCYAN}│${NC}"
        echo -e "${LCYAN}  └─────────────────────────────┘${NC}"
        echo -e "${CYAN}  Choice: ${NC}"
    else
        echo -e "${LCYAN}  ┌─────────────────────────────┐${NC}"
        echo -e "${LCYAN}  │      ${WHITE}MENU PRINCIPALE${LCYAN}         │${NC}"
        echo -e "${LCYAN}  ├─────────────────────────────┤${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[1]${NC} Pulizia Leggera          ${LCYAN}│${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[2]${NC} Pulizia Profonda         ${LCYAN}│${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[3]${NC} Pulizia AUR Helper       ${LCYAN}│${NC}"
        echo -e "${LCYAN}  │  ${WHITE}[0]${NC} Esci                     ${LCYAN}│${NC}"
        echo -e "${LCYAN}  └─────────────────────────────┘${NC}"
        echo -e "${CYAN}  Scelta: ${NC}"
    fi

    read -r clean_choice || exit 0

    case "$clean_choice" in
        1) light_clean ;;
        2) deep_clean ;;
        3) aur_helper_clean ;;
        0)
            echo
            if [[ $language == "EN" ]]; then
                echo -e "${GREEN}Exiting Cleaner Advanced...${NC}"
            else
                echo -e "${GREEN}Uscita da Cleaner Advanced...${NC}"
            fi
            sleep 1
            exit 0
            ;;
        *)
            if [[ $language == "EN" ]]; then
                echo -e "${RED}Invalid choice!${NC}"
            else
                echo -e "${RED}Scelta non valida!${NC}"
            fi
            pause_return
            ;;
    esac
}

# ── Avvio ──────────────────────────────────────────────────────────────────────
show_header
echo -e "${WHITE}  Scegli la tua lingua / Choose your language:${NC}"
echo -e "${CYAN}  [1] English${NC}"
echo -e "${CYAN}  [2] Italiano${NC}"
echo
read -r language_choice || exit 0

if [[ $language_choice == "1" ]]; then
    language="EN"
elif [[ $language_choice == "2" ]]; then
    language="IT"
else
    echo -e "${RED}  Invalid choice, defaulting to English.${NC}"
    language="EN"
fi

while true; do
    main_menu
done
