# /www/admin/categories/add-link-to-parent-2.tcl
ad_page_contract {

  Creates a parent-child relationship between two categories.

  @param category_id Which category is being worked on
  @param parent_category_id Category designated as parent to category_id

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id add-link-to-parent-2.tcl,v 3.3.2.5 2000/07/23 16:47:21 seb Exp
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

	db_dml put_on_top_of_hierarchy "INSERT INTO category_hierarchy
      (child_category_id, parent_category_id)
    VALUES (:category_id, NULL)" 

    } else {

	db_dml remove_from_top_of_hierarchy "DELETE FROM category_hierarchy
    WHERE child_category_id = :category_id
    AND parent_category_id IS NULL" 

	db_dml insert_parent_child_relationship "INSERT INTO category_hierarchy
	(child_category_id, parent_category_id)
    VALUES (:category_id, :parent_category_id)" 
    }

} on_error {
    ad_return_error "Database error" "Database threw an error: $errmsg"
    return
}

db_release_unused_handles

ad_returnredirect "edit-parentage?[export_url_vars category_id]"
