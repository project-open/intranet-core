# /packages/intranet-core/www/admin/categories/remove-link-to-parent.tcl
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
  Deletes a parent-child relationship between two categories.
  @param category_id Which category is being worked on
  @param parent_category_id Category designated as parent to category_id

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @author frank.bergmann@project-open.com
} {
  category_id:naturalnum,notnull
  parent_category_id:naturalnum,notnull
}

db_transaction {
    db_dml delete_parent_child_relationship "DELETE FROM category_hierarchy
	WHERE child_category_id = :category_id
	    AND parent_category_id = :parent_category_id" 

    set parent_count [db_string parent_count "SELECT COUNT(*)
	FROM category_hierarchy
	WHERE child_category_id=:category_id" ]

    #  IMPORTANT!  We must provide each category with at least one parent, even
    # the NULL one, otherwise strange things may happen (categories
    # mysteriously disappear from list etc)

    if {$parent_count == 0} {
	db_dml put_on_top_of_hierarchy "INSERT INTO im_category_hierarchy
	(child_category_id, parent_category_id)
	VALUES (:category_id, NULL)" 
    }
} on_error {
    ad_return_error "Database error" $errmsg
    return
}

db_release_unused_handles

ad_returnredirect "edit-parentage?[export_url_vars category_id]"
