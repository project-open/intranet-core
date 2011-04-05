# /packages/intranet-core/www/admin/profiles/delete.tcl

ad_page_contract {

    Adds a new profile

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com

} {
} 

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_be_a_syst]">
    return
}

set title "Delete a Profile"
set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] $title]

set select_html ""

set profile_sql "
	select	g.group_name,
		g.group_id
	from	groups g,
		im_profiles p
	where	g.group_id = p.profile_id and
		g.group_name not in (
			'Employees', 'Freelancers', 'Customers', 'P/O Admins',
			'Sales', 'Helpdesk', 'Accounting',
			'Project Managers', 'Senior Managers'
		)
	order by group_id
"
db_foreach profiles $profile_sql {
    append select_html "
	<li><input type=radio name=profile_id value=$group_id>
	$group_name
    "
}


