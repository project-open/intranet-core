# /www/admin/categories/category-nuke-2.tcl
ad_page_contract {

  Actually nukes a category.

  @param category_id Category ID we're nuking
  @author gbelcic@sls-international.com
  @creation-date 030905

} {

  category_id:naturalnum,notnull

}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------


if [ catch {
    db_1row category_name "select category_type from categories c where category_id = :category_id"
    
    db_transaction {
	db_dml delete_category "delete from categories where category_id = :category_id"
    }
} errmsg ] {
    ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return
} 

db_release_unused_handles
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
