# /packages/intranet-core/tcl/intranet-util-procs.tcl
#
# Copyright (C) 2004 various authors
# The code is based on ArsDigita ACS 3.4
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
    ]project-open[ utility routines.

    @author various@arsdigita.com
    @author christof.damian@project-open.com
}

ad_proc -public multirow_sort_tree {
    { -integer:boolean 0 }
    { -nosort:boolean 0 }
    multirow_name 
    id_name 
    parent_name
    order_by
} {
    multirow_sort_tree sorts a multirow with a tree structure to make
    displaying it easy. It also adds columns for the level and the row 
    number. 

    arguments:
    @param	multirow_name	the name of the multirow
    @param	id_name      	name of the id column
    @param	parent_name  	name of the parent_id column
    @param	order_by     	name of the field to sort children of the same parent 
    		                by<ul>
    				<li>integer	order_by is sorted by integer sort (boolean)
    				<li>nosort	disable the final sorting of the multirow (boolean)
						the information to do the sort is in tree_order and tree_level
    				</ul>
} {
    if {$integer_p} {
	set sortopt "-integer"
    } else {
	set sortopt ""
    }

    # Store multirow information into hash arrays
    array set id_to_row {}
    array set children {}
    array set order {}
    set row 1
    template::multirow foreach $multirow_name {
	eval set id $$id_name
	set id_to_row($id) $row

	eval set parent_id $$parent_name
	eval set tmp $$order_by
	if { $tmp=="" } { set tmp 0 }
	set order($id) $tmp
	lappend children($parent_id) $id

	incr row
    }

    # Find the root elements
    set roots [list]
    foreach parent_id [array names children] {
	if {![info exists id_to_row($parent_id)]} {
	    foreach i $children($parent_id) {
		lappend roots [list $i 0 $order($i)]
	    }
	}
    }

    set roots [eval lsort -decreasing $sortopt -index 2 \$roots]

    template::multirow extend $multirow_name tree_order tree_level

    # recurse through list
    set row 1
    while {"" != $roots} {
	# pop
	set tmp [lindex $roots end]
	set roots [lrange [lindex [list $roots [unset roots]] 0] 0 end-1]
	
	unlist $tmp id level
	
	template::multirow set $multirow_name $id_to_row($id) tree_order $row
	template::multirow set $multirow_name $id_to_row($id) tree_level $level

	if {[info exists children($id)]} {
	    set slist [list]
	    foreach i $children($id) {
		lappend slist [list $i $order($i)]
	    }
	    foreach i [eval lsort -decreasing $sortopt -index 1 \$slist] {
		lappend roots [list [lindex $i 0] [expr $level+1]]
	    }
	}

	incr row
    }
    
    if {!$nosort_p} {
	template::multirow sort $multirow_name -integer tree_order
    }
}

ad_proc -public unlist {list args} {
    this procedure takes a list and any number of variable names in the 
    caller's environment, and sets the variables to successive elements 
    from the list:

    unlist {scrambled corned buttered} eggs beef toast
    # $eggs = scrambled
    # $beef = corned
    # $toast = buttered
} {
    foreach value $list name $args {
	if {![string length $name]} return
	upvar 1 $name var
	set var $value
    }
}

ad_proc -public textdate_to_ansi {
     date
} {
    Reformats textdate from the users locale to the iso standard YYYY-MM-DD
    adaption of template::data::transform::textdate
} {

    set value $date

    if { $value == "" } {
        # they didn't enter anything
        return ""
    }

    # we get the format they need to use
    # set format [template::util::textdate_localized_format]
    # set format "%d.%m.%Y"

    # set format "dd.mm.yyyy"
    set format [lc_get -locale [lang::user::locale] "d_fmt"]

    regsub {\%d} $format {dd} format
    regsub {\%m} $format {mm} format
    regsub {\%Y} $format {yyyy} format
    regsub {\%y} $format {yy} format

    set exp $format
    regsub -all {(\-|\.|/)} $exp {(\1)} exp
    regsub -all {dd|mm} $exp {([0-9]{1,2})} exp
    regsub -all {yyyy} $exp {([0-9]{2,4})} exp
    regsub -all {yy} $exp {([0-9]{2,4})} exp

    # results is what comes out in a regexp
    set results $format
    regsub {\-|\.|/} $results { format_one} results
    regsub {\-|\.|/} $results { format_two} results
    regsub {mm} $results { month} results
    regsub {dd} $results { day} results
    regsub {yyyy} $results { year} results
    regsub {yy} $results { year} results

    set results [string trim $results]

    if { [regexp {([\-|\.|/])yyyy$} $format match year_punctuation] } {
        # we might be willing to accept this date if it doesn't have a year
        # at the end, since we can assume that the year is the current one
        # this is useful for fast keyboard based date entry for formats that
        # have years at the end (such as in en_US which is mm/dd/yyyy or
        # de_DE which is dd.mm.yyyy)

        # we check if adding the year and punctuation makes it a valid date
        set command "regexp {$exp} \"\${value}\${year_punctuation}\[dt_sysdate -format %Y\]\" match $results"
        if { [eval $command] } {
            if { ![catch { clock scan "${year}-${month}-${day}" }] } {
                # we add the missing year and punctuation to the value
                # we don't return it here because formatting is done
                # later on (i.e. adding leading zeros if needed)
                append value "${year_punctuation}[dt_sysdate -format %Y]"
            }
        }
    }
    # now we verify that we have a valid date
    # and adding leading/trailing zeros if needed
    set command "regexp {$exp} \"\${value}\" match $results"

    if { [eval $command] } {
        # the regexp will have given us: year month day format_one format_two
        if { [string length $month] == 1 } {
            set month "0$month"
        }
        if { [string length $day] == 1 } {
            set day "0$day"
        }
        if { [string length $year] == 2 } {
            # we'll copy microsoft excel's default assumptions
            # about the year it is so if the year is 29 or
            # lower its in this century otherwise its last century
            if { $year < 30 } {
                set year "20$year"
            } else {
                set year "19$year"
            }
        }
        return "${year}-${month}-${day}"
    } else {
        # they did not provide a correctly formatted date so we send it back to them
        return $value
    }
}

ad_proc -public validate_textdate {
     textdate
} {
    Validate that a submitted textdate if properly formatted.
    Adaption of template::data::validate::textdate
} {
    set error_msg ""
    if { [exists_and_not_null textdate] } {
        if { [regexp {^[0-9]{4}-[0-9]{2}-[0-9]{2}$} $textdate match] } {
            if { [catch { [clock scan $textdate] }] } {
                # the textdate is formatted properly the template::data::transform::textdate proc
                # will only return correctly formatted dates in iso format, but the date is not
                # valid so they have entered some info incorrectly
                set datelist [split $textdate "-"]
                set year  [lindex $datelist 0]
                set month [::string trimleft [lindex $datelist 1] 0]
                set day   [::string trimleft [lindex $datelist 2] 0]
                if { $month < 1 || $month > 12 } {
                    lappend error_msg [_ acs-templating.Month_must_be_between_1_and_12]
                } else {
                    set maxdays [template::util::date::get_property days_in_month $datelist]
                    if { $day < 1 || $day > $maxdays } {
                        set month_pretty [template::util::date::get_property long_month_name $datelist]
                        if { $month == "2" } {
                            # February has a different number of days depending on the year
                            append month_pretty " ${year}"
                        }
                        lappend error_msg [_ acs-templating.lt_day_between_for_month_pretty]
                    }
                }
            }
        } else {
            # the textdate is not formatted properly
            # set format [::string toupper [template::util::textdate_localized_format]]
            lappend error_msg [_ acs-templating.lt_Dates_must_be_formatted_]
        }
    }

    if { [llength $error_msg] > 0 } {
        set message "[join $error_msg {<br>}]"
        return 0
    } else {
        return 1
    }
}


