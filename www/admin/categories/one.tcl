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
    { select_category_type "" }
}

set user_id [ad_maybe_redirect_for_registration]


# ---------------------------------------------------------------
# Format Category Data 
# ---------------------------------------------------------------

set profiling_weight 0
set select_categories ""
set hierarchy_component ""
ns_log Notice "one: category_id=$category_id"

if {0 != $category_id} {
    
    set page_title "One Category"
    set context_bar [ad_context_bar $page_title]

    db_1row category_properties "
select	c.*
from	im_categories c
where	c.category_id = :category_id"

    ns_log Notice "one: category_description=$category_description"
    
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
order by category_id"
    
    db_foreach parents $parent_sql {
	set selected ""
	if {[info exists child($parent_id)]} { set selected "selected" } 
	append hierarchy_component "<option value=$parent_id $selected>$parent_category</option>\n"
    }
    
    
} else {


    set page_title "Add Category"
    set context_bar [ad_context_bar_ws $page_title]
    set form_action_html "action=\"category-add.tcl\""
    set input_form_html "value=Add"
    set delete_action_html ""
    set category_id [db_nextval im_categories_seq]
    set category_description ""
    set profiling_weight 0
    set category ""
    if {![string equal "none" $select_category_type]} {
	set category_type $select_category_type
    }
    set enabled_p ""
    set mailing_list_info ""

    set select_category_types_sql "
select
	nvl(c.category_type, 'none') as category_for_select
from
	im_categories c
group by c.category_type
order by c.category_type asc" 
    
    set select_categories "<tr><td>Category type</td><td><select name=category_type>"
    db_foreach select_category_types $select_category_types_sql {
	append select_categories "<option>$category_for_select</option>\n"
    }
    append select_categories "</select></td></tr>"

}

set export_form_vars [export_form_vars category_type]

set descr [ns_quotehtml $category_description]