# /www/admin/categories/index.tcl
#
# Copyright (C) 2004 Project/Open
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
  Home page for category administration.

  @author guillermo.belcic@project-open.com
  @creation-date 030904
} {
    { select_category_type "All" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set page_title "Categories"
set context_bar [ad_context_bar_ws $page_title]
set context ""

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

# ---------------------------------------------------------------
# Format Category Type Drop Down Box
# ---------------------------------------------------------------

set select_category_types_sql "
select
	nvl(c.category_type, 'none') as category_type,
	count(c.category_id) as n_categories
from
	categories c
group by c.category_type
order by c.category_type asc" 


set category_select_html "
<form method=GET action=index.tcl>
<table border=0 cellpadding=0 cellspacing=0>
<tr> 
  <td class=rowtitle align=center>
    Filter Categories
  </td>
  <td class=rowtitle align=center><a href=one?select_category_type=none>[im_gif new "new category"]</a></td>
</tr>
<tr>
  <td>
    <select name=select_category_type>
"

# Render the "All" categories option
if {[string equal "All" $select_category_type]} {
    append category_select_html "<option selected>All</option>\n"
} else {
    append category_select_html "<option>All</option>\n"
}

db_foreach select_kategory_types $select_category_types_sql {
    if {[string equal $category_type $select_category_type]} {
	append category_select_html "<option selected>$category_type</option>\n"
    } else {
	append category_select_html "<option>$category_type</option>\n"
    }
}
append category_select_html "
    </select>
    <input type=submit name=Submit value=go></td>
</tr>
</table>
</form>"


# ---------------------------------------------------------------
# Render Category List
# ---------------------------------------------------------------

set category_list_html "
<table border=0>
<tr>
  <td class=rowtitle>Id</td>
  <td class=rowtitle>Category</td>"

if {[string equal "All" $select_category_type]} {
    append category_list_html "<td class=rowtitle>Category Type</td>"
}
append category_list_html "
  <td class=rowtitle>Description</td>
</tr>"

# Now let's generate the sql query
set criteria [list]
set bind_vars [ns_set create]

set category_type_criterion "1=1"
if {![string equal "All" $select_category_type]} {
    set category_type_criterion "c.category_type = :select_category_type"
}

set category_select_sql "
select
	c.*
from 
	categories c
where 
	$category_type_criterion
order by
	category_type,
	category_id
"

set ctr 1
db_foreach all_categories_of_type $category_select_sql {

append category_list_html "
<tr $bgcolor([expr $ctr % 2])>
  <td>$category_id</td>
  <td><a href=\"one.tcl?[export_url_vars category_id]\">$category</A></td>"

if {[string equal "All" $select_category_type]} {
    append category_list_html "<td>$category_type</td>"
}

    append category_list_html "
  <td>
    $category_description
  </td>
</tr>"
    incr ctr
}

append category_list_html "</table>"

if {![string equal "All" $select_category_type]} {
    append category_list_html "
<ul>
  <a href=\"one.tcl?[export_url_vars select_category_type]\">
  Add a category
  </a>
</ul>"

}

