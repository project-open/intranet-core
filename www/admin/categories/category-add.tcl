# /www/admin/categories/category-add-2.tcl
ad_page_contract {

  Inserts a new category.

  @param category_id          ID of newly created category
  @param parent_category_id   If exists, places newly created category in appropariate position in hierarchy
  @param category             Category name
  @param category_description Category description
  @param mailing_list_info    What kind of spam user might expect if this category is chosen in User Interest widget
  @param enabled_p            Enabled as User Interest category
  @param profiling_weight     Category profiling weight
  @param category_type        Dimension which this category is described along
  @param new_category_type    If set, new category type is created

  @author gbelcic@sls-international.com
  @creation-date 030905

} {

  category_id:naturalnum,notnull
  category:notnull
  category_description
  mailing_list_info
  enabled_p:notnull
  profiling_weight:naturalnum,notnull
  category_type

}


# ---------------------------------------------------------------
# Check Arguments
# ---------------------------------------------------------------

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Category ID is somehow missing."
}


if {![info exists category] || [empty_string_p $category]} {
    incr exception_count
    append exception_text "<li>Please enter a category"
}

if {[info exists category_description] && [string length $category_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your category description to 4000 characters"
}

if {[info exists mailing_list_info] && [string length $mailing_list_info] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your Mailing list information to 4000 characters"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count "<ul>$exception_text</ul>"
    return
}

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

    
if [catch {

    db_transaction {
	db_dml new_category_entry {
	    insert into categories
	    (category_id, category, category_type, profiling_weight,
	     category_description, mailing_list_info, enabled_p)
	    values
	    (:category_id, :category, :category_type, :profiling_weight,
	     :category_description, :mailing_list_info, :enabled_p)
	}
    }
} errmsg ] {
    ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return
}


db_release_unused_handles
set select_category_type $category_type
ad_returnredirect "index.tcl?[export_url_vars select_category_type]"
