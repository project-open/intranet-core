# /packages/intranet-core/www/admin/templates/template-download.tcl
#
# Copyright (C) 2010 ]project-open[


ad_page_contract {
    Purpose: allows downloading a template file
    @param path_to_file - location of template file to download
    @author klaus.hofeditz@project-open.com
} {
    { template_name }
}


# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set path_to_file [parameter::get -package_id [db_string get_view_id "select package_id from apm_packages where package_key = 'intranet-invoices'" -default 0] -parameter "InvoiceTemplatePathUnix" -default ""]
append path_to_file "/"  $template_name



if {[catch {
    # set outputheaders [ns_conn outputheaders]
    # ns_set cput $outputheaders "Content-Disposition" "attachment; filename=${template_name}"
    ns_returnfile 200 "application" $path_to_file
} err_msg]} {
    ad_return_complaint 1 "
       <b>Error receiving template, please ask your System Administrator check category 'Intranet Cost Template'</b>:<br>
       <pre>$err_msg</pre>
    "
}
