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
		
		"MNU_FILE"					=> "Datei",
		
		"SCR_WELCOME"					=> "Willkommen",
		"SCR_TARGET_DISK"				=> "Zeilfestplatte wählen",
		"SCR_HOWTO_PARTITION"				=> "Wie soll partitioniert werden?",
		"SCR_PARTITIONING"				=> "Partitionieren",
		
		"HLP_TARGET_DISK"				=> "Wählen Sie hier die Festplatte aus auf der Linoratix GNU/Linux installiert"
								.  "\n"
								.  "werden soll."
								.  "\n\n"
								.  "Danach können Sie die Partitierung bestimmen.",
	);
	return $texte{$_[0]};
}

1;
