# /www/admin/categories/category-nuke-2.tcl
#
# Copyright (C) 2004 various parties
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
    Actually nukes a category.

    @param category_id Category ID we're nuking
    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
} {
  category_id:naturalnum,notnull
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
    db_1row category_name "select category_type from im_categories c where category_id = :category_id"
    
    db_transaction {

	db_dml delete_map "delete from im_category_hierarchy where parent_id = :category_id or child_id = :category_id"
	db_dml delete_map "delete from im_dynfield_type_attribute_map where object_type_id = :category_id"
	db_dml delete_category "delete from im_categories where category_id = :category_id"
    }
} errmsg ] {
    ad_return_complaint "Argument Error" "<b>[lang::message::lookup "" intranet-core.Err_Delete_Category "This category can't be deleted, please consider 'disabling'"]</b><br><br><ul>$errmsg</ul>"
    return
} 



# Remove all permission related entries in the system cache
im_permission_flush

# Redirect
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
