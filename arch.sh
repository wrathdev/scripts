
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





function setup_arch() {

    # Set Time Synchronisation
    echo "Setting NetworkTime Syncronization .......... "
    if timedatectl set-ntp true > /dev/null  ; then
        echo "${GREEN}OK${RESET}"
    else
        echo "${RED}FAILED${RESET}"
    fi

    echo 

    # FIx the timeou error when connected to college internet.
    fix_dwd_limit="sed /\[options\]/aDisableDownloadTimeout ${PACMAN_CONF} -i.backup"
    echo "Disabling Download Limit from pacman.(Fix for college wifi) ...... "
    if $fix_dwd_limit > /dev/null  ; then
        echo "${GREEN}OK${RESET}"
    else
        echo "${RED}FAILED${RESET}"
    fi

    echo 

    # Update Pacman Databse and FONT change
    echo "${BLUE}Updating pacman databases ....... ${RESET}"
    if pacman -Sy terminus-font  ; then
        setfont $FONT
    else
        echo "${RED}FAILED to UPDATE PACMAN database.${RESET}"
        echo "${YELLOW}Check Internet and Mirrors.${RESET}"
        return 1
    fi

    echo 

    echo "${BOLD}[ Preparing FileSystem ] ${RESET}"

    echo "Opening CryptLVM Container :-"
    if cryptsetup open /dev/sda5 ${CRYPTLVM}; then
        echo "${GREEN}SUCESS${RESET}"
    else
        echo "${RED}FAILED${RESET}"
        return 2
    fi

    echo 

    echo "Formating Partitions :-"
    format_exec=(
        "mkfs.ext4 ${VG_ROOT}"
        "mkfs.ext4 ${VG_HOME}"
        "mkswap ${VG_SWAP}"
    )

    for i in "${format_exec[@]}"    
    do
        printf "${i} ... "
        if $i >/dev/null; then
            echo "${GREEN}OK ${RESET}"
        else
            echo "${RED}FAILED${RESET}"
        fi
    done

    echo

    echo "Mounting Partitions :-"
    mount_exec=(
        "mount ${VG_ROOR} /mnt"
        "mkdir  /mnt/home"
        "mkdir  /mnt/efi"
        "mount ${VG_HOME} /mnt/home"
        "mount ${PART_EFI} /mnt/efi"
    )

    for i in "${mount_exec[@]}"    
    do
        printf "${i} ... "
        if $i >/dev/null; then
            echo "${GREEN}OK ${RESET}"
        else
            echo "${RED}FAILED${RESET}"
        fi
    done


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
    if $pacstrap_exec; then
        echo "${GREEN}SUCESS${RESET}"
    else
        echo "${RED}FAILED${RESET}"
        return 3
    fi


    echo 
    echo
    echo

    echo "${BOLD} [CHROOTING INTO /mnt] ${RESET}"
    if arch-chroot /mnt; then
        echo
    else
        echo "${RED}FAILED${RESET}"
        return 2
    fi

    echo "Setting console font ....."
    echo "FONT=ter-122n" > /etc/vconsole.conf

    echo

    echo "Setting Time :-"
    time_exec=(
        "ln -sf /usr/share/zoneinfo/${ZONEINFO} /etc/localtime"
        "mkdir  /mnt/home"
    )

    for i in "${time_exec[@]}"    
    do
        printf "${i} ... "
        if $i >/dev/null; then
            echo "${GREEN}OK ${RESET}"
        else
            echo "${RED}FAILED${RESET}"
        fi
    done

    echo 

    echo "Setting Locale :-"
    time_exec=(
        "echo "en_US.UTF-8 UTF-8" > /etc/locale.gen"
        "locale-gen"
        "echo "LANG=${LANG}" > /etc/locale.conf"
        "export $LANG"
    )

    for i in "${time_exec[@]}"    
    do
        printf "${i} ... "
        if $i >/dev/null; then
            echo "${GREEN}OK ${RESET}"
        else
            echo "${RED}FAILED${RESET}"
        fi
    done

    echo 

    echo "Setting Hostname:-"

    echo "${hostname}" > /etc/hostname
    echo "127.0.0.1 localhost \\n::1 localhost \\n127.0.1.1 blusamurai.densetsu blusamurai" >> /etc/hosts
    echo "{GREEN} Sucess{RESET}"

    dbus-uuidgen --ensure > /dev/null









    








}



