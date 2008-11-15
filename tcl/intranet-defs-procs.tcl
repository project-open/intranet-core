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


# ------------------------------------------------------------------
# CSV File Parser
# ------------------------------------------------------------------

ad_proc im_csv_get_values { file_content {separator ","}} {
    Get the values from a CSV (Comma Separated Values) file
    and generate an list of list of values. Deals with:
    <ul>
    <li>Fields enclosed by double quotes
    <li>Komma or Semicolon separators
    <li>Quoted field contents
    </ul>
    The state machine can be in one of two states:
    <ul>
    <li>"field_start": Starting reading a field, either starting
        with a quote character (double quote, single quote) or
        with a non-quote character.
    <li>"field": Reading a field, either quoted or not quoted
        The variable "quote" contains the quote character with reading
        the field content.
    <li>"separator": Reading a separator, either a "," or a ";"
    </ul>

} {
    set debug 0

    set csv_files [split $file_content "\n"]
    set csv_files_len [llength $csv_files]
    set result_list_of_lists [list]
	
    # get start with 1 because we use the function im_csv_split to get the header
    for {set line_num 1} {$line_num < $csv_files_len} {incr line_num} {

	set line [lindex $csv_files $line_num]
	if {[empty_string_p $line]} {
	    incr line_num
	    continue
	}
	if {$debug} {ns_log notice "im_csv_get_values: line=$line num=$line_num"}
	set result_list [im_csv_split $line $separator]
	lappend result_list_of_lists $result_list
    }
    return $result_list_of_lists
}


# ------------------------------------------------------------------
# CSV Line Parser
# ------------------------------------------------------------------

ad_proc im_csv_split { line {separator ","}} {
    Splits a line from a CSV (Comma Separated Values) file
    into an array of values. Deals with:
    <ul>
    <li>Fields enclosed by double quotes
    <li>Komma or Semicolon separators
    <li>Quoted field contents
    </ul>
    The state machine can be in one of two states:
    <ul>
    <li>"field_start": Starting reading a field, either starting
        with a quote character (double quote, single quote) or
        with a non-quote character.
    <li>"field": Reading a field, either quoted or not quoted
        The variable "quote" contains the quote character with reading
        the field content.
    <li>"separator": Reading a separator, either a "," or a ";"
    </ul>

} {
    set debug 0

    set result_list [list]
    set pos 0
    set len [string length $line]
    set quote ""
    set state "field_start"
    set field ""

    while {$pos <= $len} {
	set char [string index $line $pos]
	set next_char [string index $line [expr $pos+1]]
	if {$debug} {ns_log notice "im_csv_split: pos=$pos, char=$char, state=$state"}

	switch $state {
	    "field_start" {

		# We're before a field. Next char may be a quote
		# or not. Skip white spaces.

		if {[string is space $char]} {

		    if {$debug} {ns_log notice "im_csv_split: field_start: found a space: '$char'"}
		    incr pos

		} else {

		    # Skip the char if it was a quote
		    set quote_pos [string first $char "\"'"]
		    if {$quote_pos >= 0} {
			if {$debug} {ns_log notice "im_csv_split: field_start: found quote=$char"}
			# Remember the quote char
			set quote $char
			# skip the char
			incr pos
		    } else {
			if {$debug} {ns_log notice "im_csv_split: field_start: unquoted field"}
			set quote ""
		    }
		    # Initialize the field value for the "field" state
		    set field ""
		    # "Switch" to reading the field content
		    set state "field"
		}
	    }

	    "field" {

		# We are reading the content of a field until we
		# reach the end, either marked by a matching quote
		# or by the "separator" if the field was not quoted

		# Check for a duplicated quote when in quoted mode.
		if {"" != $quote && [string equal $char $quote] && [string equal $next_char $quote]} {
		    append field $char
		    incr pos
		    incr pos    
		} else {


		    # Check if we have reached the end of the field
		    # either with the matching quote of with the separator:
		    if {"" != $quote && [string equal $char $quote] || "" == $quote && [string equal $char $separator]} {

			if {$debug} {ns_log notice "im_csv_split: field: found quote or term: $char"}

			# Skip the character if it was a quote
			if {"" != $quote} { incr pos }

			# Trim the field if it was not quoted
			if {"" == $quote} { set field [string trim $field] }

			lappend result_list $field
			set state "separator"

		    } else {

			if {$debug} {ns_log notice "im_csv_split: field: found a field char: $char"}
			append field $char
			incr pos

		    }
		}
	    }

	    "separator" {

		# We got here after finding the end of a "field".
		# Now we expect a separator or we have to throw an
		# error otherwise. Skip whitespaces.
		
		if {[string is space $char]} {
		    if {$debug} {ns_log notice "im_csv_split: separator: found a space: '$char'"}
		    incr pos
		} else {
		    if {[string equal $char $separator]} {
			if {$debug} {ns_log notice "im_csv_split: separator: found separator: '$char'"}
			incr pos
			set state "field_start"
		    } else {
			if {$debug} {ns_log error "im_csv_split: separator: didn't find separator: '$char'"}
			set state "field_start"
		    }
		}
	    }
	    # Switch, while and proc ending
	}
    }

    # Add the field to the result if we reach the end of the line
    # in state "field".
    if {"field" == $state} {
	lappend result_list $field	
    }

    return $result_list
}



# ------------------------------------------------------------------
# System Functions
# ------------------------------------------------------------------

ad_proc -public im_bash_command { } {
    Returns the path to the BASH command shell, depending on the
    operating system (Windows, Linux or Solaris).
    The resulting bash command can be used with the "-c" option 
    to execute arbitrary bash commands.
} {

    # Find out if platform is "unix" or "windows"
    global tcl_platform
    set platform [lindex $tcl_platform(platform) 0]

    switch $platform {
	unix
	{
	    # windows means running under CygWin
	    return "/bin/bash"
	}
	windows {
	    # "windows" means running under CygWin
	    set acs_root_dir [acs_root_dir]
	    set acs_root_dir_list [split $acs_root_dir "/"]
	    set acs_install_dir_list [lrange $acs_root_dir_list 0 end-1]
	    set acs_install_dir [join $acs_install_dir_list "/"]
	    return "$acs_install_dir/cygwin/bin/bash"
	}
	
	default {
	    ad_return_complaint 1 "Internal Error:<br>
            Unknown platform '$platform' found.<br>
            Expected 'windows' or 'unix'."
	}    
    }
}


ad_proc -public im_exec_dml { { -dbn "" } sql_name sql } {
    Execute a DML procedure (function in PostgreSQL) without
    regard of the database type. Basicly, the procedures wraps
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
		db_dml $sql_name \"select $sql;\"
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
    return [util_memoize "im_package_core_id_helper"]
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

ad_proc -public im_exec_dml { { -dbn "" } sql_name sql } {
    Execute a DML procedure (function in PostgreSQL) without
    regard of the database type. Basicly, the procedures wraps
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
                db_string $sql_name \"select $sql\"
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


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

ad_proc -public im_opt_val { var_name } {
    Acts like a "$" to evaluate a variable, but
    returns "" if the variable is not defined,
    instead of an error.<BR>
    If no value is found, im_opt_val checks wether there is
    a HTTP variables with the same name, either in the URL or 
    as part of a POST.<br>
    This function is useful for passing optional
    variables to components, if the component can't
    be sure that the variable exists in the callers
    context.
} {
    # Check if the variable exists in the parent's caller environment
    upvar $var_name var
    if [exists_and_not_null var] { 
	return $var
    }
    
    # get from the list of all HTTP variables.
    # ns_set get returns "" if not found
    set form_vars [ns_conn form]
    if {"" == $form_vars} { set form_vars [ns_set create] }
    set value [ns_set get $form_vars $var_name]
    ns_log Notice "im_opt_val: found variable='$var_name' with value='$value' in HTTL header"
    return $value
} 


ad_proc -public im_parameter {
    name
    package_key
    {default ""}
} {
    Not tested or used yet!!!<br>
    Wrapper for ad_parameter with the extra functionality to create
    the parameter if it didn't exist before.<br>
    With ]project-open[ we don't need package ids because all ]po[
    packages are singletons.
    im_parameter "SystemCSS" "intranet-core" "/intranet/style/style.default.css"
} {

    # Get the package_id. That's because a single package (identified
    # by a "package_key" can be mounted several times in the system.
    db_1row get_package_id "
select 
	count(*) as param_count, 
	min(package_id) as package_id
from 
	apm_packages 
where 
	package_key = :package_key
"

    # Check if the user has specified an non-existing package key.
    # param_count > 1 is impossible because all intranet packages
    # are singleton packages
    if {0 == $param_count} {
	ad_return_complaint 1 "<li><b>Internal Error</b><br>
        Unknown package key '$package_key'.<br>
        Please contact your support partner and report this error."
	return ""
    }

    set parameter_p [db_exec_plsql parameter_count {
        begin
        :1 := apm.parameter_p(
		package_key => :package_key,
		parameter_name => :name
	);
	end;
    }]

    if {!$parameter_p} {

	# didn't exist yet - create the parameter

	set parameter_id [db_exec_plsql create_parameter {
	    begin
	    :1 := apm.register_parameter(
		 parameter_id => :parameter_id,
		 parameter_name => :parameter_name,
		 package_key => :package_key,
		 description => :description,
		 datatype => :datatype,
		 default_value => :default_value,
		 section_name => :section_name,
		 min_n_values => :min_n_values,
		 max_n_values => :max_n_values
	    );
	    end;
	}]

	set value $default

    } else {

	# Get the parameter
	set value [parameter::get -package_id $package_id -parameter $name -default $default]

    }
    
    return $value
}

# Basic Intranet Parameter Shortcuts
ad_proc im_url_stub {} {
    return [ad_parameter -package_id [im_package_core_id] IntranetUrlStub "" "/intranet"]
}

ad_proc im_url {} {
    return [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""][im_url_stub]
}

# ------------------------------------------------------------------
#
# ------------------------------------------------------------------

# Find out the user name
ad_proc -public im_name_from_user_id {user_id} {
    return [util_memoize "im_name_from_user_id_helper $user_id"]
}

ad_proc -public im_name_from_user_id_helper {user_id} {
    set user_name "&lt;unknown&gt;"
    catch { set user_name [db_string uname "select im_name_from_user_id(:user_id)"] } err
    return $user_name
}


# Find out the user email
ad_proc -public im_email_from_user_id {user_id} {
    return [util_memoize "im_email_from_user_id_helper $user_id"]
}

ad_proc -public im_email_from_user_id_helper {user_id} {
    set user_email "unknown@unknown.com"
    if ![catch { 
	set user_email [db_string get_user_email {
	select	email
	from	parties
	where	party_id = :user_id
    }] } errmsg] {
	# no errors
    }
    return $user_email
}


ad_proc im_employee_select_optionlist { {user_id ""} } {
    set employee_group_id [im_employee_group_id]
    return [db_html_select_value_options_multiple -translate_p 0 -select_option $user_id im_employee_select_options "
select
	u.user_id, 
	im_name_from_user_id(u.user_id) as name
from
	registered_users u,
	group_distinct_member_map gm
where
	u.user_id = gm.member_id
	and gm.group_id = $employee_group_id
order by lower(im_name_from_user_id(u.user_id))"]
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
    if { [empty_string_p $default] } {
	set default [ad_partner_upvar $field_name 1]
    }
    set exclude_var_list [list $field_name]
    foreach var $var_list_not_to_export {
	lappend exclude_var_list $var
    }
    set url "[ns_conn url]?"
    set query_args [export_ns_set_vars url $exclude_var_list]
    if { ![empty_string_p $query_args] } {
	append url "$query_args&"
    }
    # Count up the number of characters we display to help us select either
    # text links or a select box
    set text_length 0
    foreach { value text } $pairs {
	set text_length [expr $text_length + [string length $text]]
	if { [string compare $value $default] == 0 } {
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\" selected>$text</option>\n"
	} else {
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\">$text</option>\n"
	}
    }
    return "
<form method=get action=\"[ns_conn url]\">
[export_ns_set_vars form $exclude_var_list]
<select name=\"[ad_quotehtml $field_name]\">
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

    set multiple ""
    if {$multiple_p} { 
	set multiple "multiple" 
	set size "size=\"$size\""
    } else {
	set size ""
    }

    if { [empty_string_p $default] } {
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
	    set l10n_key [lang::util::suggest_key $text]
            set text_tr [lang::message::lookup "" intranet-core.$l10n_key $text]
        } else {
            set text_tr $text
        }

	set item "<option value=\"[ad_urlencode $value]\">$text_tr</option>"
	if {$multiple_p} {
	    if {[lsearch $default $value] >= 0} {
		set item "<option value=\"[ad_urlencode $value]\" selected>$text_tr</option>"
	    }
	} else {
	    if {[string compare $value $default] == 0} {
		set item "<option value=\"[ad_urlencode $value]\" selected>$text_tr</option>"
	    }
	}
	lappend items $item
    }
    return "
    <select name=\"[ad_quotehtml $field_name]\" $size $multiple>
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
	    if { [empty_string_p [string trim $value]] } {
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


ad_proc im_country_select {select_name {default ""}} {
    Return a HTML widget that selects a country code from
    the list of global countries.
} {
    set bind_vars [ns_set create]
    set statement_name "country_code_select"
    set sql "select iso, country_name
	     from country_codes
	     order by lower(country_name)"

    return [im_selection_to_select_box -translate_p 1 $bind_vars $statement_name $sql $select_name $default]
}


ad_proc im_country_options {} {
    Return a list of lists with country_code - country_name
    suitable for ad_form
} {
    set sql "select country_name, iso
	     from country_codes
	     order by lower(country_name)"

    return [db_list_of_lists country_options $sql]
}


ad_proc -public im_category_from_id { 
    {-translate_p 1}
    category_id 
} {
    Get a category_name from 
} {
    if {"" == $category_id} { return "" }
    if {0 == $category_id} { return "" }
    set category_name [util_memoize "db_string cat \"select im_category_from_id($category_id)\" -default {}"]
    set category_key [lang::util::suggest_key $category_name]
    if {$translate_p} {
	set category_name [lang::message::lookup "" intranet-core.$category_key $category_name]
    }

    return $category_name
}


# Hierarchical category select:
# Uses the im_category_hierarchy table to determine
# the hierarchical structure of the category type.
#
ad_proc im_category_select {
    {-translate_p 1}
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-plain_p 0}
    {-super_category_id 0}
    {-cache_interval 3600}
    category_type
    select_name
    { default "" }
} {
    Hierarchical category select:
    Uses the im_category_hierarchy table to determine
    the hierarchical structure of the category type.
} {
    return [util_memoize [list im_category_select_helper -translate_p $translate_p -include_empty_p $include_empty_p -include_empty_name $include_empty_name -plain_p $plain_p -super_category_id $super_category_id $category_type $select_name $default] $cache_interval]
}

ad_proc im_category_select_helper {
    {-translate_p 1}
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-plain_p 0}
    {-super_category_id 0}
    {-cache_interval 3600}
    category_type
    select_name
    { default "" }
} {
    Returns a formatted "option" widget with hierarchical
    contents.
    @param super_category_id determines where to start in the category hierarchy
} {
    if {$plain_p} {
	return [im_category_select_plain -translate_p $translate_p -include_empty_p $include_empty_p -include_empty_name $include_empty_name $category_type $select_name $default]
    }

    set super_category_sql ""
    if {0 != $super_category_id} {
	set super_category_sql "
	    and category_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :super_category_id
	    )
	"
    }

    # Read the categories into the a hash cache
    # Initialize parent and level to "0"
    set sql "
        select
                category_id,
                category,
                category_description,
                parent_only_p,
                enabled_p
        from
                im_categories
        where
                category_type = :category_type
		and enabled_p = 't'
		$super_category_sql
        order by lower(category)
    "
    db_foreach category_select $sql {
        set cat($category_id) [list $category_id $category $category_description $parent_only_p $enabled_p]
        set level($category_id) 0
    }

    # Get the hierarchy into a hash cache
    set sql "
        select
                h.parent_id,
                h.child_id
        from
                im_categories c,
                im_category_hierarchy h
        where
                c.category_id = h.parent_id
                and c.category_type = :category_type
		$super_category_sql
        order by lower(category)
    "

    # setup maps child->parent and parent->child for
    # performance reasons
    set children [list]
    db_foreach hierarchy_select $sql {
	if {![info exists cat($parent_id)]} { continue}
	if {![info exists cat($child_id)]} { continue}
        lappend children [list $parent_id $child_id]
    }

    # Calculate the level(category) and direct_parent(category)
    # hash arrays. Please keep in mind that categories from a DAG 
    # (directed acyclic graph), which is a generalization of a tree, 
    # with "multiple inheritance" (one category may have more then
    # one direct parent).
    # The algorithm loops through all categories and determines
    # the depth-"level" of the category by the level of a direct
    # parent+1.
    # The "direct_parent" relationship is different from the
    # "category_hierarchy" relationship stored in the database: 
    # The category_hierarchy is the "transitive closure" of the
    # "direct_parent" relationship. This means that it also 
    # contains the parent's parent of a category etc. This is
    # useful in order to quickly answer SQL queries such as
    # "is this catagory a subcategory of that one", because the
    # this can be mapped to a simple lookup in category_hierarchy 
    # (because it contains the entire chain). 

    set count 0
    set modified 1
    while {$modified} {
        set modified 0
        foreach rel $children {
            set p [lindex $rel 0]
            set c [lindex $rel 1]
            set parent_level $level($p)
            set child_level $level($c)
            if {[expr $parent_level+1] > $child_level} {
                set level($c) [expr $parent_level+1]
                set direct_parent($c) $p
                set modified 1
            }
        }
        incr count
        if {$count > 1000} {
            ad_return_complaint 1 "Infinite loop in 'im_category_select'<br>
            The category type '$category_type' is badly configured and contains
            and infinite loop. Please notify your system administrator."
            return "Infinite Loop Error"
        }
#	ns_log Notice "im_category_select: count=$count, p=$p, pl=$parent_level, c=$c, cl=$child_level mod=$modified"
    }

    set base_level 0
    set html ""
    if {$include_empty_p} {
        append html "<option value=\"\">$include_empty_name</option>\n"
        if {"" != $include_empty_name} {
            incr base_level
        }
    }

    # Sort the category list's top level. We currently sort by category_id,
    # but we could do alphabetically or by sort_order later...
    set category_list [array names cat]
    set category_list_sorted [lsort $category_list]

    # Now recursively descend and draw the tree, starting
    # with the top level
    foreach p $category_list_sorted {
        set p [lindex $cat($p) 0]
        set enabled_p [lindex $cat($p) 4]
	if {"f" == $enabled_p} { continue }
        set p_level $level($p)
        if {0 == $p_level} {
            append html [im_category_select_branch -translate_p $translate_p $p $default $base_level [array get cat] [array get direct_parent]]
        }
    }

    return "
<select name=\"$select_name\">
$html
</select>
"
}


ad_proc im_category_select_branch { 
    {-translate_p 0}
    parent 
    default 
    level 
    cat_array 
    direct_parent_array 
} {
    Returns a list of html "options" displaying an options hierarchy.
} {
    if {$level > 10} { return "" }

    array set cat $cat_array
    array set direct_parent $direct_parent_array

    set category [lindex $cat($parent) 1]
    if {$translate_p} {
	set category_key "intranet-core.[lang::util::suggest_key $category]"
	set category [lang::message::lookup "" $category_key $category]
    }

    set parent_only_p [lindex $cat($parent) 3]

    set spaces ""
    for {set i 0} { $i < $level} { incr i} {
	append spaces "&nbsp; &nbsp; &nbsp; &nbsp; "
    }

    set selected ""
    if {$parent == $default} { set selected "selected" }
    set html ""
    if {"f" == $parent_only_p} {
        set html "<option value=\"$parent\" $selected>$spaces $category</option>\n"
	incr level
    }


    # Sort by category_id, but we could do alphabetically or by sort_order later...
    set category_list [array names cat]
    set category_list_sorted [lsort $category_list]

    foreach cat_id $category_list_sorted {
	if {[info exists direct_parent($cat_id)] && $parent == $direct_parent($cat_id)} {
	    append html [im_category_select_branch -translate_p $translate_p $cat_id $default $level $cat_array $direct_parent_array]
	}
    }

    return $html
}


ad_proc im_category_select_plain { 
    {-translate_p 1} 
    {-include_empty_p 1} 
    {-include_empty_name "--_Please_select_--"} 
    category_type 
    select_name 
    { default "" } 
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type

    set sql "
	select *
	from
		(select
			category_id,
			category,
			category_description
		from
			im_categories
		where
			category_type = :category_type
			and (enabled_p = 't' OR enabled_p is NULL)
		) c
	order by lower(category)
    "

    return [im_selection_to_select_box -translate_p $translate_p -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars category_select $sql $select_name $default]
}


ad_proc im_category_select_multiple { 
    {-translate_p 1}
    category_type 
    select_name 
    { default "" } 
    { size "6"} 
    { multiple ""}
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
	     from im_categories
	     where category_type = :category_type
	     order by lower(category)"
    return [im_selection_to_list_box -translate_p $translate_p $bind_vars category_select $sql $select_name $default $size multiple]
}    


ad_proc -public template::widget::im_category_tree { element_reference tag_attributes } {
    Category Tree Widget

    @param category_type The name of the category type (see categories
	   package) for valid choice options.

    The widget takes a tree from the categories package and displays all
    of its leaves in an indented drop-down box. For details on creating
    and modifying widgets please see the documentation.
} {
    upvar $element_reference element
    if { [info exists element(custom)] } {
	set params $element(custom)
    } else {
	return "Intranet Category Widget: Error: Didn't find 'custom' parameter.<br>
	Please use a Parameter such as:
	<tt>{custom {category_type \"Intranet Company Type\"}} </tt>"
    }

    # Get the "category_type" parameter that defines which
    # category to display
    set category_type_pos [lsearch $params category_type]
    if { $category_type_pos >= 0 } {
	set category_type [lindex $params [expr $category_type_pos + 1]]
    } else {
	return "Intranet Category Widget: Error: Didn't find 'category_type' parameter"
    }

    # Get the "plain_p" parameter to determine if we should
    # display the categories as an (ordered!) plain list
    # instead of a hierarchy.
    #
    set plain_p 0
    set plain_p_pos [lsearch $params plain_p]
    if { $plain_p_pos >= 0 } {
	set plain_p [lindex $params [expr $plain_p_pos + 1]]
    }

    # Get the "translate_p" parameter to determine if we should
    # translate the category items
    #
    set translate_p 0
    set translate_p_pos [lsearch $params translate_p]
    if { $translate_p_pos >= 0 } {
	set translate_p [lindex $params [expr $translate_p_pos + 1]]
    }

    # Get the "include_empty_p" parameter to determine if we should
    # include an empty first line in the widget
    #
    set include_empty_p 1
    set include_empty_p_pos [lsearch $params include_empty_p]
    if { $include_empty_p_pos >= 0 } {
	set include_empty_p [lindex $params [expr $include_empty_p_pos + 1]]
    }

    array set attributes $tag_attributes
    set category_html ""
    set field_name $element(name)

    set default_value_list $element(values)

    set default_value ""
    if {[info exists element(value)]} {
	set default_value $element(values)
    }

    if {0} {
	set debug ""
	foreach key [array names element] {
	    set value $element($key)
	    append debug "$key = $value\n"
	}
	ad_return_complaint 1 "<pre>$element(name)\n$debug\n</pre>"
	return
    }


    if { "edit" == $element(mode)} {
	append category_html [im_category_select -translate_p 1 -include_empty_p $include_empty_p -include_empty_name "" -plain_p $plain_p $category_type $field_name $default_value]


    } else {
	if {"" != $default_value && "\{\}" != $default_value} {
	    append category_html [db_string cat "select im_category_from_id($default_value) from dual" -default ""]
	}
    }
    return $category_html
}

# usage:
#   suppose the variable is called "expiration_date"
#   put "[philg_dateentrywidget expiration_date]" in your form
#     and it will expand into lots of weird generated var names
#   put ns_dbformvalue [ns_getform] expiration_date date expiration_date
#     and whatever the user typed will be set in $expiration_date

ad_proc philg_dateentrywidget {column {default_date "1940-11-03"}} {
    ns_share NS

    set output "<SELECT name=$column.month>\n"
    for {set i 0} {$i < 12} {incr i} {
	append output "<OPTION> [lindex $NS(months) $i]\n"
    }

    append output \
"</SELECT>&nbsp;<INPUT NAME=$column.day\
TYPE=text SIZE=3 MAXLENGTH=2>&nbsp;<INPUT NAME=$column.year\
TYPE=text SIZE=5 MAXLENGTH=4>"

    return [ns_dbformvalueput $output $column date $default_date]
}


ad_proc philg_dateentrywidget_default_to_today {column} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
    return [philg_dateentrywidget $column $today]
}

ad_proc im_selection_to_select_box { 
    {-translate_p 1} 
    {-include_empty_p 1}
    {-include_empty_name "--_Please_select_--"}
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
} {
    # Size set? Then add to <select>
    set size_html ""
    if {"" != $size} { set size_html "size=$size" }

    set result "<select name=\"$select_name\" $size_html>\n"
    if {$include_empty_p} {

	if {"" != $include_empty_name} {
	    set include_empty_name [lang::message::lookup "" intranet-core.[lang::util::suggest_key $include_empty_name] $include_empty_name]
	}
	append result "<option value=\"\">$include_empty_name</option>\n"
    }
    append result [db_html_select_value_options_multiple \
		       -translate_p $translate_p \
		       -bind $bind_vars \
		       -select_option $default \
		       $statement_name \
		       $sql \
    ]
    append result "\n</select>\n"
    return $result
}



ad_proc im_options_to_select_box { select_name options { default "" } } {
    Takes an "options" list (list of list, the inner containing a 
    (category, category_id) as for formbuilder) and returns a formatted
    select box.
} {
#   ad_return_complaint 1 "select_name=$select_name, options=$options, default=$default"

    set result "\n<select name=\"$select_name\">\n"
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
    if { ![empty_string_p $bind] } {
	set options [db_list_of_lists $stmt_name $sql -bind $bind]
    } else {
	set options [uplevel [list db_list_of_lists $stmt_name $sql]]
    }

    foreach option $options {
	set option_string [lindex $option $option_index]

	if { $translate_p && "" != [lindex $option $option_index] } {
	    set translated_value [lang::message::lookup "" intranet-core.[lang::util::suggest_key $option_string] $option_string ]
	} else {
	    set translated_value $option_string
	}

	if { [lsearch $select_option [lindex $option $value_index]] >= 0 } {
	    append select_options "<option value=\"[ad_quotehtml [lindex $option $value_index]]\" selected>$translated_value</option>\n"
	} else {
	    append select_options "<option value=\"[ad_quotehtml [lindex $option $value_index]]\">$translated_value</option>\n"
	}

    }
    return $select_options
}

ad_proc im_selection_to_list_box { {-translate_p "1"} bind_vars statement_name sql select_name { default "" } {size "6"} {multiple ""} } {
    Expects selection to have a column named id and another named name. 
    Runs through the selection and return a list bar named select_name, 
    defaulted to $default 
} {
    return "
<select name=\"$select_name\" size=\"$size\" $multiple>
[db_html_select_value_options_multiple -translate_p $translate_p -bind $bind_vars -select_option $default $statement_name $sql]
</select>
"
}

ad_proc im_maybe_prepend_http { orig_query_url } {
    Prepends http to query_url unless it already starts with http://
} {
    set orig_query_url [string trim $orig_query_url]
    set query_url [string tolower $orig_query_url]
    if { [empty_string_p $query_url] || [string compare $query_url "http://"] == 0 } {
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
    if { ![empty_string_p $street_1] } {
	append street $street_1
    }
    if { ![empty_string_p $street_2] } {
	if { ![empty_string_p $street] } {
	    append street "<br>\n"
	}
	append street $street_2
    }
    if { ![empty_string_p $street] } {
	lappend items $street
    }	
    set line_2 ""
    if { ![empty_string_p $state] } {
	set line_2 $state
    }	
    if { ![empty_string_p $zip] } {
	append line_2 " $zip"
    }	
    if { ![empty_string_p $city] } {
	if { [empty_string_p $line_2] } {
	    set line_2 $city
	} else { 
	    set line_2 "$city, $line_2"
	}
    }
    if { ![empty_string_p $line_2] } {
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
	    if { ![empty_string_p $value] } {
		append hidden_vars "<input type=hidden name=$varname value=\"[ad_quotehtml $value]\">\n"
	    }
	}
    }
    return "
<table>
  <tr>
    <td><form method=post action=\"[ad_quotehtml $yes_action]\">
	$hidden_vars
	<input type=submit name=operation value=\"[ad_quotehtml $yes_button]\">
	</form>
    </td>
    <td><form method=get action=\"[ad_quotehtml $no_action]\">
	$hidden_vars
	<input type=submit name=operation value=\"[ad_quotehtml $no_button]\">
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
    if { [empty_string_p $url] } {
	set url [ns_conn url]
    }
    set query [export_ns_set_vars url]
    if { ![empty_string_p $query] } {
	append url "?$query"
    }
    return $url
}

ad_proc im_memoize_list { { -bind "" } statement_name sql_query { force 0 } {also_memoize_as ""} } {
    Allows you to memoize database queries without having to grab a db
    handle first. If the query you specified is not in the cache, this
    proc grabs a db handle, and memoizes a list, separated by $divider
    inside the cache, of the results. Your calling proc can then process
    this list as normally. 
} {

    ns_share im_memoized_lists

    set str ""
    set divider "\253"

    if { [info exists im_memoized_lists($sql_query)] } {
	set str $im_memoized_lists($sql_query)
    } else {
	# ns_log Notice "Memoizing: $sql_query"
	if { [catch {set db_data [db_list_of_lists $statement_name $sql_query -bind $bind]} err_msg] } {
	    # If there was an error, let's log a nice error message that includes 
	    # the statement we executed and any bind variables
	    ns_log error "im_memoize_list: Error executing db_list_of_lists $statement_name \"$sql_query\" -bind \"$bind\""
	    if { [empty_string_p $bind] } {
		set bind_string ""
	    } else {
		set bind_string [NsSettoTclString $bind]
		ns_log error "im_memoize_list: Bind Variables: $bind_string"
	    }
	    error "im_memoize_list: Error executing db_list_of_lists $statement_name \"$sql_query\" -bind \"$bind\"\n\n$bind_string\n\n$err_msg\n\n"
	}
	foreach row $db_data {
	    foreach col $row {
		if { ![empty_string_p $str] } {
		    append str $divider
		}
		append str $col
	    }
	}
	set im_memoized_lists($sql_query) $str
    }
    if { ![empty_string_p $also_memoize_as] } {
	set im_memoized_lists($also_memoize_as) $str
    }
    return [split $str $divider]
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
    if { ![empty_string_p $previous_page] } {
	append link "$previous_page"
    }
    if { ![empty_string_p $next_page] } {
	if { ![empty_string_p $link] } {
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
    set rowlimit [expr $lastrow - $firstrow]
 
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
    if { [empty_string_p $second_group_id] } {
	if { [string compare $role "all"] != 0 } {
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

ad_proc im_csv_duplicate_double_quotes {arg} {
    This proc duplicates double quotes so that the resulting
    string becomes suitable to be written to a CSV file
    according to the Microsoft Excel CSV conventions
    @see ad_quotehtml
} {
    regsub -all {"} $arg {""} result
    return $result
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
        select
                u.password as user_password,
                u.salt as user_salt
        from
                users u
        where
                u.user_id = :user_id"
    db_0or1row get_user_data $user_data_sql

    # generate the expected auto_login variable
    return [ns_sha1 "$user_id$user_password$user_salt$expiry_date"]
}

ad_proc -public im_valid_auto_login_p {
    {-expiry_date ""}
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
    set expected_auto_login [im_generate_auto_login -user_id $user_id]
    if {![string equal $auto_login $expected_auto_login]} { return 0 }

    # Ok, the tokens are identical, we can log the dude in if
    # the "expiry_date" is OK.
    if {"" == $expiry_date} { return 1 }

    if {![regexp {[0-9]{4}-[0-9]{2}-[0-9]{2}-} $expiry_date]} { 
	ad_return_complaint 1 "<b>im_valid_auto_login_p</b>:
        You have specified a bad date syntax"
	return 0
    }

    set current_date [db_string current_date "select to_char(sysdate, 'YYYY-MM-DD') from dual"]

    if {[string compare $current_date $expiry_date]} {
	return 0
    }
    return 1
}


# -----------------------------------------------------------
# Project ::new, ::del and ::name procedures
# -----------------------------------------------------------

ad_proc -public im_category_is_a { 
    child
    parent
    { category_type "" }
} {
    Returns 1 if the first category "is_a" second category.
    Can be called with two integers (third argument empty) or
    with two categories plus the category type as the third argument.
} {
    if {$child == $parent} { return 1 }

    if {"" == $category_type} {
	if {![string is integer $child]} { ad_return_complaint 1 "First argument is not an integer" }
	if {![string is integer $parent]} { ad_return_complaint 1 "First argument is not an integer" }

	return [db_string is_a "
		select	count(*)
		from	im_category_hierarchy
		where	parent_id = :parent
			and child_id = :child
        " -default 0]
    }

    set child_id [db_string child "select category_id from im_categories where category = :child and category_type = :category_type" -default ""]
    set parent_id [db_string child "select category_id from im_categories where category = :parent and category_type = :category_type" -default ""]

    if {"" == $child_id} { ad_return_complaint 1 "<b>Internal Error</b>:<br>im_category_is_a: Category '$child' is not part of '$category_type'" }
    if {"" == $parent_id} { ad_return_complaint 1 "<b>Internal Error</b>:<br>im_category_is_a: Category '$parent' is not part of '$category_type'" }

    return [db_string is_a "
	select	count(*)
	from	im_category_hierarchy
	where	parent_id = :parent_id 
		and child_id = :child_id
    " -default 0]
}


# ---------------------------------------------------------------
# Category Hierarchy Helper
# ---------------------------------------------------------------

ad_proc -public im_sub_categories {
    category_list
} {
    Takes a single category or a list of categories and
    returns a list of the transitive closure (all sub-
    categories) plus the original input categories.
} {
    # Add a dummy value so that an empty input list doesn't
    # give a syntax error...
    lappend category_list 0
    
    # Check security. category_list should only contain integers.
    if {[regexp {[^0-9\ ]} $category_list match]} { 
	im_security_alert \
	    -location "im_category_subcategories" \
	    -message "Received non-integer value for category_list" \
	    -value $category_list
	return [list]
    }

    set closure_sql "
	select	category_id
	from	im_categories
	where	category_id in ([join $category_list ","])
      UNION
	select	child_id
	from	im_category_hierarchy
	where	parent_id in ([join $category_list ","])
    "

    set result [db_list category_trans_closure $closure_sql]

    # Avoid SQL syntax error when the result is used in a where x in (...) clause
    if {"" == $result} { set result [list 0] }

    return $result
}


# ---------------------------------------------------------------
# Ad-hoc execution of SQL-Queries
# Format for "Developer Service" "pre" display
# ---------------------------------------------------------------

ad_proc -public im_ad_hoc_query {
    {-format plain}
    {-border 0}
    {-col_titles {} }
    sql
} {
    Ad-hoc execution of SQL-Queries
    Format for browser "pre" display
} {
    set lol [db_list_of_lists ad_hoc_query $sql]
    set result ""
    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "

    set header ""
    if {"" != $col_titles} {
	foreach title $col_titles {
	    switch $format {
		html { append header "<th>$title</th>" }
		csv { append header "$title;" }
		default {append header "$title\t" }
	    }
	}
	switch $format {
	    html { set header "<tr class=rowtitle>\n$header\n</tr>\n" }
	    csv { append header "$header;" }
	    default { set header $header }
	}
    }

    set row_count 1
    foreach row $lol {
	foreach col $row {
	    switch $format {
		html {	
		    if {"" == $col} { set col "&nbsp;" }
		    append result "<td>$col</td>" 
		}
		csv { append result "$col;" }
		plain {	append result "$col\t" }
	    }
	}

	# Change to next line
	switch $format {
	    html { append result "</tr>\n<tr $bgcolor([expr $row_count % 2])>" }
	    default { append result "\n" }
	}
	incr row_count
    }
    
    switch $format {
	html { return "
		<table border=$border>
		$header
		<tr $bgcolor(0)>
		$result
		</tr>
		</table>
	       "  
	}
	default { return "$header\n$result"  }
    }
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
    set component_title [lang::message::lookup "" intranet-core.Generic_Table_Header_$table_name $table_name]
    return [im_table_with_title $component_title $result]
}
