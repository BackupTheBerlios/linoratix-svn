# language file for build-tool

sub _()
{
	my %texte = (
		"MSG_QUIT"					=> "Beenden",
		"MSG_PREV"					=> "1 Schritt zur�ck",
		"MSG_NEXT"					=> "N�chster Schritt",
		"MSG_MENU"					=> "Men�",
		"MSG_GREETING"					=> "Willkommen bei der Installation von Linoratix GNU/Linux!"
								.  "\n"
								.  "\n"
								.  "Dieses Programm wird Sie Schritt f�r Schritt durch den Installationsprozess\n"
								.  "f�hren."
								.  "\n"
								.  "\n"
								.  "Bitte beachten Sie alle Meldungen und folgen Sie den Anweisungen"
								.  "\n"
								.  "\n"
								.  "Dr�cken Sie CTRL + N um zum n�chsten Schritt zu gelangen.",
		"MSG_TARGET_DISK"				=> "Zielfestplatte",
		"MSG_DISK"					=> "Festplatte",
		"MSG_INIT_SETUP"				=> "Bitte warten. Setup untersucht Ihre Hardware...",
		"MSG_USE_ENTIRE_DISK"				=> "Die ganze Festplatte verwenden.",
		"MSG_USE_ONLY_FREE_SPACE"			=> "Nur den freien Speicherplatz verwenden.",
		"MSG_PARTITION_BY_HAND"				=> "Partitionen selber verwalten. (nur f�r Experten).",
		"MSG_HOWTO_PARTITION"				=> "Wie soll partitioniert werden?",
		"MSG_PARTITION_MODI"				=> "Art der Partitionierung",
		"MSG_INIT_DISKS"					=> "Initialisiere Festplatten...",
		"MSG_INIT_PARTITIONS"				=> "Initialisiere Partitionen...",
		"MSG_READ_DISK_INFO"			=> "Lese Festplatteninformationen aus...",
		"MSG_SEARCH_HARDWARE"			=> "Suche nach Plug'n'Play f�higer Hardware...",
		"MSG_READ_TIMEZONE"				=> "Lese Zeitzonen...",
		"MSG_SELECT_TIMEZONE"			=> "Bitte w�hlen Sie hier Ihre Zeitzone aus."
										.   "\n\n"
										.   "Das wird ben�tigt, dass Ihr Computer die richtige Uhrzeit anzeigt.",
		"MSG_TIMEZONE"			=> "Zeitzone: ",
		"MSG_REALLY_PARTITION"	=> "Wenn Sie jetzt fortfahren wird die Partitionstabelle Ihrer Festplatte\nver�ndert.\n\nBitte vergewissern Sie sich, dass Sie ein aktuelles Backup Ihrer Daten\nhaben.",
		"MSG_FORMAT"			=> "Formatiere",
		"MSG_THIS_MAY_TAKE_A_MINUTE"	=> "Bitte haben Sie etwas Geduld.",
		"MSG_PART_DISK"				=> "Partitioniere Festplatte...",
		"MSG_PART_FORMAT_BOOT"		=> "Formatiere /boot...",
		"MSG_PART_FORMAT_ROOT"		=> "Formatiere /...",
		"MSG_PART_FORMAT_HOME"		=> "Formatiere /home...",
		"MSG_PART_FORMAT_SWAP"		=> "Formatiere swap...",
		"MSG_PART_MOUNT"			=> "Mounte die Partitionen...",
		"MSG_INSTALL_BASE_SYSTEM"	=> "Installiere das Basissystem.\n\nBitte haben Sie etwas Gedult.",
		"MSG_PARTITIONS"			=> "Partitionen",
		"MSG_MANUAL_PART_DESC"		=> "p = Prim�re-, e = Erweiterte-, l = Logische-Partition",
		"MSG_FILESYSTEM"			=> "Dateisystem",
		"MSG_SIZE"					=> "Gr��e",
		"MSG_TYPE"					=> "Typ",
		"MSG_MOUNTPOINT"			=> "Mountpunkt",
		"MSG_SPECIFY_MOUNTPOINT"		=> "Geben Sie hier den Mountpunkt an",
		"MSG_PART_SIZE"				=> "Partitionsgr��e eingeben.\n\nGeben Sie 'free' ein um den kompletten freien Speicherplatz zu verwenden.\nGr��enangabe in MB.",
		"MSG_PART_TITLE"				=> "Partitionsgr��e",
		"MSG_SEKTOREN"			=> "Sektoren",
		"MSG_PART_FORMAT"		=> "Formatieren",
		"MSG_MOUNT_PART"		=> "Mounte",
		"MSG_CATEGORY"			=> "Rubrik",
		"MSG_CHOOSE_CATEGORY"		=> "Bitte w�hlen Sie hier die Software aus die installiert werden soll.",
		"MSG_INSTALLING"			=> "Installiere",
		"MSG_VERSION"			=> "Version",
		"MSG_INSTALL_BOOTMANAGER"	=> "Soll ein Bootmanager installiert werden?."
										. "\n"
										. "\n"
										. "Ein Bootmanager wird dazu verwendet um ein (oder mehrere)"
										. "\n"
										. "Betriebsysteme zu starten. Wenn Sie Linoratix verwenden m�chten,"
										. "\n"
										. "m�ssen Sie einen Bootmanager installieren",
		"MSG_SCANNING_PARTITIONS"		=> "Scanne Partitionen...",
		"MSG_INSTALL_GRUB"			=> "Installiere GRUB",
		"MSG_CONFIGURING_SYSTEM"		=> "Konfiguriere das System...",
		"MSG_SETTING_TIMEZONE_TO"		=> "Setzte Zeitzone auf: ",
		"MSG_HOSTNAME_INFO"				=> "Geben Sie hier den Computernamen ein."
										.  "\n"
										.  "Dieser Name identifiziert Ihren Computer im Netzwerk."
										.  "\n\n"
										.  "Beispiel: linux.home.net",
		"MSG_HOSTNAME"						=> "Computername",
		"MSG_SETTING_HOSTNAME"			=> "Setzte Computername auf: ",
		"MSG_SETTING_RCCONF"			=> "Erstelle rc.conf",
		"MSG_RUN_LDCONFIG"			=> "Linker cache aktualisieren",
		"MSG_ROOT_PASSWORD_INFO"		=> "Setzten Sie hier das Root Passwort."
										.  "\n"
										.  "root ist der Benutzer der auf einem Linuxsystem alles darf.",
		"MSG_PASSWORD"				=> "Passwort",
		"MSG_PASSWORD_REPEAT"		=> "Passwort wiederholen",
		"MSG_PASSWORD_NOT_MATCH"		=> "Passw�rter sind nicht gleich!",
		"MSG_PASSWORD_MATCH"		=> "Passw�rter sind gleich!",
		"MSG_SETUP_FINISHED"			=> "Linoratix ist nun auf Ihrem Computer installiert."
										.  "\n"
										.  "\n"
										.  "Der Computer wird jetzt neu gestartet.",
		"MSG_FSTAB"						=> "Erstelle Dateisystem Tabelle",
		
		"MNU_FILE"					=> "Datei",
		
		"SCR_WELCOME"					=> "Willkommen",
		"SCR_TARGET_DISK"				=> "Zeilfestplatte w�hlen",
		"SCR_HOWTO_PARTITION"				=> "Wie soll partitioniert werden?",
		"SCR_PARTITIONING"				=> "Partitionieren",
		"SCR_TIMEZONE"					=> "Zeitzone",
		"SCR_PREPARE_DISK"			=> "Bereite Festplatte vor.",
		"SCR_INSTALL_BASE_SYSTEM"	=> "Basissystem installieren",
		"SCR_CHOOSE_CATEGORIE"		=> "Kategorieen ausw�hlen",
		"SCR_BOOTMANAGER"			=> "Bootmanager",
		"SCR_CONFIGURE_SYSTEM"		=> "Konfiguriere System",
		"SCR_HOSTNAME"				=> "Computername",
		"SCR_ROOT_PASSWORD"			=> "Root Passwort setzten",
		"SCR_FINISHED"			=> "Setup beenden",
		
		"HLP_TARGET_DISK"				=> "W�hlen Sie hier die Festplatte aus auf der Linoratix GNU/Linux installiert"
								.  "\n"
								.  "werden soll."
								.  "\n\n"
								.  "Danach k�nnen Sie die Partitierung bestimmen.",
		
		"BTN_CANCEL"			=> " < Abbrechen > ",
		"BTN_NEXT"				=> " < Weiter > ",
		"BTN_PART_DELETE"		=> " < l�schen > ",
		"BTN_PART_ADD"			=> " < hinzuf�gen > ",
		"BTN_PART_MOUNT"		=> " < Mountpunkt > ",
	);
	return $texte{$_[0]};
}

1;
