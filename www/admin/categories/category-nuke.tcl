# /www/admin/categories/category-nuke.tcl
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
  @author gbelcic@sls-international.com
} {
  category_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------


set category [db_string category_name "select category from categories where category_id = :category_id" ]
set page_title "Categories - Delete $category"
set context_bar [ad_context_bar_ws $page_title]
set page_focus "im_header_form.keywords"

set page_body "
<form action=\"category-nuke-2.tcl\" method=GET>
[export_form_vars category_id]
<center>Are you sure that you want to nuke the category \"$category\"? This action cannot be undone.<p>
<input type=submit value=\"Yes, nuke this category now\"></form><hr>
"

doc_return  200 text/html [im_return_template]
