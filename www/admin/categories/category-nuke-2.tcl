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
  @creation-date 030905

} {
  category_id:naturalnum,notnull
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------


if [ catch {
    db_1row category_name "select category_type from categories c where category_id = :category_id"
    
    db_transaction {
	db_dml delete_category "delete from categories where category_id = :category_id"
    }
} errmsg ] {
    ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return
} 

db_release_unused_handles
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
