# /packages/intranet-core/tcl/intranet-l10n-procs.tcl
#
# Copyright (C) 2005 Project/Open
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Library routines to handle ]project-open[ specific
    localization

    @author frank.bergmann@project-open.com
}

ad_proc -public im_l10n_sql_currency_format { 
    {-locale ""} 
    {-digits 12}
    {-style simple}
} {
    Returns a currency format string for the locale
    to be used in (Postgres) SQL queries.
    Example: 99,999,999,999.00 for "en" locale
    @param locale Locale. "" defaults to user's locale
    @param digits Default 12.
    @param style Default "simple" {simple|separators}
} {
    if {"" == $locale} {
	set locale [lang::conn::locale]
    }
    set cur_format ""

    set decimal_point "D"
    set thousands_sep "G"
    set frac_digits [lc_get -locale $locale "frac_digits"]

    # Fractional part
    for {set i 0} {$i < $frac_digits} {incr i} {
	set cur_format "0$cur_format"
    }
    set cur_format "$decimal_point$cur_format"

    # Format the integer part in groups of 3
    set cur_format "999$cur_format"
    for {set i 0} {$i < [expr $digits-3]} {incr i} {
	if {("separators" == $style) && (0 == [expr $i % 3])} {
	    set cur_format "$thousands_sep$cur_format"
	}
	set cur_format "9$cur_format"
    }

    return $cur_format
}


ad_proc -public im_l10n_sql_date_format { 
    {-locale ""} 
    {-digits 12}
    {-style "simple"}
} {
    Returns a date format string for the locale
    to be used in (Postgres) SQL queries.
    Example: YYYY-MM-DD
} {
    return "YYYY-MM-DD"
}



ad_proc im_l10n_normalize_string {
    {-style alphanum}
    filename
} {
    Normalize a string by removing non-supported characters.
    A parameter determines the supported and non-supported characters.
    Supported styles include:
	alphanum_lower, alphanum, alphanum_space, latin, utf8, none
} {
    switch $style {
	alphanum_lower {
	    set filename [im_l10n_asciiize_string $filename]
	    set filename [string tolower $filename]
	    regsub -all {[^a-z0-9]+} $filename "_" filename
	}
	alphanum {
	    set filename [im_l10n_asciiize_string $filename]
	    regsub -all {[^a-zA-Z0-9]+} $filename "_" filename
	}
	alphanum_space {
	    set filename [im_l10n_asciiize_string $filename]
	    regsub -all {[^a-zA-Z0-9\ ]+} $filename "_" filename
	}
	latin {
	}
	utf8 {
	}
	none {
	}
	default {
	    set filename [im_l10n_asciiize_string $filename]
	    regsub -all {[^a-zA-Z0-9]+} $filename "_" filename
	}
    }
    
    if {"none" != $style} {
	# Remove multiple occurrences of "_"
	regsub -all {_+} $filename "_" filename
	
	# Remove a leading and trailing "_"
	regsub {^_} $filename "" filename
	regsub {_$} $filename "" filename
    }

    return $filename
}

ad_proc im_l10n_asciiize_string {s} {
    Replaces accented and characters with diaresis with
    standard ASCII characters.
} {
    regsub -all {\u00E1|\u00C1|\u00E2|\u00C2|\u00E0|\u00C0|\u00E5|\u00C5|\u00E3|\u00C3|\u00E4|\u00C4} $s "a" s
    regsub -all {\u00E7|\u00C7} $s "c" s
    regsub -all {\u00E9|\u00C9|\u00EA|\u00CA|\u00E8|\u00C8|\u00EB|\u00CB} $s "e" s
    regsub -all {\u00ED|\u00CD|\u00EE|\u00CE|\u00CC|\u00EF|\u00CF} $s "i" s
    regsub -all {\u00F1|\u00D1} $s "n" s
    regsub -all {\u00F3|\u00D3|\u00F4|\u00D4|\u00F2|\u00D2|\u00F8|\u00D8|\u00F5|\u00D5|\u00F6|\u00D6} $s "o" s
    regsub -all {\u00DF} $s "s" s
    regsub -all {\u00FA|\u00DA|\u00FB|\u00DB|\u00F9|\u00D9|\u00FC|\u00DC} $s "u" s
    regsub -all {\u00FD|\u00DD|\u00FF} $s "y" s
    return $s
}


