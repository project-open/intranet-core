# /www/admin/categories/index.tcl
ad_page_contract {
  Home page for category administration.

  @author gbelcic@sls-international.com
  @creation-date 030904
} {
    { select_category_type "All" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set page_title "Administration"
set context_bar [ad_context_bar $page_title]

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

