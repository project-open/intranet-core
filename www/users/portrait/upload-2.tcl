# /packages/intranet-filestorage/www/upload-2.tcl
#
# Copyright (C) 2003-2004 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    insert a file into the file system

    @author frank.bergmann@project-open.com
} {
    user_id:integer
    return_url
    upload_file
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-core.Upload_Portrait "Upload Portrait"]
set context_bar [im_context_bar [list "/intranet/users/" "Users"] $page_title]

im_user_permissions $current_user_id $user_id view read write admin
if {!$write} {
    ad_return_complaint 1 "[_ intranet-hr.lt_You_have_insufficient]"
    return
}

# ---------------------------------------------------------------
# Get the file from the user.
# ---------------------------------------------------------------


# number_of_bytes is the upper-limit
set max_n_bytes [parameter::get_from_package_key -package_key "acs-subsite" -parameter "MaxPortraitBytes" -default 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "upload-2.tcl" -value $tmp_filename
ns_log Notice "upload-2: tmp_filename=$tmp_filename"

set file_size [file size $tmp_filename]

if { $max_n_bytes && ($file_size > $max_n_bytes) } {
    ad_return_complaint 1 "Your file is larger than the maximum permissible upload size:  [util_commify_number $max_n_bytes] bytes"
    return 0
}

if { $file_size == 0 } {
    ad_return_complaint 1 "<b>Your file is empty</b>:<br>
    Please upload a different file."
    return 0
}

set file_extension [string tolower [file extension $upload_file]]
# remove the first . from the file extension
regsub "\." $file_extension "" file_extension
set guessed_file_type [ns_guesstype $upload_file]
set n_bytes [file size $tmp_filename]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

if {[regexp {\.\.} $client_filename]} {
    set error "<li>Path contains forbidden characters<br>
    Please don't use '.' characters."
    ad_return_complaint "User Error" $error
}


# ---------- Make sure client_filename starts with "portrait" -----------
set client_filename_pieces [split $client_filename "."]
set client_filename_pices_len [llength $client_filename_pieces]
set client_filename_ext [lindex $client_filename_pieces [expr $client_filename_pices_len-1]]
set client_filename "portrait.$client_filename_ext"


# ---------- Determine the location where to save the file -----------
set base_path [im_filestorage_user_path $user_id]
if {"" == $base_path} {
    ad_return_complaint 1 "<LI>Unknown folder for user $user_id."
    return
}
set dest_file "$base_path/$client_filename"
ns_log Notice "dest_file=$dest_file"



# --------------- Delete portraits from FS --------------------
set find_cmd [im_filestorage_find_cmd]
set dest_path "$base_path/"

if { [catch {
    set file_list [exec $find_cmd $dest_path -type f -maxdepth 1]
    foreach file $file_list {
	if {[regexp {portrait} $file match]} {
	    ns_log Notice "portraits/upload-2: /bin/rm $file"
	    exec /bin/rm $file
	}
    }
} err_msg] } {
    ad_return_complaint 1 "<b>Error deleting portrait file</b>:<br><pre>$err_msg</pre>"
    return
}


# --------------- Let's copy the file into the FS --------------------
if { [catch {
    ns_log Notice "/bin/mv $tmp_filename $dest_file"
    exec /bin/cp $tmp_filename $dest_file
    ns_log Notice "/bin/chmod ug+w $dest_file"
    exec /bin/chmod ug+w $dest_file
} err_msg] } {
    # Probably some permission errors
    ad_return_complaint  "Error writing upload file"  $err_msg
    return
}


set page_content "
<div id=\"slave\">
<div id=\"slave_content\">
<H2>Upload Successful</H2>

You have successfully uploaded $n_bytes bytes of '$client_filename'.<br>
You can now return to the project page.
<P>

<A href=\"$return_url\">Return to Previous Page</a>
</div>
</div>
"

# -----------------------------------------------
# Flush all cached portraits...

util_memoize_flush_regexp "im_portrait_html_helper.*"



db_release_unused_handles
doc_return  200 text/html [im_return_template]
