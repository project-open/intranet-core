# /www/admin/categories/category-update.tcl
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

  Updates the properties of an existing category.

  @param category_id           Id of category we're updating
  @param category              Category name
  @param category_description  Category description
  @param mailing_list_info     What kind of spam user should expect if subscr.
  @param profiling_weight      Category profiling weight
  @param enabled_p             Enabled as User Interest category
  @param category_type         Dimension of categorization
  @param new_category_type     New type can be specified
  
  @author unknown@arsdigita.com
  @author guillermo.belcic@project-open.com
  @creation-date 030904

} {

  category_id:naturalnum,notnull
  category:notnull
  category_description
  enabled_p:notnull
  category_type

}

# ---------------------------------------------------------------
# Check Arguments
# ---------------------------------------------------------------


set exception_count 0
set exception_text ""

if {![info exists category] || [empty_string_p $category]} {
    incr exception_count
    append exception_text "<li>Please enter category name"
}

if {[info exists category_description] && [string length $category_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your category description to 4000 characters"
}

if {[info exists mailing_list_info] && [string length $mailing_list_info] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your Mailing list information to 4000 characters"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count "<ul>$exception_text</ul>"
    return
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------


if [catch {
   
   db_dml update_category_properties "
UPDATE 
	im_categories
SET 
	category = :category,
	category_type = :category_type,
	category_description = :category_description,
	enabled_p = :enabled_p
WHERE 
	category_id = :category_id" 
} errmsg ] {
    ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return

}

db_release_unused_handles
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
