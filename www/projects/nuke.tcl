# /packages/intranet-core/www/users/nuke.tcl
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
    Try to remove a user completely

    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    project_id:integer,notnull
    { return_url "/intranet/users" }
}


db_0or1row project_info "
    select	*,
		project_name as project_name_org
    from	im_projects
    where	project_id = :project_id
"

if {![info exists project_name]} { 
    ad_return_complaint 1 "<br><b>[lang::message::lookup "" intranet-core.Project_already_nuked "The project has already been nuked."]</b><br>&nbsp;<br>" 
}

set page_title [_ intranet-core.Nuke_this_project]
set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
set object_name $project_name
set object_type "project"

set delete_user_link "<a href=\"/acs-admin/users/member-state-change?member_state=banned&[export_url_vars project_id return_url]\">[_ intranet-core.lt_delete_this_user_inst]</a>"
set project_url_org [export_vars -base "/intranet/projects/view" {project_id}]


#----------------------------------------------
# Allow to nuke subprojects


db_multirow -extend {indent project_url project_chk finance_html} subprojects subprojects {
	select	child.*,
		tree_level(child.tree_sortkey)-1 as indent_level,
		(select count(*)
		 from	im_costs cc,
		 	acs_rels cr
		 where	cr.object_id_one = cc.cost_id and
			cr.object_id_two = child.project_id
		) as cost_count,
		(select count(*)
		 from	im_costs cc2
		 where	cc2.project_id = child.project_id
		) as cost_count2,
		(select count(*)
		 from	im_hours hh
		 where	hh.project_id = child.project_id
		) as hour_count
	from	im_projects parent,
		im_projects child
	where	parent.project_id = :project_id and
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
	order by
		child.tree_sortkey
} {
    set project_url [export_vars -base "/intranet/projects/view" {project_id}]

    set project_chk "<input type=\"checkbox\" checked
                                name=\"project_id\"
                                value=\"$project_id\"
                                id=\"subprojects,$project_id\"
    >"

    if {0 != $cost_count || 0 != $cost_count2 || 0 != $hour_count} {
	set project_chk "\[&nbsp;\]"
	set finance_html [lang::message::lookup "" intranet-core.There_are_financical_documents_associated_with_this_project "There are financial documents associated with this project"]
    } else {
	set finance_html ""
    }
    set indent ""
    for {set i 0} {$i < $indent_level} {incr i} {
        append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    }
}


set export_var_list [list return_url]
set list_id "subprojects"
set bulk_actions_list [list]
lappend bulk_actions_list "[lang::message::lookup "" intranet-confdb.Delete "Delete"]" "nuke-2" "[lang::message::lookup "" intranet-confdb.Remove_checked_items "Remove Checked Items"]"


template::list::create \
    -name $list_id \
    -multirow subprojects \
    -key project_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { return_url} \
    -row_pretty_plural "[lang::message::lookup "" intranet-core.Nuke_Project Nuke]" \
    -elements {
        project_chk {
            label "<input type=\"checkbox\" checked
                          name=\"_dummy\"
                          onclick=\"acs_ListCheckAll('subprojects', this.checked)\"
                          title=\"Check/uncheck all rows\">"
            display_template {
                @subprojects.project_chk;noquote@
            }
        }
        project_name {
            label "[lang::message::lookup {} intranet-core.Project_name Name]"
            display_template {
                @subprojects.indent;noquote@<a href=@subprojects.project_url;noquote@>@subprojects.project_name;noquote@</a>
            }
        }
        finance_html {
            label "[lang::message::lookup {} intranet-core.Financial_Documents {Financial Documents}]"
	}
    }