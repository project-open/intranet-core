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


ad_proc -public im_opt_val { var_name } {
    Acts like a "$" to evaluate a variable, but
    returns "" if the variable is not defined,
    instead of an error.<BR>
    This function is useful for passing optional
    variables to components, if the component can't
    be sure that the variable exists in the callers
    context.
} {
    upvar $var_name var
    if [exists_and_not_null var] { 
	return $var
    }
    return ""
} 



# Basic Intranet Parameter Shortcuts
ad_proc im_url_stub {} {
    return [ad_parameter -package_id [im_package_core_id] IntranetUrlStub "" "/intranet"]
}

ad_proc im_url {} {
    return [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""][im_url_stub]
}


ad_proc im_name_in_mailto { user_id} {
    if { $user_id > 0 } {
	db_1row user_name_and_email \
		"select first_names || ' ' || last_name as name, email from users where user_id=:user_id"
	set mail_to "<a href=mailto:$email>$name</a>"
    } else {
	set mail_to "Unassigned"
    }
    return $mail_to
}

ad_proc im_name_paren_email {user_id} {
    if { $user_id > 0 } {
	db_1row user_name_and_email \
		"select first_names || ' ' || last_name as name, email from users where user_id=:user_id"
	set text "$name: $email"
    } else {
	set text "Unassigned"
    }    
    return $text
}


# ------------------------------------------------------------------
# ------------------------------------------------------------------

# Find out the user name
ad_proc -public im_get_user_name {user_id} {
    return [util_memoize "im_get_user_name_helper $user_id"]
}


ad_proc -public im_get_user_name_helper {user_id} {
    set user_name "&lt;unknown&gt;"
    if ![catch { set user_name [db_string index_get_user_first_names {
select
	first_names || ' ' || last_name as name
from
	persons
where
	person_id = :user_id

}] } errmsg] {
	# no errors
    }
    return $user_name
}



ad_proc im_db_html_select_value_options_plus_hidden {query list_name {select_option ""} {value_index 0} {label_index 1}} {
    #this is html to be placed into a select tag
    #when value!=option, set the index of the return list
    #from the db query. selected option must match value
    #it also sends a hidden variable with all the values 
    #designed to be availavle for spamming a list of user ids from the next page.

    set select_options ""
    set values_list ""
    set options [db_list_of_lists im_db_html_select_random_query $query]
    foreach option $options {
	set one_label [lindex $option $label_index] 
	set one_value [lindex $option $value_index]
	if { [lsearch $select_option $one_value] != -1 } {
	    append select_options "<option value=$one_value selected>$one_label\n"
	    lappend values_list $one_value
	} else {
	    append select_options "<option value=$one_value>$one_label\n"
	    lappend values_list $one_value
	}
    }
    if { [empty_string_p $values_list] } {
	# use 0 for unassigned and/or no one is on the project
	ns_log warning "values list empty!"
	append select_options "<option value=0>unassigned\n"
    	set value_list 0
    }
    append select_options "</select> [philg_hidden_input $list_name $values_list]"
    return $select_options
}

ad_proc im_employee_select_optionlist { {user_id ""} } {
    set employee_group_id [im_employee_group_id]
    return [db_html_select_value_options -select_option $user_id im_employee_select_options "
select
	u.user_id, 
	im_name_from_user_id(u.user_id) name
from
	users u,
	group_distinct_member_map gm
where
	u.user_id = gm.member_id
	and gm.group_id = $employee_group_id
order by lower(name)"]
}


ad_proc im_num_employees {{since_when ""} {report_date ""} {purpose ""} {user_id ""}} "Returns string that gives # of employees and full time equivalents" {

    set num_employees [db_string employees_total_number \
	    "select count(time.percentage_time) 
               from im_employees_active emp, im_employee_percentage_time time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (emp.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=emp.user_id"]

    set num_fte [db_string employee_total_fte \
	    "select sum(time.percentage_time) / 100
               from im_employees_active emp, im_employee_percentage_time time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (emp.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=emp.user_id"]

    if { [empty_string_p $num_fte] } {
	set num_fte 0
    }
     
    set return_string "We have $num_employees [util_decode $num_employees 1 employee employees] ($num_fte full-time [util_decode $num_fte 1 $num_fte equivalent equivalents])"

    if {$purpose == "web_display"} {
	return "<blockquote>$return_string</blockquote>"
    } else {
	return "$return_string"
    }
}

ad_proc im_num_employees_simple { } "Returns # of employees." {
    return [db_string employees_count_total \
	    "select count(time.percentage_time) 
               from im_employees_active info, im_employee_percentage_time  time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (info.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=info.user_id"]
}

ad_proc im_num_offices_simple { } "Returns # of offices." {
    return [db_string offices_count_total \
	    "select count(*) 
               from user_groups
              where parent_group_id = [im_office_group_id]"]
}


ad_proc im_allocation_date_optionlist { {start_block ""} {start_of_larger_unit_p ""} { number_months_ahead 18 } } {
    Returns an optionlist of valid allocation start dates. If
    start_of_larger_unit_p is t/f, then we limit to those blocks matching
    t/f. Number_months_ahead specified the number of months of start
    blocks from today to include. This is great for limiting the size of
    select bars. Specifying a negative value includes all of the start
    blocks.
} {
 
    set bind_vars [ns_set create]
    if { [empty_string_p $start_of_larger_unit_p] } {
	set start_p_sql ""
    } else {
	ns_set put $bind_vars start_of_larger_unit_p $start_of_larger_unit_p
	set start_p_sql " and start_of_larger_unit_p=:start_of_larger_unit_p "
    }
    if { $number_months_ahead < 0 } {
	set number_months_sql ""
    } else {
	ns_set put $bind_vars number_months_ahead $number_months_ahead
	set number_months_sql " and start_block <= add_months(sysdate, :number_months_ahead) "
    }
    # Only go as far as 1 year into the future to save space
    return [db_html_select_value_options -bind $bind_vars -select_option $start_block allocations_near_future \
	    "select start_block, to_char(start_block,'Month YYYY')
               from im_start_blocks 
              where to_char(start_block,'W') = 1 $number_months_sql $start_p_sql
              order by start_block asc"]
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

ad_proc im_select { field_name pairs { default "" } } {
    Formats a "select" tag
} {
    if { [llength $pairs] == 0 } {
	# Get out early as there's nothing to do
	return ""
    }

    if { [empty_string_p $default] } {
	set default [ad_partner_upvar $field_name 1]
    }
    set url "[ns_conn url]?"
    set menu_items_text [list]
    set menu_items_select [list]

    foreach { value text } $pairs {
	if { [string compare $value $default] == 0 } {
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\" selected>$text</option>\n"
	} else {
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\">$text</option>\n"
	}
    }
    return "
    <select name=\"[ad_quotehtml $field_name]\">
    [join $menu_items_select ""]
    </select>
"
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

    return [im_selection_to_select_box $bind_vars $statement_name $sql $select_name $default]
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

    return [im_selection_to_select_box $bind_vars $statement_name $sql $select_name $default]
}


ad_proc -public im_category_from_id { category_id } {
    Get a category_name from 
} {
    if {"" == $category_id} { return "" }
    set sql "select im_category_from_id($category_id) from dual"
    return [util_memoize "db_string category_from_id \"$sql\" -default {}"]

#    set member_count [util_memoize "db_string member_count \"select count(*) from acs_rels where object_id_two = $user_id and object_id_one = $group_id\""]

}


ad_proc im_category_select { category_type select_name { default "" } } {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
             from im_categories
             where category_type = :category_type
             order by lower(category)"
    return [im_selection_to_select_box $bind_vars category_select $sql $select_name $default]
}    

ad_proc im_category_select_multiple { category_type select_name { default "" } { size "6"} { multiple ""}} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
             from im_categories
             where category_type = :category_type
             order by lower(category)"
    return [im_selection_to_list_box $bind_vars category_select $sql $select_name $default $size multiple]
}    

ad_proc im_employee_select_multiple { select_name { defaults "" } { size "6"} {multiple ""}} {
    set bind_vars [ns_set create]
    set employee_group_id [im_employee_group_id]
    set sql "
select
	u.user_id,
	im_name_from_user_id(u.user_id) as employee_name
from
	users u,
	group_distinct_member_map gm
where
	u.user_id = gm.member_id
	and gm.group_id = $employee_group_id
order by lower(employee_name)
"
    return [im_selection_to_list_box $bind_vars category_select $sql $select_name $defaults $size $multiple]
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








ad_proc im_partner_status_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the partner statuses in the system} {
    return [im_category_select "Intranet Partner Status" $select_name $default]
}

ad_proc im_invoice_payment_method_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the partner statuses in the system
} {
    return [im_category_select "Intranet Invoice Payment Method" $select_name $default]
}

ad_proc im_invoice_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the reasonable stati for an invoice
} {
    set bind_vars [ns_set create]
    set sql "select invoice_status_id as category_id, invoice_status as category
             from im_invoice_status
             order by lower(invoice_status_id)"
    return [im_selection_to_select_box $bind_vars category_select $sql $select_name $default]
}

ad_proc im_payment_type_select { select_name { default "" } } {
} {
    return [im_category_select "Intranet Payment Type" $select_name $default]
}

ad_proc im_invoice_template_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the partner statuses in the system
} {
    return [im_category_select "Intranet Invoice Template" $select_name $default]
}

ad_proc im_partner_type_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    return [im_category_select "Intranet Partner Type" $select_name $default]
}

ad_proc im_selection_to_select_box { bind_vars statement_name sql select_name { default "" } } {
    Expects selection to have a column named id and another named name. 
    Runs through the selection and return a select bar named select_name, 
    defaulted to $default 
} {
    set result "<select name=\"$select_name\">"
    if {[string equal $default ""]} {
	append result "<option value=\"\"> -- Please select -- </option>"
    }
    append result "
[db_html_select_value_options -bind $bind_vars -select_option $default $statement_name $sql]
</select>
"
    return $result
}


ad_proc -public db_html_select_value_options_multiple {
    { -bind "" }
    { -select_option "" }
    { -value_index 0 }
    { -option_index 1 }
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
	if { [lsearch $select_option [lindex $option $value_index]] >= 0 } {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\" selected>[lindex $option $option_index]\n"
	} else {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\">[lindex $option $option_index]\n"
	}
    }
    return $select_options
}

ad_proc im_selection_to_list_box { bind_vars statement_name sql select_name { default "" } {size "6"} {multiple ""} } {
    Expects selection to have a column named id and another named name. 
    Runs through the selection and return a list bar named select_name, 
    defaulted to $default 
} {
    return "
<select name=\"$select_name\" size=\"$size\" $multiple>
[db_html_select_value_options_multiple -bind $bind_vars -select_option $default $statement_name $sql]
</select>
"
}

ad_proc im_user_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the available project_leads in 
    the system
} {
    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set bind_vars [ns_set create]
    ns_set put $bind_vars employee_group_id [im_employee_group_id]
    set sql "select emp.user_id, emp.last_name || ', ' || emp.first_names as name
from im_employees_active emp
order by lower(name)"
    return [im_selection_to_select_box $bind_vars project_lead_list $sql $select_name $default]
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


ad_proc im_burn_rate_blurb { } {
    Counts the number of employees with payroll information and returns 
    "The company has $num_employees employees and a monthly payroll of 
    $payroll"
} {
    # We use "exists" instead of a join because there can be more
    # than one mapping between a user and a group, one for each role,
    #
    set group_id [im_employee_group_id]
    db_1row employees_on_payroll "select count(u.user_id) as num_employees, 
ltrim(to_char(sum(salary),'999G999G999G999')) as payroll,
sum(decode(salary,NULL,1,0)) as num_missing
from im_monthly_salaries salaries, users u
where exists (select 1
              from user_group_map ugm
              where ugm.user_id = u.user_id
              and ugm.group_id = :group_id)
and u.user_id = salaries.user_id (+)"

    if { $num_employees == 0 } {
	return ""
    }
    set html "The company has $num_employees [util_decode $num_employees 1 employee employees]"
    if { ![empty_string_p $payroll] } {
        append html " and a monthly payroll of \$$payroll"
    }
    if { $num_missing > 0 } {
	append html " ($num_missing missing info)"
    }
    append html "."
    return $html
}

ad_proc im_salary_period_input {} {
    return [ad_parameter -package_id [im_package_core_id] SalaryPeriodInput "" ""]
}

ad_proc im_salary_period_display {} {
    return [ad_parameter -package_id [im_package_core_id] SalaryPeriodDisplay "" ""]
}

ad_proc im_display_salary {salary salary_period} {Formats salary for nice display} {

    set display_pref [im_salary_period_display]

    switch $salary_period {
        month {
	    if {$display_pref == "month"} {
                 return "[format %6.2f $salary] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f [expr $salary * 12]] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        year {
	    if {$display_pref == "month"} {
                 return "[format %6.2f [expr $salary/12]] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f $salary] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        default {
            return "\$[format %6.2f $salary] per $salary_period"
        }
    }
}

ad_proc im_reduce_spaces { string } {Replaces all consecutive spaces with one} {
    regsub -all {[ ]+} $string " " string
    return $string
}



ad_proc im_yes_no_table { yes_action no_action { var_list [list] } { yes_button " Yes " } {no_button " No "} } {
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


ad_proc im_group_scope_url { group_id return_url module_url {user_belongs_to_group_p ""} } {
    Creates a url for a group scoped module. If the current user is
    not in the group for the module, we redirect first to a page to
    explain that the user must be in the group to access the scoping
    functionality. 
 } {
    
    if { [regexp {\?} $module_url] } {
	set url "$module_url&"
    } else {
	set url "$module_url?"
    }
    append url "scope=group&[export_url_vars group_id return_url]"
    if { ![empty_string_p $user_belongs_to_group_p] && $user_belongs_to_group_p } {
	set in_group_p 1
    } else {
	set in_group_p [ad_user_group_member $group_id [ad_get_user_id]]
    }
    if { $in_group_p } {
	return $url
    }
    set continue_url $url
    set cancel_url $return_url
    return "[im_url_stub]/group-member-option?[export_url_vars group_id continue_url cancel_url]"
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
    a tcl proc curtisg wrote to return a sql query that will only 
    contain rows firstrow - lastrow
} {
    return "
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
}



ad_proc im_email_people_in_group { group_id role from subject message } {
    Emails the message to all people in the group who are acting in
    the specified role
} {
    # Until we use roles, we only accept the following:
    set second_group_id ""
    switch $role {
	"employees" { set second_group_id [im_employee_group_id] }
	"customers" { set second_group_id [im_customer_group_id] }
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
    
    set where_clause [join $criteria "\n        and "]

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

## MJS 8/2
ad_proc ad_build_url args { 

    Proc for building an entire url.
    To replace export_url_vars, used in a similar manner

    The main difference is that this proc accepts the stub
    as the first argument, and prepends either a ? or &
    to each variable as necessary.  If the first argument
    is null, then the returned value is equivalent to 
    that which is returned by export_url_vars.

    Usage: build_url stubvar argvar1 argvar2 argvar3 ...
    OR     build_url "literalstub" argvar1 argvar2 argvar3 ...
    
    Usage backwards-compatible with export_url_vars:

    build_url "" argvar1 argvar2 argvar3 ...

} {

    set stubvar [lindex $args 0]
    set varlist [lrange $args 1 end]

    set bind_char "?"

    ## the stub - can be a variable name or a value
    if { [empty_string_p $stubvar] } {
	
	## export_url_vars compatibility mode

	set stub ""
	set bind_char ""
	
    } else {
	
	upvar 1 $stubvar stub
	
	if { ![info exists stub] } { 
	
	    ## literal stub mode

	    set stub $stubvar
	}
	    
	if { [regexp {\?} $stub match] } {
	    set bind_char "&"
	}
    }
    
    ## the vars - expect only variable names  
    foreach var $varlist { 
	
	upvar 1 $var value 
	
	if { [info exists value] } {
	    lappend params "$var=[ns_urlencode $value]" 
	} 
    } 

    return "$stub$bind_char[join $params "&"]"
} 


## MJS 8/2
ad_proc im_validate_and_set_category_type {} {

    Used as security for category-list, category-add, and 
    category-edit and edit-2 in employees/admin.  

    We use these generalized pages to manage several subsets 
    of the categories table, but to avoid url hackery that 
    would access other subsets, we define the allowed subsets here.

    category_html is a plural pretty-name that is both d
    isplayed on the page and passed in the url.  category_type 
    is its corresponding column data in the categories table.

    Ideally, these subsets should become their own tables and 
    this proc should be obsoleted.

} {

    upvar 1 category_html got_category_html

    switch $got_category_html {

	"Hiring Sources" { uplevel { set category_type "Intranet Hiring Source"} }
	"Previous Positions" { uplevel { set category_type "Intranet Prior Experience"} }
	"Job Titles" { uplevel { set category_type "Intranet Job Title"} }
	
	default { 
	    
	    ad_return_complaint 1 "<LI><I>$got_category_html</I> is not a valid category"
	    
	}
    }

    return 1
}


ad_proc im_email_aliases { short_name } {
    Returns an html string describing the intranet email alias system,
    if it's turned on.  
} {
    set domain [ad_parameter -package_id [im_package_core_id] EmailDomain ""]
    if { [empty_string_p $domain] || ![ad_parameter -package_id [im_package_core_id] LogEmailToGroupsP 0] } {
	# No email aliases set up
	return "  <li> Project short name: $short_name\n"
    } 
    set help_link "(<a href=[im_url_stub]/help/email-aliases?[export_url_vars short_name]&return_url=[ad_urlencode [im_url_with_query]]>help</a>)"
    if { [regexp { } $short_name] } {
	return "  <li> Email aliases - this group's short name, \"$short_name,\" cannot contain a space for email aliases to work $help_link\n"
    }

    return "
  <li> Email aliases $help_link:
       <ul> 
         <li> <a href=mailto:${short_name}@$domain>$short_name@$domain</a>
         <li> <a href=mailto:${short_name}-employees@$domain>${short_name}-employees@$domain</a>
         <li> <a href=mailto:${short_name}-customers@$domain>${short_name}-customers@$domain</a>
         <li> <a href=mailto:${short_name}-all@$domain>${short_name}-all@$domain</a>
       </ul>
"
}



ad_proc im_calendar_insert_or_update {
    -type
    -current_user_id
    -on_which_table:required
    -on_what_id:required
    -start_date:required
    -user_id:required
    -related_url:required
    -title:required
    -group_id
    -end_date
    -description
} {
    Sets defaults we use in the intranet and then calls
    cal_insert_repeating_item with the appropriate tags.  Note that in
    particular, group_id defaults to the employees group.
} {
    # If the calendar package is not enabled, this becomes a no-op
    if ![apm_package_enabled_p "calendar"] {
	return
    }
    if { ![exists_and_not_null type] } {
	set type "insert"
    }
    if { ![exists_and_not_null current_user_id] } {
	set current_user_id [ad_get_user_id]
    }
    if { ![exists_and_not_null end_date] } {
	set end_date $start_date
    }
    if { ![exists_and_not_null group_id] } {
	set group_id [im_employee_group_id]
    }
    if { ![info exists description] } {
	set description ""
    }

    if { [string compare $type "insert"] != 0 } {
	# Remove old instances so they'll be added below
	cal_delete_mapped_instances $on_which_table $on_what_id
    }
    
    cal_insert_repeating_item -on_which_table $on_which_table -on_what_id $on_what_id -start_date $start_date -end_date $end_date -creation_user $current_user_id -title $title -user_id $user_id -group_id $group_id -related_url_p "t" -related_url $related_url -editable_p "f" -description $description

}



ad_proc bd_formatDateTz { date fmt gmt localTz} {
    global env
    
    set saveTz ""

    if {$localTz != ""} {
        catch { set saveTz $env(TZ) }
        set env(TZ) $localTz
    }
    
    set r [clock format $date -format $fmt -gmt $gmt]
    
    if {$localTz != ""} {
        if {$saveTz != ""} {
            set env(TZ) $saveTz
        } else {
            unset env(TZ)
        }
    }
    
    return $r
}
