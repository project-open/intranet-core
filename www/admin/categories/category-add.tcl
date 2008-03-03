# /packages/intranet-core/www/admin/categories/category-add-2.tcl
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

  @author unknown@arsdigita.com
  @author guillermo.belcic@project-open.com
  @author frank.bergmann@project-open.com
} {
    category_id:naturalnum,notnull
    category:notnull
    category_description
    enabled_p:notnull
    category_type
    translation:array
    aux_int1
    aux_int2
    aux_string1
    aux_string2
}

# ---------------------------------------------------------------
# Check Arguments
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

set package_key "intranet-core"

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Category ID is somehow missing."
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

if { $exception_count > 0 } {
    ad_return_complaint $exception_count "<ul>$exception_text</ul>"
    return
}

# ---------------------------------------------------------------
# Update the category
# ---------------------------------------------------------------

if [catch {

    db_transaction {
	db_dml new_category_entry {
	    insert into im_categories (
		category_id, category, category_type,
		category_description, enabled_p,
		aux_int1, aux_int2,
		aux_string1, aux_string2
	    ) values (
		:category_id, :category, :category_type,
		:category_description, :enabled_p,
		:aux_int1, :aux_int2,
		:aux_string1, :aux_string2
	    )
	}
    }
} errmsg ] {
    ad_return_complaint "Argument Error" "<pre>$errmsg</pre>"
    return
}


# ---------------------------------------------------------------
# Add translations
# ---------------------------------------------------------------


# Treat en_US first - as always :-)
# The system requires it for some reason, probably as a default
set locale "en_US"
set msg [string trim $translation($locale)]
set msg_key [lang::util::suggest_key $category]

if {"" != $msg} {
    lang::message::register -comment $category_description $locale $package_key $msg_key $msg
}

# Now add all the other locales
foreach locale [array names translation] {
    set msg [string trim $translation($locale)]
    set msg_key [lang::util::suggest_key $category]

    if {"" != $msg} {
	lang::message::register -comment $category_description $locale $package_key $msg_key $msg
    }
}

# Remove all permission related entries in the system cache
im_permission_flush

db_release_unused_handles
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
