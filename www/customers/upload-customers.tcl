# /intranet/customers/upload.tcl
#
# Copyright (C) 2004 Project/Open
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date July 2003
} {
    return_url:notnull
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Upload Client CSV"

set context_bar [ad_context_bar [list "/intranet/customers/" "Customers"] "Upload CSV"]

set page_content "
<form enctype=multipart/form-data method=POST action=upload-customers-2.tcl>
[export_form_vars return_url]
                    <table border=0>
                      <tr> 
                        <td align=right>Filename: </td>
                        <td> 
                          <input type=file name=upload_file size=30>
                          <img src=/images/help.gif width=16 height=16 alt='Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;.'> 
                        </td>
                      </tr>
                      <tr> 
                        <td></td>
                        <td> 
                          <input type=submit value=Submit and Upload>
                        </td>
                      </tr>
                    </table>
</form>
"

db_release_unused_handles

doc_return  200 text/html [im_return_template]
