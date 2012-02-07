ad_page_contract {

} {
    category_id:integer,multiple
    return_url
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

foreach cid $category_id {
    if {[catch {
	db_dml del_template "delete from im_categories where category_id = :cid"
    } err_msg]} {
	ad_return_complaint 1 "
		<b>Error deleting template</b>:<br>
		You get this error probably because one of your financial documents
		still uses this template.<br>
		You can:
		<ul>
		<li>Use 'Disable Template' instead of 'Delete Template' or
		<li>Edit your existing financial documents (invoices, quotes,...)
		    and change the template in all affected invoices.
		</ul>
		<br>&nbsp;
		<br>&nbsp;
		<br>&nbsp;
		<br>&nbsp;
		Here is the database error message for references:<br>&nbsp;<br>
		<pre>$err_msg</pre>
        "
    }
}

# Remove all permission related entries in the system cache
im_permission_flush

ad_returnredirect $return_url

