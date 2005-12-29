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
} {
    Returns a currency format string for the locale
    to be used in (Postgres) SQL queries.
    Example: 99,999,999,999.00 for "en" locale
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
	if {0 == [expr $i % 3]} {
	    set cur_format "$thousands_sep$cur_format"
	}
	set cur_format "9$cur_format"
    }

    return $cur_format
}
