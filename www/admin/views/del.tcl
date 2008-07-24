# /packages/intranet-core/www/admin/views/del.tcl
#
# Copyright (C) 2003-2004 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new view or edit an existing one.

    @param form_mode edit or display

    @author juanjoruizx@yahoo.es
} {
    view_id:integer,optional
    return_url
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}


# ------------------------------------------------------------------
# Delete the View
# ------------------------------------------------------------------

if {[catch {
	db_dml del_view {
		delete from IM_VIEWS
		where view_id = :view_id
	}
} err_msg]} {
	ad_return_complaint 1 "<li>Error deleting view. Perhaps you try to delete a view that still has dependeces. Here is the error:<br><pre>$err_msg</pre>"
	return
}

ad_returnredirect $return_url
ad_script_abort
