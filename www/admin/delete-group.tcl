# /www/admin/delete-group.tcl

ad_page_contract {
    Tries to delete a group

    @author frank.bergmann@project-open.com
} {
    group_id:integer,notnull
    { return_url "/intranet/admin/" }
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

if [ catch {
    
    db_transaction {

	db_dml del "delete from im_profiles where profile_id = :group_id"
	db_dml del "delete from group_element_index where group_id = :group_id"
	db_dml del "delete from group_element_index where container_id = :group_id"
	db_dml del "delete from groups where group_id = :group_id"
	db_dml del "delete from acs_object_context_index where object_id = :group_id"
	db_dml del "delete from acs_object_context_index where ancestor_id = :group_id"
	db_dml del "delete from membership_rels where rel_id in (
		select rel_id 
		from acs_rels 
		where object_id_one = :group_id or object_id_two = :group_id
	)"
	db_dml del "delete from composition_rels where rel_id in (
		select rel_id from acs_rels 
		where object_id_one = :group_id or object_id_two = :group_id
	)"
	db_dml del "delete from acs_rels where rel_id in (
		select rel_id from acs_rels 
		where object_id_one = :group_id or object_id_two = :group_id
	)"

	db_dml upd "update acs_objects set context_id = null where context_id = :group_id"
	db_dml del "delete from acs_permissions where object_id = :group_id"
	db_dml del "delete from parties where party_id = :group_id"
	db_dml del "delete from acs_objects  where object_id = :group_id"
    }

} errmsg ] {
    ad_return_complaint "Argument Error""<ul>$errmsg</ul>"
    return
} 


# Remove all permission related entries in the system cache
im_permission_flush


db_release_unused_handles
ad_returnredirect $return_url

