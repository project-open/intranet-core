# /packages/intranet-core/www/admin/profiles/delete-2.tcl

ad_page_contract {

    Adds a new profile

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com

} {
    profile_id:integer
} 

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set title "Delete a Profile"
set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] $title]

set debug_html ""

catch {

    set rel_ids [db_list rel_ids "
	select	rel_id 
	from	acs_rels 
	where	object_id_one = :profile_id or object_id_two = :profile_id
    "]

    append debug_html "<li>Going to delete [llength rel_ids] memberships\n"
    foreach rel_id $rel_ids {
	append debug_html "<li>Deleting rel_id \#$rel_id\n"
	db_string del_rel "select acs_rel__delete(:rel_id)"
    }

    append debug_html "<li>Deleting permissions\n"
    db_dml del_perms "delete from acs_permissions where grantee_id = :profile_id"

    if {[db_table_exists im_ticket_queue_ext]} {
	append debug_html "<li>Deleting from im_profiles\n"
	db_dml del_profile "delete from im_ticket_queue_ext where group_id = :profile_id"
    }

    append debug_html "<li>Deleting from im_profiles\n"
    db_dml del_profile "delete from im_profiles where profile_id = :profile_id"

    append debug_html "<li>Deleting from groups\n"
    db_dml del_group "delete from groups where group_id = :profile_id"  

} err_msg

