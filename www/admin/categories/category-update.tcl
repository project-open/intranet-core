# /packages/intranet-core/www/admin/categories/category-update.tcl
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
  @author frank.bergmann@project-open.com
} {
    category_id:naturalnum,notnull
    category:notnull
    enabled_p:notnull
    sort_order:integer
    aux_int1:integer
    aux_int2:integer
    aux_string1
    aux_string2
    category_description:allhtml
    category_type
    { parents:multiple "" }
    translation:trim,array
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
# Update Hierarchy
# ---------------------------------------------------------------

db_dml delete_parents "
delete from im_category_hierarchy 
where child_id=:category_id
"

foreach parent $parents {
    db_dml insert_parent "
insert into im_category_hierarchy
(parent_id, child_id) values (:parent, :category_id)
"
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
	enabled_p = :enabled_p,
	sort_order = :sort_order,
	aux_int1 = :aux_int1,
	aux_int2 = :aux_int2,
	aux_string1 = :aux_string1,
	aux_string2 = :aux_string2,
	category_description = :category_description
WHERE 
	category_id = :category_id" 
} errmsg ] {
    ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return

}

# ---------------------------------------------------------------
# Update Translations
# ---------------------------------------------------------------


# Treat en_US first - as always :-)
# The system requires it for some reason, probably as a default
set locale "en_US"
set msg [string trim $translation($locale)]
set msg_key [lang::util::suggest_key $category]
set msg_key_len [string length $msg_key]
set cat_len [string length $category]

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

# Emit a warning if the msg_key_len is > 24.
if {$msg_key_len >= 24} {
    ad_return_complaint 1 "<b>Warning:</b>
    Your category is quite long ($cat_len Characters).<br>
    We cannot guarantee a unique translation for a category of this length
    because our translation are restricted in size.<br>
    Please try to use a shorter 'category' if possible or ignore this
    warning if you know what you are doing."
    return
}


# Remove all permission related entries in the system cache
im_permission_flush


db_release_unused_handles
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
