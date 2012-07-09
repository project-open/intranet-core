# /www/admin/categories/one.tcl
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
    Displays and edits the properties of one category.
    @param category_id Which category is being worked on

    @author sskracic@arsdigita.com
    @author michael@yoon.org
    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
} {
    { category_id:naturalnum 0 }
    { category_type "" }
    { new_category 0 }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

set package_key "intranet-core"

# ---------------------------------------------------------------
# Format Category Data 
# ---------------------------------------------------------------

set sort_order 0
set profiling_weight 0
set hierarchy_component ""
ns_log Notice "one: category_id=$category_id"

if {0 != $category_id} {
    
    db_1row category_properties "
	select	c.*
	from	im_categories c
	where	c.category_id = :category_id
    "

    set page_title "$category_type - $category"
    set context_bar [im_context_bar $page_title]

    set delete_action_html "
      <form action=category-nuke.tcl method=GET>[export_form_vars category_id] 
      <input type=submit name=Submit value=Delete></form>"
    set input_form_html "value=Update"
    set form_action_html "action=\"category-update.tcl\""

    # Get the parents of category_id into an array
    db_foreach parents "select h.* from im_category_hierarchy h where child_id=:category_id" {
	set child($parent_id) $child_id
    }

    set parent_sql "
	select	c.category_id as parent_id,
		c.category as parent_category
	from	im_categories c
	where	c.category_type = :category_type
	order by category_id
    "

    db_foreach parents $parent_sql {
	set selected ""
	if {[info exists child($parent_id)]} { set selected "selected" } 
	append hierarchy_component "<option value=$parent_id $selected>$parent_category</option>\n"
    }
        
} else {

    set page_title "Add Category"
    if {"" != $category_type} { append page_title " for '$category_type'" }
    set context_bar [im_context_bar $page_title]
    set form_action_html "action=\"category-add.tcl\""
    set input_form_html "value=Add"
    set delete_action_html ""

    # Increase the category counter until up to date
    set category_id [db_string max_cat_id "select max(category_id) from im_categories" -default 100000]


    # Increase the category counter until up to date
    set category_id [db_string max_cat_id "select max(category_id) from im_categories" -default\
			 10000]
    set category_id [expr $category_id + 1]
    while {[db_string max_cat_id "select max(category_id) from im_categories"] >= $category_id} {
	set category_id [db_nextval im_categories_seq]
    }

    set category_description ""
    set profiling_weight 0
    set category ""
    set enabled_p ""
    set mailing_list_info ""

    set aux_int1 ""
    set aux_int2 ""
    set aux_string1 ""
    set aux_string2 ""
}

if {"f" == $enabled_p} {
    set enabled_p_checked ""
    set enabled_p_unchecked "checked"
} else {
    set enabled_p_checked "checked"
    set enabled_p_unchecked ""
}

# ---------------------------------------------------------------
# Category Select Component
# ---------------------------------------------------------------

set select_category_types_sql "
	select
		c.category_type as category_for_select
	from
		im_categories c
	group by c.category_type
	order by c.category_type asc
" 
  
set category_type_select "<select name=category_type>\n"
db_foreach select_category_types $select_category_types_sql {
    set selected ""
    if {$category_for_select == $category_type} { set selected "selected" }
    append category_type_select "<option $selected>$category_for_select</option>\n"
}
append category_type_select "</select>\n"

if {$new_category} {
    set category_type_select "
	<input name=category_type value=\"$category_type\">
    "
}


# set descr [ns_quotehtml $category_description]
set descr $category_description

# ---------------------------------------------------------------
# Category Translation
# ---------------------------------------------------------------

set category_translation_component ""


set msg_key [lang::util::suggest_key $category]

set l10n_text_sql "
	select
		el.*,
		lm.message
	from
		enabled_locales el left outer join (
			select * 
			from lang_messages lm
			where 
				lm.package_key = :package_key
				and lm.message_key = :msg_key
		) lm on (el.locale = lm.locale)
	order by
		el.locale
"

db_foreach l10n_strings $l10n_text_sql {
    append category_translation_component "
$locale: <input type=text name=translation.$locale value=\"$message\" size=40><br>
"
}

set constant_p f