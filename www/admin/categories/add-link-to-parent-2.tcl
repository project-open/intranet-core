# /www/admin/categories/add-link-to-parent-2.tcl
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

  Creates a parent-child relationship between two categories.

  @param category_id Which category is being worked on
  @param parent_category_id Category designated as parent to category_id

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
} {
  category_id:naturalnum,notnull
  parent_category_id:naturalnum,notnull
}

db_transaction {

    #  If parent_category_id is 0, that means that user clicked on a
    #  'top-level' link.  We respond by clearing all parentage lines
    #  of that category and putting onto the top of hierarchy.

    if {$parent_category_id == 0} {

	db_dml delete_current_parents "DELETE FROM category_hierarchy
    WHERE child_category_id = :category_id" 

	db_dml put_on_top_of_hierarchy "INSERT INTO im_category_hierarchy
      (child_category_id, parent_category_id)
    VALUES (:category_id, NULL)" 

    } else {

	db_dml remove_from_top_of_hierarchy "DELETE FROM category_hierarchy
    WHERE child_category_id = :category_id
    AND parent_category_id IS NULL" 

	db_dml insert_parent_child_relationship "INSERT INTO im_category_hierarchy
	(child_category_id, parent_category_id)
    VALUES (:category_id, :parent_category_id)" 
    }

} on_error {
    ad_return_error "Database error" "Database threw an error: $errmsg"
    return
}

db_release_unused_handles

ad_returnredirect "edit-parentage?[export_url_vars category_id]"
