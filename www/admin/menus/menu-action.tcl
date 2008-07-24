# /packages/intranet-core/www/admin/menus/menu-action.tcl
#
# Copyright (C) 2003-2004 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Delete selected menus

    @param return_url the url to return to
    @param menu_id The list of menus to delete

    @author frank.bergmann@project-open.com
} {
    menu_id:array,optional
    { submit "delete" }
    {return_url "/intranet/admin/menus"}
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set menu_list [array names menu_id]
ns_log Notice "menu-action: menu_list=$menu_list"

if {0 == [llength $menu_list]} {
    ad_returnredirect $return_url
}

# Convert the list of selected menus into a
# "menu_id in (1,2,3,4...)" clause
#
set menu_in_clause "and menu_id in ("
append menu_in_clause [join $menu_list ", "]
append menu_in_clause ")\n"
ns_log Notice "menu-action: menu_in_clause=$menu_in_clause"

switch $submit {

    "delete" {
	set sql "
			delete from im_menus
			where 1=1
				$menu_in_clause"
	if {[catch {
	    db_dml del_menus $sql
	} err_msg]} {
	    ad_return_complaint 1 "<li>Error deleting menus. Perhaps you try to delete menus that still have submenus. Here is the error:<br><pre>$err_msg</pre>"
	    return
	}
    }

    default {
	ad_return_complaint 1 "<li>Unknown value for submit: '$submit'"
    }
}

# Remove all permission related entries in the system cache
im_permission_flush


ad_returnredirect $return_url
