# /packages/intranet-core/tcl/intranet-design.tcl
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
    Design related functions
    Code based on work from Bdoesborg@comeptitiveness.com

    @author unknown@arsdigita.com
    @author Frank Bergmann (fraber@fraber.de)
}



# --------------------------------------------------------
# HTML Components
# --------------------------------------------------------

ad_proc -public im_gif { name {alt ""} { border 0} {width 0} {height 0} } {
    Create an <IMG ...> tag to correctly render a range of GIFs
    frequently used by the Intranet
} {
    set url "/intranet/images"
    set navbar_gif_path [im_navbar_gif_path]
    switch [string tolower $name] {
	"delete" 	{ return "<img src=$url/delete.gif width=14 heigth=15 border=$border alt='$alt'>" }
	"help"		{ return "<img src=$url/help.gif width=16 height=16 border=$border alt='$alt'>" }
	"category"	{ return "<img src=$url/help.gif width=16 height=16 border=$border alt='$alt'>" }
	"new"		{ return "<img src=$url/new.gif width=13 height=15 border=$border alt='$alt'>" }
	"open"		{ return "<img src=$url/open.gif width=16 height=15 border=$border alt='$alt'>" }
	"save"		{ return "<img src=$url/save.gif width=14 height=15 border=$border alt='$alt'>" }
	"incident"	{ return "<img src=$url/incident.gif width=20 height=20 border=$border alt='$alt'>" }
	"1102"		{ return "<img src=$url/incident.gif width=20 height=20 border=$border alt='$alt'>" }
	"discussion"	{ return "<img src=$url/discussion.gif width=20 height=20 border=$border alt='$alt'>" }
	"1106"		{ return "<img src=$url/discussion.gif width=20 height=20 border=$border alt='$alt'>" }
	"task"		{ return "<img src=$url/task.gif width=24 height=20 border=$border alt='$alt'>" }
	"1104"		{ return "<img src=$url/task.gif width=24 height=20 border=$border alt='$alt'>" }
	"news"		{ return "<img src=$url/news.gif width=20 height=20 border=$border alt='$alt'>" }
	"1100"		{ return "<img src=$url/task.gif width=24 height=20 border=$border alt='$alt'>" }
	"note"		{ return "<img src=$url/note.gif width=20 height=20 border=$border alt='$alt'>" }
	"1108"		{ return "<img src=$url/note.gif width=20 height=20 border=$border alt='$alt'>" }
	"reply"		{ return "<img src=$url/reply.gif width=22 height=20 border=$border alt='$alt'>" }
	"1190"		{ return "<img src=$url/reply.gif width=22 height=20 border=$border alt='$alt'>" }
	"tick"		{ return "<img src=$url/tick.gif width=14 heigth=15 border=$border alt='$alt'>" }
	"wrong"		{ return "<img src=$url/delete.gif width=14 heigth=15 border=$border alt='$alt'>" }
	"turn"		{ return "<img src=$url/turn.gif widht=15 height=15 border=$border alt='$alt'>" }
	"exp-folder"	{ return "<img src=$url/exp-folder.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"exp-minus"	{ return "<img src=$url/exp-minus.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"exp-unknown"	{ return "<img src=$url/exp-unknown.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"exp-line"	{ return "<img src=$url/exp-line.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"profile"	{ return "<img src=$url/discussion.gif width=20 height=20 border=$border alt='$alt'>" }
	"member"	{ return "<img src=$url/m.gif width=19 heigth=13 border=$border alt='$alt'>" }
	"key-account"	{ return "<img src=$url/k.gif width=18 heigth=13 border=$border alt='$alt'>" }
	"project-manager" { return "<img src=$url/p.gif width=17 heigth=13 border=$border alt='$alt'>" }

	"left-sel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"left-notsel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"right-sel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"right-notsel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"middle-sel-notsel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"middle-notsel-sel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"middle-sel-sel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }
	"middle-notsel-notsel"	{ return "<img src=$navbar_gif_path/$name.gif width=19 heigth=19 border=$border alt='$alt'>" }

	default		{ 
	    set result "<img src=\"$url/$name.gif\" border=$border "
	    if {$width > 0} { append result "width=$width " }
	    if {$height > 0} { append result "height=$height " }
	    append result "alt=\"$alt\">"
	    return $result
	}
    }
}


ad_proc -public im_admin_category_gif { category_type } {
    Returns a HTML widget with a link to the category administration
    page for the respective category_type if the user is Admin
    or "" otherwise.
} {
    set html ""
    set user_id [ad_maybe_redirect_for_registration]
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {$user_admin_p} {
        set html "
<A HREF=/intranet/admin/categories/?select_category_type=[ns_urlencode $category_type]>[im_gif new "Admin $category_type"]</A>"
    }
    return $html
}


ad_proc -public im_gif_cleardot { {width 1} {height 1} {alt ""} } {
    Creates an &lt;IMG ... &gt; tag of a given size
} {
    set url "/intranet/images"
    return "<img src=$url/cleardot.gif width=$width height=$height alt=\"$alt\">"
}


ad_proc -public im_return_template {} {
    Wrapper that adds page contents to header and footer<p>
    040221 fraber: Should not be called anymore - should
    be replaced by .adp files containing the same calls...
} {
    uplevel { 

	return "  
[im_header]
[im_navbar]
[value_if_exists page_body]
[value_if_exists page_content]
[im_footer]\n"
    }
}

ad_proc -public im_tablex {{content "no content?"} {pad "0"} {col ""} {spa "0"} {bor "0"} {wid "100%"}} {
    Make a quick table
} {

    return "
    <table cellpadding=$pad cellspacing=$spa border=$bor bgcolor=$col width=$wid>
    <tr>
    <td>
    $content
    </td>
    </tr>
    </table>"
    
}


ad_proc -public im_table_with_title { title body } {
    Returns a two row table with background colors
} {
    return "
<table cellpadding=5 cellspacing=0 border=0 width='100%'>
 <tr>
  <td class=tableheader>$title</td>
 </tr>
 <tr>
  <td class=tablebody><font size=-1>$body</font></td>
 </tr>
</table><br>
"
}


# --------------------------------------------------------
# Navigation Bars
# --------------------------------------------------------

ad_proc -public im_user_navbar { default_letter base_url next_page_url prev_page_url export_var_list } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/users/.
    The lower part of the navbar also includes an Alpha bar.<br>
    Default_letter==none marks a special behavious, printing no alpha-bar.
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
    set url_stub [ns_urldecode [im_url_with_query]]
    ns_log Notice "im_user_navbar: url_stub=$url_stub"

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_user_navbar: $var <- $value"
        }
    }
    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]
    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    if {![string equal "" $prev_page_url]} {
	set alpha_bar "<A HREF=$prev_page_url>&lt;&lt;</A>\n$alpha_bar"
    }
  
    if {![string equal "" $next_page_url]} {
	set alpha_bar "$alpha_bar\n<A HREF=$next_page_url>&gt;&gt;</A>\n"
    }

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where name='Users'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql]
    set navbar [im_sub_navbar $parent_menu_id "" $alpha_bar "tabnotsel"]

    return $navbar
}

ad_proc -public im_project_navbar { default_letter base_url next_page_url prev_page_url export_var_list} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
#    set url_stub [ns_conn url]
    set url_stub [ns_urldecode [im_url_with_query]]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_project_navbar: $var <- $value"
        }
    }
    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]
    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }

    # -------- Compile the list of menus -------
    set parent_menu_sql "select menu_id from im_menus where name='Projects'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql]
    set menu_select_sql "
	select	m.*
	from	im_menus m
	where	parent_menu_id = :parent_menu_id
		and acs_permission.permission_p(m.menu_id, :user_id, 'read') = 't'
	order by sort_order"

    # make sure at most one field gets selected..
    set navbar ""
    set found_selected 0
    db_foreach menu_select $menu_select_sql {
        set html "$nosel\n<a href=\"$url\">$name</a>\n</td>\n"
        if {!$found_selected && [string equal $url_stub $url]} {
            set html "$sel\n$a_white href=\"$url\"/>$name</a>\n</td>\n"
            set found_selected 1
        }
        append navbar "$tdsp\n$html"
    }

    set navbar_html "
      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR>
          <TD align=right>
            <table border=0 cellspacing=0 cellpadding=1>
              <tr>
$navbar
              </tr>
            </table>
          </TD>
        </TR>
        <TR>
          <td colspan=6 class=tabnotsel align=center>\n"

if {![string equal "" $prev_page_url]} {
    append navbar_html "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}

append navbar_html $alpha_bar

if {![string equal "" $next_page_url]} {
    append navbar_html "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}

append navbar_html "
          </td>
        </tr>
      </table>\n"

    return $navbar_html
}


ad_proc -public im_office_navbar { default_letter base_url next_page_url prev_page_url export_var_list } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/offices/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.

} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_office_navbar: $var <- $value"
        }
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{office%5flist} { set section "Standard" }
	default {
	    set section "Standard"
	}
    }

    ns_log Notice "url_stub=$url_stub"
    ns_log Notice "section=$section"

    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]

    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set standard "$tdsp$nosel<a href='index?view_name=project_list'>Standard</a></td>"
    set status "$tdsp$nosel<a href='index?view_name=project_status'>Status</a></td>"
    set costs "$tdsp$nosel<a href='index?view_name=project_costs'>Costs</a></td>"

    switch $section {
"Standard" {set standard "$tdsp$sel Standard</td>"}
default {
    # Nothing - just let all sections deselected
}
    }

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
        <tr> 
          $standard"
if {[im_permission $user_id add_offices]} {
    append navbar "$tdsp$nosel<a href=new>[im_gif new "Add a new office"]</a></td>"
}
append navbar "
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>"
if {![string equal "" $prev_page_url]} {
    append navbar "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}
append navbar $alpha_bar
if {![string equal "" $next_page_url]} {
    append navbar "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}
append navbar "
    </td>
  </tr>
</table>
"
    return $navbar
}



ad_proc -public im_customer_navbar { default_letter base_url next_page_url prev_page_url export_var_list } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.

} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_customer_navbar: $var <- $value"
        }
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{project%5flist} { set section "Standard" }
	{project%5fstatus} { set section "Status" }
	{project%5fcosts} { set section "Costs" }
	{index$} { set section "Standard" }
	{/intranet/projects/$} { set section "Standard" }
	default {
	    set section "Standard"
	}
    }

    ns_log Notice "url_stub=$url_stub"
    ns_log Notice "section=$section"

    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]

    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set standard "$tdsp$nosel<a href='index?view_name=project_list'>Standard</a></td>"
    set status "$tdsp$nosel<a href='index?view_name=project_status'>Status</a></td>"
    set costs "$tdsp$nosel<a href='index?view_name=project_costs'>Costs</a></td>"

    switch $section {
	"Standard" {set standard "$tdsp$sel Standard</td>"}
	"Status" {set status "$tdsp$sel Status</td>"}
	"Costs" {set costs "$tdsp$sel Costs</td>"}
	default {
	    # Nothing - just let all sections deselected
	}
    }

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
        <tr> 
          $standard"
# if {[im_permission $user_id view_hours]} { append navbar $status }
# if {[im_permission $user_id view_finance]} { append navbar $costs }
if {[im_permission $user_id add_customers]} {
    append navbar "$tdsp$nosel<a href=new>[im_gif new "Add a new customer"]</a></td>"
}
append navbar "
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>"
if {![string equal "" $prev_page_url]} {
    append navbar "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}
append navbar $alpha_bar
if {![string equal "" $next_page_url]} {
    append navbar "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}
append navbar "
    </td>
  </tr>
</table>
"
    return $navbar
}



ad_proc -public im_admin_navbar { } {
    Setup a sub-navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
    # select the administration menu items
    set parent_menu_sql "select menu_id from im_menus where name='Admin'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql]

    return [im_sub_navbar $parent_menu_id]
}



ad_proc -public im_sub_navbar { parent_menu_id {bind_vars ""} {title ""} {title_class "pagedesriptionbar"} } {
    Setup a sub-navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
    @param parent_menu_id id of the parent menu in im_menus
    @param bind_vars a list of variables to pass-through
    @title string to go into the line below the menu tabs
    @title_class CSS class of the title line
} {
    set user_id [ad_get_user_id]
    set url_stub [ns_conn url]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set menu_select_sql "
	select	m.*
	from	im_menus m
	where	parent_menu_id = :parent_menu_id
		and acs_permission.permission_p(m.menu_id, :user_id, 'read') = 't'
	order by sort_order"

    # Start formatting the menu bar
    set navbar ""
    set found_selected 0
    set selected 0
    set old_sel "notsel"
    set cur_sel "notsel"
    set ctr 0
    db_foreach menu_select $menu_select_sql {

	ns_log Notice "im_sub_navbar: menu_name='$name'"
	# Construct the URL
	if {"" != $bind_vars && [ns_set size $bind_vars] > 0} {
	    for {set i 0} {$i<[ns_set size $bind_vars]} {incr i} {
		append url "&[ns_set key $bind_vars $i]=[ns_urlencode [ns_set value $bind_vars $i]]"
	    }
	}

        # Shift the old value of cur_sel to old_val
        set old_sel $cur_sel
        set cur_sel "notsel"

        # Find out if we need to highligh the current menu item
        set selected 0
        set url_length [expr [string length $url] - 1]
        set url_stub_chopped [string range $url_stub 0 $url_length]
        if {!$found_selected && [string equal $url_stub $url]} {
            # Make sure we only highligh one menu item..
            set found_selected 1
            # Set for the gif
            set cur_sel "sel"
            # Set for the other IF-clause later in this loop
            set selected 1
        }

        if {$ctr == 0} {
            set gif "left-$cur_sel"
        } else {
            set gif "middle-$old_sel-$cur_sel"
        }

        if {$selected} {
            set html "$sel$a_white href=\"$url\"/>$name</a></td>\n"
        } else {
            set html "$nosel<a href=\"$url\">$name</a></td>\n"
        }

        append navbar "<td>[im_gif $gif]</td>$html"
        incr ctr
    }
    append navbar "<td>[im_gif "right-$cur_sel"]</td>"

    return "
      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR>
          <TD align=right>
            <table border=0 cellspacing=0 cellpadding=0>
              <tr height=19>
                $navbar
              </tr>
            </table>
          </TD>
          <TD align=right>
          </TD>
        </TR>
        <TR>
          <td colspan=2 class=$title_class>
            <table cellpadding=1 width='100%'>
              <tr>
                <td class=$title_class align=center valign=middle>
		    $title
                </td>
              </tr>
            </table>
          </td>
        </TR>
      </table>\n"
}


ad_proc -public im_navbar { } {
    Setup a top navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
    set user_id [ad_get_user_id]
    set url_stub [ns_conn url]

    set context_bar [ad_partner_upvar context_bar]
    set page_title [ad_partner_upvar page_title]
    set section [ad_partner_upvar section]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"

    set navbar ""
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label='main'" -default 0]

    # select the toplevel menu items
    set menu_select_sql "
select
        m.*
from
        im_menus m
where
        parent_menu_id = :main_menu_id
	and acs_permission.permission_p(m.menu_id, :user_id, 'read') = 't'
order by
        sort_order
"

    # make sure only one field gets selected so...
    # .. check for the first complete match between menu and url.
    set ctr 0
    set selected 0
    set found_selected 0
    set old_sel "notsel"
    set cur_sel "notsel"
    db_foreach menu_select $menu_select_sql {

	# Shift the old value of cur_sel to old_val
	set old_sel $cur_sel
	set cur_sel "notsel"

	# Find out if we need to highligh the current menu item
	set selected 0
	set url_length [expr [string length $url] - 1]
	set url_stub_chopped [string range $url_stub 0 $url_length]
        if {!$found_selected && [string equal $url_stub_chopped $url]} {
	    # Make sure we only highligh one menu item..
            set found_selected 1
	    # Set for the gif
	    set cur_sel "sel"
	    # Set for the other IF-clause later in this loop
	    set selected 1
        }

	if {$ctr == 0} { 
	    set gif "left-$cur_sel" 
	} else {
	    set gif "middle-$old_sel-$cur_sel" 
	}

        if {$selected} {
            set html "$sel$a_white href=\"$url\"/>$name</a></td>\n"
        } else {
	    set html "$nosel<a href=\"$url\">$name</a></td>\n"
	}

        append navbar "<td>[im_gif $gif]</td>$html"
	incr ctr
    }
    if {"" != $navbar} {
	append navbar "<td>[im_gif "right-$cur_sel"]</td>"
    }


    return "
      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR>
          <TD align=left>
            <table border=0 cellspacing=0 cellpadding=0>
              <tr height=19>
                $navbar
              </tr>
            </table>
          </TD>
          <TD align=right>
            $context_bar
          </TD>
        </TR>
        <TR>
          <td colspan=2 class=pagedesriptionbar>
            <table cellpadding=1 width='100%'>
              <tr>
                <td class=pagedesriptionbar valign=middle>
                  $page_title
                </td>
              </tr>
            </table>
          </td>
        </TR>
      </table>\n"
}


ad_proc -public im_header { { page_title "" } { extra_stuff_for_document_head "" } } {
    The default header for Project/Open
} {
    set user_id [ad_get_user_id]
    set user_name [im_get_user_name $user_id]
    if { [empty_string_p $page_title] } {
	set page_title [ad_partner_upvar page_title]
    }
    set context_bar [ad_partner_upvar context_bar]
    set page_focus [ad_partner_upvar page_focus]
    if { [empty_string_p $extra_stuff_for_document_head] } {
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    }

    set search_form ""
    if {[ad_user_group_member [im_employee_group_id] $user_id]} {
	set search_form "
	    <form action=/intranet/search/go-search method=post name=surx>
              <input class=surx name=query_string size=15 value=Search>
              <select class=surx name=target>"
	if {[im_permission $user_id "search_intranet"]} {
	    append search_form "
                <option class=surx selected value=content>Intranet content</option>
                <option class=surx value=users>Intranet users</option>
                <option class=surx value=htsearch>All documents in H:</option>"
	}
	append search_form "
                <option class=surx value=google>The web with Google</option>
              </select>
              <input alt=go type=submit value=go name='image'>
            </form>
"
    }

    # Determine a pretty string for the type of user that it is:
    set user_profile "User"
    if {[im_permission $user_id "freelance"]} {
	set user_profile "Freelance"
    }
    if {[im_permission $user_id "client"]} {
	set user_profile "Client"
    }
    if {[im_permission $user_id "employee"]} {
	set user_profile "Employee"
    }
    if {[ad_user_group_member [im_admin_group_id] $user_id]} {
	set user_profile "Admin"
    }
    if {[im_site_wide_admin_p $user_id]} {
	set user_profile "SiteAdmin"
    }

    append extra_stuff_for_document_head [im_stylesheet]
    set change_pwd_url "/intranet/users/password-update?user_id=$user_id"

    # Enable "Users Online" mini-component
    set users_online_str ""
    if {[publish::proc_exists whos_online num_users]} {
	set num_users_online [lc_numeric [whos_online::num_users]]
	set num_users_online 0
	set user_str "users"
	if {1 == $num_users_online} { set user_str "user"}
        set users_online_str "<A href=/intranet/whos-online>$num_users_online $user_str online</A><BR>\n"
    }

    return "
[ad_header $page_title $extra_stuff_for_document_head]
<table border=0 cellspacing=0 cellpadding=0 width='100%'>
  <tr>
    <td> 
    [im_logo]
    </td>
    <td align=left valign=middle> 
      <span class=small>
        $users_online_str
        $user_profile: $user_name <BR>
        <a href='/register/logout'>Log Out</a> |
        <a href=$change_pwd_url>Change Password</a> 
      </span>
    </td>
    <td valign=middle align=right> $search_form </TD>
  </tr>
</table>
"
}


ad_proc -public im_header_emergency { page_title } {
    A header to display for error pages that do not have access to the DB
    Only the parameter file is available by default.
} {
    set html "
	<html>
	<head>
	  <title>$page_title</title>
          [im_stylesheet]
	</head>
	<body bgcolor=white text=black>
	<table>
	  <tr>
	    <td> 
	      <a href='index.html'>[im_logo]</a> 
	    </td>
	  </tr>
	</table>

      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR> 
          <TD align=left> 
            <table border=0 cellspacing=0 cellpadding=3>
              <tr> 
                <td class=tabnotsel><a href=/intranet/>Home</a></td><td>&nbsp;</td>
	        <td>&nbsp;</td>
	      </tr>

            </table>
          </TD>
          <TD align=right> 
          </TD>
        </TR>
        <TR>
          <td colspan=2 class=pagedesriptionbar>
            <table cellpadding=1 width='100%'>
              <tr>
                <td class=pagedesriptionbar valign=middle> 
	           $page_title
                </td>
              </tr>
            </table>
          </td>
        </TR>
      </table>\n"
    return $html
}



ad_proc -public im_footer {} {
    Default Project/Open footer.
} {
    return "
      <TABLE border=0 cellPadding=5 cellSpacing=0 width='100%'>
        <TBODY> 
          <TR>
            <TD>Comments? Contact: 
          <A href='mailto:[ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]'>
          [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]
          </A> 
           </TD>
        </TR>
      </TBODY>
    </TABLE>
  </BODY>
</HTML>
"
}


ad_proc -public im_stylesheet {} {
    Intranet CSS style sheet. 
} {
    set system_css [ad_parameter -package_id [im_package_core_id] SystemCSS "" "/intranet/style/style.default.css"]
    return "<link rel=StyleSheet href=\"$system_css\" type=text/css media=screen>\n"
}


ad_proc -public im_logo {} {
    Intranet System Logo
} {
    set system_logo [ad_parameter -package_id [im_package_core_id] SystemLogo "" "/intranet/images/projop-logo.gif"]
    return "<img src=$system_logo>"
}


ad_proc -public im_navbar_gif_path {} {
    Path to access the Navigation Bar corner GIFs
} {
    set navbar_gif_path [ad_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "/intranet/images/navbar_default"]
    return $navbar_gif_path
}



ad_proc im_all_letters { } {
    returns a list of all A-Z letters in uppercase
} {
    return [list A B C D E F G H I J K L M N O P Q R S T U V W X Y Z] 
}

ad_proc im_all_letters_lowercase { } {
    returns a list of all A-Z letters in uppercase
} {
    return [list a b c d e f g h i j k l m n o p q r s t u v w x y z] 
}

ad_proc im_employees_alpha_bar { { letter "" } { vars_to_ignore "" } } {
    Returns the alpha bar for employees.
} {
    return [im_alpha_nav_bar $letter [im_employees_initial_list] $vars_to_ignore]
}

ad_proc im_groups_alpha_bar { parent_group_id { letter "" } { vars_to_ignore "" } } {
    Returns the alpha bar for user_groups whose parent group is as
    specified.  
} {
    return [im_alpha_nav_bar $letter [im_groups_initial_list $parent_group_id] $vars_to_ignore]
}

ad_proc im_alpha_nav_bar { letter initial_list {vars_to_ignore ""} } {
    Returns an A-Z bar with greyed out letters not
    in initial_list and bolds "letter". Note that this proc returns the
    empty string if there are fewer than NumberResultsPerPage records.
    
    inital_list is a list where the ith element is a letter and the i+1st
    letter is the number of times that letter appears.  
} {

    set min_records [ad_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
    # Let's run through and make sure we have enough records
    set num_records 0
    foreach { l count } $initial_list {
	incr num_records $count
    }
    if { $num_records < $min_records } {
	return ""
    }

    set url "[ns_conn url]?"
    set vars_to_ignore_list [list "letter"]
    foreach v $vars_to_ignore { 
	lappend vars_to_ignore_list $v
    }

    set query_args [export_ns_set_vars url $vars_to_ignore_list]
    if { ![empty_string_p $query_args] } {
	append url "$query_args&"
    }
    
    set html_list [list]
    foreach l [im_all_letters_lowercase] {
	if { [lsearch -exact $initial_list $l] == -1 } {
	    # This means no user has this initial
	    lappend html_list "<font color=gray>$l</font>"
	} elseif { [string compare $l $letter] == 0 } {
	    lappend html_list "<b>$l</b>"
	} else {
	    lappend html_list "<a href=${url}letter=$l>$l</a>"
	}
    }
    if { [empty_string_p $letter] || [string compare $letter "all"] == 0 } {
	lappend html_list "<b>All</b>"
    } else {
	lappend html_list "<a href=${url}letter=all>All</a>"
    }
    if { [string compare $letter "scroll"] == 0 } {
	lappend html_list "<b>Scroll</b>"
    } else {
	lappend html_list "<a href=${url}letter=scroll>Scroll</a>"
    }
    return [join $html_list " | "]
}

ad_proc im_alpha_bar { target_url default_letter bind_vars} {
    Returns a horizontal alpha bar with links
} {
    set alpha_list [im_all_letters_lowercase]
    set alpha_list [linsert $alpha_list 0 All]
    set default_letter [string tolower $default_letter]

    ns_set delkey $bind_vars "letter"
    set params [list]
    set len [ns_set size $bind_vars]
    for {set i 0} {$i < $len} {incr i} {
	set key [ns_set key $bind_vars $i]
	set value [ns_set value $bind_vars $i]
	if {![string equal $value ""]} {
	    lappend params "$key=[ns_urlencode $value]"
	}
    }
    set param_html [join $params "&"]

    set html "&nbsp;"
    foreach letter $alpha_list {
	if {[string equal $letter $default_letter]} {
	    append html "<font color=white>$letter</font> &nbsp; \n"
	} else {
	    set url "$target_url?letter=$letter&$param_html"
	    append html "<A HREF=$url>$letter</A>&nbsp;\n"
	}
    }
    append html ""
    return $html
}


ad_proc -public im_render_user_id { user_id user_name current_user_id group_id } {
    Return a formatted pice of HTML showing a username according
    to the permissions of the current user.
} {
    if {$current_user_id == ""} { set current_user_id [ad_get_user_id] }

    # How to display? -1=name only, 0=none, 1=Link
    set show_user_style [im_show_user_style $user_id $current_user_id $group_id]
    ns_log Notice "im_render_user_id: user_id=$user_id, show_user_style=$show_user_style"

    if {$show_user_style==-1} {
	return $user_name
    }
    if {$show_user_style==1} {
	return "<A HREF=/intranet/users/view?user_id=$user_id>$user_name</A>"
    }
    return ""
}

ad_proc -public im_show_user_style {group_member_id current_user_id object_id} {
    Determine whether the current_user should be able to see
    the group member.
    Returns 1 the name can be shown with a link,
    Returns -1 if the name should be shown without link and
    Returns 0 if the name should not be shown at all.
} {
    # Show the user itself with a link.
    if {$current_user_id == $group_member_id} { return 1}

    # Get the permissions for this user
    im_user_permissions $current_user_id $group_member_id view read write admin

    # Project Managers/admins can read the name of all users in their
    # projects...
    if {[im_biz_object_admin_p $current_user_id $object_id]} {
	set view 1
    }

    if {$read} { return 1 }
    if {$view} { return -1 }
    return 0
}


ad_proc im_report_error { message } {
    Writes an error to the connection, allowing the user to report the error.
    This procedure replaces rp_report_error from the request processor.
    @param message The message to write (pulled from <code>$errorInfo</code> if none is specified).
} {
    set error_url [ad_conn url]
    set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
    set publisher_name [ad_parameter -package_id [ad_acs_kernel_id] PublisherName "" ""]
    set core_version "2.0"
    set error_user_id [ad_get_user_id]
    set error_first_names ""
    set error_last_name ""
    set error_user_email ""
    
    catch {
        db_1row get_user_info "
select
	pe.first_names as error_first_names,
        pe.last_name as error_last_name,
        pa.email as error_user_email
from
	persons pe,
	parties pa
where
	pe.person_id = :error_user_id
	and pa.party_id = pe.person_id
"
    } catch_err

    set report_url [ad_parameter -package_id [im_package_core_id] "ErrorReportURL" "" ""]
    if { [empty_string_p $report_url] } {
	ns_log Error "Automatic Error Reporting Misconfigured.  Please add a field in the acs/rp section of form ErrorReportURL=http://your.errors/here."
	set report_url "http://www.projop.com/intranet-forum/forum/new-system-incident"
    } 

    set error_info ""
    if {![ad_parameter -package_id [ad_acs_kernel_id] "RestrictErrorsToAdminsP" "" 0] || [permission::permission_p -object_id [ad_conn package_id] -privilege admin] } {
	set error_info $message
    }
    
    ns_returnerror 500 "
[im_header_emergency "Request Error"]
<form method=post action=$report_url>
[export_form_vars error_url error_info error_first_names error_last_name error_user_email system_url publisher_name core_version]
This file has generated an error.  
<input type=submit value='Report this error' />
</form>
<hr />
<blockquote><pre>[ns_quotehtml $error_info]</pre></blockquote>
[im_footer]"
}


