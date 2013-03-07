# /packages/intranet-core/www/projects/project-action.tcl
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Action for ProjectHierarchyPortlet
    @param return_url the url to return to
    @param menu_id The list of menus to delete

    @author frank.bergmann@project-open.com
} {
    {select_project_id:multiple ""}
    {action "" }
    {return_url "/intranet/admin/menus"}
}

set user_id [ad_maybe_redirect_for_registration]

switch $action {

    "" { ad_returnredirect $return_url }

    "set_invoiced" {
	foreach pid $select_project_id {
	    im_project_permissions $user_id $pid view_p read_p write_p admin_p
	    if {$write_p} {
		db_dml set_invoiced "
			update im_projects
			set project_status_id = [im_project_status_invoiced]
			where project_id = :pid
		"
		im_audit -object_id $pid
	    } 
	}
    }

    "set_open" {
	foreach pid $select_project_id {
	    im_project_permissions $user_id $pid view_p read_p write_p admin_p
	    if {$write_p} {
		db_dml set_invoiced "
			update im_projects
			set project_status_id = [im_project_status_open]
			where project_id = :pid
		"
		im_audit -object_id $pid
	    } 
	}
    }

    shift_project {
	ad_returnredirect [export_vars -base "/intranet/projects/project-action-shift" {return_url select_project_id}]
    }

    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url
