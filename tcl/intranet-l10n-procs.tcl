# /packages/intranet-core/tcl/intranet-l10n-procs.tcl
#
# Copyright (C) 2005 ]project-open[
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


proc im_u2shashu s {
    set res ""
    foreach i [split $s ""] {
        scan $i %c int
        if {$int<128} {
           append res $i
        } else {
	    append res \\u[format %04.4X $int]
        }
    }
    return $res
}

proc im_u2i s {
    set res ""
    foreach i [split $s ""] {
        scan $i %c int
	append res "$int."
    }
    return $res
}


# ---------------------------------------------------------------
# Pad number with trailing "0" to meet rounding_precision
# ---------------------------------------------------------------

ad_proc -public im_numeric_add_trailing_zeros {
    num
    rounding_precision
} {
    Add trailing "0" until the number has reached the "rounding_precision".
    "num" comes in TCL numeric format (after adding an "expr num+0").
    Example: 1524163.8 => 1524163.80
} {
#    set num "1524163"
#    set rounding_precision -3

    # Check if there is a "." in the format, checking from the rear
    set pos [string first "." $num]

    # Deal with the case of no fraction - this may be OK if the case
    # of negative fraction "rounding_precision".
    if {-1 == $pos} {
	if {$rounding_precision >= 0} { set num "${num}." }
	set pos [string first "." $num]
    }

    # Determine the other stuff of the number
    set len [string length $num]
    set frac [expr $len-$pos-1]
    set missing_frac [expr $rounding_precision-$frac]

    # Deal with the case of no fraction - this may be OK if the case
    # of negative fraction "rounding_precision".
    if {-1 == $pos} {
	if {$rounding_precision >= 0} { set num "${num}." }
    }
    
    set result $num

    while {$missing_frac > 0} {
	set result "${result}0"
	set missing_frac [expr $missing_frac-1]
    }

#    ad_return_complaint 1 "num=$num, prec=$rounding_precision, len=$len, pos=$pos, frac=$frac, mis_frac=$missing_frac, res=$result"

    return $result
}



# ---------------------------------------------------------------
# Auxilary functions
# ---------------------------------------------------------------

ad_proc im_date_format_locale { cur {min_decimals ""} {max_decimals ""} } {
	Takes a number in "Amercian" format (decimals separated by ".") and
	returns a string formatted according to the current locale.
} {
#    ns_log Notice "im_date_format_locale($cur, $min_decimals, $max_decimals)"

    # Remove thousands separating comas eventually
    regsub "\," $cur "" cur

    # Check if the number has no decimals (for ocurrence of ".")
    if {![regexp {\.} $cur]} {
	# No decimals - set digits to ""
	set digits $cur
	set decimals ""
    } else {
	# Split the digits from the decimals
	regexp {([^\.]*)\.(.*)} $cur match digits decimals
    }

    if {![string equal "" $min_decimals]} {

	# Pad decimals with trailing "0" until they reach $num_decimals
	while {[string length $decimals] < $min_decimals} {
	    append decimals "0"
	}
    }

    if {![string equal "" $max_decimals]} {
	# Adjust decimals by cutting off digits if too long:
	if {[string length $decimals] > $max_decimals} {
	    set decimals [string range $decimals 0 [expr $max_decimals-1]]
	}
    }

    # Format the digits
    if {[string equal "" $digits]} {
	set digits "0"
    }

    return "$digits.$decimals"
}



ad_proc im_mangle_user_group_name { unicode_string } {
	Returns the input string in lowercase and with " "
	being replaced by "_".
} {
    set unicode_string [string tolower $unicode_string]
    set unicode_string [im_mangle_unicode_accents $unicode_string]
    regsub -all { } $unicode_string "_" unicode_string
    regsub -all {/} $unicode_string "" unicode_string
    regsub -all {\+} $unicode_string "_" unicode_string
    regsub -all {\-} $unicode_string "_" unicode_string
    regsub -all {[^a-z0-9_\ ]} $unicode_string "" unicode_string
    return $unicode_string
}

ad_proc im_mangle_unicode_accents { unicode_string } {
    Returns the input string with accented characters converted into
    non-accented characters
} {
    array set accents [im_mangle_accent_chars_map]

    set res ""
    foreach i [split $unicode_string ""] {
        scan $i %c c
	if {[info exists accents($i)]} { set i $accents($i) }
	append res $i
    }
    set res
}


ad_proc im_mangle_accent_chars_map { } {
    Returns a hash (as array) in order to convert accented chars
    into non-accented equivalents
} {
    set list "
	\u00C0 \u0041
	\u00C1 \u0041
	\u00C2 \u0041
	\u00C3 \u0041
	\u00C4 \u0041
	\u00C5 \u0041
	\u00C7 \u0043
	\u00C8 \u0045
	\u00C9 \u0045
	\u00CA \u0045
	\u00CB \u0045
	\u00CC \u0049
	\u00CD \u0049
	\u00CE \u0049
	\u00CF \u0049
	\u00D1 \u004E
	\u00D2 \u004F
	\u00D3 \u004F
	\u00D4 \u004F
	\u00D5 \u004F
	\u00D6 \u004F
	\u00D9 \u0055
	\u00DA \u0055
	\u00DB \u0055
	\u00DC \u0055
	\u00DD \u0059
	\u00E0 \u0061
	\u00E1 \u0061
	\u00E2 \u0061
	\u00E3 \u0061
	\u00E4 \u0061
	\u00E5 \u0061
	\u00E7 \u0063
	\u00E8 \u0065
	\u00E9 \u0065
	\u00EA \u0065
	\u00EB \u0065
	\u00EC \u0069
	\u00ED \u0069
	\u00EE \u0069
	\u00EF \u0069
	\u00F1 \u006E
	\u00F2 \u006F
	\u00F3 \u006F
	\u00F4 \u006F
	\u00F5 \u006F
	\u00F6 \u006F
	\u00F9 \u0075
	\u00FA \u0075
	\u00FB \u0075
	\u00FC \u0075
	\u00FD \u0079
	\u00FF \u0079
	\u0100 \u0041
	\u0101 \u0061
	\u0102 \u0041
	\u0103 \u0061
	\u0104 \u0041
	\u0105 \u0061
	\u0106 \u0043
	\u0107 \u0063
	\u0108 \u0043
	\u0109 \u0063
	\u010A \u0043
	\u010B \u0063
	\u010C \u0043
	\u010D \u0063
	\u010E \u0044
	\u010F \u0064
	\u0112 \u0045
	\u0113 \u0065
	\u0114 \u0045
	\u0115 \u0065
	\u0116 \u0045
	\u0117 \u0065
	\u0118 \u0045
	\u0119 \u0065
	\u011A \u0045
	\u011B \u0065
	\u011C \u0047
	\u011D \u0067
	\u011E \u0047
	\u011F \u0067
	\u0120 \u0047
	\u0121 \u0067
	\u0122 \u0047
	\u0123 \u0067
	\u0124 \u0048
	\u0125 \u0068
	\u0128 \u0049
	\u0129 \u0069
	\u012A \u0049
	\u012B \u0069
	\u012C \u0049
	\u012D \u0069
	\u012E \u0049
	\u012F \u0069
	\u0130 \u0049
	\u0134 \u004A
	\u0135 \u006A
	\u0136 \u004B
	\u0137 \u006B
	\u0139 \u004C
	\u013A \u006C
	\u013B \u004C
	\u013C \u006C
	\u013D \u004C
	\u013E \u006C
	\u0143 \u004E
	\u0144 \u006E
	\u0145 \u004E
	\u0146 \u006E
	\u0147 \u004E
	\u0148 \u006E
	\u014C \u004F
	\u014D \u006F
	\u014E \u004F
	\u014F \u006F
	\u0150 \u004F
	\u0151 \u006F
	\u0154 \u0052
	\u0155 \u0072
	\u0156 \u0052
	\u0157 \u0072
	\u0158 \u0052
	\u0159 \u0072
	\u015A \u0053
	\u015B \u0073
	\u015C \u0053
	\u015D \u0073
	\u015E \u0053
	\u015F \u0073
	\u0160 \u0053
	\u0161 \u0073
	\u0162 \u0054
	\u0163 \u0074
	\u0164 \u0054
	\u0165 \u0074
	\u0168 \u0055
	\u0169 \u0075
	\u016A \u0055
	\u016B \u0075
	\u016C \u0055
	\u016D \u0075
	\u016E \u0055
	\u016F \u0075
	\u0170 \u0055
	\u0171 \u0075
	\u0172 \u0055
	\u0173 \u0075
	\u0174 \u0057
	\u0175 \u0077
	\u0176 \u0059
	\u0177 \u0079
	\u0178 \u0059
	\u0179 \u005A
	\u017A \u007A
	\u017B \u005A
	\u017C \u007A
	\u017D \u005A
	\u017E \u007A
	\u01A0 \u004F
	\u01A1 \u006F
	\u01AF \u0055
	\u01B0 \u0075
	\u01CD \u0041
	\u01CE \u0061
	\u01CF \u0049
	\u01D0 \u0069
	\u01D1 \u004F
	\u01D2 \u006F
	\u01D3 \u0055
	\u01D4 \u0075
	\u01D5 \u0055
	\u01D6 \u0075
	\u01D7 \u0055
	\u01D8 \u0075
	\u01D9 \u0055
	\u01DA \u0075
	\u01DB \u0055
	\u01DC \u0075
	\u01DE \u0041
	\u01DF \u0061
	\u01E0 \u0041
	\u01E1 \u0061
	\u01E2 \u00C6
	\u01E3 \u00E6
	\u01E6 \u0047
	\u01E7 \u0067
	\u01E8 \u004B
	\u01E9 \u006B
	\u01EA \u004F
	\u01EB \u006F
	\u01EC \u004F
	\u01ED \u006F
	\u01EE \u01B7
	\u01EF \u0292
	\u01F0 \u006A
	\u01F4 \u0047
	\u01F5 \u0067
	\u01F8 \u004E
	\u01F9 \u006E
	\u01FA \u0041
	\u01FB \u0061
	\u01FC \u00C6
	\u01FD \u00E6
	\u01FE \u00D8
	\u01FF \u00F8
	\u0200 \u0041
	\u0201 \u0061
	\u0202 \u0041
	\u0203 \u0061
	\u0204 \u0045
	\u0205 \u0065
	\u0206 \u0045
	\u0207 \u0065
	\u0208 \u0049
	\u0209 \u0069
	\u020A \u0049
	\u020B \u0069
	\u020C \u004F
	\u020D \u006F
	\u020E \u004F
	\u020F \u006F
	\u0210 \u0052
	\u0211 \u0072
	\u0212 \u0052
	\u0213 \u0072
	\u0214 \u0055
	\u0215 \u0075
	\u0216 \u0055
	\u0217 \u0075
	\u0218 \u0053
	\u0219 \u0073
	\u021A \u0054
	\u021B \u0074
	\u021E \u0048
	\u021F \u0068
	\u0226 \u0041
	\u0227 \u0061
	\u0228 \u0045
	\u0229 \u0065
	\u022A \u004F
	\u022B \u006F
	\u022C \u004F
	\u022D \u006F
	\u022E \u004F
	\u022F \u006F
	\u0230 \u004F
	\u0231 \u006F
	\u0232 \u0059
	\u0233 \u0079
	\u0385 \u00A8
	\u0386 \u0391
	\u0388 \u0395
	\u0389 \u0397
	\u038A \u0399
	\u038C \u039F
	\u038E \u03A5
	\u038F \u03A9
	\u0390 \u03B9
	\u03AA \u0399
	\u03AB \u03A5
	\u03AC \u03B1
	\u03AD \u03B5
	\u03AE \u03B7
	\u03AF \u03B9
	\u03B0 \u03C5
	\u03CA \u03B9
	\u03CB \u03C5
	\u03CC \u03BF
	\u03CD \u03C5
	\u03CE \u03C9
	\u03D3 \u03D2
	\u03D4 \u03D2
	\u0400 \u0415
	\u0401 \u0415
	\u0403 \u0413
	\u0407 \u0406
	\u040C \u041A
	\u040D \u0418
	\u040E \u0423
	\u0419 \u0418
	\u0439 \u0438
	\u0450 \u0435
	\u0451 \u0435
	\u0453 \u0433
	\u0457 \u0456
	\u045C \u043A
	\u045D \u0438
	\u045E \u0443
	\u0476 \u0474
	\u0477 \u0475
	\u04C1 \u0416
	\u04C2 \u0436
	\u04D0 \u0410
	\u04D1 \u0430
	\u04D2 \u0410
	\u04D3 \u0430
	\u04D6 \u0415
	\u04D7 \u0435
	\u04DA \u04D8
	\u04DB \u04D9
	\u04DC \u0416
	\u04DD \u0436
	\u04DE \u0417
	\u04DF \u0437
	\u04E2 \u0418
	\u04E3 \u0438
	\u04E4 \u0418
	\u04E5 \u0438
	\u04E6 \u041E
	\u04E7 \u043E
	\u04EA \u04E8
	\u04EB \u04E9
	\u04EC \u042D
	\u04ED \u044D
	\u04EE \u0423
	\u04EF \u0443
	\u04F0 \u0423
	\u04F1 \u0443
	\u04F2 \u0423
	\u04F3 \u0443
	\u04F4 \u0427
	\u04F5 \u0447
	\u04F8 \u042B
	\u04F9 \u044B
	\u0622 \u0627
	\u0623 \u0627
	\u0624 \u0648
	\u0625 \u0627
	\u0626 \u064A
	\u06C0 \u06D5
	\u06C2 \u06C1
	\u06D3 \u06D2
	\u0929 \u0928
	\u0931 \u0930
	\u0934 \u0933
	\u0958 \u0915
	\u0959 \u0916
	\u095A \u0917
	\u095B \u091C
	\u095C \u0921
	\u095D \u0922
	\u095E \u092B
	\u095F \u092F
	\u09CB \u09C7
	\u09CC \u09C7
	\u09DC \u09A1
	\u09DD \u09A2
	\u09DF \u09AF
	\u0A33 \u0A32
	\u0A36 \u0A38
	\u0A59 \u0A16
	\u0A5A \u0A17
	\u0A5B \u0A1C
	\u0A5E \u0A2B
	\u0B48 \u0B47
	\u0B4B \u0B47
	\u0B4C \u0B47
	\u0B5C \u0B21
	\u0B5D \u0B22
	\u0B94 \u0B92
	\u0BCA \u0BC6
	\u0BCB \u0BC7
	\u0BCC \u0BC6
	\u0C48 \u0C46
	\u0CC0 \u0CBF
	\u0CC7 \u0CC6
	\u0CC8 \u0CC6
	\u0CCA \u0CC6
	\u0CCB \u0CC6
	\u0D4A \u0D46
	\u0D4B \u0D47
	\u0D4C \u0D46
	\u0DDA \u0DD9
	\u0DDC \u0DD9
	\u0DDD \u0DD9
	\u0DDE \u0DD9
	\u0F43 \u0F42
	\u0F4D \u0F4C
	\u0F52 \u0F51
	\u0F57 \u0F56
	\u0F5C \u0F5B
	\u0F69 \u0F40
	\u0F73 \u0F71
	\u0F75 \u0F71
	\u0F76 \u0FB2
	\u0F78 \u0FB3
	\u0F81 \u0F71
	\u0F93 \u0F92
	\u0F9D \u0F9C
	\u0FA2 \u0FA1
	\u0FA7 \u0FA6
	\u0FAC \u0FAB
	\u0FB9 \u0F90
	\u1026 \u1025
	\u1E00 \u0041
	\u1E01 \u0061
	\u1E02 \u0042
	\u1E03 \u0062
	\u1E04 \u0042
	\u1E05 \u0062
	\u1E06 \u0042
	\u1E07 \u0062
	\u1E08 \u0043
	\u1E09 \u0063
	\u1E0A \u0044
	\u1E0B \u0064
	\u1E0C \u0044
	\u1E0D \u0064
	\u1E0E \u0044
	\u1E0F \u0064
	\u1E10 \u0044
	\u1E11 \u0064
	\u1E12 \u0044
	\u1E13 \u0064
	\u1E14 \u0045
	\u1E15 \u0065
	\u1E16 \u0045
	\u1E17 \u0065
	\u1E18 \u0045
	\u1E19 \u0065
	\u1E1A \u0045
	\u1E1B \u0065
	\u1E1C \u0045
	\u1E1D \u0065
	\u1E1E \u0046
	\u1E1F \u0066
	\u1E20 \u0047
	\u1E21 \u0067
	\u1E22 \u0048
	\u1E23 \u0068
	\u1E24 \u0048
	\u1E25 \u0068
	\u1E26 \u0048
	\u1E27 \u0068
	\u1E28 \u0048
	\u1E29 \u0068
	\u1E2A \u0048
	\u1E2B \u0068
	\u1E2C \u0049
	\u1E2D \u0069
	\u1E2E \u0049
	\u1E2F \u0069
	\u1E30 \u004B
	\u1E31 \u006B
	\u1E32 \u004B
	\u1E33 \u006B
	\u1E34 \u004B
	\u1E35 \u006B
	\u1E36 \u004C
	\u1E37 \u006C
	\u1E38 \u004C
	\u1E39 \u006C
	\u1E3A \u004C
	\u1E3B \u006C
	\u1E3C \u004C
	\u1E3D \u006C
	\u1E3E \u004D
	\u1E3F \u006D
	\u1E40 \u004D
	\u1E41 \u006D
	\u1E42 \u004D
	\u1E43 \u006D
	\u1E44 \u004E
	\u1E45 \u006E
	\u1E46 \u004E
	\u1E47 \u006E
	\u1E48 \u004E
	\u1E49 \u006E
	\u1E4A \u004E
	\u1E4B \u006E
	\u1E4C \u004F
	\u1E4D \u006F
	\u1E4E \u004F
	\u1E4F \u006F
	\u1E50 \u004F
	\u1E51 \u006F
	\u1E52 \u004F
	\u1E53 \u006F
	\u1E54 \u0050
	\u1E55 \u0070
	\u1E56 \u0050
	\u1E57 \u0070
	\u1E58 \u0052
	\u1E59 \u0072
	\u1E5A \u0052
	\u1E5B \u0072
	\u1E5C \u0052
	\u1E5D \u0072
	\u1E5E \u0052
	\u1E5F \u0072
	\u1E60 \u0053
	\u1E61 \u0073
	\u1E62 \u0053
	\u1E63 \u0073
	\u1E64 \u0053
	\u1E65 \u0073
	\u1E66 \u0053
	\u1E67 \u0073
	\u1E68 \u0053
	\u1E69 \u0073
	\u1E6A \u0054
	\u1E6B \u0074
	\u1E6C \u0054
	\u1E6D \u0074
	\u1E6E \u0054
	\u1E6F \u0074
	\u1E70 \u0054
	\u1E71 \u0074
	\u1E72 \u0055
	\u1E73 \u0075
	\u1E74 \u0055
	\u1E75 \u0075
	\u1E76 \u0055
	\u1E77 \u0075
	\u1E78 \u0055
	\u1E79 \u0075
	\u1E7A \u0055
	\u1E7B \u0075
	\u1E7C \u0056
	\u1E7D \u0076
	\u1E7E \u0056
	\u1E7F \u0076
	\u1E80 \u0057
	\u1E81 \u0077
	\u1E82 \u0057
	\u1E83 \u0077
	\u1E84 \u0057
	\u1E85 \u0077
	\u1E86 \u0057
	\u1E87 \u0077
	\u1E88 \u0057
	\u1E89 \u0077
	\u1E8A \u0058
	\u1E8B \u0078
	\u1E8C \u0058
	\u1E8D \u0078
	\u1E8E \u0059
	\u1E8F \u0079
	\u1E90 \u005A
	\u1E91 \u007A
	\u1E92 \u005A
	\u1E93 \u007A
	\u1E94 \u005A
	\u1E95 \u007A
	\u1E96 \u0068
	\u1E97 \u0074
	\u1E98 \u0077
	\u1E99 \u0079
	\u1E9B \u017F
	\u1EA0 \u0041
	\u1EA1 \u0061
	\u1EA2 \u0041
	\u1EA3 \u0061
	\u1EA4 \u0041
	\u1EA5 \u0061
	\u1EA6 \u0041
	\u1EA7 \u0061
	\u1EA8 \u0041
	\u1EA9 \u0061
	\u1EAA \u0041
	\u1EAB \u0061
	\u1EAC \u0041
	\u1EAD \u0061
	\u1EAE \u0041
	\u1EAF \u0061
	\u1EB0 \u0041
	\u1EB1 \u0061
	\u1EB2 \u0041
	\u1EB3 \u0061
	\u1EB4 \u0041
	\u1EB5 \u0061
	\u1EB6 \u0041
	\u1EB7 \u0061
	\u1EB8 \u0045
	\u1EB9 \u0065
	\u1EBA \u0045
	\u1EBB \u0065
	\u1EBC \u0045
	\u1EBD \u0065
	\u1EBE \u0045
	\u1EBF \u0065
	\u1EC0 \u0045
	\u1EC1 \u0065
	\u1EC2 \u0045
	\u1EC3 \u0065
	\u1EC4 \u0045
	\u1EC5 \u0065
	\u1EC6 \u0045
	\u1EC7 \u0065
	\u1EC8 \u0049
	\u1EC9 \u0069
	\u1ECA \u0049
	\u1ECB \u0069
	\u1ECC \u004F
	\u1ECD \u006F
	\u1ECE \u004F
	\u1ECF \u006F
	\u1ED0 \u004F
	\u1ED1 \u006F
	\u1ED2 \u004F
	\u1ED3 \u006F
	\u1ED4 \u004F
	\u1ED5 \u006F
	\u1ED6 \u004F
	\u1ED7 \u006F
	\u1ED8 \u004F
	\u1ED9 \u006F
	\u1EDA \u004F
	\u1EDB \u006F
	\u1EDC \u004F
	\u1EDD \u006F
	\u1EDE \u004F
	\u1EDF \u006F
	\u1EE0 \u004F
	\u1EE1 \u006F
	\u1EE2 \u004F
	\u1EE3 \u006F
	\u1EE4 \u0055
	\u1EE5 \u0075
	\u1EE6 \u0055
	\u1EE7 \u0075
	\u1EE8 \u0055
	\u1EE9 \u0075
	\u1EEA \u0055
	\u1EEB \u0075
	\u1EEC \u0055
	\u1EED \u0075
	\u1EEE \u0055
	\u1EEF \u0075
	\u1EF0 \u0055
	\u1EF1 \u0075
	\u1EF2 \u0059
	\u1EF3 \u0079
	\u1EF4 \u0059
	\u1EF5 \u0079
	\u1EF6 \u0059
	\u1EF7 \u0079
	\u1EF8 \u0059
	\u1EF9 \u0079
	\u1F00 \u03B1
	\u1F01 \u03B1
	\u1F02 \u03B1
	\u1F03 \u03B1
	\u1F04 \u03B1
	\u1F05 \u03B1
	\u1F06 \u03B1
	\u1F07 \u03B1
	\u1F08 \u0391
	\u1F09 \u0391
	\u1F0A \u0391
	\u1F0B \u0391
	\u1F0C \u0391
	\u1F0D \u0391
	\u1F0E \u0391
	\u1F0F \u0391
	\u1F10 \u03B5
	\u1F11 \u03B5
	\u1F12 \u03B5
	\u1F13 \u03B5
	\u1F14 \u03B5
	\u1F15 \u03B5
	\u1F18 \u0395
	\u1F19 \u0395
	\u1F1A \u0395
	\u1F1B \u0395
	\u1F1C \u0395
	\u1F1D \u0395
	\u1F20 \u03B7
	\u1F21 \u03B7
	\u1F22 \u03B7
	\u1F23 \u03B7
	\u1F24 \u03B7
	\u1F25 \u03B7
	\u1F26 \u03B7
	\u1F27 \u03B7
	\u1F28 \u0397
	\u1F29 \u0397
	\u1F2A \u0397
	\u1F2B \u0397
	\u1F2C \u0397
	\u1F2D \u0397
	\u1F2E \u0397
	\u1F2F \u0397
	\u1F30 \u03B9
	\u1F31 \u03B9
	\u1F32 \u03B9
	\u1F33 \u03B9
	\u1F34 \u03B9
	\u1F35 \u03B9
	\u1F36 \u03B9
	\u1F37 \u03B9
	\u1F38 \u0399
	\u1F39 \u0399
	\u1F3A \u0399
	\u1F3B \u0399
	\u1F3C \u0399
	\u1F3D \u0399
	\u1F3E \u0399
	\u1F3F \u0399
	\u1F40 \u03BF
	\u1F41 \u03BF
	\u1F42 \u03BF
	\u1F43 \u03BF
	\u1F44 \u03BF
	\u1F45 \u03BF
	\u1F48 \u039F
	\u1F49 \u039F
	\u1F4A \u039F
	\u1F4B \u039F
	\u1F4C \u039F
	\u1F4D \u039F
	\u1F50 \u03C5
	\u1F51 \u03C5
	\u1F52 \u03C5
	\u1F53 \u03C5
	\u1F54 \u03C5
	\u1F55 \u03C5
	\u1F56 \u03C5
	\u1F57 \u03C5
	\u1F59 \u03A5
	\u1F5B \u03A5
	\u1F5D \u03A5
	\u1F5F \u03A5
	\u1F60 \u03C9
	\u1F61 \u03C9
	\u1F62 \u03C9
	\u1F63 \u03C9
	\u1F64 \u03C9
	\u1F65 \u03C9
	\u1F66 \u03C9
	\u1F67 \u03C9
	\u1F68 \u03A9
	\u1F69 \u03A9
	\u1F6A \u03A9
	\u1F6B \u03A9
	\u1F6C \u03A9
	\u1F6D \u03A9
	\u1F6E \u03A9
	\u1F6F \u03A9
	\u1F70 \u03B1
	\u1F72 \u03B5
	\u1F74 \u03B7
	\u1F76 \u03B9
	\u1F78 \u03BF
	\u1F7A \u03C5
	\u1F7C \u03C9
	\u1F80 \u03B1
	\u1F81 \u03B1
	\u1F82 \u03B1
	\u1F83 \u03B1
	\u1F84 \u03B1
	\u1F85 \u03B1
	\u1F86 \u03B1
	\u1F87 \u03B1
	\u1F88 \u0391
	\u1F89 \u0391
	\u1F8A \u0391
	\u1F8B \u0391
	\u1F8C \u0391
	\u1F8D \u0391
	\u1F8E \u0391
	\u1F8F \u0391
	\u1F90 \u03B7
	\u1F91 \u03B7
	\u1F92 \u03B7
	\u1F93 \u03B7
	\u1F94 \u03B7
	\u1F95 \u03B7
	\u1F96 \u03B7
	\u1F97 \u03B7
	\u1F98 \u0397
	\u1F99 \u0397
	\u1F9A \u0397
	\u1F9B \u0397
	\u1F9C \u0397
	\u1F9D \u0397
	\u1F9E \u0397
	\u1F9F \u0397
	\u1FA0 \u03C9
	\u1FA1 \u03C9
	\u1FA2 \u03C9
	\u1FA3 \u03C9
	\u1FA4 \u03C9
	\u1FA5 \u03C9
	\u1FA6 \u03C9
	\u1FA7 \u03C9
	\u1FA8 \u03A9
	\u1FA9 \u03A9
	\u1FAA \u03A9
	\u1FAB \u03A9
	\u1FAC \u03A9
	\u1FAD \u03A9
	\u1FAE \u03A9
	\u1FAF \u03A9
	\u1FB0 \u03B1
	\u1FB1 \u03B1
	\u1FB2 \u03B1
	\u1FB3 \u03B1
	\u1FB4 \u03B1
	\u1FB6 \u03B1
	\u1FB7 \u03B1
	\u1FB8 \u0391
	\u1FB9 \u0391
	\u1FBA \u0391
	\u1FBC \u0391
	\u1FC1 \u00A8
	\u1FC2 \u03B7
	\u1FC3 \u03B7
	\u1FC4 \u03B7
	\u1FC6 \u03B7
	\u1FC7 \u03B7
	\u1FC8 \u0395
	\u1FCA \u0397
	\u1FCC \u0397
	\u1FCD \u1FBF
	\u1FCE \u1FBF
	\u1FCF \u1FBF
	\u1FD0 \u03B9
	\u1FD1 \u03B9
	\u1FD2 \u03B9
	\u1FD6 \u03B9
	\u1FD7 \u03B9
	\u1FD8 \u0399
	\u1FD9 \u0399
	\u1FDA \u0399
	\u1FDD \u1FFE
	\u1FDE \u1FFE
	\u1FDF \u1FFE
	\u1FE0 \u03C5
	\u1FE1 \u03C5
	\u1FE2 \u03C5
	\u1FE4 \u03C1
	\u1FE5 \u03C1
	\u1FE6 \u03C5
	\u1FE7 \u03C5
	\u1FE8 \u03A5
	\u1FE9 \u03A5
	\u1FEA \u03A5
	\u1FEC \u03A1
	\u1FED \u00A8
	\u1FF2 \u03C9
	\u1FF3 \u03C9
	\u1FF4 \u03C9
	\u1FF6 \u03C9
	\u1FF7 \u03C9
	\u1FF8 \u039F
	\u1FFA \u03A9
	\u1FFC \u03A9
	\u219A \u2190
	\u219B \u2192
	\u21AE \u2194
	\u21CD \u21D0
	\u21CE \u21D4
	\u21CF \u21D2
	\u2204 \u2203
	\u2209 \u2208
	\u220C \u220B
	\u2224 \u2223
	\u2226 \u2225
	\u2241 \u223C
	\u2244 \u2243
	\u2247 \u2245
	\u2249 \u2248
	\u2260 \u003D
	\u2262 \u2261
	\u226D \u224D
	\u226E \u003C
	\u226F \u003E
	\u2270 \u2264
	\u2271 \u2265
	\u2274 \u2272
	\u2275 \u2273
	\u2278 \u2276
	\u2279 \u2277
	\u2280 \u227A
	\u2281 \u227B
	\u2284 \u2282
	\u2285 \u2283
	\u2288 \u2286
	\u2289 \u2287
	\u22AC \u22A2
	\u22AD \u22A8
	\u22AE \u22A9
	\u22AF \u22AB
	\u22E0 \u227C
	\u22E1 \u227D
	\u22E2 \u2291
	\u22E3 \u2292
	\u22EA \u22B2
	\u22EB \u22B3
	\u22EC \u22B4
	\u22ED \u22B5
	\u2ADC \u2ADD
	\u304C \u304B
	\u304E \u304D
	\u3050 \u304F
	\u3052 \u3051
	\u3054 \u3053
	\u3056 \u3055
	\u3058 \u3057
	\u305A \u3059
	\u305C \u305B
	\u305E \u305D
	\u3060 \u305F
	\u3062 \u3061
	\u3065 \u3064
	\u3067 \u3066
	\u3069 \u3068
	\u3070 \u306F
	\u3071 \u306F
	\u3073 \u3072
	\u3074 \u3072
	\u3076 \u3075
	\u3077 \u3075
	\u3079 \u3078
	\u307A \u3078
	\u307C \u307B
	\u307D \u307B
	\u3094 \u3046
	\u309E \u309D
	\u30AC \u30AB
	\u30AE \u30AD
	\u30B0 \u30AF
	\u30B2 \u30B1
	\u30B4 \u30B3
	\u30B6 \u30B5
	\u30B8 \u30B7
	\u30BA \u30B9
	\u30BC \u30BB
	\u30BE \u30BD
	\u30C0 \u30BF
	\u30C2 \u30C1
	\u30C5 \u30C4
	\u30C7 \u30C6
	\u30C9 \u30C8
	\u30D0 \u30CF
	\u30D1 \u30CF
	\u30D3 \u30D2
	\u30D4 \u30D2
	\u30D6 \u30D5
	\u30D7 \u30D5
	\u30D9 \u30D8
	\u30DA \u30D8
	\u30DC \u30DB
	\u30DD \u30DB
	\u30F4 \u30A6
	\u30F7 \u30EF
	\u30F8 \u30F0
	\u30F9 \u30F1
	\u30FA \u30F2
	\u30FE \u30FD
	\uFB1D \u05D9
	\uFB1F \u05F2
	\uFB2A \u05E9
	\uFB2B \u05E9
	\uFB2C \u05E9
	\uFB2D \u05E9
	\uFB2E \u05D0
	\uFB2F \u05D0
	\uFB30 \u05D0
	\uFB31 \u05D1
	\uFB32 \u05D2
	\uFB33 \u05D3
	\uFB34 \u05D4
	\uFB35 \u05D5
	\uFB36 \u05D6
	\uFB38 \u05D8
	\uFB39 \u05D9
	\uFB3A \u05DA
	\uFB3B \u05DB
	\uFB3C \u05DC
	\uFB3E \u05DE
	\uFB40 \u05E0
	\uFB41 \u05E1
	\uFB43 \u05E3
	\uFB44 \u05E4
	\uFB46 \u05E6
	\uFB47 \u05E7
	\uFB48 \u05E8
	\uFB49 \u05E9
	\uFB4A \u05EA
	\uFB4B \u05D5
	\uFB4C \u05D1
	\uFB4D \u05DB
	\uFB4E \u05E4
    "
    return $list

    # The following list doesnt need to be transformed, 
    # its 32 bit Asian characters
    set 32bit_list {
	1D15E 1D157
	1D15F 1D158
	1D160 1D158
	1D161 1D158
	1D162 1D158
	1D163 1D158
	1D164 1D158
	1D1BB 1D1B9
	1D1BC 1D1BA
	1D1BD 1D1B9
	1D1BE 1D1BA
	1D1BF 1D1B9
	1D1C0 1D1BA
    }
}


ad_proc im_unicode2html {s} {
    Converts the TCL unicode characters in a string beyond
    127 into HTML characters.
    Doesn't work with MS-Excel though...
} {
    set res ""
    foreach u [split $s ""] {
	scan $u %c t
	if {$t>127} {
	    append res "&\#$t;"
	} else {
	    append res $u
	}
    }
    set res
}
