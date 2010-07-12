# /packages/intranet-core/www/index.tcl
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
    @author frank.bergmann@project-open.com
} {
    { order_by "Project #" }
    { include_subprojects_p "f" }
    { mine_p "t" }
    { status_id "" } 
    { type_id:integer "0" } 
    { letter "scroll" }
    { start_idx:integer "1" }
    { how_many "" }
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

sett user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set view_types [list "t" "Mine" "f" "All"]
set subproject_types [list "t" "Yes" "f" "No"]
set page_title "Projects"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set current_url [ns_conn url]
set return_url "/intranet/"

set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]


set today [lindex [split [ns_localsqltimestamp] " "] 0]

# Define the column headers and column contents that we want to show:
#
set column_headers [list]
set column_vars [list]
lappend column_headers "Project #"
lappend column_vars {"<A HREF='/intranet/projects/view?project_id=$project_id'>" $project_nr "</A>"}
if {[im_permission $user_id view_companies]} {
    lappend column_headers "Client"
    lappend column_vars {"<A HREF='/intranet/companies/view?company_id=$company_id'>" $company_name "</A>"}
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
    set status_id [im_project_status_open]
}

# Reset some values for unprivileged users
if {![im_permission $current_user_id "view_projects_all"]} {
    # Don't let clients and freelancers view other projects
    set mine_p "t"
    set include_subprojects_p "f"
    
    # allow to see only open projects
    set status_id [im_project_status_open]
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
    set mine_restriction ""
} else {
    set mine_restriction "or perm.permission_all > 0"
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
    "Client" { set order_by_clause "order by company_name" }
    "Project #" { set order_by_clause "order by project_nr desc" }
    "Project Manager" { set order_by_clause "order by upper(last_name), upper(first_names)" }
    "URL" { set order_by_clause "order by upper(url)" }
    "Project Name" {  }
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}



set perm_sql "
	select
	        p.project_id,
		r.member_p as permission_member,
		see_all.see_all as permission_all
	from
	        im_projects p,
		(	select	count(rel_id) as member_p,
				object_id_one as object_id
			from	acs_rels
			where	object_id_two = :user_id
			group by object_id_one
		) r,
	        (       select  count(*) as see_all
	                from acs_object_party_privilege_map
	                where   object_id=:subsite_id
	                        and party_id=:user_id
	                        and privilege='view_projects_all'
	        ) see_all
	where
	        p.project_id = r.object_id(+)
	        $where_clause
"

set sql "
SELECT
	p.*,
        c.company_name,
        im_name_from_user_id(project_lead_id) as lead_name,
        im_category_from_id(p.project_type_id) as project_type,
        im_category_from_id(p.project_status_id) as project_status,
        to_char(end_date, 'HH24:MI') as end_date_time
FROM
	im_projects p,
	im_companies c,
	($perm_sql) perm
WHERE
	perm.project_id = p.project_id
	and p.company_id = c.company_id(+)
	and (
		p.project_status_id = 76
		and perm.permission_member > 0
		$mine_restriction
	)
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
	set how_many [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
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
	eval "$cmd"
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
<form method=POST action='/intranet/index'>
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
if {[im_permission $current_user_id "view_projects_all"]} { 
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
if {[im_permission $current_user_id "view_projects_all"]} {
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
    append project_list_html "<tr><td colspan=$colspan><ul><li><b> 
[lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
</b></ul></td></tr>\n"
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

