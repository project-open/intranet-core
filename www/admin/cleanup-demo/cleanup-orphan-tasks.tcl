# /packages/intranet-core/www/admin/cleanup-demo/cleanup-orphan-tasks.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Show all the views

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
    { limit 1000 }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $return_url} { set return_url [ad_conn url] }

set page_title "[lang::message::lookup "" intranet-core.Nuke_Orphan_Tasks "Nuke Orphan Tasks"] (BETA)"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action "all"
set action_list [list "[_ intranet-core.Nuke_Orphan_Tasks]" "[export_vars -base "cleanup-tasks-2" {return_url action}]" "[_ intranet-core.Nuke_Orphan_Tasks]"]
set action_list {}

set elements_list {
  task_id {
    label "[_ intranet-core.Id]"
  }
  project_nr {
    label "[_ intranet-core.Nr]"
    display_template {
	    <a href="@tasks.project_url@">@tasks.project_nr@</a>
    }
  }
  project_name {
    label "[_ intranet-core.Name]"
    display_template {
	    <a href="@tasks.project_url@">@tasks.project_name@</a>
    }
  }
  project_status {
  	label "[_ intranet-core.Status]"
  }
}

list::create \
        -name task_list \
        -multirow tasks \
        -key task_id \
        -actions $action_list \
        -elements $elements_list \
    	-bulk_actions [list  [lang::message::lookup "" intranet-core.Nuke_Checked_Tasks "Nuke checked Tasks"] cleanup-tasks-2 [lang::message::lookup "" intranet-core.Nuke_Checked_Tasks "Nuke checked Tasks"]] \
	-bulk_action_export_vars { return_url } \
        -bulk_action_method post \
        -filters {
        	return_url
        }
        
db_multirow -extend {project_url parent_project_url} tasks get_tasks "
	select
		t.task_id,
	 	p.*,
		im_category_from_id(p.project_status_id) as project_status,
		im_category_from_id(p.project_type_id) as project_type,
		im_project_name_from_id(p.parent_id) as parent_project_name,
		im_project_nr_from_id(p.parent_id) as parent_project_nr
	from
		im_projects p,
		im_timesheet_tasks t
	where	
		p.project_id = t.task_id 
		and p.parent_id is null
	order 
		by p.project_id DESC
	LIMIT :limit
" {
    set project_url [export_vars -base "/intranet-timesheet2-tasks/new" {task_id return_url}]
}

