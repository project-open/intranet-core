# /www/intranet/preferences-edit.tcl

ad_page_contract { 
    Displays the user's preferences for status reports

    @author Michael Pih (pihman@arsdigita.com)
    @creation-date 1 August 2000
    @cvs-id preferences-edit.tcl,v 1.1.2.2 2000/09/22 01:38:48 kevin Exp

} {}

# make sure the user is logged in
set user_id [ad_maybe_redirect_for_registration]

# fetch the user's status report preferences if any
set sql "select killed_sections, killed_offices, 
         my_customers_only_p, my_projects_only_p
         from im_status_report_preferences
         where user_id = :user_id" 
if { [db_0or1row status_report_preferences $sql] } {
    # killed_sections, killed_offices, 
    #   my_customers_only_p, my_projects_only_p
    set personalization_p 1
} else {
    set killed_sections [list]
    set killed_offices [list]
    set my_customers_only_p f
    set my_projects_only_p f
    set personalization_p 0
}

set page_title "Intranet Status Report Preferences"
set context_bar [ad_context_bar [list [im_url_stub]/reports/ "Reports"] [list index "Status report"] "Preferences"]

set doc_body "
[im_header $page_title]

<p>
All changes to your status report preferences will take place 
on the next update.
<p>
"

if { $personalization_p == 1 } {
    append doc_body "<a href=\"preferences-reset\">Reset preferences to default</a><p>\n"
}

append doc_body "
<h4>Displayed Sections</h4>
<form method=post action=\"preferences-edit-2\">
"

set sql_query "select sr_section_id, sr_section_name 
               from im_status_report_sections
               order by upper(sr_section_name)"
db_foreach status_report_sections $sql_query {
    # if it hasn't been killed, it's checked
    if { [lsearch -exact $killed_sections $sr_section_id] != -1 } {
	append doc_body "<input type=checkbox name=\"sections\" value=\"$sr_section_id\"> $sr_section_name<br>\n"
    } else {
	append doc_body "<input type=checkbox name=\"sections\" value=\"$sr_section_id\" checked> $sr_section_name<br>\n"
    }
}

append doc_body "<p>
<h4>Displayed Offices</h4>
"

set sql_query "select imo.group_id as group_id, group_name
               from im_offices imo, user_groups ug
               where imo.group_id = ug.group_id
               order by upper(group_name)"
db_foreach office_names $sql_query {
    if { [lsearch -exact $killed_offices $group_id] != -1 } {
	append doc_body "<input type=checkbox name=\"offices\" value=\"$group_id\"> $group_name<br>\n"
    } else {
	append doc_body "<input type=checkbox name=\"offices\" value=\"$group_id\" checked> $group_name<br>\n"
    }
} if_no_rows {
    append doc_body "<i>There are no offices in the database.</i><br>\n"
}


append doc_body "
<p>
<h4>Displayed Projects</h4>
"

if { [string compare $my_projects_only_p t] == 0 } {
    append doc_body "
    <input name=\"my_projects_only_p\" type=checkbox value=\"t\" checked>
    My projects only<p>\n"    
} else {
    append doc_body "
    <input name=\"my_projects_only_p\" type=checkbox value=\"t\">
    My projects only<p>\n"    
}

set status_id 0
append doc_body "You can add yourself to a project group from the 
<a href=\"projects/?[export_url_vars status_id]\">
project pages</a><p>"


append doc_body "
<p>
<h4>Displayed Customers</h4>
"


if { [string compare $my_customers_only_p t] == 0 } {
    append doc_body "
    <input name=\"my_customers_only_p\" type=checkbox value=\"t\" checked>
    My customers only<p>\n"    
} else {
    append doc_body "
    <input name=\"my_customers_only_p\" type=checkbox value=\"t\">
    My customers only<p>\n"    
}


set status_id 0
append doc_body "You can add yourself to a customer group from the 
<a href=\"customers/?[export_url_vars status_id]\">
customers pages</a><p>"

db_release_unused_handles


append doc_body "
<p>
<input type=submit value=\"Update Preferences\">
</form>

[im_footer]
"

doc_return 200 text/html $doc_body
