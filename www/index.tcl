# /www/intranet/index.tcl

ad_page_contract { 
    List all projects with dimensional sliders.

    @param order_by project display order 
    @param include_subprojects_p whether to include sub projects
    @param mine_p show my projects or all projects
    @param status_id criteria for project status
    @param type_id criteria for project_type_id
    @param letter criteria for im_first_letter_default_to_a(ug.group_name)
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author mbryzek@arsdigita.com
    @cvs-id index.tcl,v 3.24.2.9 2000/09/22 01:38:44 kevin Exp
} {
    { order_by "Project #" }
    { include_subprojects_p "f" }
    { mine_p "t" }
    { status_id "" } 
    { type_id:integer "0" } 
    { letter "scroll" }
    { start_idx:integer "1" }
    { how_many "" }
    { forum_start_idx 1}
    { forum_order_by "P" }
    { forum_how_many 0 }
    { forum_view_name "forum_list_home"}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_get_user_id]
set current_user_id $user_id
set view_types [list "t" "Mine" "f" "All"]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "Projects"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set return_url [im_url_with_query]
set current_url [ns_conn url]

set today [lindex [split [ns_localsqltimestamp] " "] 0]

# Define the column headers and column contents that we want to show:
#
set column_headers [list]
set column_vars [list]
lappend column_headers "Project #"
lappend column_vars {"<A HREF='/intranet/projects/view?project_id=$project_id'>" $project_nr "</A>"}
if {[im_permission $user_id view_customers]} {
    lappend column_headers "Client"
    lappend column_vars {"<A HREF='/intranet/customers/view?customer_id=$customer_id'>" $customer_name "</A>"}
}
lappend column_headers "Project Name"
lappend column_vars {$project_name}
lappend column_headers "Delivery Date"
lappend column_vars {"$end_date $end_date_time"}
lappend column_headers "Status"
lappend column_vars {$project_status}

# Determine the default status if not set
if { [empty_string_p $status_id] } {
    # Default status is open
    set status_id [ad_parameter ProjectStatusOpen intranet 0]
}

# Reset some values for unprivileged users
if {![im_permission $current_user_id "view_projects_of_others"]} {
    # Don't let clients and freelancers view other projects
    set mine_p "t"
    set include_subprojects_p "f"
    
    # allow to see only open projects
    set status_id [ad_parameter ProjectStatusOpen intranet 0]
}

# status_types will be a list of pairs of (project_status_id, project_status)
set status_types [im_memoize_list select_project_status_types \
	"select project_status_id, project_status
           from im_project_status
          order by lower(project_status)"]
lappend status_types 0 All

# project_types will be a list of pairs of (project_type_id, project_type)
set project_types [im_memoize_list select_project_types \
	"select project_type_id, project_type
           from im_project_types
          order by lower(project_type)"]
lappend project_types 0 All


# Now let's generate the sql query
#
set criteria [list]
if { ![empty_string_p $status_id] && $status_id > 0 } {
    lappend criteria "p.project_status_id=:status_id"
}
if { ![empty_string_p $type_id] && $type_id != 0 } {
    lappend criteria "p.project_type_id=:type_id"
}
if { [string compare $mine_p "t"] == 0 } {
    lappend criteria "ad_group_member_p ( :user_id, p.project_id ) = 't'"
}
if { ![empty_string_p $letter] && [string compare $letter "all"] != 0 && [string compare $letter "scroll"] != 0 } {
    lappend criteria "im_first_letter_default_to_a(p.project_name)=:letter"
}
if { $include_subprojects_p == "f" } {
    lappend criteria "p.parent_id is null"
}

ns_log Notice "order by: $order_by"
set order_by_clause "order by upper(p.project_name)"
switch $order_by {
    "Type" { set order_by_clause "order by project_type" }
    "Type" { set order_by_clause "order by project_type" }
    "Status" { set order_by_clause "order by project_status_id" }
    "Delivery Date" { set order_by_clause "order by end_date" }
    "Client" { set order_by_clause "order by customer_name" }
    "Project #" { set order_by_clause "order by project_nr desc" }
    "Project Manager" { set order_by_clause "order by upper(last_name), upper(first_names)" }
    "URL" { set order_by_clause "order by upper(url)" }
    "Project Name" {  }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set sql "
select 
	p.*,
	c.customer_name,
        im_name_from_user_id(p.project_lead_id) as lead_name, 
        im_category_from_id(p.project_type_id) as project_type, 
        im_category_from_id(p.project_status_id) as project_status,
        im_proj_url_from_type(p.project_id, 'website') as url,
        to_char(end_date, 'HH24:MI') as end_date_time
from 
	im_projects p, 
        im_customers c
where 
        p.customer_id = c.customer_id
	$where_clause
	$order_by_clause
"

if { [string compare $letter "all"] == 0 } {
    set selection "$sql $order_by_clause"
    # Set these limits to negative values to deactivate them
    set total_in_limited -1
    set how_many -1

} else {
    # Set up boundaries to limit the amount of rows we display
    if { [empty_string_p $how_many] || $how_many < 1 } {
	set how_many [ad_parameter NumberResultsPerPage intranet 50]
    }
    set end_idx [expr $start_idx + $how_many - 1]
    set limited_query [im_select_row_range $sql $start_idx $end_idx]

    # We can't get around counting in advance if we want to be able to 
    # sort inside the table on the page for only those users in the 
    # query results
    set total_in_limited [db_string projects_total_in_limited \
	    "select count(*) 
               from im_projects p 
              where p.parent_id is null $where_clause"]

    set selection "select z.* from ($limited_query) z $order_by_clause"
}	

set results ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx
db_foreach projects_info_query $selection {
    set url [im_maybe_prepend_http $url]

    if { [empty_string_p $url] } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }

    # Append together a line of data based on the "column_vars" parameter list
    append results "\n<tr$bgcolor([expr $ctr % 2])>\n"
    foreach column_var $column_vars {
	append results "\n\t<td valign=top>"
	set cmd "append results $column_var"
	eval $cmd
	append results "\n\t</td>"
    }
    append results "\n</tr>\n"

    incr ctr
    if { $how_many > 0 && $ctr >= $how_many } {
	break
    }
    incr idx
}

if {$ctr==$how_many && $total_in_limited > 0 && $end_idx < $total_in_limited} {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page 
    set next_start_idx [expr $end_idx + 1]
    set next_page "<a href=index?start_idx=$next_start_idx&[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

if { $start_idx > 1 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr $start_idx - $how_many]
    if { $previous_start_idx < 1 } {
	set previous_start_idx 1
    }
    set previous_page "<a href=index?start_idx=$previous_start_idx&[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

# ----------------------------------------------------------
# Note that we use a nested table because im_slider might
# return a table with a form in it (if there are too many options)

set filter_html "
<form method=get action='/intranet/index'>
[export_form_vars include_subprojects_p]

<table border=0 cellpadding=0 cellspacing=0>
<tr> 
  <td colspan='2' class=rowtitle align=center>
    Filter Projects 
  </td>
</tr>
<tr>
  <td valign=top>
    <table border=0 cellspacing=0 cellpadding=0>
"
if {[im_permission $current_user_id "view_projects_of_others"]} { 
    append filter_html "
      <tr>
        <td valign=top><font size=-1>
           View:
        </font></td>
        <td valign=top><font size=-1>
           [im_select mine_p $view_types ""]
        </font></td>
      </tr>"
}

# Don't show the status select box for unprivileged users
if {[im_permission $current_user_id "view_projects_of_others"]} {
    append filter_html "
      <tr>
        <td valign=top><font size=-1>
           Project Status: 
        </font></td>
        <td valign=top><font size=-1>
           [im_select status_id $status_types ""]
        </font></td>
      </tr>"
}

append filter_html "
      <tr>
        <td valign=top><font size=-1>
           Project Type:
        </font></td>
        <td valign=top><font size=-1>
           [im_select type_id $project_types ""]
           <input type=submit value=Go name=submit>

        </font></td>
      </tr>      
    </table>
  </td>
 <td valign=top>
    <table border=0 cellspacing=0 cellpadding=0>
     <tr>
        <td colspan=2 valign=top align=right><font size=-1>"

append filter_html "
       </td>
     </tr>
    </table>
  </td>
</tr>
</table>
</form>\n"


# ----------------------------------------------------------
# Do we have to show administration links?

set admin_html ""
if {[im_permission $current_user_id "add_projects"]} {
    append admin_html "<li><a href=/intranet/projects/new>Add a new project</a>\n"
}

set project_filter_html $filter_html

if {"" != $admin_html} {
    set project_filter_html "

<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td> <!-- TD for the left hand filter HTML -->
    $filter_html
  </td> <!-- end of left hand filter TD -->
  <td>&nbsp;</td>
  <td valign=top width='30%'>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        Admin Projects
      </td>
    </tr>
    <tr>
      <td>
        $admin_html
      </td>
    </tr>
    </table>
  </td>
</tr>
</table>
"
}

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr [llength $column_headers] + 1]

set project_list_html "
<table width=100% cellpadding=2 cellspacing=2 border=0>"

#<tr>
#  <td align=center valign=top colspan=$colspan><font size=-1>
#    [im_groups_alpha_bar [im_project_group_id] $letter "start_idx"]</font>
#  </td>
#</tr>"

if { [empty_string_p $results] } {
    append project_list_html "<tr><td colspan=$colspan<ul><li><b> There are currently no projects matching the selected criteria</b></ul></td></tr>\n"
} else {
    set url "index?"
    set query_string [export_ns_set_vars url [list order_by]]
    if { ![empty_string_p $query_string] } {
	append url "$query_string&"
    }

#    append project_list_html "<tr>\n  <td class=rowtitle>Project #</td>\n"
    foreach col $column_headers {
	if { [string compare $order_by $col] == 0 } {
	    append project_list_html "  <td class=rowtitle>$col</td>\n"
	} else {
	    append project_list_html "  <td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col</a></td>\n"
	}
    }
    append project_list_html "</tr>$results\n"
}

append project_list_html "
<tr>
  <td align=center colspan=$colspan>[im_maybe_insert_link $previous_page $next_page]</td>
</tr>
</table>"


# ----------------------------------------------------------------
# Hours
# ----------------------------------------------------------------

set hours_html ""
set on_which_table "im_projects"

if { [catch {
    set num_hours [hours_sum_for_user $current_user_id $on_which_table "" 7]
} err_msg] } {
    set num_hours 0
}

if { $num_hours == 0 } {
    append hours_html "<b>You haven't logged your hours in the last week. <BR>
     Please <a href=hours/index?[export_url_vars on_which_table]>log them now</a></b>\n"
} else {
    append hours_html "You logged $num_hours [util_decode $num_hours 1 hour hours] in the last 7 days."
}

if {[im_permission $current_user_id view_hours_of_others]} {
    set user_id $current_user_id
    append hours_html "
    <ul>
    <li><a href=hours/projects?[export_url_vars on_which_table user_id]>View your hours on all projects</a>
    <li><a href=hours/total?[export_url_vars on_which_table]>View time spent on all projects by everyone</a>
    <li><a href=hours/projects?[export_url_vars on_which_table]>View the hours logged by someone else</a>\n"
}
append hours_html "<li><a href=hours/index?[export_url_vars on_which_table]>Log hours</a>\n"

# Show the "Work Absences" link only to in-house staff.
# Clients and Freelancers do not necessarily need it.
if {[im_permission $current_user_id employee] || [im_permission $current_user_id wheel] || [im_permission $current_user_id accounting]} {
    append hours_html "<li> <a href=/intranet/absences/>Work absences</a>\n"
}
append hours_html "</ul>"


set hours_component ""
if { [ad_parameter TrackHours intranet 0] && [im_permission $current_user_id add_hours]} {
    set hours_component [im_table_with_title "Work Log" "$hours_html"]
}

# -------------- Format the Forum box ---------------------

set forum_component ""

if { 0 } {

# How to present the forum items?
set group_id 0
set restrict_to_group_id 0
set restrict_to_mine_p "t"

set forum_title_text "<B>Forum Items</B>"
set forum_title [im_forum_create_bar $forum_title_text $group_id $return_url]

# 0=all, 1="Tasks & Incidents", ...
set restrict_to_topic_type_id 0

# status not used yet
set restrict_to_topic_status_id 0
set restrict_to_asignee_id 0
set max_entries_per_page 0

# Show only topics not marked as "read".
set restrict_to_new_topics 1

set export_var_list [list group_id forum_order_by forum_how_many forum_view_name]

set forum_content [im_forum_component $current_user_id $restrict_to_group_id $current_url $return_url $export_var_list $forum_view_name $forum_order_by $restrict_to_mine_p $restrict_to_topic_type_id $restrict_to_topic_status_id $restrict_to_asignee_id $forum_how_many $forum_start_idx $restrict_to_new_topics]


set forum_component [im_table_with_title $forum_title $forum_content]


}


# ----------------------------------------------------------------
# Administration
# ----------------------------------------------------------------

set admin_items ""

if { 0 } {
    set admin_items "
  <li> <a href=/intranet/employees/admin>Employee administration</a>
  <li> <a href=/intranet/projects/import-project-txt>Import Projects from H:\\ </a>
  <li> <a href=/intranet/anonymize>Anonymize this server (Test server only!!)</a>"

    db_foreach admin_groups_user_belongs_to \
	    "select ug.group_id, ug.group_name, ai.url as ai_url
               from  user_groups ug, administration_info ai
              where ug.group_id = ai.group_id
                and ad_group_member_p ( :user_id, ug.group_id ) = 't'" {
	append admin_items "<li><a href=\"$ai_url\">$group_name</a>\n"
    }
}

append admin_items "<li> <a href=/intranet/users/view?user_id=$current_user_id>About You</A>\n"

set admin_info "
<ul>
$admin_items
</ul>
"

set administration_component [im_table_with_title "Administration" $admin_info]

db_release_unused_handles
