ad_page_contract {
    allow a user to modify or set the comment for their photo

    @cvs-id comment-modify.tcl,v 1.1.2.4 2000/09/22 01:36:29 kevin Exp

    @param user_id
} {
    user_id:naturalnum,notnull
}

ad_maybe_redirect_for_registration

if ![db_0or1row user_info {
    select 
      first_names, 
      last_name
    from users 
    where user_id = :user_id
}] {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

set page_title "Add/Modify Comment"
set context_bar [ad_context_bar [list "/intranet/users/" "Users"] [list "../one.tcl?user_id_from_search=$user_id" "$first_names $last_name"] $page_title]

set portrait_p [db_0or1row portrait_info {
   select portrait_id,
	  portrait_upload_date,
	  portrait_comment,
	  portrait_original_width,
	  portrait_original_height
     from general_portraits
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
}]

if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
    set widthheight "width=$portrait_original_width height=$portrait_original_height"
} else {
    set widthheight ""
}

set page_body "
<hr>

How would you like the world to see $first_names $last_name?

<P>

<center><img $widthheight src=\"/shared/portrait-bits?[export_url_vars portrait_id]\"></center>

<blockquote>
<form enctype=multipart/form-data method=POST action=\"comment-modify-2.tcl\">
[export_form_vars return_url]
<table>
<tr>
<td valign=top align=right>Story Behind Photo
<br>
<font size=-1>(optional)</font>
</td>
<td><textarea rows=6 cols=50 wrap=soft name=portrait_comment>
$portrait_comment
</textarea>
</td>
</tr>

</table>
<p>
<center>
<input type=hidden name=user_id value=$user_id>
<input type=submit value=\"Upload\">
</center>
</blockquote>
</form>"

doc_return  200 text/html [im_return_template]
