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

    @author unknown@arsdigita.com
    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
} {
    category_id:naturalnum,optional
    { select_category_type "" }
}

set user_id [ad_maybe_redirect_for_registration]


# ---------------------------------------------------------------
# Format Category Data 
# ---------------------------------------------------------------

if {[string equal "none" $select_category_type]} {
    set select_category_types_sql "
select
	nvl(c.category_type, 'none') as category_for_select,
	count(c.category_id) as n_categories
from
	im_categories c
group by c.category_type
order by c.category_type asc" 
    
    set select_categories "<tr><td>Category type</td><td><select name=category_type>"
    db_foreach select_kategory_types $select_category_types_sql {
	append select_categories "<option>$category_for_select</option>\n"
    }
    append select_categories "</select></td></tr>"

} else {
    set select_categories ""
}

set profiling_weight 0

if {[info exists category_id] && ![empty_string_p $category_id]} {

    set page_title "One Category"
    set context_bar [ad_context_bar $page_title]
    db_1row category_properties "
select
	c.*
from
	im_categories c
where
	c.category_id = :category_id
"
    set delete_action_html "
      <form action=category-nuke.tcl method=GET>[export_form_vars category_id] 
      <input type=submit name=Submit value=Delete></form>"
    set input_form_html "value=Update"
    set form_action_html "action=\"category-update.tcl\""


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
}

set page_body "
<form $form_action_html method=GET>
[export_form_vars category_type]
<table border=0 cellpadding=0 cellspacing=0>
<tr><td class=rowtitle colspan=2 align=center>Category</td></tr>
$select_categories
<tr><td>Category Nr.</td>
<td><input size=10 name=category_id value=\"$category_id\"></td>
</tr>
<tr><td>Category name</td>
<td><input size=40 name=category value=\"$category\"></td>
</tr>
<tr><td>Category description</td><td>
<textarea name=category_description rows=5 cols=50 wrap=soft>[ns_quotehtml $category_description]</textarea>
</td></tr>
</table>

<input type=hidden name=enabled_p value=\"t\">
<input type=submit name=submit $input_form_html>
</form>
$delete_action_html"



doc_return  200 text/html [im_return_template]


# this changes are because the new im_categories don't have some
# entries like profiling_weight, mailing_list_info, etc.
# <input type=hidden name=mailing_list_info value=\"$mailing_list_info\">
# <tr><td>Profiling weight</td><td><input size=10 name=profiling_weight value=\"$profiling_weight\" disable></td></tr>