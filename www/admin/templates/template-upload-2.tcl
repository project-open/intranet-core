# /packages/intranet-translation/www/upload-task-2.tcl
#
# Copyright (C) 2004 - 2009 ]project-open[
#
# All rights reserved (this is not GPLed software!).
# Please check http://www.project-open.com/ for licensing
# details.

ad_page_contract {
    insert a file into the file system
} {
    return_url
    upload_file
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set template_path [im_filestorage_template_path]
set page_title "[_ intranet-translation.Upload_Successful]"
set context_bar [im_context_bar $page_title]


# -------------------------------------------------------------------
# Get the file
# -------------------------------------------------------------------

set max_n_bytes [ad_parameter -package_id [im_package_filestorage_id] MaxNumberOfBytes "" 0]
set tmp_filename [ns_queryget upload_file.tmpfile]
im_security_alert_check_tmpnam -location "template-upload-2.tcl" -value $tmp_filename
set filesize [file size $tmp_filename]

if { $max_n_bytes && ($filesize > $max_n_bytes) } {
    set util_commify_number_max_n_bytes [util_commify_number $max_n_bytes]
    ad_return_complaint 1 "[_ intranet-translation.lt_Your_file_is_larger_t_1]"
    ad_script_abort
}

if {![regexp {^([a-zA-Z0-9_\-]+)\.([a-zA-Z_]+)\.([a-zA-Z]+)$} $upload_file match]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-core.Invalid_Template_format "
	<b>Invalid Template Format</b>:<br>
	Templates should have the format 'filebody.locale.ext'.
    "]
    ad_script_abort
}




# -------------------------------------------------------------------
# Copy the uploaded file into the template filestorage
# -------------------------------------------------------------------

if { [catch {
    ns_cp $tmp_filename "$template_path/$upload_file"
} err_msg] } {
    # Probably some permission errors
    ad_return_complaint 1 "[lang::message::lookup "" intranet-core.Error_Copying "Error Copying File"]:<br>
	<pre>$err_msg</pre>during command:
	<pre>ns_cp $tmp_filename $template_path/$upload_file</pre>
    "
    ad_script_abort
}

# -------------------------------------------------------------------
# Create a new category
# -------------------------------------------------------------------

set cat_exists_p [db_string ex "select count(*) from im_categories where category = :upload_file and category_type = 'Intranet Cost Template'"]
if {!$cat_exists_p} {

    set cat_id [db_nextval "im_categories_seq"]
    set cat_id_exists_p [db_string cat_ex "select count(*) from im_categories where category_id = :cat_id"]
    while {$cat_id_exists_p} {
	set cat_id [db_nextval "im_categories_seq"]
	set cat_id_exists_p [db_string cat_ex "select count(*) from im_categories where category_id = :cat_id"]
    }

    db_dml new_cat "
	insert into im_categories (
		category_id,
		category,
		category_type,
		enabled_p
	) values (
		nextval('im_categories_seq'),
		:upload_file,
		'Intranet Cost Template',
		't'
	)
    "
}

# (Re-) enable the category
db_dml enable "update im_categories set enabled_p = 't' where category = :upload_file and category_type = 'Intranet Cost Template'"


# Remove all permission related entries in the system cache
im_permission_flush

