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
		"MNU_FILE"					=> "Datei",
		"SCR_WELCOME"					=> "Willkommen",
		"HLP_WELCOME"					=> "N�chster Schritt: Wahl des Installationsziels.",
	);
	return $texte{$_[0]};
}

1;
