# File: /www/intranet/status-report.tcl

ad_page_contract {
    gives the random user a comprehensive view of 
    the company's status 

    @param coverage_days:integer,optional
    @param custom_view_p:optional

    @author Tracy Adams (teadams@mit.edu)
    @author Michael Bryzek (mbryzek@arsdigita.com)

    @creation-date Dec 10, 1999, last modified december 26 by ahmedaa@mit.edu
    @cvs-id status-report.tcl,v 3.16.2.4 2000/07/21 04:00:49 ron Exp
} {
    { coverage_days:integer "1" }
    { custom_view_p "t" }
}


# check that user is logged in
set user_id [ad_maybe_redirect_for_registration]

set page_title "Intranet Status Report"
set context_bar [ad_context_bar [list [im_url_stub]/reports/ "Reports"] "Status report"]

set report_date [db_string sysdate_from_dual "select sysdate from dual"] 

set n_days_possible [list 1 2 3 4 5 6 7 14 30]

set right_widget [list]

foreach n_days $n_days_possible {
    if { $n_days == $coverage_days } {
	# current choice, just the item
	lappend right_widget_items $n_days
    } else {
	lappend right_widget_items "<a href=\"index?coverage_days=$n_days\">$n_days</a>"
    }
}

set right_widget [join $right_widget_items]

set page_body "
<table width=100%>
<tr>
  <td align=left>Report date: [util_IllustraDatetoPrettyDate $report_date]</td>
  <td align=right>Coverage: $right_widget days</a>
</tr>
</table>

<p>
"

if { [string compare $custom_view_p "t"] == 0 } {
    set user_preferences_p 1
    set custom_view_p "f"
    append page_body "<a href=\"index?[export_url_vars coverage_days custom_view_p]\">View entire (un-customized) status report</a><br>"
} else {
    set user_preferences_p 0
    set custom_view_p "t"
    append page_body "<a href=\"index?[export_url_vars coverage_days custom_view_p]\">View customized status report</a><br>"
}

append page_body "
<a href=\"preferences-edit\">View my status report preferences</a>
<p>

Note that this page is usually updated only once a day.
<p>
[im_table_with_title "Menu" "<ul>
<li><a href=\"\#Population Count\">Population Count</a>
<li><a href=\"\#New Employees\">New Employees</a>
<li><a href=\"\#Future Employees\">Future Employees</a>
<li><a href=\"\#Employees Out of the Office\">Employees Out of the Office</a>
<li><a href=\"\#Future office excursions\">Future office excursions</a>
<li><a href=\"\#Delinquent Employees\">Delinquent Employees</a>
<li><a href=\"\#Downloads\">Downloads</a>
<li><a href=\"\#Customers: Bids Out\">Customers: Bids Out</a>
<li><a href=\"\#Customers: Status Changes\">Customers: Status Changes</a>
<li><a href=\"\#New Registrants at [ad_parameter SystemURL]\">New Registrants at [ad_parameter SystemURL]</a>
<li><a href=\"\#Progress Reports\">Progress Reports</a>
</ul>"]
"

if { $user_preferences_p == 1 } {
    set status_report_body "
[im_status_report $coverage_days $report_date "web_display" "im_status_report_section_list" $user_id]
"
} else {
    set status_report_body "
[im_status_report $coverage_days $report_date "web_display" "im_status_report_section_list"]
"
}

append page_body $status_report_body

doc_return  200 text/html [im_return_template]

