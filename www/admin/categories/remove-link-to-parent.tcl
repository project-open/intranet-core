# /www/admin/categories/remove-link-to-parent.tcl
ad_page_contract {

  Deletes a parent-child relationship between two categories.

  @param category_id Which category is being worked on
  @param parent_category_id Category designated as parent to category_id

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id remove-link-to-parent.tcl,v 3.4.2.5 2000/07/23 16:47:23 seb Exp
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
	db_dml put_on_top_of_hierarchy "INSERT INTO category_hierarchy
	(child_category_id, parent_category_id)
	VALUES (:category_id, NULL)" 
    }
} on_error {
    ad_return_error "Database error" $errmsg
    return
}

db_release_unused_handles

ad_returnredirect "edit-parentage?[export_url_vars category_id]"
