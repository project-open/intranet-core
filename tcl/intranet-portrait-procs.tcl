# /packages/intranet-core/tcl/intranet-portrait-procs.tcl
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

ad_library {
    Common procedures about portraits
    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Random User Portrait
# ----------------------------------------------------------------------

ad_proc -public im_random_employee_blurb { } {
    Returns a random employee's photograph and a little bio
} {
    # Get the current user id to not show the current user's portrait
    set subsite_url [subsite::get_element -element url]
    set export_vars [export_url_vars user_id return_url]

    set portrait_sql "
	select
	        live_revision as revision_id,
		a.object_id_one as portrait_user_id,
	        item_id
	from
	        acs_rels a,
	        cr_items c
	where
	        a.object_id_two = c.item_id
	        and a.rel_type = 'user_portrait_rel'
    "

    set user_list [list]
    db_foreach portrait_users $portrait_sql  {
	lappend user_list $portrait_user_id
    }

    # Select a random user from the list
    set user_list_len [llength $user_list]
    set random_user_pos [randomRange $user_list_len]
    set random_user_id [lindex $user_list $random_user_pos]

    return [im_portrait_component $random_user_id "/intranet/" 1 0 0]
}

# ----------------------------------------------------------------------
# Portrait Component
# ----------------------------------------------------------------------

ad_proc im_portrait_component { user_id return_url read write admin} {
    Show the portrait and a short bio (comments) about a user
} {
    if {!$read} { return ""}

    set current_user_id [ad_get_user_id]
    set subsite_url [subsite::get_element -element url]
    set export_vars [export_url_vars user_id return_url]

    if {![db_0or1row get_item_id "
	select
		live_revision as revision_id, 
		item_id
	from 
		acs_rels a, 
		cr_items c
	where 
		a.object_id_two = c.item_id
		and a.object_id_one = :user_id
		and a.rel_type = 'user_portrait_rel'
    "] || [empty_string_p $revision_id]
    } {
	# The user doesn't have a portrait yet
	set portrait_p 0
    } else {
	set portrait_p 1
    }

    if [catch {db_1row get_picture_info "
	select 
		i.width, 
		i.height, 
		cr.title, 
		cr.description, 
		cr.publish_date
	from 
		images i, 
		cr_revisions cr
	where 
		i.image_id = cr.revision_id
		and image_id = :revision_id
	"
    } errmsg] {
	# There was an error obtaining the picture information
	set portrait_p 0
    }

    # Check if there was a portrait
    if {![exists_and_not_null publish_date]} { 
	set portrait_p 0 
    }

    set portrait_alt "Portrait"

    if {$portrait_p} {
	if { ![empty_string_p $width] && ![empty_string_p $height] } {
	    set widthheight "width=$width height=$height"
	} else {
	    set widthheight ""
	}
    
	set portrait_gif "<img $widthheight src=\"/shared/portrait-bits.tcl?user_id=$user_id\" alt=\"$portrait_alt\" title=\"$portrait_alt\" >"

    } else {
	
	set portrait_gif [im_gif anon_portrait $portrait_alt]
	set description "No portrait for <br>\n$first_names $last_name."
	
	if {$admin} { append description "<br>\n[_ intranet-core.lt_Please_upload_a_portr]"}
    }
    
    set portrait_admin "
<li><a href=\"/intranet/users/portrait/upload?$export_vars\">[_ intranet-core.Upload_portrait]</a></li>
<li><a href=\"/intranet/users/portrait/erase?$export_vars\">[_ intranet-core.Delete_portrait]</a></li>\n"

    if {$portrait_p} {
	append portrait_admin "
<li><a href=\"/intranet/users/portrait/comment-edit?$export_vars\">[_ intranet-core.lt_Edit_comments_about_y]</a></li>\n"
    }
    

    if {!$admin && !$write} { set portrait_admin "" }

    if {$admin && "" == $description} {
	set description "
[_ intranet-core.lt_No_comments_about_fir]<br>
[_ intranet-core.lt_Please_click_above_to]
"}

    set portrait_html "
<table border=0 cellspacing=1 cellpadding=1>
<tr valign=top>
  <td>
    $portrait_gif <br>
  </td>
  <td>
    $portrait_admin <br>
    <blockquote>$description</blockquote>
  </td>
</tr>
</table>
"

}

