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
		"MNU_FILE"					=> "Datei",
		"SCR_WELCOME"					=> "Willkommen",
		"HLP_WELCOME"					=> "Nächster Schritt: Wahl des Installationsziels.",
	);
	return $texte{$_[0]};
}

1;
