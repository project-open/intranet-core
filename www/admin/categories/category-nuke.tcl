# /packages/intranet-core/www/admin/categories/category-nuke.tcl
#
# Copyright (C) 1998-2004 various parties
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
    Confirmation page for nuking a category.
    @param category_id Category ID we're about to nuke

    @author unknown@arsdigita.com
    @author gbelcic@project-open.com
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

set category [db_string category_name "select category from im_categories where category_id = :category_id" ]
set page_title "Categories - Delete $category"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set page_body "
<form action=\"category-nuke-2.tcl\" method=GET>
[export_form_vars category_id]
<center>Are you sure that you want to nuke the category \"$category\"? This action cannot be undone.<p>
<input type=submit value=\"Yes, nuke this category now\"></form><hr>
"

ad_return_template
