# /packages/intranet-core/www/admin/consistency-check.tcl
#
# Copyright (C) 2011 ]project-open[
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
    Performs a number of sql queries in order to check
    for some know misconfiguration issues.
} {
}

# ------------------------------------------------------
# Security & Start of Page
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title [lang::message::lookup "" intranet-core.Consistency_Check "Consistency Checks"]
set parent_menu_id [util_memoize [list db_string admin_parent_menu "select menu_id from im_menus where label = 'admin'" -default 0]]
set admin_navbar_label ""

ad_return_top_of_page "
    [im_header]
    [im_navbar]
    [im_sub_navbar $parent_menu_id "" $page_title "pagedesriptionbar" $admin_navbar_label]
"

ns_write "<ul>\n"


# ------------------------------------------------------
# 
# ------------------------------------------------------

ns_write "</ul><br>\n"
ns_write "<h3>Check Categories' Transitive Closure</h3>\n"
ns_write "<ul>\n"

set check_sql "
	select	c.category_id,
		c.category,
		c.category_type,
		ch.parent_id,
		ch2.parent_id as parent2_id
	from	im_categories c,
		im_category_hierarchy ch,
		im_category_hierarchy ch2
	where	c.category_id = ch.child_id and
		-- Check if the parent itself has a parent
		ch2.child_id = ch.parent_id and
		-- Check if that parent-parent is not a parent of c.
		not exists (select * from im_category_hierarchy ch3 where ch3.child_id = c.category_id and ch3.parent_id = ch2.parent_id)
"
set cnt 0
db_foreach check $check_sql {
    ns_write "<li>
	<a href=[export_vars -base "/intranet/admin/categories/index" {{select_category_type $category_type}}]>$category ($category_type)</a><br>
	Found a 3rd level category that does not ALL of its parents set as a parent.<br>
	Please make sure that categories have ALL of their parents (1st level parent, 2nd level parent, ...)
	set in the 'is-a' field.<br>
	\]project-open\[ categories are designed for speed and not for user comfort currently.
	For this reason, you have to specify not only the 'direct parent', but also all of the
	parent's parents.<br>
	This issue is not very easy to understand. For more information please check the 
	<a href='http://www.project-open.org/en/object_type_im_category'>categories's page</a>.
	</li>
    "
    incr cnt
}
if {0 == $cnt} { ns_write "<li>No inconsistencies found</li>\n" }



# ------------------------------------------------------
# 
# ------------------------------------------------------

ns_write "</ul><br>\n"
ns_write "<h3>Check that every user is either an Emplyoee, a Customer or a Freelancer</h3>\n"
ns_write "<ul>\n"

set check_sql "
	select	*
	from	(
		select	u.*,
			(select	count(*) from acs_rels r 
			where	r.object_id_two = u.user_id and r.object_id_one = [im_employee_group_id]
			) as employee_p,
			(select	count(*) from acs_rels r 
			where	r.object_id_two = u.user_id and r.object_id_one = [im_customer_group_id]
			) as customer_p,
			(select	count(*) from acs_rels r 
			where	r.object_id_two = u.user_id and r.object_id_one = [im_freelance_group_id]
			) as freelancer_p
		from	cc_users u
		) t
	where
		employee_p + customer_p + freelancer_p != 1
"
set cnt 0
db_foreach check $check_sql {
    ns_write "<li>
	<a href=[export_vars -base "/intranet/users/view" {user_id}]>$first_names $last_name</a><br>
	Found a user who is not member of exactly one of the groups Employees, Customer or Freelancers.<br>
	Every user should be member of exactly one of these groups, because these groups are used
	for certain hard-coded functionality in the system.<br>
	Also, these groups should be the base of the permission configuration. 
	Additional group memberships (Project Manager, Sales, ...) should only contain the 
	_additional_ permissions for these groups.<br>
	</li>
    "
    incr cnt
}
if {0 == $cnt} { ns_write "<li>No inconsistencies found</li>\n" }




# ------------------------------------------------------
# Render the footer of the page
# ------------------------------------------------------
   
ns_write "<ul>\n"
ns_write [im_footer]



