# language file for build-tool

sub _()
{
	my %texte = (
		"MSG_QUIT"					=> "Beenden",
		"MSG_PREV"					=> "1 Schritt zurück",
		"MSG_NEXT"					=> "Nächster Schritt",
		"MSG_MENU"					=> "Menü",
		"MSG_GREETING"					=> "Willkommen bei der Installation von Linoratix GNU/Linux!"
								.  "\n"
								.  "\n"
								.  "Dieses Programm wird Sie Schritt für Schritt durch den Installationsprozess\n"
								.  "führen."
								.  "\n"
								.  "\n"
								.  "Bitte beachten Sie alle Meldungen und folgen Sie den Anweisungen"
								.  "\n"
								.  "\n"
								.  "Drücken Sie CTRL + N um zum nächsten Schritt zu gelangen.",
		"MSG_TARGET_DISK"				=> "Zielfestplatte",
		"MSG_DISK"					=> "Festplatte",
		"MSG_INIT_SETUP"				=> "Bitte warten. Setup untersucht Ihre Hardware...",
		"MSG_USE_ENTIRE_DISK"				=> "Die ganze Festplatte verwenden.",
		"MSG_USE_ONLY_FREE_SPACE"			=> "Nur den freien Speicherplatz verwenden.",
		"MSG_PARTITION_BY_HAND"				=> "Partitionen selber verwalten. (nur für Experten).",
		"MSG_HOWTO_PARTITION"				=> "Wie soll partitioniert werden?",
		"MSG_PARTITION_MODI"				=> "Art der Partitionierung",
		"MSG_INIT_DISKS"					=> "Initialisiere Festplatten...",
		"MSG_INIT_PARTITIONS"				=> "Initialisiere Partitionen...",
		"MSG_READ_DISK_INFO"			=> "Lese Festplatteninformationen aus...",
		"MSG_SEARCH_HARDWARE"			=> "Suche nach Plug'n'Play fähiger Hardware...",
		"MSG_READ_TIMEZONE"				=> "Lese Zeitzonen...",
		"MSG_SELECT_TIMEZONE"			=> "Bitte wählen Sie hier Ihre Zeitzone aus."
										.   "\n\n"
										.   "Das wird benötigt, dass Ihr Computer die richtige Uhrzeit anzeigt.",
		"MSG_TIMEZONE"			=> "Zeitzone: ",
		"MSG_REALLY_PARTITION"	=> "Wenn Sie jetzt fortfahren wird die Partitionstabelle Ihrer Festplatte\nverändert.\n\nBitte vergewissern Sie sich, dass Sie ein aktuelles Backup Ihrer Daten\nhaben.",
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
		"MSG_MANUAL_PART_DESC"		=> "p = Primäre-, e = Erweiterte-, l = Logische-Partition",
		"MSG_FILESYSTEM"			=> "Dateisystem",
		"MSG_SIZE"					=> "Größe",
		"MSG_TYPE"					=> "Typ",
		"MSG_MOUNTPOINT"			=> "Mountpunkt",
		"MSG_SPECIFY_MOUNTPOINT"		=> "Geben Sie hier den Mountpunkt an",
		"MSG_PART_SIZE"				=> "Partitionsgröße eingeben.\n\nGeben Sie 'free' ein um den kompletten freien Speicherplatz zu verwenden.\nGrößenangabe in MB.",
		"MSG_PART_TITLE"				=> "Partitionsgröße",
		"MSG_SEKTOREN"			=> "Sektoren",
		
		"MNU_FILE"					=> "Datei",
		
		"SCR_WELCOME"					=> "Willkommen",
		"SCR_TARGET_DISK"				=> "Zeilfestplatte wählen",
		"SCR_HOWTO_PARTITION"				=> "Wie soll partitioniert werden?",
		"SCR_PARTITIONING"				=> "Partitionieren",
		"SCR_TIMEZONE"					=> "Zeitzone",
		"SCR_PREPARE_DISK"			=> "Bereite Festplatte vor.",
		"SCR_INSTALL_BASE_SYSTEM"	=> "Basissystem installieren",
		
		"HLP_TARGET_DISK"				=> "Wählen Sie hier die Festplatte aus auf der Linoratix GNU/Linux installiert"
								.  "\n"
								.  "werden soll."
								.  "\n\n"
								.  "Danach können Sie die Partitierung bestimmen.",
		
		"BTN_CANCEL"			=> " < Abbrechen > ",
		"BTN_NEXT"				=> " < Weiter > ",
		"BTN_PART_DELETE"		=> " < Partition löschen > ",
		"BTN_PART_ADD"			=> " < Partition hinzufügen > ",
		"BTN_PART_MOUNT"		=> " < Mountpunkt > ",
	);
	return $texte{$_[0]};
}

1;
