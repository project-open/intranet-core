ad_page_contract {

    company-projects.tcl
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-10-30
}

set user_id [ad_maybe_redirect_for_registration]

# Check permissions. "See details" is an additional check for
# critical information
im_company_permissions $user_id $company_id view read write admin


set enable_project_estimates 0

# ------------------------------------------------------
# Company Project List
# ------------------------------------------------------

set projects_html ""
set current_level 1
set ctr 1
set max_projects 15
set project_status_name ""
set warning ""

# -- 
#db_multirow starts here. it still is a draft and it is not finished.

set where_clause3 "[im_project_type_task]"
set where_clause4 "[im_project_type_ticket]"

db_multirow -extend {llevel current_level project_status_name} active_projects select_projects {} {

    if { $llevel > $current_level } {
	incr current_level
    } elseif { $llevel < $current_level } {
	set current_level [expr $current_level - 1]
    }

    set project_status_name [im_category_from_id $project_status_id]
    lappend tt [im_category_from_id $project_status_id] 
    set project_url [export_vars -base "../projects/view" {project_id}]

    incr ctr
    if {$ctr > $max_projects} { 
	set warning  "<p class=\"warning\">[lang::message::lookup "" intranet-core.NumberOfItemsExceedsLimit "Please note: Only a subset of items is shown, total number exceeds limit"]</p>"
	break 
    }
}

set close_ul_p 0
if { [exists_and_not_null level] && $llevel < $current_level } {
    set close_ul_p 1
}

# KH: ... this is obsolete
# set projects_html [im_table_with_title "[_ intranet-core.Projects]" "$warning<ul>$projects_html</ul>"]
