# language file for build-tool

sub _()
{
	my %texte = (
		"MSG_QUIT"					=> "Beenden",
		"MSG_PREV"					=> "1 Schritt zur�ck",
		"MSG_NEXT"					=> "N�chster Schritt",
		"MSG_MENU"					=> "Men�",
		"MSG_GREETING"					=> "Willkommen bei ,,Build-Tool'' - Dem Customizing Programm f�r Linoratix!"
								.  "\n"
								.  "\n"
								.  "Dieses Programm wird Sie Schritt f�r Schritt durch den Customizingprozess \n"
								.  "f�hren."
								.  "\n"
								.  "\n"
								.  "Bitte beachten Sie alle Meldungen und folgen Sie den Anweisungen"
								.  "\n"
								.  "\n"
								.  "Dr�cken Sie CTRL + N um zum n�chsten Schritt zu gelangen.",
		"MSG_OPTIMIZE"					=> "Hier k�nnen Sie die Prozessoroptimierung ausw�hlen."
								.  "\n"
								.  "\n"
								.  "Durch die Prozessoroptimierung kann man bei vielen Programmen h�here"
								.  "\n"
								.  "Ausf�hrgeschwindigkeiten erreichen, da das Programm auch die"
								.  "\n"
								.  "Spezialfunktionen Ihres Prozessors verwenden kann.",
		"MSG_CPU"					=> "Prozessor",
		"MSG_OPTIMIZED_FOR_NONE"			=> "Keine Optimierung",
		"MSG_OPTIMIZED_FOR_i386"			=> "Optimiert f�r Intel 386",
		"MSG_OPTIMIZED_FOR_i486"			=> "Optimiert f�r Intel 486",
		"MSG_OPTIMIZED_FOR_via_cyrix_3_via_c3"		=> "Optimiert f�r VIA CyrixIII/VIA-C3",
		"MSG_OPTIMIZED_FOR_via_c3_2_nemiah"		=> "Optimiert f�r VIA-C3-2 Nemiah",
		"MSG_OPTIMIZED_FOR_intel_pentium"		=> "Optimiert f�r Intel Pentium",
		"MSG_OPTIMIZED_FOR_intel_pentium_mmx"		=> "Optimiert f�r Intel Pentium mit MMX",
		"MSG_OPTIMIZED_FOR_intel_pentium_pro"		=> "Optimiert f�r Intel Pentium-Pro",
		"MSG_OPTIMIZED_FOR_intel_pentium_2"		=> "Optimiert f�r Intel Pentium 2",
		"MSG_OPTIMIZED_FOR_intel_pentium_3"		=> "Optimiert f�r Intel Pentium 3",
		"MSG_OPTIMIZED_FOR_intel_pentium_4"		=> "Optimiert f�r Intel Pentium 4",
		"MSG_OPTIMIZED_FOR_amd_k6"			=> "Optimiert f�r AMD K6",
		"MSG_OPTIMIZED_FOR_amd_k6_2"			=> "Optimiert f�r AMD K6-2",
		"MSG_OPTIMIZED_FOR_amd_k6_3"			=> "Optimiert f�r AMD K6-3",
		"MSG_OPTIMIZED_FOR_amd_athlon"			=> "Optimiert f�r AMD Athlon",
		"MSG_OPTIMIZED_FOR_amd_athlon_thunderbird"	=> "Optimiert f�r AMD Athlon Thunderbird",
		"MSG_OPTIMIZED_FOR_amd_athlon_4"		=> "Optimiert f�r AMD Athlon 4",
		"MSG_OPTIMIZED_FOR_amd_athlon_xp"		=> "Optimiert f�r AMD Athlon XP",
		"MSG_OPTIMIZED_FOR_amd_athlon_mp"		=> "Optimiert f�r AMD Athlon MP",
		"MSG_TARGET_DISTRIBUTION"			=> "W�hlen Sie hier den Einsatzzweck der Distribution aus",
		"MSG_TARGET_DISTRIBUTION_TITLE"			=> "Einsatzzweck w�hlen",
		"MSG_TARGET_SERVER"				=> "Server Linux",
		"MSG_TARGET_DESKTOP"				=> "Desktop Linux",
		"MSG_TARGET_ROUTER_FIREWALL"			=> "Special Router/Firewall Linux",
		"MSG_TARGET_RESCUE_SYSTEM"			=> "Rescuesystem on a CD/DVD",
		"MSG_TARGET_GENERIC_LINORATIX"			=> "Generic Linoratix Build (all packages)",
		"MNU_FILE"					=> "Datei",
		"SCR_WELCOME"					=> "Willkommen",
		"SCR_OPTIMIZE"					=> "Prozessoroptimierung",
		"SCR_TARGET_DISTRIBUTION"			=> "Zieldistribution"
	);
	return $texte{$_[0]};
}

1;
