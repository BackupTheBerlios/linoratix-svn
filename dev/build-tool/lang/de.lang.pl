# language file for build-tool

sub _()
{
	my %texte = (
		"MSG_QUIT"					=> "Beenden",
		"MSG_PREV"					=> "1 Schritt zurück",
		"MSG_NEXT"					=> "Nächster Schritt",
		"MSG_MENU"					=> "Menü",
		"MSG_GREETING"					=> "Willkommen bei ,,Build-Tool'' - Dem Customizing Programm für Linoratix!"
								.  "\n"
								.  "\n"
								.  "Dieses Programm wird Sie Schritt für Schritt durch den Customizingprozess \n"
								.  "führen."
								.  "\n"
								.  "\n"
								.  "Bitte beachten Sie alle Meldungen und folgen Sie den Anweisungen"
								.  "\n"
								.  "\n"
								.  "Drücken Sie CTRL + N um zum nächsten Schritt zu gelangen.",
		"MSG_OPTIMIZE"					=> "Hier können Sie die Prozessoroptimierung auswählen."
								.  "\n"
								.  "\n"
								.  "Durch die Prozessoroptimierung kann man bei vielen Programmen höhere"
								.  "\n"
								.  "Ausführgeschwindigkeiten erreichen, da das Programm auch die"
								.  "\n"
								.  "Spezialfunktionen Ihres Prozessors verwenden kann.",
		"MSG_CPU"					=> "Prozessor",
		"MSG_OPTIMIZED_FOR_NONE"			=> "Keine Optimierung",
		"MSG_OPTIMIZED_FOR_i386"			=> "Optimiert für Intel 386",
		"MSG_OPTIMIZED_FOR_i486"			=> "Optimiert für Intel 486",
		"MSG_OPTIMIZED_FOR_via_cyrix_3_via_c3"		=> "Optimiert für VIA CyrixIII/VIA-C3",
		"MSG_OPTIMIZED_FOR_via_c3_2_nemiah"		=> "Optimiert für VIA-C3-2 Nemiah",
		"MSG_OPTIMIZED_FOR_intel_pentium"		=> "Optimiert für Intel Pentium",
		"MSG_OPTIMIZED_FOR_intel_pentium_mmx"		=> "Optimiert für Intel Pentium with MMX",
		"MSG_OPTIMIZED_FOR_intel_pentium_pro"		=> "Optimiert für Intel Pentium-Pro",
		"MSG_OPTIMIZED_FOR_intel_pentium_2"		=> "Optimiert für Intel Pentium 2",
		"MSG_OPTIMIZED_FOR_intel_pentium_3"		=> "Optimiert für Intel Pentium 3",
		"MSG_OPTIMIZED_FOR_intel_pentium_4"		=> "Optimiert für Intel Pentium 4",
		"MSG_OPTIMIZED_FOR_amd_k6"			=> "Optimiert für AMD K6",
		"MSG_OPTIMIZED_FOR_amd_k6_2"			=> "Optimiert für AMD K6-2",
		"MSG_OPTIMIZED_FOR_amd_k6_3"			=> "Optimiert für AMD K6-3",
		"MSG_OPTIMIZED_FOR_amd_athlon"			=> "Optimiert für AMD Athlon",
		"MSG_OPTIMIZED_FOR_amd_athlon_thunderbird"	=> "Optimiert für AMD Athlon Thunderbird",
		"MSG_OPTIMIZED_FOR_amd_athlon_4"		=> "Optimiert für AMD Athlon 4",
		"MSG_OPTIMIZED_FOR_amd_athlon_xp"		=> "Optimiert für AMD Athlon XP",
		"MSG_OPTIMIZED_FOR_amd_athlon_mp"		=> "Optimiert für AMD Athlon MP",
		"MNU_FILE"					=> "Datei",
		"SCR_WELCOME"					=> "Willkommen",
		"SCR_OPTIMIZE"					=> "Prozessoroptimierung"
	);
	return $texte{$_[0]};
}

1;