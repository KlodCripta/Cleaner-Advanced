#!/bin/bash

# Colori per il testo
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    clear
    if [[ $language == "EN" ]]; then
        echo -e "${BLUE}This command cleans the AUR helper cache and part of the pacman cache.${NC}"
    else
        echo -e "${BLUE}Questo comando pulisce la cache dell'AUR helper e parte della cache di pacman.${NC}"
    fi

    # Pulisce residui pacman (directory download-*) che possono causare "Error reading fd 7"
    sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null

    local helper=""
    if command -v paru &> /dev/null; then
        helper="paru"
        echo -e "${CYAN}Using paru for cleaning...${NC}"
        paru -Sc
    elif command -v yay &> /dev/null; then
        helper="yay"
        echo -e "${CYAN}Using yay for cleaning...${NC}"
        yay -Sc
    elif command -v pikaur &> /dev/null; then
        helper="pikaur"
        echo -e "${CYAN}Using pikaur for cleaning...${NC}"
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

    # Messaggio finale coerente: completo solo se un helper è stato trovato
    if [[ $language == "EN" ]]; then
        echo -e "${GREEN}AUR helper cleaning complete (${helper}).${NC}"
    else
        echo -e "${GREEN}Pulizia AUR helper completata (${helper}).${NC}"
    fi
    pause_return
}

# Funzione per la pulizia leggera
light_clean() {
    clear
    if [[ $language == "EN" ]]; then
        echo -e "${GREEN}Light Clean selected${NC}"
        echo -e "${CYAN}This command removes old packages from pacman's cache while keeping the currently installed ones.${NC}"
        echo -e "${CYAN}Proceed? (Y/N)${NC}"
    else
        echo -e "${GREEN}Pulizia Leggera selezionata${NC}"
        echo -e "${CYAN}Questo comando rimuove i vecchi pacchetti dalla cache di pacman mantenendo quelli attualmente installati.${NC}"
        echo -e "${CYAN}Procedere? (S/N)${NC}"
    fi

    read -r answer
    if [[ $answer == "Y" || $answer == "y" || $answer == "S" || $answer == "s" ]]; then
        sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null
        sudo pacman -Sc
    fi
    pause_return
}

# Funzione per la pulizia profonda
deep_clean() {
    clear
    if [[ $language == "EN" ]]; then
        echo -e "${GREEN}Deep Clean selected${NC}"
        echo -e "${CYAN}This command removes ALL pacman cache (aggressive).${NC}"
        echo -e "${CYAN}Proceed? (Y/N)${NC}"
    else
        echo -e "${GREEN}Pulizia Profonda selezionata${NC}"
        echo -e "${CYAN}Questo comando rimuove TUTTA la cache di pacman (operazione aggressiva).${NC}"
        echo -e "${CYAN}Procedere? (S/N)${NC}"
    fi

    read -r answer
    if [[ $answer == "Y" || $answer == "y" || $answer == "S" || $answer == "s" ]]; then
        sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null
        sudo pacman -Scc
    fi
    pause_return
}

# Funzioni di menu
main_menu() {
    clear
    if [[ $language == "EN" ]]; then
        echo -e "${GREEN}Cleaner Advanced${NC}"
        echo -e "${CYAN}1. Light Clean${NC}"
        echo -e "${CYAN}2. Deep Clean${NC}"
        echo -e "${CYAN}3. Clean AUR Helper${NC}"
        echo -e "${CYAN}4. Exit${NC}"
        echo -e "${CYAN}Choose an option: ${NC}"
    else
        echo -e "${GREEN}Cleaner Advanced${NC}"
        echo -e "${CYAN}1. Pulizia Leggera${NC}"
        echo -e "${CYAN}2. Pulizia Profonda${NC}"
        echo -e "${CYAN}3. Pulizia AUR Helper${NC}"
        echo -e "${CYAN}4. Esci${NC}"
        echo -e "${CYAN}Scegli un'opzione: ${NC}"
    fi

    read -r clean_choice

    case "$clean_choice" in
        1) light_clean ;;
        2) deep_clean ;;
        3) aur_helper_clean ;;
        4)
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

# Avvio del menu principale
clear
echo -e "${GREEN}Cleaner Advanced è un software sviluppato da Klod Cripta${NC}"
echo -e "${CYAN}Scegli la tua lingua:${NC}"
echo -e "${CYAN}1. English${NC}"
echo -e "${CYAN}2. Italiano${NC}"
read -r language_choice

if [[ $language_choice == "1" ]]; then
    language="EN"
elif [[ $language_choice == "2" ]]; then
    language="IT"
else
    echo -e "${RED}Invalid choice, defaulting to English.${NC}"
    language="EN"
fi

while true; do
    main_menu
done
