# /packages/intranet-core/www/admin/templates/template-upload.tcl
#
# Copyright (C) 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Upload a new template and create a corresponding category entry.

    @author frank.bergmann@project-open.com
    @creation-date 091116
} {
    { return_url "/intranet/admin/templates/index" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title "[_ intranet-core.Upload_Template]"
set current_url [im_url_with_query]
set context_bar [im_context_bar $page_title]

