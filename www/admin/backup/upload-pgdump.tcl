# /packages/intranet-core/www/admin/backup/upload-pgdump.tcl
#
# Copyright (C) 2003 - 2012 ]project-open[
#
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

ad_page_contract {
    Upload a backup file into ~/filestorage/backup
    @author frank.bergmann@project-open.com
} {
    { return_url ""}
}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set page_title [lang::message::lookup "" intranet-core.Upload_Backup_Dump "Upload Backup Dump"]
set context_bar [im_context_bar $page_title]

set page_body "
<form enctype=multipart/form-data method=POST action=upload-pgdump-2.tcl>
[export_vars -form {company_id return_url}]
                    <table border=0>
                      <tr> 
                        <td align=right>Filename: </td>
                        <td> 
                          <input type=file name=upload_file size=30>
[im_gif -translate_p 1 help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."]
                        </td>
                      </tr>
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=\"[lang::message::lookup "" intranet-trans-invoices.Submit_and_Upload "Submit and Upload"]\">
                        </td>
                      </tr>
                    </table>
</form>
"
