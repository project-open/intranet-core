# /packages/intranet-core/www/admin/backup/upload-pgdump-2.tcl
#
# Copyright (C) 2003 - 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Upload the file and store in the backup file storage
} {
    return_url
    upload_file
} 


set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    ad_script_abort
}

set page_title "Upload New File/URL"
set context_bar [im_context_bar [list "/intranet/cusomers/" "Clients"] "Upload CSV"]

# Get the file from the user.
# number_of_bytes is the upper-limit
set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-pgdump-2.tcl" -value $tmp_filename
if { $max_n_bytes && ([file size $tmp_filename] > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return
}

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match company_filename] {
    # couldn't find a match
    set company_filename $upload_file
}

if {[regexp {\.\.} $company_filename]} {
    set error "Filename contains forbidden characters"
    ad_returnredirect "/error.tcl?[export_url_vars error]"
}

if {![file readable $tmp_filename]} {
    set err_msg "Unable to read the file '%tmp_filename%'. 
    Please check the file permissions or price your system administrator."
    append page_body "\n$err_msg\n"
    ad_return_template
}

# Move the file into the right folder
exec mv $tmp_filename "[im_backup_path]/$company_filename"

ad_returnredirect $return_url
