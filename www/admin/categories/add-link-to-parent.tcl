# /www/admin/categories/add-link-to-parent.tcl
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

  Form for designating a parent for a given category.

  @param category_id Which category is being worked on

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
} {

  category_id:naturalnum,notnull

}

set category [db_string category_name "SELECT category FROM categories WHERE category_id=:category_id" ]

# If there is no hierarchy defined, then just display a flat list of the existing categories. If there
# is, then show a fancy tree (which, btw, should be a proc).

set n_hierarchy_links [db_string n_hierarchy_links "select count(*)
from category_hierarchy
where parent_category_id is not null"]

set category_html ""

if { $n_hierarchy_links > 0 } {
    append category_html "<ul>

<li> <a href=\"add-link-to-parent-2?[export_url_vars category_id]&parent_category_id=0\">Top Level</a>
"

    #  Find all children, grand-children, etc of category in question and
    #  store them in a list.  The category MUST NOT have parent among any
    #  element in this list.

    set children_list [db_list category_children_list "
SELECT h.child_category_id
FROM category_hierarchy h
START WITH h.child_category_id = :category_id
CONNECT BY PRIOR h.child_category_id = h.parent_category_id" ]

    set parent_list [db_list category_parent_list "
SELECT h.parent_category_id
FROM category_hierarchy h
WHERE h.child_category_id = :category_id" ]

    set exclude_list [concat $children_list $parent_list]
    set prevlevel 0

    db_foreach category_hierarchy_tree "
SELECT c.category_id AS cat_id, c.category AS cat_name, hc.levelcol
FROM categories c,
(SELECT h.child_category_id, LEVEL AS levelcol, ROWNUM AS rowcol
 FROM category_hierarchy h
 START WITH h.parent_category_id IS NULL
 CONNECT BY PRIOR h.child_category_id = h.parent_category_id) hc
WHERE c.category_id = hc.child_category_id
ORDER BY hc.rowcol" {

	#  We will iterate the loop for every category.  If current category
	#  falls within $exclude_list, turn off hyperlinking to prevent
	#  circular parentships or unique constraint on category_hierarchy.

	set indent {}
	if {$prevlevel < $levelcol} {
	    regsub -all . [format %*s [expr $levelcol - $prevlevel] {}] \
		    "<UL> " indent
	} elseif {$prevlevel > $levelcol} {
	    regsub -all . [format %*s [expr $levelcol - $prevlevel] {}] \
		    "</UL> " indent
	}
	set prevlevel $levelcol
	append category_html "$indent <LI> "
	if {[lsearch -exact $exclude_list $cat_id] == -1} {
	    append category_html "<a href=\"add-link-to-parent-2?[export_url_vars category_id]&parent_category_id=$cat_id\">$cat_name</a> \n"
	} else {
	    append category_html "$cat_name \n"
	}
    }

    # Set close_tags to the appropriate number of </ul> tags

    if { [info exists levelcol] } {
        regsub -all . [format %*s $levelcol {}] "</ul> " close_tags

        append category_html "
</ul> $close_tags
"
    }

} else {

    # There's no hierarchy, so display all categories (except for this one) as possible parents.

    append category_html "<ul>\n"

    db_foreach plain_category_listing "
select category_id as parent_category_id, category as parent_category
from categories
where category_id <> :category_id
order by category" {

	append category_html "<li><a href=\"add-link-to-parent-2?[export_url_vars category_id parent_category_id]\">$parent_category</a>\n"
    }

    append category_html "</ul>\n"
}



doc_return  200 text/html "[ad_admin_header  "Define parent"]

<H2>Define parent for $category</H2>

[ad_admin_context_bar [list "index" "Categories"] [list "one?[export_url_vars category_id]" $category] "Define parent"]

<hr>

Click on a category to designate it as a parent of $category.

<p>

$category_html

[ad_admin_footer]
"
