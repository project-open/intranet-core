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

ad_proc -public im_portrait_user_file { user_id } {
    Return the user's portrait file
} {
    # Get the current user id to not show the current user's portrait
    set base_path [im_filestorage_user_path $user_id]
    set base_paths [split $base_path "/"]
    set base_paths_len [llength $base_paths]

    set find_cmd [im_filestorage_find_cmd]

    if { [catch {
        ns_log Notice "im_portrait_user_file: Checking $base_path"
        exec /bin/mkdir -p $base_path
        exec /bin/chmod ug+w $base_path
        set file_list [exec $find_cmd "$base_path/" -maxdepth 1 -type f]
    } err_msg] } {
        # Probably some permission errors - return empty string
        set file_list ""
    }

    set files [lsort [split $file_list "\n"]]
    set full ""
    foreach file $files {
        set file_paths [split $file "/"]
        set file_paths_len [llength $file_paths]
        set rel_path_list [lrange $file_paths $base_paths_len $file_paths_len]
        set rel_path [join $rel_path_list "/"]
	ns_log Notice "im_portrait_user_file: rel_path=$rel_path"
        if {[regexp "^portrait\....\$" $rel_path match]} { set full $rel_path}
    }

    return $full
}


ad_proc -public im_random_employee_component { } {
    Returns a random employee's photograph and a little bio
} {
    return ""

    # Get the current user id to not show the current user's portrait
    set current_user_id [ad_get_user_id]
    set subsite_url [subsite::get_element -element url]
    set export_vars [export_url_vars user_id return_url]


    # --------------------------------------------------------
    # Get the list of "old" Content Repository Portraits
    set portrait_sql "
        select
                live_revision as revision_id,
                a.object_id_one as portrait_user_id,
                item_id,
                m.group_id
        from
                acs_rels a,
                cr_items c,
                im_profiles p,
                group_distinct_member_map m,
                cc_users u
        where
                a.object_id_two = c.item_id
                and a.object_id_one = u.user_id
                and u.member_state = 'approved'
                and a.rel_type = 'user_portrait_rel'
                and m.member_id = a.object_id_one
                and m.group_id = p.profile_id
		and im_object_permission_p(m.group_id, :current_user_id, 'read') = 't'

    "

    db_foreach portrait_perms $portrait_sql {
	lappend asdf $portrait_user_id
    }



    # --------------------------------------------------------
    # Make sure that there are no users with checkdate==null
    set empty_portrait_sql "
	select	p.*,
		person_id as portrait_user_id
	from	persons p
	where	portrait_checkdate is null
	limit 10
    "
    db_foreach empty_portraits $empty_portrait_sql {
	set portrait_file [im_portrait_user_file $person_id]
	db_dml update_empty_portrait "
	    update persons set
		portrait_checkdate = now()::date,
		portrait_file = :portrait_file
	    where
		person_id = :portrait_user_id
	"
    }

    # --------------------------------------------------------
    # Get the list of all users that have a portrait 
    # AND that are within the permission skope of the
    # current user.
    # The SQL check the im_object_permissions_p of the users _group_
    # and checks whether the current user can "read" the members of
    # this group. The current user must be able to read _all_
    # groups of a member in order to get final read permission.
    set portrait_sql "
	select
		p.*,
		p.person_id as portrait_user_id,
		pr.profile_id as group_id
	from
		persons p,
		registered_users u,
		im_profiles pr,
	        group_distinct_member_map m
	where
		p.portrait_file is not null
		and m.member_id = u.user_id
		and p.person_id = u.user_id
		and m.group_id = pr.profile_id
		and im_object_permission_p(m.group_id, :current_user_id, 'read') = 't'
    "
    set user_list [list]
    db_foreach portrait_perms $portrait_sql {
	lappend user_list $portrait_user_id
    }

    # Skip if no users
    set user_list_len [llength $user_list]
    if {0 == $user_list_len} { return "" }

    # Select a random user from the list
    # Try 10 times and check whether the 
    set ctr 10
    set random_user_id 0
    set random_portrait_file ""
    while {$ctr && ("" == $random_portrait_file)} {
	set random_user_pos [randomRange $user_list_len]
	set random_user_id [lindex $user_list $random_user_pos]
	set random_portrait_file [db_string portrait "
		select portrait_file 
		from persons 
		where person_id = :random_user_id
	" -default ""]
	set ctr [expr $ctr-1]
    }

    db_1row user_info "
	select
		im_email_from_user_id(:random_user_id) as user_email,
		im_name_from_user_id (:random_user_id) as user_name
	from dual
    "

    set portrait_html [im_portrait_component $random_user_id "/intranet/" 1 0 0]
    set portrait_title [_ intranet-core.Learn_About_Your_Company] 
    set portrait_html "
	<table>
        <tr>
	  <td>Portrait of <a href=/intranet/users/view?user_id=$random_user_id>$user_name</a></td>
	</tr>
        <tr>
          <td>
            $portrait_html
          </td>
        </tr>
	<tr>
	  <td>
<!--
	    <b>[_ intranet-core.Learn_About_Your_Company]</b><br>
	    [_ intranet-core.Learn_About_Your_Company_Blurb]
-->
	  </td>
	</tr>
	</table>
    "
#    set portrait_html [im_table_with_title $portrait_title $portrait_html]
    return $portrait_html
}



ad_proc im_portrait_html { 
    user_id 
    {portrait_alt ""} 
} {
    Return html to display portrait of the user
} {
    return [util_memoize [list im_portrait_html_helper $user_id $portrait_alt] 3600]
}

ad_proc im_portrait_html_helper { 
    user_id 
    {portrait_alt ""} 
} {
    Return html to display portrait of the user
} {
    set user_fs_url "/intranet/download/user/$user_id"

    set portrait_gif ""

   # ------------ Check if there is a portrait in the FS --------
    set portrait_file [im_portrait_user_file $user_id]
    if {"" != $portrait_file} {
	set portrait_gif "<img  src=\"$user_fs_url/$portrait_file\" alt=\"$portrait_alt\" title=\"$portrait_alt\" >"
    }
    
    # ------------ Check if there is a portrait in the CR --------
    if {"" == $portrait_gif} {
	if {![db_0or1row get_cr_item ""] || [empty_string_p $revision_id]} {
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

	if {$portrait_p} {
	    if { ![empty_string_p $width] && ![empty_string_p $height] } {
		set widthheight "width=$width height=$height"
	    } else {
		set widthheight ""
	    }
    
	    set portrait_gif "<img $widthheight src=\"/shared/portrait-bits.tcl?user_id=$user_id\" alt=\"$portrait_alt\" title=\"$portrait_alt\" >"

	} 
    }


    return $portrait_gif
}

ad_proc im_portrait_or_anon_html { user_id portrait_alt } {

    # The portrait is used in the default navbar, 
    # but may fail if the "find" cmd doesn't exist
    set portrait_gif ""
    catch {
	set portrait_gif [im_portrait_html $user_id $portrait_alt]
	if {"" == $portrait_gif} {
	    set portrait_gif [im_gif anon_portrait $portrait_alt]
	}
    }
    
    return $portrait_gif
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

    set portrait_p 0
    set portrait_gif [im_portrait_html $user_id "Portrait"]
    set description ""

    if {"" == $portrait_gif} {
	set portrait_gif [im_gif anon_portrait "Portrait"]
	set description [lang::message::lookup "" intranet-core.No_portrait_for_this_user "No portrait for this user."]
	if {$admin} { append description "<br>\n[_ intranet-core.lt_Please_upload_a_portr]"}
    }
     
    # ------------ Frame and admin  --------
    set portrait_admin "<ul>
<li><a href=\"/intranet/users/portrait/upload?$export_vars\">[_ intranet-core.Upload_portrait]</a></li>
<li><a href=\"/intranet/users/portrait/erase?$export_vars\">[_ intranet-core.Delete_portrait]</a></li>
</ul>\n"

    if {!$admin && !$write} { set portrait_admin "" }

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

