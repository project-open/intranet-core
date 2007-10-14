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
    With Project/Open we don't need package ids because all P/O
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
	if { $translate_p } {
            set text_tr [_ intranet-core.[lang::util::suggest_key $text]]
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


ad_proc im_currency_select {select_name {default ""}} {
    Return a HTML widget that selects a currency code from
    the list of global countries.
} {
    set bind_vars [ns_set create]
    set statement_name "currency_code_select"
    set sql "select iso, iso
	     from currency_codes
	     where supported_p='t'
	     order by lower(currency_name)"

    return [im_selection_to_select_box -translate_p 0 $bind_vars $statement_name $sql $select_name $default]
}


ad_proc -public im_category_from_id { 
    {-translate_p 1}
    category_id 
} {
    Get a category_name from 
} {
    if {"" == $category_id} { return "" }
    set category_name [db_string cat "select im_category_from_id(:category_id)" -default ""]
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


ad_proc im_csv_duplicate_double_quotes {arg} {
    This proc duplicates double quotes so that the resulting
    string becomes suitable to be written to a CSV file
    according to the Microsoft Excel CSV conventions
    @see ad_quotehtml
} {
    regsub -all {"} $arg {""} result
    return $result
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
		plain {	append header "$title\t" }
		html {	
		    append header "<th>$title</th>" 
		}
	    }
	}
	switch $format {
	    plain { set header $header }
	    html { set header "<tr class=rowtitle>\n$header\n</tr>\n" }
	}
    }

    set row_count 1
    foreach row $lol {
	foreach col $row {
	    switch $format {
		plain {	append result "$col\t" }
		html {	
		    if {"" == $col} { set col "&nbsp;" }
		    append result "<td>$col</td>" 
		}
	    }
	}

	# Change to next line
	switch $format {
	    plain { append result "\n" }
	    html { append result "</tr>\n<tr $bgcolor([expr $row_count % 2])>" }
	}
	incr row_count
    }
    
    switch $format {
	plain { return "$header\n$result"  }
	html { return "
		<table border=$border>
		$header
		<tr $bgcolor(0)>
		$result
		</tr>
		</table>
	       "  
	}
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
