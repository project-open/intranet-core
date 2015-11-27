# /www/admin/categories/batch-import-.tcl
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
    Batch import multiple categories
    @author frank.bergmann@project-open.com
} {
    category_type
    categories
}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

set page_title "Category Batch Import"
set cats [split $categories "\n"]
set category_description ""
set enabled_p "t"

foreach category $cats {
    set category [string trim $category]
    if {"" == $category} { continue }
    set category [regsub -all {^a-zA-Z0-9_\-\ } $category ""]

#    ad_return_complaint 1 "'$category'"

    set category_id [db_nextval im_categories_seq]
    
    db_transaction {
	db_dml new_category_entry {
		insert into im_categories (
			category_id, category, category_type,
			category_description, enabled_p
		) values (
			:category_id, :category, :category_type,
			:category_description, :enabled_p
		)
	}
    } on_error {
	ad_return_error "Database error occured inserting $category" "<pre>$errmsg</pre>"
	ad_script_abort
    }
}

# Remove all permission related entries in the system cache
im_permission_flush

ad_returnredirect [export_vars -base "/intranet/admin/categories/index" {{select_category_type $category_type}}]

