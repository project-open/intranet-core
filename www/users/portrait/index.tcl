# /packages/intranet-core/www/users/portraits/index.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
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
    displays a user's portrait to the user him/herself
    offers options to replace it

    @cvs-id index.tcl,v 1.1.2.6 2000/09/22 01:36:30 kevin Exp
    @author philg@mit.edu

    @param user_id
} {
    user_id:naturalnum,notnull
}

set current_user_id [ad_maybe_redirect_for_registration]

if ![db_0or1row get_user_info {
    select
      u.first_names, 
      u.last_name, 
      gp.portrait_id,
      gp.portrait_upload_date,
      gp.portrait_comment,
      gp.portrait_original_width,
      gp.portrait_original_height,
      gp.portrait_client_file_name
    from users u, general_portraits gp
    where u.user_id = :user_id
      and u.user_id = gp.on_what_id(+)
      and 'USERS' = gp.on_which_table(+)
      and 't' = gp.portrait_primary_p(+)
}] {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

set page_title "$first_names's Portrait"
set context_bar [ad_context_bar [list "/intranet/users/" "Users"] [list "/intranet/users/view?user_id=$user_id" "$first_names $last_name"] $page_title]


if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}

if  { [empty_string_p $portrait_id] } {
    set img_html_frag "\[ <i>No portrait has been uploaded for this user.</i> \]"
    set replacement_text "portrait"
    set comment_html_frag ""
} else {
    set img_html_frag "<img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars portrait_id]\">"
    set replacement_text "replacement"
    if { [empty_string_p $portrait_comment] } {
      set comment_html_frag "<li><a href=comment-modify.tcl?[export_url_vars user_id]>add a comment</a>\n"
    } else {
      set comment_html_frag "<li><a href=comment-modify.tcl?[export_url_vars user_id]>modify the comment</a>\n"
    }
}


set page_body "
<table width='100%'>
  <tr>
    <td>
<ul>
<li><a href=\"upload?[export_url_vars user_id]\">upload a $replacement_text</a>
$comment_html_frag
<li><a href=\"erase?[export_url_vars user_id]\">erase</a>
</ul>

<P>

<ul>
<li>Uploaded:  [util_AnsiDatetoPrettyDate $portrait_upload_date]
<li>Original Name:  $portrait_client_file_name
<li>Comment:  
<blockquote>
$portrait_comment
</blockquote>
</ul>
    </td>
    <td>
      $img_html_frag
    </td>
  </tr>
</table>

This is the image that we show to other users at [ad_system_name]:<br>
(If you just changed the image, you may need to reload this page to see your changes.)
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]