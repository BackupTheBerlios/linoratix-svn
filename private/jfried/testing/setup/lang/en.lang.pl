# language file for build-tool

sub _()
{
	my %texte = (
		"MSG_QUIT"					=> "Quit",
		"MSG_PREV"					=> "1 Step back",
		"MSG_NEXT"					=> "Next Step",
		"MSG_MENU"					=> "Menu",
		"MSG_GREETING"					=> "Welcome to the installation of Linoratix GNU/Linux!"
								.  "\n"
								.  "\n"
								.  "This program will guide you through the complete setup procedure.\n"
								.  "\n"
								.  "\n"
								.  "Please read and follow the instructions!"
								.  "\n"
								.  "\n"
								.  "Press CTRL + N to go to the next step.",
		"MSG_TARGET_DISK"				=> "Targetdisk",
		"MSG_DISK"					=> "Disk",
		"MSG_INIT_SETUP"				=> "Please wait. Setup is detecting your hardware...",
		"MSG_USE_ENTIRE_DISK"				=> "Use entire disk!",
		"MSG_USE_ONLY_FREE_SPACE"			=> "Use only free (unpartitioned) space.",
		"MSG_PARTITION_BY_HAND"				=> "Manage Partitions youself. (only for experts!).",
		"MSG_HOWTO_PARTITION"				=> "How should the setup partition your harddisk?",
		"MSG_PARTITION_MODI"				=> "Kind of partitioning",
		"MSG_INIT_DISKS"					=> "Initiliaze harddrives...",
		"MSG_INIT_PARTITIONS"				=> "Initilaize partitions...",
		"MSG_READ_DISK_INFO"			=> "Reading Harddrive information...",
		"MSG_SEARCH_HARDWARE"			=> "Searching for plug'n'play hardware...",
		"MSG_READ_TIMEZONE"				=> "Reading timezones...",
		"MSG_SELECT_TIMEZONE"			=> "Please select you timezone."
										.   "\n\n"
										.   "You need this to display the correct date of your area.",
		"MSG_TIMEZONE"			=> "Timezone: ",
		"MSG_REALLY_PARTITION"	=> "If you continue, the partition table of your harddrive will be changed.\n\nPlease be sure that you have a up to date backup of ALL your data.\n. All your data MIGHT be LOST!",
		"MSG_FORMAT"			=> "Formating",
		"MSG_THIS_MAY_TAKE_A_MINUTE"	=> "Please be patient.",
		"MSG_PART_DISK"				=> "Partitioning harddrive...",
		"MSG_PART_FORMAT_BOOT"		=> "Formating /boot...",
		"MSG_PART_FORMAT_ROOT"		=> "Formating /...",
		"MSG_PART_FORMAT_HOME"		=> "Formatin /home...",
		"MSG_PART_FORMAT_SWAP"		=> "Formating swap...",
		"MSG_PART_MOUNT"			=> "Mounting partitions...",
		"MSG_INSTALL_BASE_SYSTEM"	=> "Installing the base system.\n\nPlease be patient.",
		"MSG_PARTITIONS"			=> "Partitions",
		"MSG_MANUAL_PART_DESC"		=> "p = Primary-, e = Extended-, l = logical-partition",
		"MSG_FILESYSTEM"			=> "Filesystem",
		"MSG_SIZE"					=> "Size",
		"MSG_TYPE"					=> "Type",
		"MSG_MOUNTPOINT"			=> "Mountpoint",
		"MSG_SPECIFY_MOUNTPOINT"		=> "Please set the mountpoint",
		"MSG_PART_SIZE"				=> "Partitionsize.\n\nType 'free' to use all the free space\nSize in MB.",
		"MSG_PART_TITLE"				=> "Partitionsize",
		"MSG_SEKTOREN"			=> "Sectors",
		"MSG_PART_FORMAT"		=> "Format",
		"MSG_MOUNT_PART"		=> "Mount",
		"MSG_CATEGORY"			=> "Category",
		"MSG_CHOOSE_CATEGORY"		=> "Please select the software you want to install.",
		"MSG_INSTALLING"			=> "Installing",
		"MSG_VERSION"			=> "Version",
		"MSG_INSTALL_BOOTMANAGER"	=> "Should the setup install a Bootmanager?"
										. "\n"
										. "\n"
										. "You need a Bootmanager to run Linoratix.",
		"MSG_SCANNING_PARTITIONS"		=> "Scanning partitions...",
		"MSG_INSTALL_GRUB"			=> "Installing GRUB",
		"MSG_CONFIGURING_SYSTEM"		=> "Configure the system...",
		"MSG_SETTING_TIMEZONE_TO"		=> "Setting timezone to: ",
		"MSG_HOSTNAME_INFO"				=> "Please set the computername."
										.  "\n"
										.  "This name identifies your computer in a network."
										.  "\n\n"
										.  "Example: linux.home.net",
		"MSG_HOSTNAME"						=> "Computername",
		"MSG_SETTING_HOSTNAME"			=> "Set computername to: ",
		"MSG_SETTING_RCCONF"			=> "Creating rc.conf",
		"MSG_RUN_LDCONFIG"			=> "Updating linker cache...",
		"MSG_ROOT_PASSWORD_INFO"		=> "Please set the root Password."
										.  "\n"
										.  "root is the Superuser of a Linux System.",
		"MSG_PASSWORD"				=> "Password",
		"MSG_PASSWORD_REPEAT"		=> "Repeat password.",
		"MSG_PASSWORD_NOT_MATCH"		=> "Passwords are different!",
		"MSG_PASSWORD_MATCH"		=> "Passwords are the same!",
		"MSG_SETUP_FINISHED"			=> "Linoratix is now reday to use."
										.  "\n"
										.  "\n"
										.  "The computer will be restartet in 10 seconds.",
		"MSG_FSTAB"						=> "Creating file system table.",
		
		"MNU_FILE"					=> "File",
		
		"SCR_WELCOME"					=> "Welcome",
		"SCR_TARGET_DISK"				=> "Choose targetdisk",
		"SCR_HOWTO_PARTITION"				=> "Howto Partition?",
		"SCR_PARTITIONING"				=> "Partitioning",
		"SCR_TIMEZONE"					=> "Timezone",
		"SCR_PREPARE_DISK"			=> "Preparing disk.",
		"SCR_INSTALL_BASE_SYSTEM"	=> "Installing base system",
		"SCR_CHOOSE_CATEGORIE"		=> "Choose category",
		"SCR_BOOTMANAGER"			=> "Bootmanager",
		"SCR_CONFIGURE_SYSTEM"		=> "Configuring system",
		"SCR_HOSTNAME"				=> "Computername",
		"SCR_ROOT_PASSWORD"			=> "Set root password",
		"SCR_FINISHED"			=> "Setup finished.",
		
		"HLP_TARGET_DISK"				=> "Choose the Harddrive where Linoratix should be installed on."
								.  "\n\n"
								.  "After that you can partition this disk.",
		
		"BTN_CANCEL"			=> " < Cancel > ",
		"BTN_NEXT"				=> " < Next > ",
		"BTN_PART_DELETE"		=> " < delete > ",
		"BTN_PART_ADD"			=> " < add > ",
		"BTN_PART_MOUNT"		=> " < Mountpoint > ",
	);
	return $texte{$_[0]};
}

1;
