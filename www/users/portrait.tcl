# /packages/intranet-core/www/users/portrait.tcl
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
    offers an admin the option to delete a user's portrait

    @author philg@mit.edu
    @author frank.bergmann@project-open.com

} {
    user_id:integer,notnull
}
set user_info [db_0or1row user_info {
   select first_names, last_name
     from users
    where user_id = :user_id
}]

db_0or1row portrait_p {
select 
  portrait_id,
  portrait_upload_date,
  portrait_comment,
  portrait_original_width,
  portrait_original_height,
  portrait_client_file_name
from general_portraits 
where on_what_id = :user_id
  and on_which_table = 'USERS'
}]


if { [empty_string_p $first_names] && [empty_string_p $last_name] } {
    ad_return_error "Portrait Unavailable" "We couldn't find a portrait (or this user)"
    return
}

if { ! $portrait_p } {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for this person."
    return
}

if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}


set page_content "[ad_admin_header "Portrait of $first_names $last_name"]

<h2>Portrait of $first_names $last_name</h2>

[ad_admin_context_bar [list "one.tcl?[export_url_vars user_id]" "One User"] "Portrait"]

<hr>

<br>
<br>

<center>
<img $widthheight src=\"/shared/portrait-bits?[export_url_vars portrait_id]\">
</center>

<br>
<br>

<ul>
<li>Comment:  
<blockquote>
$portrait_comment
</blockquote>
<li>Uploaded:  [util_AnsiDatetoPrettyDate $portrait_upload_date]
<li>Original Name:  $portrait_client_file_name

<p>

<li><a href=\"portrait-erase?user_id=$user_id\">erase</a>

</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content
