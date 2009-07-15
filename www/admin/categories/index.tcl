# /packages/intranet-core/www/admin/categories/index.tcl
#
# Copyright (C) 2004 ]project-open[
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

  @author sskracic@arsdigita.com
  @author michael@yoon.org
  @author guillermo.belcic@project-open.com
  @author frank.bergmann@project-open.com
} {
    { select_category_type "All" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set page_title "Categories"
set context_bar [im_context_bar $page_title]
set context ""

set new_href "one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"


set show_add_new_category_p 1
if {"" == $select_category_type} { set show_add_new_category_p 0 }
if {"All" == $select_category_type} { set show_add_new_category_p 0 }



# ---------------------------------------------------------------
# Format Category Type Drop Down Box
# ---------------------------------------------------------------

set select_category_types_sql "
select
	c.category_type as category_type,
	count(c.category_id) as n_categories
from
	im_categories c
group by c.category_type
order by c.category_type asc" 


# ---------------------------------------------------------------
# Format category type drop-down
# ---------------------------------------------------------------

set category_select_html "
    <select name=select_category_type>\n"

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
"

# ---------------------------------------------------------------
# Render Category List
# ---------------------------------------------------------------

set category_list_html "
<table border=0>
<tr>
  <td class=rowtitle align=center>Id</td>
  <td class=rowtitle align=center>En</td>
  <td class=rowtitle align=center>Category</td>
  <td class=rowtitle align=center>Sort<br>Order</td>
  <td class=rowtitle align=center>Is-A</td>
  <td class=rowtitle align=center>Int1</td>
  <td class=rowtitle align=center>Int2</td>
  <td class=rowtitle align=center>String1</td>
  <td class=rowtitle align=center>String2</td>
"

if {[string equal "All" $select_category_type]} {
    append category_list_html "<td class=rowtitle align=center>Category Type</td>"
}
append category_list_html "
  <td class=rowtitle align=center>Description</td>
</tr>"

# Now let's generate the sql query
set criteria [list]
set bind_vars [ns_set create]

set category_type_criterion "1=1"
if {![string equal "All" $select_category_type]} {
    set category_type_criterion "c.category_type = :select_category_type"
}

set ctr 1
set old_id 0
db_foreach category_select {} {

    if {"t" == $enabled_p } { set enabled_p "" }

    if {$old_id == $category_id} {
	# We got another is-a for the same category
	append category_list_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td></td>
	  <td></td>
	  <td></td>
	  <td>$parent</td>
	  <td></td>
	  <td></td>
	  <td></td>
	  <td></td>
	"
	if {[string equal "All" $select_category_type]} {
	    append category_list_html "<td></td>"
	}
	append category_list_html "<td></td></tr>\n"
	continue
    }

    append category_list_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td>$category_id</td>
	  <td>$enabled_p</td>
	  <td><a href=\"one.tcl?[export_url_vars category_id]\">$category</A></td>
	  <td>$sort_order</td>
	  <td><A href=\"/intranet/admin/categories/one?category_id=$parent_id\">$parent</A></td>
	  <td>$aux_int1 $aux_int1_cat</td>
	  <td>$aux_int2 $aux_int2_cat</td>
	  <td>$aux_string1</td>
	  <td>$aux_string2</td>
    "
    if {[string equal "All" $select_category_type]} {
	append category_list_html "<td>$category_type</td>"
    }
    append category_list_html "<td>$category_description</td></tr>\n"
    set old_id $category_id
    incr ctr
}

append category_list_html "</table>"

if {![string equal "All" $select_category_type]} {
    set category_type $select_category_type

    set new_href "one.tcl?[export_url_vars category_type]"

    append category_list_html "
<ul>
  <a href=\"$new_href\">
  Add a category
  </a>
</ul>"

}

