
T_COLS = $(tput cols)
T_ROWS = $(tput lines)

LANG=en_US.UTF-8
FONT=ter-122n


HOSTNAME=blusamurai
DOMAIN_NAME=densetsu

ZONEINFO="Asia/Kolkata"

PACMAN_CONF=/etc/pacman.conf

PART_CRYPT=/dev/sda1
PART_EFI=/dev/sda2
VG_ROOT=/dev/vg/root
VG_HOME=/dev/vg/home
VG_SWAP=/dev/vg/swap
CRYPTLVM=cryptlvm
DEV_CRYPT=/dev/mapper/cryptlvm





error() {
	echo ${RED}"Error: $@"${RESET} >&2
}


# Source: https://github.com/robbyrussell/oh-my-zsh/blob/master/tools/install.sh
setup_color() {
	# Only use colors if connected to a terminal
	if [ -t 1 ]; then
		RED=$(printf '\033[31m')
		GREEN=$(printf '\033[32m')
		YELLOW=$(printf '\033[33m')
		BLUE=$(printf '\033[34m')
		BOLD=$(printf '\033[1m')
		RESET=$(printf '\033[m')
	else
		RED=""
		GREEN=""
		YELLOW=""
		BLUE=""
		BOLD=""
		RESET=""
	fi
}




function cmd_nostdout() {
    for i in "$@"
    do
        printf "${i} ... "
        if $i >/dev/null; then
            echo "${GREEN}OK${RESET}"
        else
            echo "${RED}FAILED${RESET}"
        fi
    done
}

function cmd_abort_nostd(){
    for i in "$@"
    do
        if $i >/dev/null; then
            echo "${GREEN}OK${RESET}"
        else
            echo "${RED}FAILED${RESET}"
            echo "${RED} Aborting Script"
            return 1
        fi
    done
    return 0
}

function cmd()
{
    for i in "$@"
    do
        if $i; then
            echo "${GREEN}OK${RESET}"
        else
            echo "${RED}FAILED${RESET}"
        fi
    done
}

function cmd_abort(){
    for i in "$@"
    do
        if $i; then
            echo "${GREEN}OK${RESET}"
        else
            echo "${RED}FAILED${RESET}"
            echo "${RED} Aborting Script"
            return 1
        fi
    done
    return 0
}






function setup_arch() {

    # Set Time Synchronisation
    printf "Setting NetworkTime Syncronization .......... "
    cmd_nostdout "timedatectl set-ntp true" 
   
    echo 

    # FIx the timeou error when connected to college internet.
    fix_dwd_limit="sed /\[options\]/aDisableDownloadTimeout ${PACMAN_CONF} -i.backup"
    printf "Disabling Download Limit from pacman.(Fix for college wifi) ...... "
    cmd_nostdout $fix_dwd_limit

    echo 



    # Update Pacman Databse and FONT change
    printf "${BLUE}Updating pacman databases ....... ${RESET}"
    if cmd "yes | pacman -Sy terminus-font"  ; then
        setfont $FONT
    else
        echo "${RED}FAILED to UPDATE PACMAN database.${RESET}"
        echo "${YELLOW}Check Internet and Mirrors.${RESET}"
        exit 1
    fi

    echo 

    echo "${BOLD}[ Preparing FileSystem ] ${RESET}"

    echo "Opening CryptLVM Container :-"
    
    if ! cmd "cryptsetup open ${PART_CRYPT} ${CRYPTLVM}"; then
        echo "${RED}Could'nt open Crypt container. Exiting Script ${RESET}"
        exit 2
    fi

    echo 

    echo "Formating Partitions :-"
    format_exec=(
        "mkfs.ext4 ${VG_ROOT}"
        "mkfs.ext4 ${VG_HOME}"
        "mkswap ${VG_SWAP}"
        "mkfs.fat -F32 ${PART_EFI}"
    )
    cmd_nostdout "${format_exec[@]}"


    echo

    echo "Mounting Partitions :-"
    mount_exec=(
        "mount ${VG_ROOR} /mnt"
        "mkdir  /mnt/home"
        "mkdir  /mnt/efi"
        "mount ${VG_HOME} /mnt/home"
        "mount ${PART_EFI} /mnt/efi"
    )

    if ! cmd_abort_nostd "${mount_exec[@]}"; then
        echo "${RED}Failed to mount partitions. Exiting Script ${RESET}"
    fi

    echo 

    echo "${BOLD}[ Pacstrap /mnt ] ${RESET}"

    pacstrap_exec="pacstrap /mnt \
                        base base-devel \
                        grub efibootmgr intel-ucode \
                        zsh git go vim wget \
                        terminus-font \
                        networkmanager \
                        python python-requests \
                    "
    if ! cmd_abort_nostd $pacstrap_exec; then
        echo "${RED}FAILED to install arch in /mnt. Exiting Script.${RESET}"
        exit 3
    fi


    echo 
    echo

    echo "${BOLD} [CHROOTING INTO /mnt] ${RESET}"
    if ! cmd_abort "arch-chroot /mnt"; then
        exit 2
    fi

    echo "Setting console font ....."
    cmd_abort_nostd "echo 'FONT=ter-122n' > /etc/vconsole.conf"

    echo

    echo "Setting Time :-"
    time_exec=(
        "ln -sf /usr/share/zoneinfo/${ZONEINFO} /etc/localtime"
        "mkdir  /mnt/home"
    )

    cmd_nostdout "${time_exec[@]}"

    echo 

    echo "Setting Locale :-"
    locale_exec=(
        "echo "en_US.UTF-8 UTF-8" > /etc/locale.gen"
        "locale-gen"
        "echo "LANG=${LANG}" > /etc/locale.conf"
        "export $LANG"
    )

    cmd_abort_nostd "${locale_exec[@]}"

    echo 

    echo "Setting Hostname:-"

    cmd_abort_nostd "echo '${hostname}' > /etc/hostname"
    cmd_abort_nostd "echo '127.0.0.1 localhost \\n::1 localhost \\n127.0.1.1 blusamurai.densetsu blusamurai' >> /etc/hosts"
 

    cmd_abort_nostd "dbus-uuidgen --ensure"

}

setup_color
setup_arch



