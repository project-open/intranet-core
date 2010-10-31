# packages/intranet-core/www/group-type-save.tcl

ad_page_contract {
    Bulk action on group type memberships.
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 2010-10-25
} {
    user_id:integer
    { group_id:integer,multiple {}}
    group_type
    return_url
}

# ******************************************************
# Default & Security
# ******************************************************

set current_user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
im_user_permissions $current_user_id $user_id view read write admin
if {!$admin} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ad_return_complaint 1 "group_type=$group_type, group_id=$group_id, user_id=$user_id"

# Make sure there is at least one element in the group
lappend group_id 0

foreach gid $group_id {
    set rel_id [db_string membership_rel "
	select	min(r.rel_id)
	from	acs_rels r,
		membership_rels mr
	where	r.rel_id = mr.rel_id and
		r.object_id_two = :user_id and
		r.object_id_one = :gid
    " -default ""]
    if {"" == $rel_id} {
        relation_add -member_state "approved" "membership_rel" $gid $user_id
    } else {
	db_dml re_enable "
		update	membership_rels
		set	member_state = 'approved'
		where	rel_id = :rel_id
        "
    }
}

db_foreach unchecked_groups "
	select	r.rel_id
	from	acs_rels r,
		membership_rels mr
	where	r.rel_id = mr.rel_id and
		r.object_id_two = :user_id and
		r.object_id_one in (
			select	group_id
			from	groups g,
				acs_objects o
			where	g.group_id = o.object_id and
				o.object_type = :group_type and
				g.group_id not in ([join $group_id ","])
		)
" {
    db_dml remove_membership "
	update	membership_rels
	set	member_state = 'deleted'
	where	rel_id = :rel_id
    "
}


ad_returnredirect $return_url

