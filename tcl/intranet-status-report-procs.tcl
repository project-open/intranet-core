# /packages/intranet-core/tcl/intranet-status-report-defs.tcl
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
    Procedures used to generate the intranet status report
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author Tracy Adams (teadams@mit.edu)
    @author Michael Pih (pihman@arsdigita.com)
    @author frank.bergmann@project-open.com
}

ns_share im_status_report_section_list

# the following 3 procedure within this tcl file are never called:
#   im_vacationing_employees
#   im_future_vacationing_employees
#   im_customer_comments

ad_proc im_add_to_status_report { title proc_name { cache_p "f" } } {
    Adds proc_name to the list of procs needed to generete the
    status_report. If cache_p is t, then we cache the result to reuse
    later (like when we're sending the status report to all employees). 
    You want to cache all information that does not depend on the
    current user id.
} {
    ns_share im_status_report_section_list    
    if { ![info exists im_status_report_section_list] || \
	    [lsearch -glob $im_status_report_section_list $proc_name] == -1 } {
	lappend im_status_report_section_list [list $title $proc_name $cache_p]
    }
}


ad_proc set_status_report_user_preferences {} {
    Sets the variables killed_sections, killed_offices, my_projects_only_p, my_customers_only_p in the environment.  If the user has no preferences, then set these as empty lists
} {
    uplevel {
	set sql "select killed_sections, killed_offices,
                 my_projects_only_p, my_customers_only_p
                 from im_status_report_preferences
                 where user_id = :user_id"
	if { ![db_0or1row status_report_preferences $sql] } {
	    set killed_sections ""
	    set killed_offices ""
	    set my_projects_only_p "f"
	    set my_customers_only_p "f"
	}
	db_release_unused_handles
    }
}


im_add_to_status_report "Population Count" im_num_employees
im_add_to_status_report "New Employees" im_recent_employees
im_add_to_status_report "Future Employees" im_future_employees
im_add_to_status_report "Employees Out of the Office" im_absent_employees
im_add_to_status_report "Future Office Excursions" im_future_absent_employees
im_add_to_status_report "Delinquent Employees" im_delinquent_employees f
im_add_to_status_report "Downloads" im_downloads_status
im_add_to_status_report "Customers: Bids Out" im_customers_bids_out
im_add_to_status_report "Customers: Status Changes" im_customers_status_change
im_add_to_status_report "New Registrants at [ad_parameter -package_id [ad_acs_kernel_id] SystemURL]" im_new_registrants


# Too much correspondance now!
# im_add_to_status_report "Customers: Correspondence" im_customers_comments t
# this conflicted with some security stuff (ad_sec_user_id) that I didn't understand
# im_add_to_status_report "News" im_news_status t

proc im_news_status { {coverage ""} {report_date ""} {purpose ""} } {
    if { [empty_string_p $coverage] } {
	set coverage 1
    } 
    if { [empty_string_p $report_date] } {
	set since_when [db_string select_since_sysdate "select to_date(sysdate, 'YYYY-MM-DD') - :coverage from dual"]
    } else {
	set since_when [db_string select_since_date "select to_date(:report_date, 'YYYY-MM-DD') - :coverage from dual"]
    }
    return [news_new_stuff $since_when "f" $purpose]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_project_reports"] == -1 } {
    lappend im_status_report_section_list [list "Progress Reports" im_project_reports]
}

# teadams on December 10th, 1999
# modified ad-new-stuff.tcl to work for the status reports
# I tried to extend ad_new_stuff to do so, but it got too hairy.
ad_proc im_status_report {{coverage ""} {report_date ""} {purpose "web_display"} {ns_share_list "im_status_report_section_list"} {user_id ""} } {
    Returns a string of new stuff on the site.  COVERAGE and
    REPORT_DATE are ANSI date.  The PURPOSE argument can be
    \"web_display\" (intended for an ordinary user), \"site_admin\" (to
    help the owner of a site nuke stuff), or \"email_summary\" (in which
    case we get plain text back).  These arguments are passed down to the
    procedures on the ns_share'd ns_share_list."  
} {

    if { [empty_string_p $user_id] } {
	set user_id 0
    }

    # let's default the date if we didn't get one	
    if { [empty_string_p $coverage] || [empty_string_p $report_date] } {
	set the_sysdate [db_string sysdate_from_dual "select sysdate from dual"]
	if { [empty_string_p $coverage] } {
	    set since_when $the_sysdate
	} 
	if { [empty_string_p $report_date] } {
	    set report_date $the_sysdate
	}
    }

    ns_share $ns_share_list
    set result_list [list]
    
    # module_name_proc_history will ensure that we do not have duplicates in the 
    # status report, even if the same procedure is registered twice 
    # with ns_share_list
    set module_name_proc_history [list]

    set_status_report_user_preferences
    # killed_sections, killed_offices, my_projects_only_p, my_customers_only_p

    foreach sublist [set $ns_share_list] {
	
	set module_name [lindex $sublist 0]
	set module_proc [lindex $sublist 1]
	set module_cache_p [lindex $sublist 2]
	
	if { [lsearch -exact $module_name_proc_history "${module_name}_$module_proc"] > -1 } {
	    # This is a duplicate call to the same procedure! Skip it
	    continue
	}

	# now see if this section is 'killed'
	set sql_query "select sr_section_id from im_status_report_sections
                       where upper(sr_section_name) = upper(:module_name)
                       or upper(sr_function_name) = upper(:module_proc)"
	set sr_section_id [db_string killed_section_p $sql_query -default 0] 
	if { $sr_section_id > 0 && \
		[lsearch -exact $killed_sections $sr_section_id] != -1 } {
	    # This is a killed section! Skip it
	    continue
	}

	set result_elt ""
	set subresult ""

	if { [string compare $module_cache_p "t"] == 0 } {
	    if { [catch {set subresult [util_memoize [list $module_proc $coverage $report_date $purpose $user_id]]} err_msg] } {
		ns_log error "im_status_report got an error \"$err_msg\" trying to execute: $module_proc $coverage $report_date $purpose" 
	    }
	} else {
	    if { [catch {set subresult [eval "$module_proc $coverage $report_date $purpose $user_id"]} err_msg] } {
		ns_log error "im_status_report got an error \"$err_msg\" trying to execute: $module_proc $coverage $report_date $purpose" 
	    } 
	}
	if { ![empty_string_p $subresult] } {
	    # we got something, let's write a headline 
	    if { [string compare $purpose "email_summary"] == 0 } {
		append result_elt "[string toupper $module_name]\n\n"
	    } else {
		append result_elt "<h3><a name=\"$module_name\">$module_name</a></h3>\n\n"
	    }
	    append result_elt $subresult
	    append result_elt "\n\n"
	    lappend result_list $result_elt
	}
    }

    db_release_unused_handles
    return [join $result_list ""]
}

ad_proc im_vacationing_employees { {coverage ""} {report_date ""} {purpose ""} {user_id ""} } "Returns a string that gives a list of vacationing employees" {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set sql "select distinct u.user_id, u.first_names, u.last_name, u.email, 
to_char(user_vacations.start_date,'Mon DD, YYYY') || ' - ' || to_char(user_vacations.end_date,'Mon DD, YYYY') as dates, user_vacations.end_date
from users_active u, user_vacations, user_group_map ugm
where u.user_id = ugm.user_id
and ugm.group_id = [im_employee_group_id]
and u.user_id = user_vacations.user_id 
and user_vacations.start_date < to_date(:report_date, 'YYYY-MM-DD')
and user_vacations.end_date > to_date(:report_date, 'YYYY-MM-DD')
order by user_vacations.end_date"

    set return_list [list]
    db_foreach vacationing_employees $sql {

	if {[string compare $purpose "web_display"] == 0 } {
	    lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> - $dates"
	} else {
	    lappend return_list "$first_names $last_name - $dates"
	}
    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list "\n"] "
    }

}

ad_proc im_recent_employees { 
    {coverage ""} {report_date ""} {purpose ""} {user_id ""}
} {
    "Returns a string that gives a list of recent employees" 
} {
    
    if { [empty_string_p $coverage] } {
	set coverage 1
    }

    set bind_vars [ns_set create]
    ns_set put $bind_vars coverage $coverage

    if { [empty_string_p $report_date] } {
	set report_date_sql sysdate
    } else {
	set report_date_sql "to_date(:report_date)"
	ns_set put $bind_vars report_date $report_date
    }
    set group_type [ad_parameter -package_id [im_package_core_id] IntranetGroupType intranet intranet]
    ns_set put $bind_vars group_type $group_type

    # check for killed_offices and update the sql query as necessary
    set sub_sql ""
    if { ![empty_string_p $user_id] } {
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p    

	if { ![empty_string_p $killed_offices] } {
	    set killed_offices_csv [join $killed_offices ","]    
	    set sub_sql "and (not exists (select 1 
	                       from user_group_map
	                       where user_id = u.user_id
                               and group_id in ($killed_offices_csv))
                            or u.user_id = :user_id)"
	    ns_set put $bind_vars user_id $user_id
	}
    }

    set sql "select first_names, last_name, email, start_date, u.user_id,
         group_names_of_user_by_type(u.user_id, :group_type) as group_names_of_user
         from users_active u, im_employees info
         where u.user_id = info.user_id
         and trunc(start_date) <= trunc($report_date_sql)
         and nvl(info.termination_date,sysdate) >= $report_date_sql
         and start_date + :coverage > $report_date_sql
         /* coverage = $coverage */ $sub_sql 
         order by start_date"
    set return_list [list]

    # cache the query if it's not personalized
    if { [empty_string_p $sub_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { first_names last_name email start_date user_id \
		group_names_of_user } \
		[im_memoize_list -bind $bind_vars recent_employees $sql] {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> ($email) - Groups: $group_names_of_user"
	    } else {
		lappend return_list "$first_names $last_name ($email) - Groups: $group_names_of_user"
	    }
	}
    } else {
	db_foreach select_recent_employees $sql {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> ($email) - Groups: $group_names_of_user"
	    } else {
		lappend return_list "$first_names $last_name ($email) - Groups: $group_names_of_user"
	    }
	}
    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list ", "] "
    }
}

ad_proc im_future_employees { {coverage ""} {report_date ""} {purpose ""} {user_id ""} } "Returns a string that gives a list of future employees" {

    set bind_vars [ns_set create]

    # some default vars
    if { [empty_string_p $report_date] } {
	set report_date_sql sysdate
    } else {
	set report_date_sql "to_date(:report_date)"
	ns_set put $bind_vars report_date $report_date
    }	    

    # check killed offices and update the sql query as necessary
    set sub_sql ""
    if { ![empty_string_p $user_id] } {
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p
	if { ![empty_string_p $killed_offices] } {
	    set killed_offices_csv [join $killed_offices ","]
	    set sub_sql "and (not exists (select 1
	                        from user_group_map
                                where user_id = u.user_id
                                and group_id in ($killed_offices_csv))
                              or u.user_id = :user_id)"
	    ns_set put $bind_vars user_id $user_id
	}
    }

    set sql "select u.user_id, first_names, last_name, email, start_date, 
         (select job_title from im_job_titles 
          where original_job_id = job_title_id) as job_title, 
         decode(im_employee_percentage_time.percentage_time,NULL,'',im_employee_percentage_time.percentage_time||'% ') as percentage_string, 
         group_names_of_user_by_type(u.user_id,'[ad_parameter -package_id [im_package_core_id] IntranetGroupType intranet intranet]') as group_names_of_user
         from users_active u, im_employees info, im_employee_percentage_time
         where u.user_id = info.user_id
         $sub_sql and im_employee_percentage_time.user_id = info.user_id
         and (im_employee_percentage_time.start_block = (select min(start_block) from
                 im_employee_percentage_time 
                 where im_employee_percentage_time.user_id = info.user_id) 
              or im_employee_percentage_time.start_block is null)
         and info.start_date > $report_date_sql
         order by start_date"

    set return_list [list]

    if { [empty_string_p $sub_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { user_id first_names last_name email start_date job_title \
		percentage_string group_names_of_user } \
		[im_memoize_list -bind $bind_vars future_employees $sql] {
	    if { [string compare $purpose "web_display"] == 0 } {	 
		lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> ($start_date) Groups: $group_names_of_user"
	    } else {
		lappend return_list "$first_names $last_name ($start_date) Groups: $group_names_of_user"
	    }
	}
    } else {
	db_foreach select_future_employees $sql {
	    if { [string compare $purpose "web_display"] == 0 } {	 
		lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> ($start_date) Groups: $group_names_of_user"
	    } else {
		lappend return_list "$first_names $last_name ($start_date) Groups: $group_names_of_user"
	    }
	}
    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list "\n"]"
    }
}

ad_proc im_absent_employees_helper { bind_vars sql purpose sub_sql} {
    Queries user_vacations and formats the results
} {
    set web_string [list]
    set text_string [list]
    
    set last_type ""

    # cache the query if it's not personalized
    if { [empty_string_p $sub_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { user_id first_names last_name email end_date description vacation_type dates} \
		[im_memoize_list -bind $bind_vars im_absent_employees $sql] {
	    if { [string compare $last_type $vacation_type] != 0 } {
		if { ![empty_string_p $last_type] } {
		    append web_string "</ul>\n"
		    append text_string "\n"
		}
		append web_string "<li><b>$vacation_type</b>\n<ul>\n"
		append text_string "[string toupper $vacation_type]\n"
		set last_type $vacation_type
	    }
	
	    append web_string " <li> <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> - $dates: $description\n"
	    append text_string "[wrap_string "* $first_names $last_name - $dates: $description"]\n"
	}
    } else {
	db_foreach random_absent_employees_query $sql -bind $bind_vars {
	    if { [string compare $last_type $vacation_type] != 0 } {
		if { ![empty_string_p $last_type] } {
		    append web_string "</ul>\n"
		    append text_string "\n"
		}
		append web_string "<li><b>$vacation_type</b>\n<ul>\n"
		append text_string "[string toupper $vacation_type]\n"
		set last_type $vacation_type
	    }
	
	    append web_string " <li> <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> - $dates: $description\n"
	    append text_string "[wrap_string "* $first_names $last_name - $dates: $description"]\n"
	}
    }

    if { [empty_string_p $web_string] } {
	return "None\n"
    }
    
    if { [string compare $purpose "web_display"] == 0 } {
	# Close out the previously opened ul tag
	append web_string "</ul>\n"
	return "<ul>$web_string</ul>\n"
    } else {
	return "$text_string\n"
    }
}

ad_proc im_absent_employees { {coverage ""} {report_date ""} {purpose ""} {user_id ""}} {
    Returns a string that gives a list of vacationing employees
} {

    if { [empty_string_p $coverage] } {
	set coverage 1
    }

    set bind_vars [ns_set create]
    ns_set put $bind_vars coverage $coverage
    if { [empty_string_p $report_date] } {
	set report_date_sql "sysdate"
    } else {
	set report_date_sql "to_date(:report_date)"
	ns_set put $bind_vars report_date $report_date
    }


    # check killed offices and update the sql query as necessary

    set sub_sql ""
    if { ![empty_string_p $user_id] } {
	ns_set put $bind_vars user_id $user_id
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p

	if { ![empty_string_p $killed_offices] } {
	    set killed_offices_csv [join $killed_offices ","]
	    set sub_sql "and (not exists (select 1 
	                        from user_group_map
	                        where user_id = u.user_id
                                and group_id in ($killed_offices_csv))
	                      or u.user_id = :user_id)"
	}
    }

    set sql "select u.user_id, u.first_names, u.last_name, u.email, 
      uv.end_date, uv.description, uv.vacation_type,
      to_char(uv.start_date,'Mon DD, YYYY') || ' - ' || to_char(uv.end_date,'Mon DD, YYYY') as dates
      from users_active u, im_employees info, user_vacations uv
      where u.user_id = uv.user_id 
      and u.user_id = info.user_id
      and info.start_date < $report_date_sql
      and nvl(info.termination_date,$report_date_sql) >= $report_date_sql
      and trunc(uv.start_date) <= trunc($report_date_sql)
      and trunc(uv.end_date) >= trunc($report_date_sql + :coverage)
      /* coverage = $coverage */ $sub_sql 
      order by uv.vacation_type, uv.start_date"

    return [im_absent_employees_helper $bind_vars $sql $purpose $sub_sql]
}

ad_proc im_future_absent_employees { {coverage ""} {report_date ""} {purpose ""} {user_id ""} } {
    "Returns a string that gives a list of recent employees" } {
	
    if { [empty_string_p $coverage] } {
	set coverage 1
    }

    set bind_vars [ns_set create]
    ns_set put $bind_vars coverage $coverage
    if { [empty_string_p $report_date] } {
	set report_date_sql "sysdate"
    } else {
	ns_set put $bind_vars report_date $report_date
	set report_date_sql "to_date(:report_date)"
    }
    

    # check killed offices and update the sql query as necessary
    set sub_sql ""
    if { ![empty_string_p $user_id] } {
	ns_set put $bind_vars user_id $user_id
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p

	if { ![empty_string_p $killed_offices] } {
	    set killed_offices_csv [join $killed_offices ","]
	    set sub_sql "and (not exists (select 1
	                        from user_group_map
	                        where user_id = u.user_id
                                and group_id in ($killed_offices_csv))
	                      or u.user_id = :user_id)"
	}
    }

    set sql "select u.user_id, u.first_names, u.last_name, u.email, 
      uv.end_date, uv.description, uv.vacation_type,
      to_char(uv.start_date,'Mon DD, YYYY') || ' - ' || to_char(uv.end_date,'Mon DD, YYYY') as dates
      from users_active u, im_employees info, user_vacations uv
      where u.user_id = uv.user_id 
      and u.user_id = info.user_id
      and info.start_date < $report_date_sql
      and nvl(info.termination_date,$report_date_sql) >= $report_date_sql
      and uv.start_date > $report_date_sql
      and uv.start_date <= add_months($report_date_sql, :coverage)
      /* coverage = $coverage */ $sub_sql 
      order by uv.vacation_type, uv.start_date"

    return [im_absent_employees_helper $bind_vars $sql $purpose $sub_sql]
}

ad_proc im_customers_comments { {coverage ""} { report_date ""} {purpose ""} {user_id ""}} {
    "Returns a string that gives a list  of customer profiles that have had correspondences - comments - addedto them with in the period of the coverage date from the report date" 
} {
    if { [empty_string_p $report_date] } {
	set report_date [db_string sysdate_from_dual "select sysdate from dual"] 
    }

    set sql "select u.user_id, first_names, last_name, 
      general_comments.content, general_comments.html_p, user_groups.group_name,
      im_projects.group_id, comment_date, one_line, comment_id
      from users_active u, general_comments, im_projects, user_groups
      where u.user_id =general_comments.user_id
      and im_projects.group_id = general_comments.on_what_id
      and on_which_table = 'user_groups'
      and comment_date > to_date(:report_date, 'YYYY-MM-DD') - :coverage
      and user_groups.group_id = im_projects.group_id
      /* coverage = $coverage */ order by lower(group_name), comment_date"

    set return_list [list]
    set return_url "[im_url]/customers/view?[export_url_vars group_id]"
    db_foreach select_customer_comments $sql {
	
	if { [string compare $purpose "web_display"] == 0 } {
	    lappend return_list "<a href=/general-comments/view-one?[export_url_vars comment_id]&item=[ns_urlencode $group_name]&[export_url_vars return_url]>$one_line</a> -  <a href=[im_url_stub]/project-info?[export_url_vars project_id]>$name</a> by <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a> on [util_AnsiDatetoPrettyDate $comment_date]<br>
	    
	    [util_maybe_convert_to_html $content $html_p]
	    "
	} else {
    
	    lappend return_list "$one_line - $name by $first_names $last_name on [util_AnsiDatetoPrettyDate $comment_date]
	    \n
	    [util_striphtml $content]
	    
	    -- [im_url]/project-info?[export_url_vars project_id]
	    "
	}
    }

    set end_date [db_string sysdate_minus_coverage "select sysdate-$coverage from dual"]
    
    if {[llength $return_list] == 0} {
	return "No customer correspondences in period [util_AnsiDatetoPrettyDate $end_date] -  [util_AnsiDatetoPrettyDate $report_date].\n"
    }
    
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n [join $return_list "\n"] "
    }
}

ad_proc im_new_registrants { {coverage ""} {report_date ""} {purpose ""} {user_id ""} } {
    Returns the number of people who've registered over a period of time
} {

    set bind_vars [ns_set create]
    if { [empty_string_p $coverage] } {
	set coverage 1
    }
    ns_set put $bind_vars coverage $coverage

    if { [empty_string_p $report_date] } {
	set report_date_sql "sysdate"
    } else {
	set report_date_sql "to_date(:report_date,'YYYY-MM-DD')"
	ns_set put $bind_vars report_date $report_date
    }

    set sql "select count(1) as num_users, sysdate - :coverage as end_date
             from users 
    	     where registration_date > $report_date_sql - :coverage"

    #db_1row count_new_registrants $sql
    set first_row [lindex [im_memoize_list -bind $bind_vars count_new_registrants $sql] 0]
    set num_users [lindex $first_row 0]
    set end_date [lindex $first_row 1]

    return "[util_decode $num_users 0 "No new registrants" 1 "1 new registrant" "$num_users new registrants"] in period [util_AnsiDatetoPrettyDate $end_date] -  [util_AnsiDatetoPrettyDate $report_date].\n"
}

ad_proc im_customers_status_change { {coverage ""} {report_date ""} {purpose ""} {user_id ""} } {
    "Returns a string that gives a list of customers that have had a status change with in the coverage date from the report date.  It also displays what status change they have undergone.  Note that the most recent status change is listed for the given period." 
} {

    set bind_vars [ns_set create]
    ns_set put $bind_vars coverage $coverage
    ns_set put $bind_vars report_date $report_date

    # check killed customers and update the sql query as necessary
    set user_id_sql ""
    if { ![empty_string_p $user_id] } {
        set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p
	if { [string compare $my_customers_only_p "t"] == 0 } {
	    set user_id_sql "and ugm.user_id = :user_id"
	    ns_set put $bind_vars user_id $user_id
	}
    }

    set sql "select g.group_name, g.group_id, 
      to_char(status_modification_date,'Mon DD, YYYY') as status_modification_date,
      im_cust_status_from_id(customer_status_id) as status,
      im_cust_status_from_id(old_customer_status_id) as old_status
      from im_customers c, user_groups g, user_group_map ugm
      where status_modification_date > to_date([util_decode $report_date "" sysdate ":report_date"],'YYYY-MM-DD')-[util_decode $coverage "" 1 :coverage]
      and old_customer_status_id is not null
      and old_customer_status_id <> customer_status_id
      and c.group_id = g.group_id
      and ugm.group_id = g.group_id
      /* coverage = $coverage */ $user_id_sql 
      order by lower(group_name)"
	  
    set return_list [list]
    if { [empty_string_p $user_id_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { group_name group_id status_modification_date \
		status old_status} \
		[im_memoize_list -bind $bind_vars customer_status_changes $sql] {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/customers/view?[export_url_vars group_id]>$group_name</a> went from <b>$old_status</b> to <b>$status</b> on $status_modification_date." 
	    } else {
		lappend return_list "$group_name went from $old_status to $status on $status_modification_date."
	    }
	}
    } else {
	db_foreach customer_status_changes $sql {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/customers/view?[export_url_vars group_id]>$group_name</a> went from <b>$old_status</b> to <b>$status</b> on $status_modification_date." 
	    } else {
		lappend return_list "$group_name went from $old_status to $status on $status_modification_date."
	    }
	}
    }

    if {[llength $return_list] == 0} {
	set end_date [db_string sysdate_minus_coverage "select sysdate-[util_decode $coverage "" 1 ":coverage"] from dual"]
	if { [empty_string_p $report_date] } {
	    set report_date [db_string sysdate_from_dual "select sysdate from dual"]
	}
	return "No status changes in period [util_AnsiDatetoPrettyDate $end_date] -  [util_AnsiDatetoPrettyDate $report_date].\n"
    }
    
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n[join $return_list "\n"] "
    }    
}

ad_proc im_customers_bids_out {{coverage ""} {report_date ""} {purpose ""} {user_id ""} } {
    "Returns a string that gives a list of bids given out to customers" 
} {
    
    set bind_vars [ns_set create]

    # check killed customers and update the sql query as necessary
    set user_id_sql ""
    if { ![empty_string_p $user_id] } {
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p
	if { [string compare $my_customers_only_p "t"] == 0 } {
	    set user_id_sql " and ugm.user_id = :user_id "
	    ns_set put $bind_vars user_id $user_id
	}
    }

    set sql "select g.group_id, g.group_name, 
      to_char(c.status_modification_date, 'Mon DD, YYYY') as bid_out_date,
      u.first_names||' '||u.last_name as contact_name, u.email,
      decode(uc.work_phone,null,uc.home_phone,uc.work_phone) as contact_phone
      from user_groups g, im_customers c, users_active u, users_contact uc, 
        user_group_map ugm
      where g.parent_group_id = [im_customer_group_id]
      and g.group_id = c.group_id
      and ugm.group_id = c.group_id
      and c.primary_contact_id = u.user_id(+)
      and c.primary_contact_id = uc.user_id(+)
      and c.customer_status_id = (select customer_status_id 
        from im_customer_status
        where upper(customer_status) = 'BID OUT')
      $user_id_sql order by lower(group_name)"


    set return_list [list]

    if { [empty_string_p $user_id_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { group_id group_name bid_out_date contact_name \
		email contact_phone} \
		[im_memoize_list -bind $bind_vars customer_bids_out $sql] {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/customers/view?[export_url_vars group_id]>$group_name</a>, $bid_out_date[util_decode $contact_name  " " "" ", $contact_name"][util_decode $email "" "" ", <a href=mailto:$email>$email</a>"][util_decode $contact_phone "" "" ", $contact_phone"]"
	    } else {
		lappend return_list "$group_name, $bid_out_date[util_decode $contact_name " " "" ", $contact_name"][util_decode $email "" "" ", $email"][util_decode $contact_phone "" "" ", $contact_phone"]\n"
	    }
	}
    } else {
	db_foreach customer_bids_out $sql {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/customers/view?[export_url_vars group_id]>$group_name</a>, $bid_out_date[util_decode $contact_name  " " "" ", $contact_name"][util_decode $email "" "" ", <a href=mailto:$email>$email</a>"][util_decode $contact_phone "" "" ", $contact_phone"]"
	    } else {
		lappend return_list "$group_name, $bid_out_date[util_decode $contact_name " " "" ", $contact_name"][util_decode $email "" "" ", $email"][util_decode $contact_phone "" "" ", $contact_phone"]\n"
	    }
	}
    }

    if {[llength $return_list] == 0} {
	return "No bids out. \n"
    }
    
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n[join $return_list "\n"] "
    }
}

ad_proc im_delinquent_employees { {coverage ""} {report_date ""} {purpose ""} {user_id ""} {memoize_p "t"} } {
    "Returns a string that gives a list of recent employees" 
} {

    set target_user_id $user_id

    set bind_vars [ns_set create]
    ns_set put $bind_vars target_user_id $user_id

    if { [empty_string_p $report_date] } {
	set report_date_sql "sysdate"
    } else {
	set report_date_sql "to_date(:report_date,'YYYY-MM-DD')"
	ns_set put $bind_vars report_date $report_date
    }
    set employee_group_id [im_employee_group_id]


    # check killed offices and update the sql query as necessary
    set sub_sql ""
    if { ![empty_string_p $user_id] } {
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p

	if { ![empty_string_p $killed_offices] } {
	    set killed_offices_csv [join $killed_offices ","]
	    set sub_sql "and (not exists (select 1 
	                        from user_group_map
	                        where user_id = u.user_id
                                and group_id in ($killed_offices_csv))
	                      or u.user_id = :target_user_id)"
	}
    }

    # delinquent employees = employees who have not logged their 
    #   hours within the last 7 work (non-vacation) days from the report_date
    set sql "select u.user_id, u.email, u.first_names || ' ' || u.last_name as name
             from users_active u, im_employees info
             where u.user_id = info.user_id
             and info.start_date < $report_date_sql
             and nvl(info.termination_date,$report_date_sql) >= $report_date_sql
             and cl_delinquent_employee_p(u.user_id) = 0
             $sub_sql"

#             and im_delinquent_employee_p(u.user_id,$report_date_sql,7) = 1

    set count 0
    set return_string ""
    set return_list [list]
    # jsotil : 20010508 : list of single names for writing in a file
    set return_single_list [list]

    # cache the query if it's not personalized
    if { [empty_string_p $sub_sql] && $memoize_p == "t"} {
	# Memoize the sql query since it takes so long...
	# jsotil 20010511 : added email to this query
	foreach { user_id email name } [im_memoize_list -bind $bind_vars im_delinquent_employees $sql] {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$name</a>"
	    } else {
		lappend return_list $name
	    }

	    # jsotil : 20010511 : add user to list if is not authorized to be a delinquent
	    set user_login [cl_get_user_login_from_email $email]
	    if {  [cl_user_is_authorized_delinquent_user $user_login] != 1 } {
		ns_log Notice "***** im_delinquent_employees --> memoize_p : $user_login *****"
		lappend return_single_list $user_login
	    }
	}
    } else {
	db_foreach im_delinquent_employees $sql {
	    if { [string compare $purpose "web_display"] == 0 } {
		lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$name</a>"
	    } else {
		lappend return_list $name
	    }

	    # jsotil : 20010511 : add user to list if is not authorized to be a delinquent
	    set user_login [cl_get_user_login_from_email $email]
	    if {  [cl_user_is_authorized_delinquent_user $user_login] != 1 } {
		ns_log Notice "***** im_delinquent_employees: --> !memoize_p : $user_login *****"
		lappend return_single_list $user_login
	    }
 	}
    }
 
    if { [llength $return_list] > 0 } {
	##### jsotil 20010508 : write all delinquent users in a file to block access to H:/ for them.
	set delinquent_users_path "/var/log/delinquent"
	set list_stream [open $delinquent_users_path w+]
	puts $list_stream [join $return_single_list "\n"]
	flush $list_stream
	close $list_stream
	#####
	# jruiz 20030304: execute H lyon command
#	exec /root/cron/lyondelinquent
	if { [string compare $purpose "web_display"] == 0 } {
	    append return_string "
                     <blockquote>
                       <b>The following employees have not logged their work in over 7 days:</b> <br>
                       [join $return_list " | "]
                     </blockquote>"
        }  else {
	    append return_string "The following employees have not logged their work in over 7 days: 
                                  [join $return_list " | "]"
	}
    }

    set return_list [list]
    # to be on time with a status report
    # you have to fill out the following every 7 dates
    # a) If a survey exists for your project_type, fill it out
    # b) If not, the project report is a general comment

    set project_report_type_as_survey_list ""
    foreach type_survey_pair [ad_parameter_all_values_as_list ProjectReportTypeSurveyNamePair intranet] {
	set type_survey_list [split $type_survey_pair ","]
	set type [lindex $type_survey_list 0]
	set survey [lindex $type_survey_list 1]
	# we found a project type done with a survey
	
	lappend project_report_type_as_survey_list [string tolower $type]
    }


    set sql "select u.first_names || ' ' || u.last_name as name, u.user_id,
      g.group_id, g.group_name, im_project_types.project_type
      from im_projects p, user_groups g, im_employees_active u, im_project_types
      where p.parent_id is null 
      $sub_sql and p.project_type_id = im_project_types.project_type_id
      and p.requires_report_p = 't'
      and p.group_id = g.group_id
      and p.project_lead_id = u.user_id
      and p.project_status_id = (select project_status_id 
        from im_project_status
        where project_status = 'Open')
      and ((lower(project_type) not in ('[join  $project_report_type_as_survey_list "','"]')  
      and p.group_id not in (select on_what_id from general_comments 
        where on_which_table = 'user_groups'
        and comment_date between to_date($report_date_sql)-7 and to_date($report_date_sql)+1))
        or (lower(project_type) in ('[join $project_report_type_as_survey_list "','"]')  
          and not exists (select 1 from survsimp_responses
            where submission_date between to_date($report_date_sql)-7 
            and to_date($report_date_sql)+1 and survsimp_responses.group_id = p.group_id)))
      order by lower(im_project_types.project_type), lower(g.group_name)"
    # note: report_date + 1 about is to catch the case
    # where the user submitted it on that day

    set last_project_type "" 
    set web_string ""
    set text_string ""

    # cache the query if it's not personalized
    if { [empty_string_p $sub_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { name user_id group_id group_name project_type } \
		[im_memoize_list -bind $bind_vars late_project_reports $sql] {
	    if { [string compare $last_project_type $project_type] != 0} {
		if { ![empty_string_p $last_project_type] } {
		    append web_string "</ul>\n"
		    append text_string "\n"
		}
		append web_string "<li><b>$project_type:</b><ul>"
		append text_string "[string toupper $project_type]"
		set last_project_type $project_type
	    }
	    append web_string "<li><a href=[im_url_stub]/users/view?[export_url_vars user_id]>$name</a> on <a href=[im_url_stub]/projects/view?[export_url_vars group_id]>$group_name</a>\n"
	    append text_string "\n* $name on $group_name"
	}
    } else {
	db_foreach late_project_reports $sql {
	    if { [string compare $last_project_type $project_type] != 0} {
		if { ![empty_string_p $last_project_type] } {
		    append web_string "</ul>\n"
		    append text_string "\n"
		}
		append web_string "<li><b>$project_type:</b><ul>"
		append text_string "[string toupper $project_type]"
		set last_project_type $project_type
	    }
	    append web_string "<li><a href=[im_url_stub]/users/view?[export_url_vars user_id]>$name</a> on <a href=[im_url_stub]/projects/view?[export_url_vars group_id]>$group_name</a>\n"
	    append text_string "\n* $name on $group_name"
	}
    }

    if { [empty_string_p $web_string] } {
	append return_string "No employees are late with progress reports\n"
    } else {  	
	if { [string compare $purpose "web_display"] == 0 } {
	    append web_string "</ul>\n"
	    append return_string "
	    <p>
	    <blockquote>
	    <b>The following employees are late with a progress report:</b><ul>
	    <br>
	    $web_string
	    </ul>
	    </blockquote>"
	} else {
	    append return_string " \n\nThe following employees are late with a progress reports: \n$text_string"
	}
    }

    return $return_string
}

ad_proc im_project_reports {{coverage ""} {report_date ""} {purpose ""} { user_id "" }} {
    "Returns a string that gives a list of recent employees" 
} {
    
    set bind_vars [ns_set create]

    if { [empty_string_p $coverage] } {
	set coverage 1
    }
    ns_set put $bind_vars coverage $coverage

    if { [empty_string_p $report_date] } {
	set report_date_sql sysdate
    } else {
	set report_date_sql "to_date(:report_date,'YYYY-MM-DD')"
	ns_set put $bind_vars report_date $report_date
    }


    # check for killed projects and update the sql query as necessary
    set user_id_sql ""
    if { ![empty_string_p $user_id] } {
	set_status_report_user_preferences
	# killed_sections, killed_offices, my_projects_only_p, my_customers_only_p

	if { [string compare $my_projects_only_p "t"] == 0 } {
	    set user_id_sql " and (u.user_id = :user_id
                or exists (select 1 from user_group_map
                           where user_id = :user_id
                           and group_id = user_groups.group_id))"
	        ns_set put $bind_vars target_user_id $user_id
	}
    }

    set sql "select u.user_id, first_names, last_name, general_comments.content, 
      general_comments.html_p, one_line, comment_id,
      user_groups.group_name, user_groups.group_id, 
      to_char(comment_date,'Mon DD, YYYY') as pretty_comment_date
      from users_active u, general_comments, user_groups, im_projects
      where u.user_id = general_comments.user_id
      $user_id_sql and im_projects.group_id = user_groups.group_id
      and user_groups.group_id = general_comments.on_what_id
      and on_which_table = 'user_groups'
      and comment_date > $report_date_sql - :coverage
      /* coverage = $coverage */ order by lower(group_name), comment_date"

    set return_list [list]
    set return_url "[im_url]/projects/view?[export_url_vars group_id]"

    # cache the query if it's not personalized
    if { [empty_string_p $user_id_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { user_id first_names last_name content html_p one_line comment_id \
		group_name group_id pretty_comment_date } \
		[im_memoize_list -bind $bind_vars im_project_reports $sql] {
	    if { [string compare $purpose "web_display"] == 0 } {
		set info "<a href=[ad_url]/general-comments/view-one?[export_url_vars comment_id return_url]&item=[ns_urlencode $group_name]>$one_line</a> - <a href=[im_url]/projects/view?[export_url_vars group_id]>$group_name</a> posted on $pretty_comment_date"
		if { ![empty_string_p $user_id] } {
		    append info " by <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a>"
		}
		lappend return_list "$info
		<blockquote>[util_maybe_convert_to_html $content $html_p]</blockquote>
		"
	    } else {
		lappend return_list "$one_line - $group_name posted on $pretty_comment_date  by $first_names $last_name
		
[util_striphtml $content]
		
-- [im_url]/projects/view?[export_url_vars group_id]
"
           }
	}
    } else {
	db_foreach user_comments $sql {
	    if { [string compare $purpose "web_display"] == 0 } {
		set info "<a href=[ad_url]/general-comments/view-one?[export_url_vars comment_id return_url]&item=[ns_urlencode $group_name]>$one_line</a> - <a href=[im_url]/projects/view?[export_url_vars group_id]>$group_name</a> posted on $pretty_comment_date"
		if { ![empty_string_p $user_id] } {
		    append info " by <a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a>"
		}
		lappend return_list "$info
		<blockquote>[util_maybe_convert_to_html $content $html_p]</blockquote>
		"
	    } else {
		lappend return_list "$one_line - $group_name posted on $pretty_comment_date  by $first_names $last_name
		
		[util_striphtml $content]
		
		-- [im_url]/projects/view?[export_url_vars group_id]
		"
	    }
	}
    }

    # get all the project surveys linked projects
    set sql "select u.user_id, first_names, last_name, response_id,
      user_groups.group_name, user_groups.group_id, 
      to_char(submission_date,'Mon DD, YYYY') as pretty_date
      from users_active u, survsimp_responses, user_groups, im_projects
      where u.user_id =survsimp_responses.user_id
      and im_projects.group_id = user_groups.group_id
      and user_groups.group_id = survsimp_responses.group_id
      and submission_date > $report_date_sql - :coverage
      /* coverage = $coverage */ $user_id_sql 
      order by lower(group_name), submission_date"

    # cache the query if it's not personalized
    if { [empty_string_p $user_id_sql] } {
	# Memoize the sql query since it takes so long...
	foreach { user_id first_names last_name response_id \
		group_name group_id pretty_date } \
		[im_memoize_list -bind $bind_vars list_project_surveys $sql] {
	    set text ""
	    if { [string compare $purpose "web_display"] == 0 } {
		set survey_html_p 1
		append text " <b><a href=[im_url_stub]/projects/view?group_id=$group_id>$group_name</a> report posted on $pretty_date by <a href=/shared/community-member?user_id=$user_id>$first_names $last_name</a></b><blockquote>\n"
	    } else {
		set survey_html_p 0
		append text "$group_name report posted on $pretty_date by $first_names $last_name\n"
	    }
	    append text [survsimp_answer_summary_display $response_id $survey_html_p]
	    if { $survey_html_p } {
		append text "</blockquote>\n"
	    }
	    lappend return_list $text
	}
    } else {
	db_foreach list_project_surveys $sql {
	    set text ""
	    if { [string compare $purpose "web_display"] == 0 } {
		set survey_html_p 1
		append text " <b><a href=[im_url_stub]/projects/view?group_id=$group_id>$group_name</a> report posted on $pretty_date by <a href=/shared/community-member?user_id=$user_id>$first_names $last_name</a></b><blockquote>\n"
	    } else {
		set survey_html_p 0
		append text "$group_name report posted on $pretty_date by $first_names $last_name\n"
	    }
	    append text [survsimp_answer_summary_display $response_id $survey_html_p]
	    if { $survey_html_p } {
		append text "</blockquote>\n"
	    }
	    lappend return_list $text
	}
    }



    if {[llength $return_list] == 0} {
	return "None. \n"
    }

    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n [join $return_list "\n"] "
    }
}

ad_proc im_future_vacationing_employees { {coverage ""} {report_date ""} {purpose ""} {user_id ""} } "Returns a string that gives a list of recent employees" {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    if { [empty_string_p $coverage] } {
	set coverage 30
    }
    if { [empty_string_p $report_date] } {
	set report_date_sql "sysdate"
    } else {
	set report_date_sql ":report_date"
    }

    set sql "select
 distinct u.user_id, first_names, last_name, email, 
to_char(user_vacations.start_date,'Mon DD, YYYY') || ' - ' || to_char(user_vacations.end_date,'Mon DD, YYYY') as dates, user_vacations.end_date
from users_active u, user_vacations, user_group_map ugm
where u.user_id = ugm.user_id
and ugm.group_id = [im_employee_group_id]
and u.user_id = user_vacations.user_id 
and user_vacations.start_date > to_date($report_date_sql, 'YYYY-MM-DD')
and user_vacations.start_date < to_date($report_date_sql, 'YYYY-MM-DD') + :coverage
/* coverage = $coverage */ order by user_vacations.end_date"

    set return_list [list]
    db_foreach users_on_vacation $sql {

	if { [string compare $purpose "web_display"] == 0 } {
	    lappend return_list "<a href=[im_url_stub]/users/view?[export_url_vars user_id]>$first_names $last_name</a>- $dates"
	} else {
	    lappend return_list "$first_names $last_name - $dates"
	}
    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    
    if { [string compare $purpose "web_display"] == 0 } {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n[join $return_list "\n"] "
    }

}


# jsotil 20010508
#
proc_doc cl_check_user_is_no_delinquent {user_id} "check wether the user is a delinquent or not depending on the file /var/log/delinquent" {

    set user_query "select email \
                   from users \
                   where user_id='$user_id'"

    db_1row user_query $user_query

    set user_login [cl_get_user_login_from_email $email]

    set delinquent_users_path "/var/log/delinquent"
    set delinquent_stream [read [open $delinquent_users_path r]]

    if { [regexp $user_login $delinquent_stream match] == 1 } {
	ns_log Notice "***** $user_login found in the delinquent file so return 1 *****"
        return 1
    } else {
	ns_log Notice "***** $user_login not found in the delinquent file so return 0 *****"
        return 0
    }
}


# jsotil 20010510 
#
proc_doc cl_rm_user_from_delinquent {user_id} "check whether the user is in the delinquent list (/var/log/delinquent) or not, AND run the select to remove it" {

    set user_query "select email, first_names || ' ' || last_name as name
                   from users \
                   where user_id='$user_id'"

    db_1row user_query $user_query

    set user_login [cl_get_user_login_from_email $email]

    set delinquent_users_path "/var/log/delinquent"

    set delinquent_stream [open $delinquent_users_path r+]
    set contents_of_file [read $delinquent_stream]
    close $delinquent_stream

    if { [regexp $user_login $contents_of_file match] == 1 } {
	set coverage 1
	set report_date [db_string sysdate_from_dual "select sysdate from dual"]
	set purpose "site_admin"
	set memoize_p "f"
	set delinquent_list [im_delinquent_employees $coverage $report_date $purpose "" $memoize_p]

	if { [regexp $name $delinquent_list match] != 1 } {
	    ns_log Notice "***** $name $email has been removed from the delinquent file so return 1 *****"
	    return 1
	} else {
	    ns_log Notice "***** $name email still remains in the delinquent file so return 0 *****"
	    return 0
	}
    } else {
	ns_log Notice "***** $name $email not found in the delinquent file so return -1 *****"
        return -1
    }
}

# jsotil 20010511 
#
proc_doc cl_get_user_login_from_email {email} "Gets the user_login from an email address" {
    if { [regexp {(.*)@} $email match user_login] == 1 } {
	return $user_login
    } else {
	return $email
    }
}

# jsotil 20010511 
#
proc_doc cl_user_is_authorized_delinquent_user {user_login} "Check whether a user is authorized to be a delinquent user or not, depending on the file /var/log/auth_delinquent" {
#    set authorized_list [list educh gcanotti acorreas visamat]

    set auth_delinquent_users_path "/var/log/auth_delinquent"
    set auth_delinquent_stream [read [open $auth_delinquent_users_path r]]

    set authorized_list [split $auth_delinquent_stream "\n"]

    if { [lsearch -exact $authorized_list $user_login] != -1 } {
	# user is authorized to be a delinquent
	return 1
    } else {
	# user is NOT authorized to be a delinquent
	return 0
    }
}










