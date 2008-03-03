# /packages/intranet-core/www/admin/categories/category-add-2.tcl
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

  Inserts a new category.

  @param category_id          ID of newly created category
  @param parent_category_id   If exists, places newly created category in appropariate position in hierarchy
  @param category             Category name
  @param category_description Category description
  @param mailing_list_info    What kind of spam user might expect if this category is chosen in User Interest widget
  @param enabled_p            Enabled as User Interest category
  @param profiling_weight     Category profiling weight
  @param category_type        Dimension which this category is described along
  @param new_category_type    If set, new category type is created

  @author sskracic@arsdigita.com
  @author michael@yoon.org
  @author frank.bergmann@project-open.com
} {
  category_id:naturalnum,notnull
  parent_category_id:naturalnum,optional
  category:notnull
  category_description
  mailing_list_info
  enabled_p:notnull
  profiling_weight:naturalnum,notnull
  category_type
  new_category_type:optional
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Category ID is somehow missing.  This is probably a bug in our software."
}

if {![info exists parent_category_id]} {
    set parent_category_id ""
}

if {![info exists category] || [empty_string_p $category]} {
    incr exception_count
    append exception_text "<li>Please enter a category"
}

if {[info exists category_description] && [string length $category_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your category description to 4000 characters"
}

if {[info exists mailing_list_info] && [string length $mailing_list_info] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your Mailing list information to 4000 characters"
}

if {[info exists new_category_type] && ![empty_string_p $new_category_type]} {
    set category_type $new_category_type
}


set naughty_html_text [ad_check_for_naughty_html "$category $category_description $mailing_list_info $category_type $new_category_type"]

if { ![empty_string_p $naughty_html_text] } {
    append exception_text "<li>$naughty_html_text"
    incr exception_count
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}




db_transaction {
    db_dml new_category_entry {
	insert into im_categories
	(category_id, category, category_type, profiling_weight,
	 category_description, mailing_list_info, enabled_p)
	values
	(:category_id, :category, :category_type, :profiling_weight,
	 :category_description, :mailing_list_info, :enabled_p)
    }

    # Even top-level categories have at least one row in category_hierarchy, for which parent_category_id is null.

    if {[empty_string_p $parent_category_id]} {
	set parent_category_id [db_null]
    }

    db_dml category_hierarchy_entry {
	insert into im_category_hierarchy
	(child_category_id, parent_category_id)
	values
	(:category_id, :parent_category_id)
    }
} on_error {
    set insert_ok_p [db_string insert_ok_p "
select decode(count(*),0,0,1) from categories
where category_id = :category_id" ]
    if { !$insert_ok_p } {
      ad_return_error "Database error occured inserting $category" $errmsg
      return
    }
}


# Remove all permission related entries in the system cache
im_permission_flush


db_release_unused_handles
ad_returnredirect "one?[export_url_vars category_id]"
