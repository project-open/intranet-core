# /packages/intranet-core/www/admin/cleanup-demo/cleanup-projects.tcl
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
    { limit 100000 }
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

set page_title "[_ intranet-core.Nuke_Demo_Projects]"
set context_bar [im_context_bar $page_title]
set context ""

# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set action "all"
set action_list [list "[_ intranet-core.Nuke_All_Demo_Projects]" "[export_vars -base "cleanup-projects-2" {return_url action}]" "[_ intranet-core.Nuke_All_Demo_Projects]"]
set action_list {}

set elements_list {
  project_id {
    label "[_ intranet-core.Id]"
  }
  project_nr {
    label "[_ intranet-core.Project_Nr]"
    display_template {
	    <a href="@projects.project_url@">@projects.project_nr@</a>
    }
  }
  project_name {
    label "[_ intranet-core.Name]"
    display_template {
	    <a href="@projects.project_url@">@projects.project_name@</a>
    }
  }
  num_subprojects {
  	label "[_ intranet-core.Num_Subprojects]"
  }
  parent_project_name {
  	label "[_ intranet-core.Parent_Project]"
	display_template {
	    <a href="@projects.parent_project_url@">@projects.parent_project_name@</a>
        }
  }
  project_type {
  	label "[_ intranet-core.Project_Type]"
  }
  project_status {
  	label "[_ intranet-core.Project_Status]"
  }
}

list::create \
        -name project_list \
        -multirow projects \
        -key project_id \
        -actions $action_list \
        -elements $elements_list \
	-bulk_actions [list [_ intranet-core.Nuke_Checked_Projects] cleanup-projects-2 [_ intranet-core.Nuke_Checked_Projects]] \
	-bulk_action_export_vars { return_url } \
        -bulk_action_method post \
        -filters {
        	return_url
        }
        
db_multirow -extend {project_url parent_project_url} projects get_projects "
	select
	 	p.*,
		im_category_from_id(p.project_status_id) as project_status,
		im_category_from_id(p.project_type_id) as project_type,
		im_project_name_from_id(p.parent_id) as parent_project_name,
		im_project_nr_from_id(p.parent_id) as parent_project_nr,
		subp.num_subprojects
	from
		im_projects p
		left outer join
		(select	
			count(*) as num_subprojects,
			proj.project_id
		from
			im_projects proj,
			im_projects sub_p
		where
			sub_p.parent_id = proj.project_id
		group by
			proj.project_id
		) subp on (p.project_id = subp.project_id)
	where	1=1
	order by p.project_id DESC
	LIMIT :limit
" {
    set project_url [export_vars -base "/intranet/projects/view" {project_id return_url}]
    set parent_project_url [export_vars -base "/intranet/projects/view" {{project_id $parent_id} return_url}]
}

