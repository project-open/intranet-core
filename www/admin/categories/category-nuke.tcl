# /www/admin/categories/category-nuke.tcl
ad_page_contract {

  Confirmation page for nuking a category.

  @param category_id Category ID we're about to nuke

  @author gbelcic@sls-international.com
  @creation-date 030905

} {

  category_id:naturalnum,notnull

}

set user_id [ad_maybe_redirect_for_registration]

# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------


set category [db_string category_name "select category from categories where category_id = :category_id" ]
set page_title "Categories - Delete $category"
set context_bar [ad_context_bar_ws $page_title]
set page_focus "im_header_form.keywords"

set page_body "
<form action=\"category-nuke-2.tcl\" method=GET>
[export_form_vars category_id]
<center>Are you sure that you want to nuke the category \"$category\"? This action cannot be undone.<p>
<input type=submit value=\"Yes, nuke this category now\"></form><hr>
"

doc_return  200 text/html [im_return_template]
