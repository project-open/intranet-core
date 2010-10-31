# Portlet showing the groups of a user.
# Vars from calling page:
# group_type
# user_id
# return_url

# Check if this page has been called as a standalone page
set portlet_p 1
if {![exists_and_not_null user_id]} { 

    ad_page_contract {
	This portlet is designed to be shown in the context of a user's page.
	It show all groups belonging to a specific group type.
	"Admins" of the user are allowed to change the group memberships of
	the user.

	@author Frank Bergmann (frank.bergmann@project-open.com)
	@creation-date 2010-10-25
    } {
	user_id:integer
	{ group_id:integer,multiple {}}
	group_type
	{ return_url "" }
    }

    set portlet_p 0
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_conn user_id]
if {![exists_and_not_null return_url]} { set return_url [ad_return_url] }
if {![exists_and_not_null user_id]} { set user_id $current_user_id }
if {![exists_and_not_null group_type]} { set group_type "im_cvs_group" }

# The .adp page uses the permissions to show the list in read-only
# mode etc., so we don't need to to anything here with the perm info:
im_user_permissions $current_user_id $user_id view read write admin

set page_title [lang::message::lookup "" intranet-cvs-integration.Group_Type_Membership "%group_type% Membership"]


# ------------------------------------------------------
# Build the list
# ------------------------------------------------------

set elements [list]
lappend elements group_chk {
    label "<input type=\"checkbox\" name=\"_dummy\" onclick=\"acs_ListCheckAll('group_list', this.checked)\" title=\"Check/uncheck all rows\">"
    display_template {
        @groups.group_chk;noquote@
    }
}
lappend elements group_name { 
    label "[lang::message::lookup {} intranet-core.Name_Column Name]" 
    display_template {
        @groups.group_name@
    }
}


set admin_group_url [export_vars -base "/admin/group-types/one" {group_type}]
set admin_group_msg [lang::message::lookup "" intranet-cvs-integration.Admin_Group_Type "Admin Group Type"]
set actions [list $admin_group_msg $admin_group_url $admin_group_msg]

set update_group_url "/intranet-cvs-integration/group-type-save"
set update_group_msg [lang::message::lookup "" intranet-cvs-integration.Save_Changes "Save Changes"]
set bulk_actions [list $update_group_msg $update_group_url $update_group_msg]

if {![im_is_user_site_wide_or_intranet_admin $current_user_id]} { 
    set actions "" 
    set bulk_actions ""
}

template::list::create \
    -name groups \
    -key group_id \
    -multirow groups \
    -actions $actions \
    -has_checkboxes \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars {return_url user_id group_type} \
    -elements $elements 

set group_sql "
	select	*
	from	acs_objects o,
		groups g
		LEFT OUTER JOIN (
			select	r.object_id_one as group_id,
				mr.member_state
			from	acs_rels r,
				membership_rels mr
			where	r.rel_id = mr.rel_id and
				r.object_id_two = :user_id
		) m ON (g.group_id = m.group_id)
	where	g.group_id = o.object_id and
		o.object_type = :group_type
"

db_multirow -extend { group_chk } groups groups $group_sql {
    set checked ""
    if {"approved" == $member_state} { set checked "checked" }
    set group_chk "<input type=\"checkbox\"
                                name=\"group_id\"
                                value=\"$group_id\"
                                id=\"group_list,$group_id\"
				$checked
    >"
}

ad_return_template

