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

  @author sskracic@arsdigita.com
  @author michael@yoon.org
  @creation-date October 31, 1999
  @cvs-id category-add-2.tcl,v 3.4.2.6 2000/07/23 16:47:22 seb Exp

} {

  category_id:naturalnum,notnull
  parent_category_id:naturalnum,optional
  category:notnull
  category_description
  mailing_list_info
  enabled_p:notnull
  profiling_weight:naturalnum,notnull
  category_type
  new_category_type:optional

}

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Category ID is somehow missing.  This is probably a bug in our software."
}

if {![info exists parent_category_id]} {
    set parent_category_id ""
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

if {[info exists new_category_type] && ![empty_string_p $new_category_type]} {
    set category_type $new_category_type
}


set naughty_html_text [ad_check_for_naughty_html "$category $category_description $mailing_list_info $category_type $new_category_type"]

if { ![empty_string_p $naughty_html_text] } {
    append exception_text "<li>$naughty_html_text"
    incr exception_count
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}




db_transaction {
    db_dml new_category_entry {
	insert into categories
	(category_id, category, category_type, profiling_weight,
	 category_description, mailing_list_info, enabled_p)
	values
	(:category_id, :category, :category_type, :profiling_weight,
	 :category_description, :mailing_list_info, :enabled_p)
    }

    # Even top-level categories have at least one row in category_hierarchy, for which parent_category_id is null.

    if {[empty_string_p $parent_category_id]} {
	set parent_category_id [db_null]
    }

    db_dml category_hierarchy_entry {
	insert into category_hierarchy
	(child_category_id, parent_category_id)
	values
	(:category_id, :parent_category_id)
    }
} on_error {
    set insert_ok_p [db_string insert_ok_p "
select decode(count(*),0,0,1) from categories
where category_id = :category_id" ]
    if { !$insert_ok_p } {
      ad_return_error "Database error occured inserting $category" $errmsg
      return
    }
}

db_release_unused_handles

ad_returnredirect "one?[export_url_vars category_id]"
