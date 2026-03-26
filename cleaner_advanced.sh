#!/bin/bash

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
LBLUE='\033[1;34m'
LCYAN='\033[1;36m'
NC='\033[0m'

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
    echo -e "${LCYAN}  │  ${WHITE}Cache & Package Cleaner for Arch Linux  ${LCYAN}│ ${WHITE}v2.1 | KlodCripta${LCYAN}  │${NC}"
    echo -e "${LCYAN}  └──────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Conferma azione (evita duplicazione logica)
confirm_action() {
    local answer
    read -r answer
    [[ $answer == "Y" || $answer == "y" || $answer == "S" || $answer == "s" ]]
}

# Pausa coerente (UX)
pause_return() {
    if [[ $language == "EN" ]]; then
        read -p "Press any key to return to the main menu..." -n1 -s
    else
        read -p "Premi un tasto per tornare al menu principale..." -n1 -s
    fi
    echo
}

# Funzione per la pulizia dei pacchetti AUR helper
aur_helper_clean() {
    show_header
    if [[ $language == "EN" ]]; then
        echo -e "${BLUE}This command cleans the AUR helper cache and part of the pacman cache.${NC}"
        echo -e "${CYAN}Proceed? (Y/N)${NC}"
    else
        echo -e "${BLUE}Questo comando pulisce la cache dell'AUR helper e parte della cache di pacman.${NC}"
        echo -e "${CYAN}Procedere? (S/N)${NC}"
    fi

    if confirm_action; then
        local helper=""

        # Pulisce residui pacman (directory download-*) che possono causare "Error reading fd 7"
        sudo rm -rf /var/cache/pacman/pkg/download-*

        if command -v paru &> /dev/null; then
            helper="paru"
            if [[ $language == "EN" ]]; then
                echo -e "${CYAN}Using paru for cleaning...${NC}"
            else
                echo -e "${CYAN}Uso di paru per la pulizia...${NC}"
            fi
            paru -Sc
        elif command -v yay &> /dev/null; then
            helper="yay"
            if [[ $language == "EN" ]]; then
                echo -e "${CYAN}Using yay for cleaning...${NC}"
            else
                echo -e "${CYAN}Uso di yay per la pulizia...${NC}"
            fi
            yay -Sc
        elif command -v pikaur &> /dev/null; then
            helper="pikaur"
            if [[ $language == "EN" ]]; then
                echo -e "${CYAN}Using pikaur for cleaning...${NC}"
            else
                echo -e "${CYAN}Uso di pikaur per la pulizia...${NC}"
            fi
            pikaur -Sc
        else
            if [[ $language == "EN" ]]; then
                echo -e "${RED}No recognized AUR helper found.${NC}"
            else
                echo -e "${RED}Nessun AUR helper riconosciuto trovato.${NC}"
            fi
            pause_return
            return
        fi

        if [[ $language == "EN" ]]; then
            echo -e "${GREEN}AUR helper cleaning complete (${helper}).${NC}"
        else
            echo -e "${GREEN}Pulizia AUR helper completata (${helper}).${NC}"
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
        sudo rm -rf /var/cache/pacman/pkg/download-*
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
        sudo rm -rf /var/cache/pacman/pkg/download-*
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

    read -r clean_choice

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
read -r language_choice

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
