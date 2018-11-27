# /packages/intranet-core/tcl/intranet-defs-procs.tcl
#
# Copyright (C) 1998-2004 various parties
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
    Definitions for the intranet module

    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
}

# ------------------------------------------------------------------
# Constant Functions
# ------------------------------------------------------------------

ad_proc -public im_uom_hour {} { return 320 }
ad_proc -public im_uom_day {} { return 321 }
ad_proc -public im_uom_unit {} { return 322 }
ad_proc -public im_uom_page {} { return 323 }
ad_proc -public im_uom_s_word {} { return 324 }
ad_proc -public im_uom_t_word {} { return 325 }
ad_proc -public im_uom_s_line {} { return 326 }
ad_proc -public im_uom_t_line {} { return 327 }


# --------------------------------------------------------
# Show a collapsible help message
# --------------------------------------------------------

ad_proc -public im_help_collapsible {
    { -return_url "" }
    { -current_user_id "" }
    help_html
} {
    Shows the help_html, unless the help has been collapsed.
} {
    if {"" eq $return_url} { set return_url [im_url_with_query] }
    if {"" eq $current_user_id} { set current_user_id [auth::require_login] }
    set page_url $return_url
    set quest_pos [string first "?" $page_url]
    if {$quest_pos > 0} { set page_url [string range $return_url 0 $quest_pos] }
    set collapse_url "/intranet/biz-object-tree-open-close"
    set collapsed_o_c [db_string collapsed "
	select	open_p
	from	im_biz_object_tree_status
	where	user_id = :current_user_id and 
		object_id = 0 and 
		page_url = :page_url
    " -default "o"]
    if {"o" == $collapsed_o_c} {
	set url [export_vars -base $collapse_url {page_url return_url {open_p "c"} {object_id 0}}]
	set collapse_html "<a href=$url>[im_gif minus_9]</a> [lang::message::lookup "" intranet-core.Hide_Help "Hide this help text"]"
    } else {
	set url [export_vars -base $collapse_url {page_url return_url {open_p "o"} {object_id 0}}]
	set collapse_html "<a href=$url>[im_gif plus_9]</a> [lang::message::lookup "" intranet-core.Show_Help "Show a help text"]"
    }

    if {"o" ne $collapsed_o_c} { set help_html "" }
    # append help_html $collapse_html
    set help_html "$collapse_html $help_html"
    return $help_html
}

# --------------------------------------------------------
# 
# --------------------------------------------------------

ad_proc var_contains_quotes { var } {
    if {[regexp {"} $var]} { return 1 }
    if {[regexp {'} $var]} { return 1 }
    return 0
}


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------


ad_proc -public im_view_id_from_name { 
    view_name
} {
    Returns the view_id for given name
} {
    if {[im_security_alert_check_alphanum -location im_view_id_from_name -value $view_name]} { return 0 }
    set view_id [util_memoize [list db_string get_view "select view_id from im_views where view_name = '$view_name'" -default 0]]
    return $view_id
}


# ------------------------------------------------------------------
# Date conversion
# ------------------------------------------------------------------

ad_proc -public im_date_ansi_to_julian { 
    { -throw_complaint_p 1 }
    ansi
} {
    Returns julian date for a YYYY-MM-DD string.
    By default, the procedure will use ad_return_complaint to report errors.
    Set the parameter throw_complaint_p to 0 to tell the procedure to return
    -1 instead.
} {
    if {"" == $ansi} { return -1 }
    set ansi [string range $ansi 0 9]

    # Check that Start & End-Date have correct format
    set ansi_ok_p [regexp {^([0-9][0-9][0-9][0-9])\-([0-9][0-9])\-([0-9][0-9])$} $ansi match year month day]
    if {!$ansi_ok_p} {
	if {!$throw_complaint_p} { return -1 }
	ad_return_complaint 1 "
		<b>Found an invalid data string.</b>:<br>
		Current value: '$ansi'<br>
		Expected format: 'YYYY-MM-DD'
	"
	ad_script_abort
    }

    if {0 == [string range $month 0 0]} { set month [string range $month 1 end] }
    if {0 == [string range $day 0 0]} { set day [string range $day 1 end] }

    # Perform the main conversion.
    if {[catch { set julian [dt_ansi_to_julian $year $month $day] } err_msg]} {
	if {!$throw_complaint_p} { return -1 }
	error "
		Invalid conversion of ANSI date to Julian format:
		Current value: '$ansi'
		Expected format: 'YYYY-MM-DD'.
		Here is the detailed error message for reference:
		$err_msg
	"
    }

    return $julian
}

ad_proc -public im_date_julian_to_dow { 
    julian 
} {
    Returns the Day-of-week for a julian date, similar
    to im_date_julian_to_components -> dow.
} {
    return [expr ($julian % 7) + 1]
}

ad_proc -public im_date_julian_to_ansi { 
    { -throw_complaint_p 1 }
    julian 
} {
    Returns YYYY-MM-DD for a julian date.
} {
    return [dt_julian_to_ansi $julian]
}

ad_proc -public im_date_julian_to_epoch { 
    { -throw_complaint_p 1 }
    julian 
} {
    Returns seconds after 1/1/1970 00:00 GMT
} {
    set tz_offset_seconds [util_memoize [list db_string tz_offset "select extract(timezone from now())"]]
    return [expr {86400.0 * ($julian - 2440588.0) - $tz_offset_seconds}]
}

ad_proc -public im_date_ansi_to_epoch { 
    { -throw_complaint_p 1 }
    ansi
} {
    Returns seconds after 1/1/1970 00:00 GMT
} {

    if {[regexp {(....)-(..)-(..)} [string range $ansi 0 9] match year month day]} {
	if {0 == [string range $month 0 0]} { set month [string range $month 1 end] }
	if {0 == [string range $day 0 0]} { set day [string range $day 1 end] }
	
	set julian [dt_ansi_to_julian $year $month $day]
	set epoch [im_date_julian_to_epoch -throw_complaint_p $throw_complaint_p $julian]
	
	set ansi_time [string range $ansi 11 end]
	if {[regexp {(..):(..):(..)} $ansi_time match hh mm ss]} {
	    if {0 == [string range $ss 0 0]} { set ss [string range $ss 1 end] }
	    if {0 == [string range $mm 0 0]} { set mm [string range $mm 1 end] }
	    if {0 == [string range $hh 0 0]} { set hh [string range $hh 1 end] }
	    set epoch [expr {$epoch + $ss + 60 * ($mm + 60.0 * $hh)}]
	}
	return $epoch
    } else {
	error "im_date_ansi_to_epoch: Invalid ANSI date: '$ansi'"
    }
}

ad_proc -public im_date_epoch_to_ansi { 
    { -throw_complaint_p 1 }
    epoch
} {
    Returns ansi date for epoch
} {
    if {"" == $epoch} { return "" }
    im_security_alert_check_float -location "im_date_epoch_to_ansi" -value $epoch
    set ansi [util_memoize [list db_string epoch_to_ansi "SELECT to_char(TIMESTAMP WITH TIME ZONE 'epoch' + $epoch * INTERVAL '1 second', 'YYYY-MM-DD')"]]
    return $ansi
}

ad_proc -public im_date_epoch_to_julian { 
    { -throw_complaint_p 1 }
    epoch
} {
    Returns ansi date for epoch
} {
    if {"" == $epoch} { return "" }
    im_security_alert_check_float -location "im_date_epoch_to_ansi" -value $epoch
    set julian [util_memoize [list db_string epoch_to_julian "SELECT to_char(TIMESTAMP WITH TIME ZONE 'epoch' + $epoch * INTERVAL '1 second', 'J')"]]
    return $julian
}

ad_proc -public im_date_epoch_to_time { 
    { -throw_complaint_p 1 }
    epoch
} {
    Returns ansi date for epoch
} {
    if {"" == $epoch} { return "" }
    im_security_alert_check_float -location "im_date_epoch_to_ansi" -value $epoch
    set ansi [util_memoize [list db_string epoch_to_ansi "SELECT to_char(TIMESTAMP WITH TIME ZONE 'epoch' + $epoch * INTERVAL '1 second', 'HH24:MI:SS')"]]
    return $ansi
}




# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

ad_proc -public im_exec_dml { { -dbn "" } sql_name sql } {
    Execute a DML procedure (function in PostgreSQL) without
    regard of the database type. Basically, the procedures wraps
    a "BEGIN ... END;" around Oracle procedures and an
    "select ... ;" for PostgreSQL.

    @param A neutral SQL statement, for example: im_cost_del(:cost_id)
} {
    set driverkey [db_driverkey $dbn]
    # PostgreSQL has a special implementation here, any other db will
    # probably work with the default:

    switch $driverkey {
        postgresql {
            set script "
                db_string $sql_name \"select $sql;\"
            "
            uplevel 1 $script
        }
        oracle -
        nsodbc -
        default {
            set script "
                db_dml $sql_name \"
                        BEGIN
                                $sql;
                        END;
                \"
            "
            uplevel 1 $script
        }
    }
}

ad_proc -public im_package_core_id {} {
    Returns the package id of the intranet-core module
} {
    return [util_memoize im_package_core_id_helper]
}

ad_proc -private im_package_core_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-core'
    } -default 0]
}



# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

ad_proc -public im_opt_val { 
    {-limit_to "nohtml"}
    var_name
} {
    Acts like a "$" to evaluate a variable, but returns "" if the variable 
    is not defined, instead of an error.<BR>
    If no value is found, im_opt_val checks whether there is a HTTP variable 
    with the same name, either in the URL or as part of a POST.<br>
    This function is useful for passing optional variables to components, 
    if the component can't be sure that the variable exists in the callers
    context.
} {
    set result ""

    # Check if the variable exists in the parent's caller environment
    upvar $var_name value
    if {[info exists value]} { 
	# Take the value from the caller's environment
	set result $value
    } else {
	# Take the value from the HTTP vars or "" otherwise.
	set form_vars [ns_conn form]
	if {"" == $form_vars} { set form_vars [ns_set create] }
	set result [ns_set get $form_vars $var_name]

	# Check the security of the value taken from HTTP vars
	set message ""
	switch $limit_to {
	    allhtml {
		# Do nothing - no checks
	    }
	    nohtml {
		# Don't allow any tags
		if { [string first < $result] >= 0 } {
		    set message [lang::message::lookup "" intranet-core.No_HTML_allowed_in_varname "No HTML tags allowed in variable '%var_name%'"]
		}
	    }
	    html {
		set message [ad_html_security_check $result]
	    }
	    integer {
		if {![string is integer $result]} { 
		    set message [lang::message::lookup "" intranet-core.Variable_is_not_an_integer "Variable '%var_name%' is not an integer"]
		}
	    }
	    default {
		# Do nothing - no checks
	    }
	}

	if {"" != $message} {
	    im_security_alert -location im_opt_val -message $message -value $result -severity "Severe"
	    ad_return_complaint 1 "<b>Security Check</b>:<br>$message"
	    ad_script_abort
	}
    }
    
    return $result
} 

ad_proc -public im_parameter {
    -localize:boolean
    -set:boolean
    {-package_id ""}
    {-package_key ""}
    {-parameter ""}
    {-default ""}
    {parameter2 ""}
    {package_key2 ""}
    {default2 ""}
} {
    Wrapper for im_parameter. With ]project-open[ we don't
						  need package ids because all ]po[ packages are singletons.
    The parameters are designed to be compatible with both
    im_parameter and the new parameter::get
} {
    if {"" != $default2} { set default $default2 }
    if {"" != $parameter2} { set parameter $parameter2 }

    # Get the package_id. We use min(...) because a single package
    # (identified by a "package_key" can be mounted several times
    # in the system.
    if {"" == $package_id && "" != $package_key} {
	set package_id [util_memoize [list db_string get_package_id "
                select  min(package_id) as package_id
                from    apm_packages
                where   package_key = '$package_key'
        "]]
    }
    if {"" == $package_id && "" != $package_key2} {
	set package_id [util_memoize [list db_string get_package_id "
                select  min(package_id) as package_id
                from    apm_packages
                where   package_key = '$package_key2'
        "]]
    }
    if {"" == $package_id} { return $default }
    if {"" == $parameter} { return $default }


    # Get the parameter
    set value [util_memoize [list parameter::get -package_id $package_id -parameter $parameter -default $default]]
    return $value
}



# Basic Intranet Parameter Shortcuts
ad_proc im_url_stub {} {
    return [im_parameter -package_id [im_package_core_id] IntranetUrlStub "" "/intranet"]
}

ad_proc im_url {} {
    return [im_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""][im_url_stub]
}

# ------------------------------------------------------------------
#
# ------------------------------------------------------------------

# Find out the user name
ad_proc -public im_name_from_user_id {
    user_id
} {
    if {"" == [string trim $user_id]} { set user_id -1 }
    return [util_memoize [list im_name_from_user_id_helper $user_id]]
}

ad_proc -public im_name_from_user_id_helper {user_id} {
    set user_name "&lt;unknown&gt;"
    set name_order [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NameOrder" -default 1]
    catch { set user_name [db_string uname "select im_name_from_user_id(:user_id, $name_order)"] } err
    return $user_name
}


# Find out the user email
ad_proc -public im_email_from_user_id {
    user_id
} {
    return [util_memoize [list im_email_from_user_id_helper $user_id]]
}

ad_proc -public im_email_from_user_id_helper {
    user_id
} {
    set user_email "unknown@unknown.com"
    if {![catch { 
	set user_email [db_string get_user_email {
	select	email
	from	parties
	where	party_id = :user_id
    }] } errmsg]} {
	# no errors
    }
    return $user_email
}


# Find out the user initials
ad_proc -public im_initials_from_user_id {user_id} {
    return [util_memoize [list im_initials_from_user_id_helper $user_id]]
}

ad_proc -public im_initials_from_user_id_helper {user_id} {
    return [db_string user_initials "select im_initials_from_user_id(:user_id)" -default $user_id]
}


ad_proc im_employee_select_optionlist { 
    { -locale "" }
    { -translate_p 0 }
    {user_id ""} 
} {
    set employee_group_id [im_employee_group_id]
    return [db_html_select_value_options_multiple -translate_p $translate_p -locale $locale -select_option $user_id im_employee_select_options "
	select
		u.user_id, 
		im_name_from_user_id(u.user_id) as name
	from
		registered_users u,
		group_distinct_member_map gm
	where
		u.user_id = gm.member_id
		and gm.group_id = $employee_group_id
	order by lower(im_name_from_user_id(u.user_id))
    "]
}


ad_proc im_slider { field_name pairs { default "" } { var_list_not_to_export "" } } {
    Takes in the name of the field in the current menu bar and a 
    list where the ith item is the name of the form element and 
    the i+1st element is the actual text to display. Returns an 
    html string of the properly formatted slider bar
} {
    if { [llength $pairs] == 0 } {
	# Get out early as there's nothing to do
	return ""
    }
    if { $default eq "" } {
	set default [ad_partner_upvar $field_name 1]
    }
    set exclude_var_list [list $field_name]
    foreach var $var_list_not_to_export {
	lappend exclude_var_list $var
    }
    set url "[ns_conn url]?"
    set query_args [export_ns_set_vars url $exclude_var_list]
    if { $query_args ne "" } {
	append url "$query_args&"
    }
    # Count up the number of characters we display to help us select either
    # text links or a select box
    set text_length 0
    foreach { value text } $pairs {
	set text_length [expr {$text_length + [string length $text]}]
	if { $value eq $default  } {
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\" selected>$text</option>\n"
	} else {
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\">$text</option>\n"
	}
    }
    return "
<form method=get action=\"[ns_conn url]\">
[export_ns_set_vars form $exclude_var_list]
<select name=\"[ns_quotehtml $field_name]\">
[join $menu_items_select ""]
</select>
<input type=submit value=\"Go\">
</form>
"
}

ad_proc im_select { 
    {-ad_form_option_list_style_p 0}
    {-multiple_p 0} 
    {-size 6}
    {-translate_p 1} 
    {-javascript ""}
    {-package_key "intranet-core" }
    {-locale "" }
    field_name
    pairs
    { default "" }
} {
    Formats a "select" tag.
    Check if "pairs" is in a sequential format or a list of tuples 
    (format of ad_form).
    @param ad_form_option_list_p Set to 1 if the options are passed on
           in the format for template:: and ad_form, as oposed to the
           legacy ]po[ style.
} {
    # Get out early as there's nothing to do
    if { [llength $pairs] == 0 } { return "" }

    if {"" == $locale} { set locale [lang::user::locale -user_id [ad_conn user_id]] }

    set multiple ""
    if {$multiple_p} { 
	set multiple "multiple" 
	set size "size=\"$size\""
    } else {
	set size ""
    }

    if { $default eq "" } {
	set default [ad_partner_upvar $field_name 1]
    }
    set url "[ns_conn url]?"
    set menu_items_text [list]
    set items [list]

    # "flatten" the list if list was given in "list of tuples" format
    if {$ad_form_option_list_style_p} {
	set pairs [im_select_flatten_list $pairs]
    }

    foreach { value text } $pairs {
	if { $translate_p && "" != [string trim $text]} {

	    # This would eliminate all translation errors cause by "%" in the message.
	    # However, I'll allow for these errors in order to track the sources
	    # regsub -all {%} $text {_} text

	    set l10n_key [lang::util::suggest_key $text]
	    set text_tr [lang::message::lookup $locale $package_key.$l10n_key $text]

        } else {
            set text_tr $text
        }

	set item "<option value=\"[ad_urlencode $value]\">$text_tr</option>"
	if {$multiple_p} {
	    if {[lsearch $default $value] >= 0} {
		set item "<option value=\"[ad_urlencode $value]\" selected>$text_tr</option>"
	    }
	} else {
	    if {$value eq $default } {
		set item "<option value=\"[ad_urlencode $value]\" selected>$text_tr</option>"
	    }
	}
	lappend items $item
    }
    return "
    <select name=\"[ns_quotehtml $field_name]\" $size $multiple $javascript>
    [join $items "\n"]
    </select>
"
}



ad_proc im_select_flatten_list { list } {
    Returns a flattened list from a list of tupels
} {
    set result [list]
    foreach l $list {
	lappend result [lindex $l 1]
	lappend result [lindex $l 0]
    }

    return $result
}




ad_proc im_format_number { num {tag "<font size=\"+1\" color=\"blue\">"} } {
    Pads the specified number with the specified tag
} {
    regsub {\.$} $num "" num
    return "$tag${num}.</font>"
}

ad_proc im_verify_form_variables required_vars {
    The intranet standard way to verify arguments. Takes a list of
    pairs where the first element of the pair is the variable name and the
    second element of the pair is the message to display when the variable
    isn't defined.
} {
    set err_str ""
    foreach pair $required_vars {
	if { [catch { 
	    upvar [lindex $pair 0] value
	    if { [string trim $value] eq "" } {
		append err_str "  <li> [lindex $pair 1]\n"
	    } 
	} err_msg] } {
	    # This means the variable is not defined - the upvar failed
	    append err_str "  <li> [lindex $pair 1]\n"
	} 
    }	
    return $err_str
}



ad_proc im_append_list_to_ns_set { { -integer_p f } set_id base_var_name list_of_items } {
    Iterates through all items in list_of_items. Adds to set_id
    key/value pairs like <var_name_0, item_0>, <var_name_1, item_1>
    etc. Returns a comma separated list of the bind variables for use in
    sql. Executes validate-integer on every element if integer_p is set to t
} {
    set ctr 0
    set sql_string_list [list]
    foreach item $list_of_items {
	if { $integer_p == "t" } {
	    validate_integer "${base_var_name} element" $item
	}
	set var_name "${base_var_name}_$ctr"
	ns_set put $set_id $var_name $item
	lappend sql_string_list ":$var_name"
	incr ctr
    }
    return [join $sql_string_list ", "]
}


ad_proc im_country_select {
    { -locale "" }
    select_name 
    {default ""}
} {
    Return a HTML widget that selects a country code from
    the list of global countries.
} {
    set bind_vars [ns_set create]
    set statement_name "country_code_select"
    set sql "select iso, country_name
	     from country_codes
	     order by lower(country_name)"

    return [im_selection_to_select_box -translate_p 1 -locale $locale $bind_vars $statement_name $sql $select_name $default]
}


ad_proc im_country_options {
    {-include_empty_p 1}
    {-include_empty_name ""}
} {
    Return a list of lists with country_code - country_name
    suitable for ad_form
} {
    set sql "select country_name, iso
	     from country_codes
	     order by lower(country_name)"

    set options [db_list_of_lists country_options $sql]
    if {$include_empty_p} { set options [linsert $options 0 [list $include_empty_name ""]] }
    return $options
}


ad_proc philg_dateentrywidget_default_to_today {column} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
    return [philg_dateentrywidget $column $today]
}


# usage:
#   suppose the variable is called "expiration_date"
#   put "[philg_dateentrywidget expiration_date]" in your form
#     and it will expand into lots of weird generated var names
#   put ns_dbformvalue [ns_getform] expiration_date date expiration_date
#     and whatever the user typed will be set in $expiration_date

ad_proc philg_dateentrywidget {column {default_date "1940-11-03"}} {
    set output "<SELECT name=$column.month>\n"
    set months [long_month_list]
    for {set i 0} {$i < 12} {incr i} {
	append output "<OPTION> [lindex $months $i]\n"
    }

    append output \
"</SELECT>&nbsp;<INPUT NAME=$column.day\
TYPE=text SIZE=3 MAXLENGTH=2>&nbsp;<INPUT NAME=$column.year\
TYPE=text SIZE=5 MAXLENGTH=4>"

    return [ns_dbformvalueput $output $column date $default_date]
}




ad_proc im_dateentrywidget {
    column 
    { value 0 } 
} {
    Replacement for ad_dateentrywidget with calendar.
    Returns form pieces for a date entry widget. A null date may be selected.
    If you would like the default to be null, call with value= ""
} {
    # ns_log Notice "im_dateentrywidget: column=$column, value=$value"

    if {[ns_info name] ne "NaviServer"} {
        ns_share NS
    } else {
        set NS(months) [list January February March April May June \
                            July August September October November December]
    }

    if {$value == 0} {
	# no default, so use today
	set value  [lindex [split [ns_localsqltimestamp] " "] 0]
    } 

    if {$value eq ""} {
	set month ""
	set day ""
	set year ""
    } else {
	lassign [split $value "-"] year month day
	# trim the day, in case we get as well a time stamp
	regexp {^([0-9]+) } $day _ day
    }

    # ------------------------ Day -----------------------------
    # append output [subst {<input name="$column.day" id="$column.day" type="text" size="2" maxlength="2" value="$day">}]
    set output ""
    append output "<input type=\"hidden\" name=\"$column.format\" value=\"DD-MM-YYYY\" >\n"
    append output "<select name=\"$column.day\" id=\"$column.day\" >\n"
    append output "<option value=\"\">--</option>\n"
    for {set i 1} {$i <= 31} {incr i} {
	set selected ""
	if {[string trimleft $day "0"] eq $i} { set selected "selected" }
	append output "<option value=\"$i\" $selected>$i</option>\n"
    }
    append output "</select>\n"

    # ------------------------ Month -----------------------------
    append output "<select name=\"$column.month\" id=\"$column.month\">\n"
    append output "<option value=\"\">--</option>\n"
    regsub "^0" $month "" month
    for {set i 0} {$i < 12} {incr i} {
	if { $month ne "" && $i == $month - 1 } {
	    append output "<option value=[expr 1+$i] selected=\"selected\">[lindex $NS(months) $i]</option>\n"
	} else {
	    append output "<option value=[expr 1+$i]>[lindex $NS(months) $i]</option>\n"
	}
    }
    append output [subst "</select>"]



    append output "&nbsp;"
    append output [subst {<input name="$column.year" id="$column.year" type="text" size="4" maxlength="4" value="$year">}]
    append output "<input type=\"button\" style=\"height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');\" onclick=\"return showCalendarWithDateWidget('$column', 'y-m-d');\">"

     return $output
}






ad_proc im_selection_to_select_box { 
    {-translate_p 1} 
    {-package_key "intranet-core" }
    {-locale "" }
    {-include_empty_p 1}
    {-include_empty_name "--_Please_select_--"}
    {-tag_attributes {} }
    {-size "" }
    bind_vars
    statement_name
    sql 
    select_name 
    { default "" } 
} {
    Expects selection to have a column named id and another named name. 
    Runs through the selection and return a select bar named select_name, 
    defaulted to $default 
    @param tag_attributes Key-value list of tag attributes. 
           Value is to be enclosed by double quotes by the system.
} {
    array set tag_hash $tag_attributes
    set tag_hash(name) $select_name
    if {"" != $size} { set tag_hash(size) $size }  
    set tag_attribute_html ""
    foreach key [array names tag_hash] {
	set val $tag_hash($key)

	# Check for unquoted double quotes.
	if {[regexp {ttt} $val match]} { ad_return_complaint 1 "im_selection_to_select_box: found unquoted double quotes in tag_attributes" }

	append tag_attribute_html "$key=\"$val\" "
    }

    set result "<select $tag_attribute_html>\n"
    if {$include_empty_p} {

	if {"" != $include_empty_name} {
	    set include_empty_name [lang::message::lookup $locale intranet-core.[lang::util::suggest_key $include_empty_name] $include_empty_name]
	}
	append result "<option value=\"\">$include_empty_name</option>\n"
    }
    append result [db_html_select_value_options_multiple \
		       -translate_p $translate_p \
		       -package_key $package_key \
		       -locale $locale \
		       -bind $bind_vars \
		       -select_option $default \
		       $statement_name \
		       $sql \
    ]
    append result "\n</select>\n"
    return $result
}



ad_proc im_options_to_select_box { select_name options { default "" } { tag_attributes "" } } {
    Takes an "options" list (list of list, the inner containing a 
    (category, category_id) as for formbuilder) and returns a formatted
    select box.
} {
    # Deal with JavaScript tags 
    array set tag_hash $tag_attributes
    set tag_hash(name) $select_name
    set tag_attribute_html ""
    foreach key [array names tag_hash] {
        set val $tag_hash($key)
        append tag_attribute_html "$key=\"$val\" "
    }

    set result "<select $tag_attribute_html>\n"
    foreach option $options {
	set value [lindex $option 0]
	set index [lindex $option 1]

	set selected ""
	if {$index == $default} { set selected "selected" }
	append result "<option value=\"$index\" $selected>$value</option>\n"
    }
    append result "</select>\n"
    return $result
}




ad_proc -public db_html_select_value_options_multiple {
    { -bind "" }
    { -select_option "" }
    { -value_index 0 }
    { -option_index 1 }
    { -translate_p 1 }
    { -package_key "intranet-core" }
    { -locale "" }
    stmt_name
    sql
} {
    Generate html option tags with values for an html selection widget. 
    If one of the elements of the select_option list coincedes with one 
    value for it in the  values list, this option will be marked as selected.
    @author yon@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    set select_options ""
    if { $bind ne "" } {
	set options [db_list_of_lists $stmt_name $sql -bind $bind]
    } else {
	set options [uplevel [list db_list_of_lists $stmt_name $sql]]
    }

    foreach option $options {
	set option_string [lindex $option $option_index]

	if { $translate_p && "" != [lindex $option $option_index] } {
	    set translated_value [lang::message::lookup $locale $package_key.[lang::util::suggest_key $option_string] $option_string ]
	} else {
	    set translated_value $option_string
	}

	if { [lsearch $select_option [lindex $option $value_index]] >= 0 } {
	    append select_options "<option value=\"[ns_quotehtml [lindex $option $value_index]]\" selected>$translated_value</option>\n"
	} else {
	    append select_options "<option value=\"[ns_quotehtml [lindex $option $value_index]]\">$translated_value</option>\n"
	}

    }
    return $select_options
}

ad_proc im_selection_to_list_box { 
    {-translate_p "1"} 
    {-locale ""}
    bind_vars 
    statement_name 
    sql 
    select_name 
    { default "" } 
    {size "6"} 
    {multiple ""} 
} {
    Expects selection to have a column named id and another named name. 
    Runs through the selection and return a list bar named select_name, 
    defaulted to $default 
} {
    return "
<select name=\"$select_name\" size=\"$size\" $multiple>
[db_html_select_value_options_multiple -translate_p $translate_p -locale $locale -bind $bind_vars -select_option $default $statement_name $sql]
</select>
"
}

ad_proc im_maybe_prepend_http { orig_query_url } {
    Prepends http to query_url unless it already starts with http://
} {
    set orig_query_url [string trim $orig_query_url]
    set query_url [string tolower $orig_query_url]
    if { $query_url eq "" || $query_url eq "http://"  } {
	return ""
    }
    if { [regexp {^http://.+} $query_url] } {
	return $orig_query_url
    }
    return "http://$orig_query_url"
}


ad_proc im_format_address { street_1 street_2 city state zip } {
    Generates a two line address with appropriate punctuation. 
} {
    set items [list]
    set street ""
    if { $street_1 ne "" } {
	append street $street_1
    }
    if { $street_2 ne "" } {
	if { $street ne "" } {
	    append street "<br>\n"
	}
	append street $street_2
    }
    if { $street ne "" } {
	lappend items $street
    }	
    set line_2 ""
    if { $state ne "" } {
	set line_2 $state
    }	
    if { $zip ne "" } {
	append line_2 " $zip"
    }	
    if { $city ne "" } {
	if { $line_2 eq "" } {
	    set line_2 $city
	} else { 
	    set line_2 "$city, $line_2"
	}
    }
    if { $line_2 ne "" } {
	lappend items $line_2
    }

    if { [llength $items] == 0 } {
	return ""
    } elseif { [llength $items] == 1 } {
	set value [lindex $items 0]
    } else {
	set value [join $items "<br>"]
    }
    return $value
}


ad_proc im_reduce_spaces { string } {Replaces all consecutive spaces with one} {
    regsub -all {[ ]+} $string " " string
    return $string
}

ad_proc im_yes_no_table { yes_action no_action { var_list [list] } { yes_button " [_ intranet-core.Yes] " } {no_button " [_ intranet-core.No] "} } {
    Returns a 2 column table with 2 actions - one for yes and one 
    for no. All the variables in var_list are exported into the to 
    forms. If you want to change the text of either the yes or no 
    button, you can ser yes_button or no_button respectively.
} {
    set hidden_vars ""
    foreach varname $var_list {
	if { [eval uplevel {info exists $varname}] } {
	    upvar $varname value
	    if { $value ne "" } {
		append hidden_vars "<input type=hidden name=$varname value=\"[ns_quotehtml $value]\">\n"
	    }
	}
    }
    return "
<table>
  <tr>
    <td><form method=post action=\"[ns_quotehtml $yes_action]\">
	$hidden_vars
	<input type=submit name=operation value=\"[ns_quotehtml $yes_button]\">
	</form>
    </td>
    <td><form method=get action=\"[ns_quotehtml $no_action]\">
	$hidden_vars
	<input type=submit name=operation value=\"[ns_quotehtml $no_button]\">
	</form>
    </td>
  </tr>
</table>
"
}


ad_proc im_url_with_query { { url "" } } {
    Returns the current url (or the one specified) with all queries 
    correctly attached
} {
    if { $url eq "" } {
	set url [ns_conn url]
    }
    set query [export_ns_set_vars url]
    if { $query ne "" } {
	append url "?$query"
    }
    return $url
}

ad_proc im_memoize_list { 
    { -bind "" } 
    statement_name 
    sql_query 
    { force 0 } 
    {also_memoize_as ""} 
} {
    if { $force } {
        ns_cache_flush -- ns:memoize db_list_of_lists $statement_name $sql_query -bind $bind
    }

    set rows ""
    if {[catch {set rows [ns_memoize db_list_of_lists $statement_name $sql_query -bind $bind]} err_msg]} {
        # If there was an error, let's log a nice error message that includes
        # the statement we executed and any bind variables
        ns_log error "im_memoize_list: Error executing db_list_of_lists $statement_name \"$sql_query\" -bind \"$bind\""
	if { $bind eq "" } {
	    set bind_string ""
	} else {
	    set bind_string [NsSettoTclString $bind]
	    ns_log error "im_memoize_list: Bind Variables: $bind_string"
	}
	error "im_memoize_list: Error executing db_list_of_lists $statement_name \"$sql_query\" -bind \"$bind\"\n\n$bind_string\n\n$err_msg\n\n"
    }

    set result [list]
    foreach row $rows {
	foreach col $row {
	    lappend result $col
	}
    }
    
    if { $also_memoize_as ne "" } {
        ns_log Notice "im_memoize_list: ignoring also_memoize_as $also_memoize_as"
    }

    return $result
}

ad_proc im_memoize_one { { -bind "" } statement_name sql { force 0 } { also_memoize_as "" } } { 
    wrapper for im_memoize_list that returns the first value from
    the sql query.
} {
    set result_list [im_memoize_list -bind $bind $statement_name $sql $force $also_memoize_as]
    if { [llength $result_list] > 0 } {
	return [lindex $result_list 0]
    }
    return ""
}

ad_proc im_maybe_insert_link { previous_page next_page { divider " - " } } {
    Formats prev and next links
} {
    set link ""
    if { $previous_page ne "" } {
	append link "$previous_page"
    }
    if { $next_page ne "" } {
	if { $link ne "" } {
	    append link $divider
	}
	append link "$next_page"
    }
    return $link
}


ad_proc im_select_row_range {sql firstrow lastrow} {
    A tcl proc curtisg wrote to return a sql query that will only 
    contain rows firstrow - lastrow
    2005-03-05 Frank Bergmann: Now extended to work with PostgreSQL
} {
    set rowlimit [expr {$lastrow - $firstrow}]
 
    set oracle_sql "
SELECT
	im_select_row_range_y.*
FROM
	(select 
		im_select_row_range_x.*, 
		rownum fake_rownum 
	from
		($sql) im_select_row_range_x
	where 
		rownum <= $lastrow
	) im_select_row_range_y
WHERE
	fake_rownum >= $firstrow"
	

    set postgres_sql "$sql\nLIMIT $rowlimit OFFSET $firstrow"

    set driverkey [db_driverkey ""]
    switch $driverkey {
	postgresql { return $postgres_sql }
	oracle { return $oracle_sql }
    }
    
    return $sql
}



ad_proc im_email_people_in_group { group_id role from subject message } {
    Emails the message to all people in the group who are acting in
    the specified role
} {
    # Until we use roles, we only accept the following:
    set second_group_id ""
    switch $role {
	"employees" { set second_group_id [im_employee_group_id] }
	"companies" { set second_group_id [im_customer_group_id] }
    }
	
    set criteria [list]
    if { $second_group_id eq "" } {
	if { $role ne "all"  } {
	    return ""
adde	}
    } else {
	lappend criteria "ad_group_member_p(u.user_id, :second_group_id) = 't'"
    }
    lappend criteria "ad_group_member_p(u.user_id, :group_id) = 't'"
    
    set where_clause [join $criteria "\n	and "]

    set email_list [db_list active_users_list_emails \
	    "select email from users_active u where $where_clause"]

    # Convert html stuff to text
    # Conversion fails for forwarded emails... leave it our for now
    # set message [ad_html_to_text $message]
    foreach email $email_list {
	catch { ns_sendmail $email $from $subject $message }
    }
    
}

# --------------------------------------------------------------------------------
# Added by Mark Dettinger <mdettinger@arsdigita.com>
# --------------------------------------------------------------------------------

ad_proc num_days_in_month {month {year 1999}} {
    Returns the number of days in a given month.
    The month can be specified as 1-12, Jan-Dec or January-December.
    The year argument is optional. It's only needed for February.
    If no year is given, it defaults to 1999 (a non-leap-year).
} {
    if { [elem_p $month [month_list]] } { 
	set month [expr [lsearch [month_list] $month]+1]
    }
    if { [elem_p $month [long_month_list]] } { 
	set month [expr [lsearch [long_month_list] $month]+1]
    }
    switch $month {
	1 { return 31 }
	2 { return [leap_year_p $year]?29:28 }
	3 { return 31 }
	4 { return 30 }
	5 { return 31 }
	6 { return 30 }
	7 { return 31 }
	8 { return 31 }
	9 { return 30 }
	10 { return 31 }
	11 { return 30 }
	12 { return 31 }
	default { error "Month $month invalid. Must be in range 1 - 12." }
    }
}



# ---------------------------------------------------------------
# Auto-Login
#
# These procedures generate security tokens for the auto-login 
# process. This process uses a cryptgraphica hash code of the
# user_id and a password in order to let a user login during
# a certain time period.
# ---------------------------------------------------------------

ad_proc -public im_generate_auto_login {
    {-expiry_date ""}
    -user_id:required
} {
    Generates a security token for auto_login
} {
    ns_log Notice "im_generate_auto_login: expiry_date=$expiry_date, user_id=$user_id"
    set user_password ""
    set user_salt ""

    set user_data_sql "
        select	u.password as user_password
        from	users u
        where	u.user_id = :user_id"
    db_0or1row get_user_data $user_data_sql

    # generate the expected auto_login variable
    set auto_login_string "$user_id$user_password$expiry_date"
    return [ns_sha1 $auto_login_string]
}

ad_proc -public im_valid_auto_login_p {
    {-expiry_date ""}
    {-check_user_requires_manual_login_p "1" }
    -user_id:required
    -auto_login:required
} {
    Verifies the auto_login in auto-login variables
    @param expiry_date Expiry date in YYYY-MM-DD format
    @param user_id The users ID
    @param auto_login The security token generated by im_generate_auto_login.

    @author Timo Hentschel (thentschel@sussdorff-roy.com)
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    ns_log Notice "im_valid_auto_login_p: expiry_date=$expiry_date, user_id=$user_id, token=$auto_login"

    # Should the Unregistered Visitor to login without password?
    set enable_anonymous_login_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "EnableUnregisteredUserLoginP" -default 0]

    if {$user_id == 0 && $enable_anonymous_login_p} {
	return 1
    }

    # Quick check on tokens
    set expected_auto_login [im_generate_auto_login -user_id $user_id -expiry_date $expiry_date]
    if {$auto_login ne $expected_auto_login } { return 0 }

    if {$check_user_requires_manual_login_p} {
	# Check if the "require_manual_login" privilege exists to protect high-profile users
	set priv_exists_p [util_memoize [list db_string priv_exists "
		select	count(*)
		from	acs_privileges
		where	privilege = 'require_manual_login'
        "]]
	set user_requires_manual_login_p [im_permission $user_id "require_manual_login"]

	if {$priv_exists_p && $user_requires_manual_login_p} {
	    return 0
	}
    }


    # Ok, the tokens are identical and the guy is allowed to login via auto_login.
    # So we can log the dude in if the "expiry_date" is OK.
    if {"" == $expiry_date} { return 1 }


    # Expiry_date has been set, so the results now depends only on the date comparison.
    if {![regexp {[0-9]{4}-[0-9]{2}-[0-9]{2}} $expiry_date]} { 
	ad_return_complaint 1 "<b>im_valid_auto_login_p</b>:
        You have specified a bad date syntax"
	return 0
    }
    set current_date [db_string current_date "select to_char(sysdate, 'YYYY-MM-DD') from dual"]

    switch [expr 1 + [string compare $current_date $expiry_date]] {
	0 {
	    # current_date < expiry_date: OK
	    return 1
	}
	1 {
	    # current_date == expiry_date: OK
	    return 1
	}
	2 {
	    # current_date > expiry_date: NOT OK
	    return 0
	}
	default {
	    # Should never occur!
	    return 0
	}
    }
}





# ---------------------------------------------------------------
# Execute the code IF the object has the specified object type
# ---------------------------------------------------------------

ad_proc -public im_execute_if_object_type {
    -object_id:required
    -object_type_id:required
    -code:required
} {
    Execute the following code IF the specified
    object has the specified object subtype.
} {
    set tid [db_string object_type_id "select im_biz_object__get_status_id(:object_id)"]
    if {[im_category_is_a $tid $object_type_id]} {
        return [eval $code]
    } else {
        ds_comment "im_execute_if_object_type -object_id $object_id -object_type_id $object_type_id: Object's type=$tid is not a sub-category of $object_type_id. Skipping code."
        return ""
    }
}


# ---------------------------------------------------------------
# Ad-hoc execution of SQL-Queries
# Format for "Developer Service" "pre" display
# ---------------------------------------------------------------

ad_proc -public im_ad_hoc_query {
    {-format plain}
    {-report_name ""}
    {-border 0}
    {-col_titles {} }
    {-col_td_attributes {} }
    {-translate_p 1 }
    {-subtotals_p 0 }
    {-package_key "intranet-core" }
    {-locale ""}
    sql
} {
    Ad-hoc execution of SQL-Queries.
    @format "plain", "hmtl", "cvs", "json" or "xml" - select the output format. Default is "plain".
    @border Table border for HTML output
    @col_titles Optional titles for columns. Normally, columns are taken directly
    from the SQL query and passed through the localization subsystem.
    @translate_p Should the columns be translated?
    @package_key Default package for translated columns
} {
    set result ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    
    regsub -all {[^0-9a-zA-Z]} $report_name "_" report_name_key

    set thousand_separator [lc_get -locale $locale "thousands_sep"]
    # ad_return_complaint 1 $thousand_separator

    # ---------------------------------------------------------------
    # Execute the report. As a result we get:
    #       - bind_rows with list of columns returned and
    #       - lol with the result set
    
    set bind_rows ""
    set err [catch {
        db_with_handle db {
            set selection [db_exec select $db query $sql]
            set lol [list]
            while { [db_getrow $db $selection] } {
                set bind_rows [ad_ns_set_keys $selection]
                set this_result [list]
                for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                    lappend this_result [ns_set value $selection $i]
                }
                lappend lol $this_result
            }
        }
        db_release_unused_handles
    } err_msg]
    
    if {$err} {
        ad_return_complaint 1 "<b>Error executing sql statement</b>:
        <pre>$sql</pre>
        <pre>$err_msg</pre>\n"
        ad_script_abort
    }

    if {"" == $col_titles} { set col_titles $bind_rows }
    set header ""
    foreach title $col_titles {
        if {$translate_p} {
            regsub -all " " $title "_" title_key
	    set key "$package_key.Ad_hoc"
	    if {"" != $report_name} { set key "${key}_${report_name_key}" }
	    set key "${key}_$title_key"
            set title [lang::message::lookup $locale $key $title]
        }
        switch $format {
            plain { append header "$title\t" }
            html { append header "<th>$title</th>" }
            csv { append header "\"$title\";" }
            xml { append header "<column>$title</column>\n" }
            json { append header "\"$title\"\n" }
        }
    }
    switch $format {
        plain { set header $header }
        html { set header "<tr class=rowtitle>\n$header\n</tr>\n" }
        csv { set header $header }
        xml { set header "" }
        json { set header "" }
    }
    
    set row_count 0
    foreach row $lol {

	set col_count 0
	set row_content ""
        foreach col $row {
	    set col_name [lindex $col_titles $col_count]
	    set col [string trim $col]
            switch $format {
                plain { append result "$col\t" }
                html {
                    if {"" == $col} { set col "&nbsp;" }
		    set td_attributes [lindex $col_td_attributes $row_count]
                    append result "<td $td_attributes>$col</td>"
                }
                csv { append result "\"$col\";" }
                xml { 
		    append row_content "<$col_name>[ns_quotehtml $col]</$col_name>\n" 
		}
                json {
		    if {0 == $col_count} { set komma "" } else { set komma "," }
		    regexp -all {\n} $col {\n} col
		    regexp -all {\r} $col {} col
		    append row_content "$komma\"$col_name\": \"[ns_quotehtml $col]\"" 
		}
            }

	    if {$subtotals_p} {
		set sum 0
		if {[info exists subtotals($col_name)]} { set sum $subtotals($col_name) }
		if {"" ne $col} {
		    if {"" ne $sum && [regexp {^[0-9\,\.]+$} $col]} {
			set col [regsub -all $thousand_separator $col ""]
			set sum [expr $sum + $col]
		    } else {
			set sum ""
		    }
		}
		set subtotals($col_name) $sum
	    }

	    incr col_count
        }
	
        # Change to next line
        switch $format {
            plain { append result "\n" }
            html { append result "</tr>\n<tr $bgcolor([expr {$row_count % 2}])>" }
            csv { append result "\n" }
            xml { append result "<row>\n$row_content</row>\n" }
            json { 
		if {0 == $row_count} { set komma "" } else { set komma "," }
		append result "$komma\n{$row_content}" 
	    }
        }
        incr row_count
    }

    set footer ""
    if {$subtotals_p} {
	foreach col_name $bind_rows {
	    set subtotal ""
	    if {[info exists subtotals($col_name)]} { set subtotal $subtotals($col_name) }
	    append footer "<td><b>[lc_numeric $subtotal "" $locale]</b></td>"
	    # append footer "<td><b>$subtotal</b></td>"
	}
	set footer "<tr>$footer</tr>\n"
    }

    switch $format {
        plain { return "$header\n$result"  }
        html { 
	    return "
                <table border=$border>
                $header
                <tr $bgcolor(0)>
                $result
                </tr>
                $footer
                </table>
            "
        }
        csv { return "$header\n$result"  }
        xml { return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<result>\n$result\n</result>\n" }
        json { return $result }
    }
}

# ---------------------------------------------------------------
# Extended Login Procedure
# ---------------------------------------------------------------

ad_proc im_require_login {
    { -no_redirect_p 0 }
} {
    Replaced auth::require_login or ad_maybe_redirect_for_registration.
    In addition, allows for auto_login or basic authentication.
} {
    # --------------------------------------------------------
    # Check for HTTP "basic" authorization
    # Example: Authorization=Basic cHJvam9wOi5mcmFiZXI=
    #
    set header_vars [ns_conn headers]
    set basic_auth [ns_set get $header_vars "Authorization"]
    set basic_auth_userpass ""
    set basic_auth_username ""
    set basic_auth_password ""
    if {[regexp {^([a-zA-Z_]+)\ (.*)$} $basic_auth match method userpass_base64]} {
	set basic_auth_userpass [base64::decode $userpass_base64]
	regexp {^([^\:]+)\:(.*)$} $basic_auth_userpass match basic_auth_username basic_auth_password
    }
    if {"" != $basic_auth_username} {
	set basic_auth_user_id [db_string userid "select user_id from users where lower(username) = lower(:basic_auth_username)" -default ""]
	if {"" == $basic_auth_user_id} {
	    set basic_auth_user_id [db_string userid "select party_id from parties where lower(email) = lower(:basic_auth_username)" -default ""]
	}
	
	# Successful 
	if {"" != $basic_auth_user_id} { 
	    ns_log Notice "im_require_login: Successful Basic authentication with user_id=$basic_auth_user_id"
	    return $basic_auth_user_id 
	} else {
	    ns_log Notice "im_require_login: Failed Basic authentication with user_id=$basic_auth_user_id"
	}
    }

    # --------------------------------------------------------
    # Check for Auto-Login token
    # Example: user_id?123&auto_login=36483CA32D586
    #
    set form_vars [ns_conn form]
    if {"" == $form_vars} { set form_vars [ns_set create] }

    set user_id [ns_set get $form_vars "user_id"]
    set auto_login [ns_set get $form_vars "auto_login"]
    set valid_login [im_valid_auto_login_p -user_id $user_id -auto_login $auto_login]
    if {$valid_login} {
	ns_log Notice "im_require_login: Successful Auto-Login authentication with user_id=$user_id"
	return $user_id
    }

    # --------------------------------------------------------
    # Check for OpenACS authenticated session
    #
    set user_id [ad_conn user_id]
    if {0 != $user_id} { 
	ns_log Notice "im_require_login: Successful OpenACS authentication with user_id=$user_id"
	return $user_id 
    }

    # --------------------------------------------------------
    # no_redirect indicates that there should redirect to authentication.
    # So we would stop here
    if {$no_redirect_p} { 
	ns_log Notice "im_require_login: Failed authentication and no_redirect_p=1, so returning user_id=0 here"
	return "" 
    }

    # --------------------------------------------------------
    # Invoke standard OpenACS redirection to /register/
    ns_log Notice "im_require_login: Failed authentication, redirecting to /register/"
    return [auth::require_login]
}


# ---------------------------------------------------------------
# Display a generic table contents
# ---------------------------------------------------------------

ad_proc im_generic_table_component {
    -table_name
    -select_column
    -select_value
    { -order_by "" }
    { -exclude_columns "" }
    { -locale "" }
} {
    Takes a table name as a parameter and displays its content.
    This function is not able to dereference values. Please use
    a user created SQL view if that is necessary.
    Uses the localization function to allow the user to create
    pretty names for table columns
} {
    set params [list \
	[list table_name $table_name] \
	[list select_column $select_column] \
	[list select_value $select_value] \
	[list order_by $order_by] \
	[list exclude_columns $exclude_columns] \
	[list return_url [im_url_with_query]] \
    ]
    set result [ad_parse_template -params $params "/packages/intranet-core/www/components/generic-table-component"]
    set component_title [lang::message::lookup $locale intranet-core.Generic_Table_Header_$table_name $table_name]
    return [im_table_with_title $component_title $result]
}



# ---------------------------------------------------------------
# Cached version of db_table_exists
# ---------------------------------------------------------------

ad_proc im_table_exists { table_name } {
    Cached version of db_table_exists
} {
    return [util_memoize [list db_table_exists $table_name]]
}

ad_proc im_column_exists { table_name column_name} {
    Cached version of db_column_exists
} {
    return [util_memoize [list db_column_exists $table_name $column_name]]
}


# ---------------------------------------------------------------
# Log performance
# ---------------------------------------------------------------

ad_proc im_performance_log { 
    { -location "undefined" }
} {
    Write a log entry into the database
} {
    # ---------------------------------------------------
    # Check if enabled
    set perf_p [parameter::get_from_package_key -package_key "intranet-core" -parameter EnablePerformanceLogging -default 0]
    if {!$perf_p} { return }
    if {![im_table_exists "im_performance_log"]} { return }


    # ---------------------------------------------------
    # Extract variables from form and HTTP header
    set header_vars [ns_conn headers]

    # Get intersting info
    set user_id [ad_conn user_id]

    # IP Addresses
    set client_ip [ns_set get $header_vars "Client-ip"]
    set peer_ip [ns_conn peeraddr]
    set forwarded_ip [string trim [ns_set get $header_vars "X-Forwarded-For"]]

    # Other
    set referer_url [ns_set get $header_vars "Referer"]
    set cookie [ns_set get $header_vars "Cookie"]
    set clock_clicks [clock clicks]
    set url [ns_conn url]
    set url_params [export_ns_set_vars url]

    set ad_session_id ""
    set ad_user_login ""
    foreach part [split $cookie ";"] {
	set c [split $part "="]
	set cookie_var [string trim [lindex $c 0]]
	set cookie_val [string trim [lindex $c 1]]
	set $cookie_var $cookie_val
    }


    ns_log Notice "im_performance_log: user_id	= $user_id"
    ns_log Notice "im_performance_log: url	= $url"
    ns_log Notice "im_performance_log: params	= $url_params"
    ns_log Notice "im_performance_log: client_ip= $client_ip"
    ns_log Notice "im_performance_log: forw_ip	= $forwarded_ip"
    ns_log Notice "im_performance_log: peer_ip	= $peer_ip"
    ns_log Notice "im_performance_log: cookie	= $cookie"
    ns_log Notice "im_performance_log: clicks	= $clock_clicks"
    ns_log Notice "im_performance_log: ad_session_id	= $ad_session_id"
    ns_log Notice "im_performance_log: ad_user_login	= $ad_user_login"
    ns_log Notice "im_performance_log: 	= $"

    db_dml im_header "
		insert into im_performance_log (
			log_id,
			user_id,
			client_ip,
			session_id,
			url,
			url_params,
			location,
			clock_time,
			clock_clicks
		) values (
			nextval('im_performance_log_seq'),
			:user_id,
			:peer_ip,
			:ad_session_id,
			:url,
			:url_params,
			:location,
			now(),
			:clock_clicks
		)
    "
}




ad_proc -public im_object_super_types { 
    -object_type:required
} {
    Returns the list of the current object type and all
    of its supertypes.
    Example for im_timesheet_task: {acs_object im_business_object im_project im_timesheet_task}
} {
    set object_type_hierarchy {acs_object}
    set otype $object_type

    # while the object type not yet in the list of super-types:
    while {$otype ne "" && ([lsearch $object_type_hierarchy $otype] < 0)} {
	lappend object_type_hierarchy $otype
	set otype [db_string super_type "select supertype from acs_object_types where object_type = :otype" -default ""]
    }
    return $object_type_hierarchy
}





ad_proc -public im_package_exists_p { package_key } {
    Returns true if the package_key exists
} {
    set exists_p [util_memoize [list db_string package_exists "select count(*) from apm_packages where package_key = '$package_key'"]]
    return $exists_p
}



ad_proc -public im_object_name { object_id } {
    Returns cached name of object
} {
    if {"" eq $object_id || "null" eq $object_id} { return "" }
    return [util_memoize [list acs_object_name $object_id]]
}



ad_proc -public im_httpget { 
    url
    {timeout 30}
    {depth 10}
} {
    Wrapper for system HTTP functionality
} {
    # Use the wrapper library from WU Vienna
    set result_list [util::http::get -url $url -timeout $timeout -max_depth $depth]
    array set result_hash $result_list
    set result ""
    if {[info exists result_hash(page)]} {
	set result $result_hash(page)
    }
    return $result
}


ad_proc -public im_httpost { 
    url
    {rqset ""}
    {qsset ""}
    {type ""}
    {timeout 30}
} {
    Wrapper for system HTTP functionality
} {
    # Use the wrapper library from WU Vienna
    # return [util::http::get -url $url -timeout $timeout -max_depth $depth]
    ns_httppost $url $rqset $qsset $type $timeout
}



proc string2hex {string} {
    set where 0
    set res {}
    while {$where<[string length $string]} {
        set str [string range $string $where [expr $where+15]]
        if {![binary scan $str H* t] || $t==""} break
        regsub -all (....) $t {\1 } t4
        regsub -all (..) $t {\1 } t2
        set asc ""
        foreach i $t2 {
            scan $i %2x c
            append asc [expr {$c>=32 && $c<=127? [format %c $c]: "."}]
        }
        lappend res [format "%7.7x: %-42s %s" $where $t4  $asc]
        incr where 16
    }
    join $res \n
}
