# /tcl/intranet-defs.tcl

ad_library {
    Definitions for the intranet module
    @author Frank Bergmann (fraber@fraber.de)
}


# Basic Intranet Parameter Shortcuts
ad_proc im_url_stub {} {
    return [ad_parameter IntranetUrlStub intranet "/intranet"]
}

ad_proc im_url {} {
    return [ad_parameter SystemURL][im_url_stub]
}

ad_proc im_enabled_p {} {
    return [ad_parameter IntranetEnabledP intranet 0]
}

ad_proc im_task_general_comment_section {task_id name} {
    set spam_id [db_nextval "spam_id_sequence"]
    set return_url  "[im_url]/spam?return_url=[ns_conn url]?[export_ns_set_vars [list task_id spam_id]]&task_id=$task_id&spam_id=$spam_id"

    set html "
<em>Comments</em>
[ad_general_comments_summary $task_id im_tasks $name]
<P>
<center>
(<A HREF=\"/general-comments/comment-add?on_which_table=im_tasks&on_what_id=$task_id&item=[ns_urlencode $name]&module=intranet&return_url=[ns_urlencode $return_url]\">Add a comment</a>)
</center>
</UL>"

    return $html
}

ad_proc im_removal_instructions {user_id} {

    set message "
------------------------------
Sent through [im_url]
"

    return $message
}



ad_proc im_spam {user_id_list from_address subject message spam_id {add_removal_instructions_p 0} } { 
    #Spams an user_id_list
    #Does not automatically add removal instructions
    set html ""
    set user_id [ad_get_user_id]    
    set status "sending"
    set peeraddr [ns_conn peeraddr]

    if { [catch [db_dml spam_history_insert {
	insert into spam_history
	(spam_id, from_address, title, body_plain, creation_date, creation_user, creation_ip_address, status)
	values
	(:spam_id, :from_address, :subject, empty_clob(), sysdate, :creation_user, :peeraddr, :status)
    } -clobs [list $body_plain]] errmsg] } {
    # choked; let's see if it is because 
	if { [db_string spam_history_count "select count(*) from spam_history where spam_id = :spam_id"] > 0 } {
	    set error_message "<blockquote>An error has occured and no email was sent because the database thinks this email was already sent.  Please check the project page and see if your changes have been made. </blockquote></p>"
	    return $error_message
	} else {
	    ad_return_error "Ouch!" "The database choked on your insert:
	    <blockquote>
	    $errmsg
	    </blockquote>
	    "
	}
    }
    set sent_html ""
    set failure_html ""
    set failure_count 0
    foreach mail_to_id $user_id_list {
	set email [db_string user_email "
	select email 
	from users_spammable 
	where user_id = :mail_to_id"]
	if { $email == 0 } {
	    incr failure_count
	    #get the failure persons' name if available.
	    set failed_name [catch { [db_string user_name "
	    select first_names || ' ' || last_name as name 
	    from users 
	    where user_id = :mail_to_id"] } "no name found" ]
	    append failure_html "<li> no email address was found for user_id = $mail_to_id: name = $failed_name"

	} else {
	    if { $add_removal_instructions_p } {
		append message [im_removal_instructions $mail_to_id]
	    }
	    ns_sendmail $email $from_address $subject $message	    
	    db_dml spam_update spam_history  -type update -where "spam_id = :spam_id" [list n_sent "n_sent+1"]
	    append sent_html "<li>$email...\n"
	}
    }
    set n_sent [db_string spam_number_sent "select n_sent from spam_history where spam_id = :spam_id"]
    db_dml spam_update_status "update spam_history set status = 'sent' where spam_id = :spam_id"
    
    append html "<blockquote>Email was sent $n_sent email addresses.  <p> If any of these addresses are bogus you will recieve a bounced email in your box<ul> $sent_html </ul> </blockquote>"
    if { $failure_count > 0 } {
	append html "They databased did not have email addresses or the user has requested that spam be blocked in the following $failure_count cases: 
	<ul> $failure_html </ul>"
    }
    return $html
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

# made by guillermo:

#proc im_category_id { category_type category } {
#    set bind_vars [ns_set create]
#    ns_set put $bind_vars category_type $category_type
#    ns_set put $bind_vars category $category
#    set sql "select category_id
#             from categories
#             where category_type = :category_type
#                   and category = :category"
#    return $sql
#}

ad_proc im_category_select { category_type select_name { default "" } } {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
             from categories
             where category_type = :category_type
             order by lower(category)"
    return [im_selection_to_select_box $bind_vars category_select $sql $select_name $default]
}    

ad_proc im_category_select_multiple { category_type select_name { default "" } { size "6"} { multiple ""}} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
             from categories
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

# 030708 fraber: Eliminate the --- Please select --- if 
# there is already a default given.
#
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
    @author yon [yon@arsdigita.com]
    @author Fraber [fraber@fraber.de]
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
    return [ad_parameter SalaryPeriodInput intranet]
}

ad_proc im_salary_period_display {} {
    return [ad_parameter SalaryPeriodDisplay intranet]
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

ad_proc hours_sum_for_user { user_id { on_which_table "" } { on_what_id "" } { number_days "" } } {
    Returns the total number of hours the specified user logged for
    whatever else is included in the arg list 
} {

    set criteria [list "user_id=:user_id"]
    if { ![empty_string_p $on_which_table] } {
	lappend criteria "on_which_table=:on_which_table"
    }
    if { ![empty_string_p $on_what_id] } {
	lappend criteria "on_what_id = :on_what_id"
    }
    if { ![empty_string_p $number_days] } {
	lappend criteria "day >= sysdate - :number_days"	
    }
    set where_clause [join $criteria "\n    and "]
    set num [db_string hours_sum \
	    "select sum(hours) from im_hours where $where_clause"]

    return [util_decode $num "" 0 $num]
}

ad_proc hours_sum { on_which_table on_what_id {number_days ""} } {
    Returns the total hours registered for the specified table and
    id. 
} {

    if { [empty_string_p $number_days] } {
	set days_back_sql ""
    } else {
	set days_back_sql " and day >= sysdate-:number_days"
    }
    set num [db_string hours_sum_for_group \
	    "select sum(hours)
               from im_hours
              where on_what_id = :on_what_id
                and on_which_table = :on_which_table $days_back_sql"]
    return [util_decode $num "" 0 $num]
}

ad_proc im_random_employee_blurb { } "Returns a random employee's photograph and a little bio" {

return ""

    # Get the current user id to not show the current user's portrait
    set current_user_id [ad_get_user_id]

    # How many photos are there?
    set number_photos [db_string number_employees_with_photos {
        select count(emp.user_id)
	  from im_employees_active emp, general_portraits  gp
 	 where emp.user_id <> :current_user_id
	   and emp.user_id = gp.on_what_id
	   and gp.on_which_table = 'USERS'
	   and gp.approved_p = 't'
	   and gp.portrait_primary_p = 't'}]

    if { $number_photos == 0 } {
        return ""
    }

    # get the lucky user
    #  Thanks to Oscar Bonilla <obonilla@fisicc-ufm.edu> who
    #  pointed out that we were previously ignoring the last user
    #  in the list
    set random_num [expr [randomRange $number_photos] + 1]
    # Using im_select_row_range means we actually only will retrieve the
    # 1 row we care about
    set sql "select emp.user_id
               from im_employees_active emp, general_portraits gp
              where emp.user_id <> :current_user_id
	        and emp.user_id = gp.on_what_id
		and gp.on_which_table = 'USERS'
		and gp.approved_p = 't'
		and gp.portrait_primary_p = 't'"

    set portrait_user_id [db_string random_user_with_photo \
	    [im_select_row_range $sql $random_num $random_num]]
 
    # We use rownum<2 in case the user is mapped to more than one office
    #
    set office_group_id [im_office_group_id]
    if { ![db_0or1row random_employee_get_info \
	    "select u.first_names || ' ' || u.last_name as name, u.bio, u.skills, 
                    NVL(u.msn_email, u.email) as msn_email,
                    ug.group_name as office, ug.group_id as office_id
               from im_employees_active u, user_groups ug, user_group_map ugm
              where u.user_id = ugm.user_id(+)
                and ug.group_id = ugm.group_id
                and ug.parent_group_id = :office_group_id
                and u.user_id = :portrait_user_id
                and rownum < 2"] } {
        # No lucky employee :(
	return ""
    }

    # **** this should really be smart and look for the actual thumbnail
    # but it isn't and just has the browser smash it down to a fixed width
 
    append name2 "<div align=center>
<!-- Begin Online Status Indicator code -->
<!-- http://www.onlinestatus.org/ -->
<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\">
<IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\"
border=\"0\" ALT=\"MSN Online Status Indicator\" onerror=\"this.onerror=null;this.src='http://status.inkiboo.com:8080/msn/$msn_email';\"></A>
<!-- End Online Status Indicator code -->
<a class=whitelink href=[im_url_stub]/users/view?user_id=$portrait_user_id><b>$name</b></a></div>"

    append content "
<br><div align=center><a class=blacklink href=\"/shared/portrait?user_id=$portrait_user_id\"><img width=125 src=\"/shared/portrait-bits?user_id=$portrait_user_id\" border=1></a></div>
<br><div align=center>Office: <a class=blacklink href=[im_url_stub]/offices/view?group_id=$office_id>$office</a></div>
[util_decode $bio "" "" "<br>Biography: $bio"]
[util_decode $skills "" "" "<br>Special skills: $skills"]
"
return "
[im_tablex "$name2" "0" "#000000" "5" "0" "150"]
[im_tablex "[im_tablex "$content" "0" "#ECF5E5" "1" "0"]" "0" "#000000" "1" "0" "150"]"

}



ad_proc im_user_information { user_id } {
Returns an html string of all the intranet applicable information for one 
user. This information can be used in the shared community member page, for 
example, to give intranet users a better understanding of what other people
are doing in the site.
} {

    set caller_id [ad_get_user_id]
    
    # is this user an employee?
    set user_employee_p [im_user_is_employee_p $user_id]

    set return_url [im_url_with_query]

    # we need a backup copy
    set user_id_copy $user_id

    # If we're looking at our own entry, we can modify some information
    if {$caller_id == $user_id} {
	set looking_at_self_p 1
    } else {
	set looking_at_self_p 0
    }

    # can the user make administrative changes to this page
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $caller_id]

    if { ![db_0or1row employee_info \
	    "select u.*, uc.*, info.*,
                    ((sysdate - info.first_experience)/365) as years_experience
               from users u, users_contact uc, im_employees info
              where u.user_id = :user_id 
                and u.user_id = uc.user_id(+)
                and u.user_id = info.user_id(+)"] } {
        # Can't find the user		    
	ad_return_error "Error" "User doesn't exist"
	ad_script_abort
    }
    # get the user portrait
    set portrait_p [db_0or1row portrait_info "
       select portrait_id,
	      portrait_upload_date,
	      portrait_client_file_name
         from general_portraits
	where on_what_id = :user_id
	  and upper(on_which_table) = 'USERS'
	  and approved_p = 't'
	  and portrait_primary_p = 't'
    "]

    # just in case user_id was set to null in the last query
    set user_id $user_id_copy
    set office_group_id [im_office_group_id]

    set sql "select ug.group_name, ug.group_id
    from user_groups ug, im_offices o
    where ad_group_member_p ( :user_id, ug.group_id ) = 't'
    and o.group_id=ug.group_id
    and ug.parent_group_id=:office_group_id
    order by lower(ug.group_name)"

    set offices ""
    set number_offices 0
    db_foreach offices_user_belongs_to $sql {
	incr number_offices
	if { ![empty_string_p $offices] } {
	    append offices ", "
	}
	append offices "  <a href=[im_url_stub]/offices/view?[export_url_vars group_id]>$group_name</A>"
    }

    set page_content "<ul>\n"

    if [exists_and_not_null job_title] {
	append page_content "<LI>Job title: $job_title\n"
    }

    if { $number_offices > 0 } {
	append page_content "  <li>[util_decode $number_offices 1 Office Offices]: $offices\n"
	if { $looking_at_self_p } {
	    append page_content "(<a href=[im_url_stub]/users/office-update?[export_url_vars user_id]>manage</a>)\n"
	}
    } elseif { $user_employee_p } {
	if { $looking_at_self_p } {
	    append page_content "  <li>Office: <a href=[im_url_stub]/users/add-to-office?[export_url_vars user_id return_url]>Add yourself to an office</a>\n"
	} elseif { $user_admin_p } {
	    append page_content "  <li>Office: <a href=[im_url_stub]/users/add-to-office?[export_url_vars user_id return_url]>Add this user to an office</a>\n"
	}
    }

    if [exists_and_not_null years_experience] {
	append page_content "<LI>Job experience: [format %3.1f $years_experience] years\n"
    }

    if { $user_employee_p } {
	# Let's offer a link to the people this person manages, if s/he manages somebody
	db_1row subordinates_for_user \
		"select decode(count(*),0,0,1) as number_subordinates
                   from im_employees_active 
                  where supervisor_id=:user_id"
	if { $number_subordinates == 0 } {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart>Org chart</a>: This user does not supervise any employees.\n"
	} else {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart>Org chart</a>: <a href=[im_url_stub]/employees/org-chart?starting_user_id=$user_id>View the org chart</a> starting with this employee\n"
	}

	set number_superiors [db_string employee_count_superiors \
		"select max(level)-1 
                   from im_employees
                  start with user_id = :user_id
                connect by user_id = PRIOR supervisor_id"]
	if { [empty_string_p $number_superiors] } {
	    set number_superiors 0
	}

	# Let's also offer a link to see to whom this person reports
	if { $number_superiors > 0 } {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart-chain?[export_url_vars user_id]>View chain of command</a> starting with this employee\n"
	}
    }	

    if { [exists_and_not_null portrait_upload_date] } {
	if { $looking_at_self_p } {
	    append page_content "<p><li><a href=/pvt/portrait/index?[export_url_vars return_url]>Portrait</A>\n"
	} else {
	    append page_content "<p><li><a href=/shared/portrait?[export_url_vars user_id]>Portrait</A>\n"
	}
    } elseif { $looking_at_self_p } {
	append page_content "<p><li>Show everyone else at [ad_system_name] how great looking you are:  <a href=/pvt/portrait/upload?[export_url_vars return_url]>upload a portrait</a>"
    }

    append page_content "<p>"

    if [exists_and_not_null email] {
	append page_content "<LI>Email: <A HREF=mailto:$email>$email</A>\n";
    }
    if [exists_and_not_null url] {
	append page_content "<LI>Homepage: <A HREF=[im_maybe_prepend_http $url]>[im_maybe_prepend_http $url]</A>\n";
    }
    if [exists_and_not_null aim_screen_name] {
	append page_content "<LI>AIM name: $aim_screen_name\n";
    }
    if [exists_and_not_null icq_number] {
	append page_content "<LI>ICQ number: $icq_number\n";
    }
    if [exists_and_not_null work_phone] {
	append page_content "<LI>Work phone: $work_phone\n";
    }
    if [exists_and_not_null home_phone] {
	append page_content "<LI>Home phone: $home_phone\n";
    }
    if [exists_and_not_null cell_phone] {
	append page_content "<LI>Cell phone: $cell_phone\n";
    }

    set address [im_format_address [value_if_exists ha_line1] [value_if_exists ha_line2] [value_if_exists ha_city] [value_if_exists ha_state] [value_if_exists ha_postal_code]]

    if { ![empty_string_p $address] } {
	append page_content "
	<p><table cellpadding=0 border=0 cellspacing=0>
	<tr>
	<td valign=top><em>Home address: </em></td>
	<td>$address</td>
	</tr>
	</table>

	"
    }

    if [exists_and_not_null skills] {
	append page_content "<p><em>Special skills:</em> $skills\n";
    }

    if [exists_and_not_null educational_history] {
	append page_content "<p><em>Degrees/Schools:</em> $educational_history\n";
    }

    if [exists_and_not_null last_degree_completed] {
	append page_content "<p><em>Last Degree Completed:</em> $last_degree_completed\n";
    }

    if [exists_and_not_null bio] {
	append page_content "<p><em>Biography:</em> $bio\n";
    }

    if [exists_and_not_null note] {
	append page_content "<p><em>Other information:</em> $note\n";
    }

    if {$looking_at_self_p} {
	set return_url [im_url_with_query]
	if { $user_employee_p } {
	    append page_content "<p>(<A HREF=[im_url_stub]/users/info-update?[export_url_vars return_url]>edit</A>)\n"
	} else {
	    # Non-employees should just use the public update page
	    append page_content "<p>(<A HREF=/pvt/basic-info-update?[export_url_vars return_url]>edit</A>)\n"
	}
    }

    if { $user_employee_p } {
	append page_content "
    <p><i>Current projects:</i><ul>\n"

	set projects_html ""

	set sql \
	    "select user_group_name_from_id(group_id) as project_name, parent_id,
                    decode(parent_id,null,null,user_group_name_from_id(parent_id)) as parent_project_name,
                    group_id as project_id
               from im_projects p
              where p.project_status_id in (select project_status_id
                                              from im_project_status 
                                             where project_status='Open' 
                                                or project_status='Future')
                and ad_group_member_p ( :user_id, p.group_id ) = 't'
            connect by prior group_id=parent_id
              start with parent_id is null"

	set projects_html ""
	db_foreach current_projects_for_employee $sql {
	    append projects_html "  <li> "
	    if { ![empty_string_p $parent_id] } {
		append projects_html "<a href=[im_url_stub]/projects/view?group_id=$parent_id>$parent_project_name</a> : "
	    }
	    append projects_html "<a href=[im_url_stub]/projects/view?group_id=$project_id>$project_name</a>\n"
	}
	if { [empty_string_p $projects_html] } {
	    set projects_html "  <li><i>None</i>\n"
	}

	append page_content "
	$projects_html
    </ul>
    "

	set sql "select start_date as unformatted_start_date, to_char(start_date, 'Mon DD, YYYY') as start_date, to_char(end_date,'Mon DD, YYYY') as end_date, contact_info, initcap(vacation_type) as vacation_type, vacation_id,
    description from user_vacations where user_id = :user_id 
    and (start_date >= to_date(sysdate,'YYYY-MM-DD') or
    (start_date <= to_date(sysdate,'YYYY-MM-DD') and end_date >= to_date(sysdate,'YYYY-MM-DD')))
    order by unformatted_start_date asc"

	set office_absences ""
	db_foreach vacations_for_employee $sql {
	    if { [empty_string_p $vacation_type] } {
		set vacation_type "Vacation"
	    }
	    append office_absences "  <li><b>$vacation_type</b>: $start_date - $end_date, <br>$description<br>
	    Contact info: $contact_info"
	    
	    if { $looking_at_self_p || $user_admin_p } {
		append office_absences "<br><a href=[im_url]/absences/edit?[export_url_vars vacation_id]>edit</a>"
	    }
	}
	
	if { ![empty_string_p $office_absences] } {
	    append page_content "
	<p>
	<i>Office Absences:</i>
	<ul>
	$office_absences
	</ul>
	"
        }

	if { [ad_parameter TrackHours intranet 0] && [im_user_is_employee_p $user_id] } {
	    append page_content "
	<p><a href=[im_url]/hours/index?on_which_table=im_projects&[export_url_vars user_id]>View this person's work log</a>
	</ul>
	"
        }

    }

    append page_content "</ul>\n"

    # Append a list of all the user's groups
    set sql "select ug.group_id, ug.group_name 
               from user_groups ug
              where ad_group_member_p ( :user_id, ug.group_id ) = 't'
              order by lower(group_name)"
    set groups ""
    db_foreach groups_user_belong_to $sql {
	append groups "  <li> $group_name\n"
    }
    if { ![empty_string_p $groups] } {
	append page_content "<p><b>Groups to which this user belongs</b><ul>\n$groups</ul>\n"
    }

    # don't sign it with the publisher's email address!
    return $page_content
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

ad_proc im_spam_multi_group_exists_clause { 
    bind
    group_id_list 
} {
    returns a portion of an sql where clause that begins
    with " and exists..." and includes all the groups in the 
    comma separated list of group ids (group_id_list)
} {
    set criteria [list]
    set ctr 0
    foreach group_id [split $group_id_list ","] {
	set group_id [string trim $group_id]
	if { [empty_string_p $group_id] } {
	    continue
	}
	set var_name im_spam_multi_group_$ctr
	ns_set put $bind $var_name $group_id
	lappend criteria "ad_group_member_p(u.user_id, :$var_name) = 't'"
	incr ctr
    }
    if { [llength $criteria] > 0 } {
	return " and [join $criteria "\n and "] "
    } else {
	return ""
    }
}

ad_proc im_spam_number_users { group_id_list {all_or_any "all"} } {
    Returns the number of users that belong to all/any of the groups in 
    the comma separated list of group ids (group_id_list)
} {
    set bind_vars [ns_set create]
    set ctr 0
    # Bind all the group ids... There's probably a much better way to
    # do this, but I can't think of one right now
    set criteria [list]
    foreach group_id [split $group_id_list ","] {
	incr ctr
	ns_set put $bind_vars group_id_$ctr $group_id
	lappend criteria "(select 1 from user_group_map ugm where u.user_id=ugm.user_id and ugm.group_id=:group_id_${ctr})"
    }
    if { $ctr == 0 } {
	# What else can we return?
	return 0
    }
    if { "$all_or_any" == "all" } {
	set ugm_clause " and exists [join $criteria " and exists "] "
    } else {
	set ugm_clause " or exists [join $criteria " or exists "] "
    }
    set value [db_string number_users_in_groups \
	    "select count(distinct u.user_id)
               from users_active u, user_group_map ugm
              where u.user_id=ugm.user_id $ugm_clause" -bind $bind_vars]
    ns_set free $bind_vars
    return $value
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

ad_proc im_hours_for_user { user_id { html_p t } { number_days 7 } } {
    Returns a string in html or text format describing the number of
    hours the specified user logged and what s/he noted as work done in
    those hours.  
} {
    set sql "select g.group_id, g.group_name, nvl(h.note,'no notes') as note, 
		    to_char( day, 'Dy, MM/DD/YYYY' ) as nice_day, h.hours
               from im_hours h, user_groups g
	      where g.group_id = h.on_what_id
     	        and h.on_which_table = 'im_projects'
                and h.day >= sysdate - :number_days
                and user_id=:user_id
              order by lower(g.group_name), day"
    
    set last_id -1
    set pcount 0
    set num_hours 0
    set html_string ""
    set text_string ""

    db_foreach hours_for_user $sql {
	if { $last_id != $group_id } {
	    set last_id $group_id
	    if { $pcount > 0 } {
		append html_string "</ul>\n"
		append text_string "\n"
	    }
	    append html_string " <li><b>$group_name</b>\n<ul>\n"
	    append text_string "$group_name\n"
	    set pcount 1
	}
	append html_string "   <li>$nice_day ($hours [util_decode $hours 1 "hour" "hours"]): &nbsp; <i>$note</i>\n"
	append text_string "  * $nice_day ($hours [util_decode $hours 1 "hour" "hours"]): $note\n"
	set num_hours [expr $num_hours + $hours]
    }

    # Let's get the punctuation right on days
    set number_days_string "$number_days [util_decode $number_days 1 "day" "days"]"

    if { $num_hours == 0 } {
	set text_string "No hours logged in the last $number_days_string."
	set html_string "<b>$text_string</b>"
    } else {
	if { $pcount > 0 } {
	    append html_string "</ul>\n"
	    append text_string "\n"
	}
        set html_string "<b>$num_hours [util_decode $num_hours 1 hour hours] logged in the last $number_days_string:</b>
<ul>$html_string</ul>"
        set text_string "$num_hours [util_decode $num_hours 1 hour hours] logged in the last $number_days_string:
$text_string"
    }
        
    return [util_decode $html_p "t" $html_string $text_string]
}

# ------------------------------------------------------------------------
# functions for printing the org chart
# ------------------------------------------------------------------------

ad_proc im_print_employee {person rowspan} "print function for org chart" {
    set user_id [fst $person]
    set employee_name [snd $person]
    set currently_employed_p [thd $person]

# Removed job title display
#    set job_title [lindex $person 3]

    if { $currently_employed_p == "t" } {

# Removed job title display
#	if { $rowspan>=2 } {
#	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br><i>$job_title</i>\n"
#	} else {
	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br>\n"
#	}
    } else {
	return "<i>Position Vacant</i>"
    }
}

ad_proc im_prune_org_chart {tree} "deletes all leaves where currently_employed_p is set to vacant position" {
    set result [list [head $tree]]
    # First, recursively process the sub-trees.
    foreach subtree [tail $tree] {
	set new_subtree [im_prune_org_chart $subtree]
	if { ![null_p $new_subtree] } {
	    lappend result $new_subtree
	}
    }
    # Now, delete vacant leaves.
    # We also delete vacant inner nodes that have only one child.
    # 1. if the tree only consists of one vacant node
    #    -> return an empty tree
    # 2. if the tree has a vacant root and only one child
    #    -> return the child 
    # 3. otherwise
    #    -> return the tree 
    if { [thd [head $result]] == "f" } {
	switch [llength $result] {
	    1       { return [list] }
	    2       { return [snd $result] }
	    default { return $result }
	}
    } else {
	return $result
    }
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



ad_proc im_default_nav_header { previous_page next_page { search_action "" } { search_target "" } { submit_text "Go" } } {
    Returns appropriately punctuated links for previous and next pages. 
} {
    set link [im_maybe_insert_link $previous_page $next_page " | "]
    if { [empty_string_p $search_action] } {
	return $link
    }
    return "<form name=im_header_form method=get action=\"[ad_quotehtml $search_action]\">
<input type=hidden name=target [export_form_value search_target]>
<input type=text name=keywords [export_form_value search_default]>
<input type=submit value=\"[ad_quotehtml $submit_text]\">
[util_decode $link "" "" "<br>$link"]
</form>
"
}



ad_proc im_employees_initial_list {} {
    Memoizes and returns a list where the ith element is the user's
    last initital and the i+1st element is the number of employees
    with that initial
} {
    return [im_memoize_list select_employees_initials \
	    "select im_first_letter_default_to_a(u.last_name), count(*)
               from im_employees_active u
              group by im_first_letter_default_to_a(u.last_name)"]
}



ad_proc im_groups_initial_list { parent_group_id } {
    Memoizes and returns a list where the ith element is the first
    initital of the group name and the i+1st element is the number of 
    groups with that initial. Only includes groups whose parent_group_id
    is as specified.
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars parent_group_id $parent_group_id
    return [im_memoize_list -bind $bind_vars select_groups_initials \
	    "select im_first_letter_default_to_a(ug.group_name), count(*)
               from user_groups ug
              where ug.parent_group_id = :parent_group_id
              group by im_first_letter_default_to_a(ug.group_name)"]
}

ad_proc im_all_letters { } {
    returns a list of all A-Z letters in uppercase
} {
    return [list A B C D E F G H I J K L M N O P Q R S T U V W X Y Z] 
}

ad_proc im_all_letters_lowercase { } {
    returns a list of all A-Z letters in uppercase
} {
    return [list a b c d e f g h i j k l m n o p q r s t u v w x y z] 
}

ad_proc im_employees_alpha_bar { { letter "" } { vars_to_ignore "" } } {
    Returns the alpha bar for employees.
} {
    return [im_alpha_nav_bar $letter [im_employees_initial_list] $vars_to_ignore]
}

ad_proc im_groups_alpha_bar { parent_group_id { letter "" } { vars_to_ignore "" } } {
    Returns the alpha bar for user_groups whose parent group is as
    specified.  
} {
    return [im_alpha_nav_bar $letter [im_groups_initial_list $parent_group_id] $vars_to_ignore]
}

ad_proc im_alpha_nav_bar { letter initial_list {vars_to_ignore ""} } {
    Returns an A-Z bar with greyed out letters not
    in initial_list and bolds "letter". Note that this proc returns the
    empty string if there are fewer than NumberResultsPerPage records.
    
    inital_list is a list where the ith element is a letter and the i+1st
    letter is the number of times that letter appears.  
} {

    set min_records [ad_parameter NumberResultsPerPage intranet 50]
    # Let's run through and make sure we have enough records
    set num_records 0
    foreach { l count } $initial_list {
	incr num_records $count
    }
    if { $num_records < $min_records } {
	return ""
    }

    set url "[ns_conn url]?"
    set vars_to_ignore_list [list "letter"]
    foreach v $vars_to_ignore { 
	lappend vars_to_ignore_list $v
    }

    set query_args [export_ns_set_vars url $vars_to_ignore_list]
    if { ![empty_string_p $query_args] } {
	append url "$query_args&"
    }
    
    set html_list [list]
    foreach l [im_all_letters_lowercase] {
	if { [lsearch -exact $initial_list $l] == -1 } {
	    # This means no user has this initial
	    lappend html_list "<font color=gray>$l</font>"
	} elseif { [string compare $l $letter] == 0 } {
	    lappend html_list "<b>$l</b>"
	} else {
	    lappend html_list "<a href=${url}letter=$l>$l</a>"
	}
    }
    if { [empty_string_p $letter] || [string compare $letter "all"] == 0 } {
	lappend html_list "<b>All</b>"
    } else {
	lappend html_list "<a href=${url}letter=all>All</a>"
    }
    if { [string compare $letter "scroll"] == 0 } {
	lappend html_list "<b>Scroll</b>"
    } else {
	lappend html_list "<a href=${url}letter=scroll>Scroll</a>"
    }
    return [join $html_list " | "]
}

ad_proc im_alpha_bar { target_url default_letter bind_vars} {
    Returns a horizontal alpha bar with links
} {
    set alpha_list [im_all_letters_lowercase]
    set alpha_list [linsert $alpha_list 0 All]
    set default_letter [string tolower $default_letter]

    ns_set delkey $bind_vars "letter"
    set params [list]
    set len [ns_set size $bind_vars]
    for {set i 0} {$i < $len} {incr i} {
	set key [ns_set key $bind_vars $i]
	set value [ns_set value $bind_vars $i]
	if {![string equal $value ""]} {
	    lappend params "$key=[ns_urlencode $value]"
	}
    }
    set param_html [join $params "&"]

    set html "&nbsp;"
    foreach letter $alpha_list {
	if {[string equal $letter $default_letter]} {
	    append html "<font color=white>$letter</font> &nbsp; \n"
	} else {
	    set url "$target_url?letter=$letter&$param_html"
	    append html "<A HREF=$url>$letter</A>&nbsp;\n"
	}
    }
    append html ""
    return $html
}


ad_proc im_select_row_range {sql firstrow lastrow} {
    a tcl proc curtisg wrote to return a sql query that will only 
    contain rows firstrow - lastrow
} {
    return "select im_select_row_range_y.*
              from (select im_select_row_range_x.*, rownum fake_rownum 
                      from ($sql) im_select_row_range_x
                     where rownum <= $lastrow) im_select_row_range_y
             where fake_rownum >= $firstrow"
}

ad_proc im_force_user_to_log_hours { conn args why } {
    If a user is not on vacation and has not logged hours since
    yesterday midnight, we ask them to log hours before using the
    intranet. Sets state in session so user is only asked once 
    per session.
} {
    set user_id [ad_get_user_id]

    if { ![im_enabled_p] || ![ad_parameter TrackHours intranet 0] } {
	# intranet or hours-logging not turned on. Do nothing
	return filter_ok
    } 
    
    if { ![im_permission $user_id add_hours] } {
	# The user doesn't have "permissions" to log his hours
	return filter_ok
    } 
    
    set last_prompted_time [ad_get_client_property intranet user_asked_to_log_hours_p]

    if { ![empty_string_p $last_prompted_time] && \
	    $last_prompted_time > [expr [ns_time] - 60*60*24] } {
	# We have already asked the user in this session, within the last 24 hours, 
	# to log their hours
	return filter_ok
    }
    # Let's see if the user has logged hours since 
    # yesterday midnight. 
    # 

    if { $user_id == 0 } {
	# This can't happen on standard acs installs since intranet is protected
	# But we check any way to prevent bugs on other installations
	return filter_ok
    }

    db_1row hours_logged_by_user \
	    "select decode(count(*),0,0,1) as logged_hours_p, 
                    to_char(sysdate - 1,'J') as julian_date
	       from im_hours h, users u
	      where h.user_id = :user_id
	        and h.user_id = u.user_id
	        and h.hours > 0
	        and h.day <= sysdate
	        and (u.on_vacation_until >= sysdate
    	             or h.day >= trunc(u.second_to_last_visit-1))"

    # Let's make a note that the user has been prompted 
    # to update hours or is okay. This saves us the database 
    # hit next time. 
    ad_set_client_property -persistent f intranet user_asked_to_log_hours_p [ns_time]

    if { $logged_hours_p } {
	# The user has either logged their hours or
	# is on vacation right now
	return filter_ok
    }

    # Pull up the screen to log hours for yesterday
    set return_url [im_url_with_query]
    ad_returnredirect "[im_url_stub]/hours/new?[export_url_vars return_url julian_date]"
    return filter_return
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

ad_proc absence_list_for_user_and_time_period {user_id first_julian_date last_julian_date} {
    For a given user and time period, this proc
    returns a list of elements where each element 
    corresponds to one day and describes its
    "work/vacation type".
} {
    # Select all vacation periods that have at least one day
    # in the given time period.
    set sql "
        select to_char(start_date,'J') as start_date,
               to_char(end_date,'J') as end_date,
               vacation_type
        from user_vacations
        where user_id = :user_id
        and   start_date <= to_date(:last_julian_date,'J')
        and   end_date   >= to_date(:first_julian_date,'J')
    "
    # Initialize array with "work" elements.
    for {set i $first_julian_date} {$i<=$last_julian_date} {incr i} {
        set vacation($i) work
    }
    # Process vacation periods and modify array accordingly.
    db_foreach vacation_period $sql {
        for {set i [max $start_date $first_julian_date]} {$i<=[min $end_date $last_julian_date]} {incr i } {
            set vacation($i) $vacation_type
        }
    }
    # Return the relevant part of the array as a list.
    set result [list]
    for {set i $first_julian_date} {$i<=$last_julian_date} {incr i} {
        lappend result $vacation($i)
    }
    return $result
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
    set domain [ad_parameter EmailDomain intranet ""]
    if { [empty_string_p $domain] || ![ad_parameter LogEmailToGroupsP intranet 0] } {
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
