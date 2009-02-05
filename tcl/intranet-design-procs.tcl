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
    @author Frank Bergmann (frank.bergmann@project-open.com)
}




# --------------------------------------------------------
# im_gif - Try to return the best matching GIF...
# --------------------------------------------------------

ad_proc -public im_gif { 
    {-translate_p 1} 
    {-type "gif"}
    name 
    {alt ""} 
    {border 0} 
    {width 0} 
    {height 0} 
} {
    Create an <IMG ...> tag to correctly render a range of GIFs
    frequently used by the Intranet.

    <ul>
    <li>First check if the name given corresponds to a group of
        special, hard coded GIFs
    <li>Then try first in the "navbar" folder
    <li>Finally try in the main "image" folder
    </ul>

    The algorithms "memoizes" the location of the GIF, so that 
    subsequent calls are faster. You'll need to restart the server
    if you change the pathes...
} {
    set debug 0
    if {$debug} { ns_log Notice "im_gif: name=$name" }

    set url "/intranet/images"
    set navbar_postfix [ad_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "navbar_default"]
    set navbar_gif_url "/intranet/images/[im_navbar_gif_url]"
    set base_path "[acs_root_dir]/packages/intranet-core/www/images/"
    set navbar_path "[acs_root_dir]/packages/intranet-core/www/images/[im_navbar_gif_url]"

    if { $translate_p && ![empty_string_p $alt] } {
	set alt_key "intranet-core.[lang::util::suggest_key $alt]"
        set alt [lang::message::lookup "" $alt_key $alt]
    }

    # 1. Check for a static GIF - it's been given without extension.
    set gif [im_gif_static $name $alt $url $navbar_path $navbar_gif_url $border $width $height]
    if {"" != $gif} { 
	if {$debug} { ns_log Notice "im_gif: static: $name" }
	return $gif 
    }

    # 2. Check in the "navbar" path to see if the navbar specifies a GIF
    set gif [im_gif_navbar $name $alt $url $navbar_path $navbar_gif_url $border $width $height]
    if {"" != $gif} { 
	if {$debug} { ns_log Notice "im_gif: navbar: $name" }
	return $gif 
    }

    # 3. Check if the FamFamFam gif exists
    set png_path "[acs_root_dir]/packages/intranet-core/www/images/$navbar_postfix/$name.png"
    set png_url "/intranet/images/$navbar_postfix/$name.png"
    if {[util_memoize "file exists $png_path"]} {
	if {$debug} { ns_log Notice "im_gif: famfamfam: $name" }
	set result "<img src=\"$png_url\" border=$border "
	if {$width > 0} { append result "width=$width " }
	if {$height > 0} { append result "height=$height " }
	append result "title=\"$alt\" alt=\"$alt\">"
	return $result
    }

    # 4. Default - check for GIF in /images
    set gif_path "[acs_root_dir]/packages/intranet-core/www/images/$name.gif"
    set gif_url "/intranet/images/$name.gif"
    if {[util_memoize "file exists $gif_path"]} {
	if {$debug} { ns_log Notice "im_gif: images_main: $name" }
	set result "<img src=\"$gif_url\" border=$border "
	if {$width > 0} { append result "width=$width " }
	if {$height > 0} { append result "height=$height " }
	append result "title=\"$alt\" alt=\"$alt\">"
	return $result
    }


    if {$debug} { ns_log Notice "im_gif: not_found: $name" }

    set result "<img src=\"$navbar_postfix/$name.$type\" border=$border "
    if {$width > 0} { append result "width=$width " }
    if {$height > 0} { append result "height=$height " }
    append result "title=\"$alt\" alt=\"$alt\">"
    return $result
}



ad_proc -public im_gif_navbar { 
    name 
    alt
    url 
    navbar_path 
    navbar_gif_url 
    {border 0} 
    {width 0} 
    {height 0} 
} {
    Part of im_gif. Checks whether the gif is available in 
    the navbar path, either as a GIF or a PNG.
} {
    set gif_file "$navbar_path/${name}.gif"
    set gif_exists_p [util_memoize "file readable $gif_file"]

    set png_file "$navbar_path/${name}.png"
    set png_exists_p [util_memoize "file readable $png_file"]

    if {$gif_exists_p} { 
	return "<img src=$navbar_gif_url/$name.gif border=0 title=\"$alt\" alt=\"$alt\">" 
    }

    if {$png_exists_p} { 
	return "<img src=$navbar_gif_url/$name.png border=0 title=\"$alt\" alt=\"$alt\">" 
    }
    
    return ""
}


ad_proc -public im_gif_static { 
    name 
    alt
    url 
    navbar_path
    navbar_gif_url 
    {border 0} 
    {width 0} 
    {height 0} 
} {
    Part of im_gif. Checks whether the gif is a hard-coded
    special GIF. Returns an empty string if GIF not found.
} {
    set debug 0
    if {$debug} { ns_log Notice "im_gif_static: name=$name, navbar_gif_url=$navbar_gif_url, navbar_path=$navbar_path" }
    switch [string tolower $name] {
	"delete" 	{ return "<img src=$url/delete.gif width=14 heigth=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"help"		{ return "<img src=$url/help.gif width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"category"	{ return "<img src=$url/help.gif width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"new"		{ return "<img src=$url/new.gif width=13 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"open"		{ return "<img src=$url/open.gif width=16 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"save"		{ return "<img src=$url/save.gif width=14 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"incident"	{ return "<img src=$navbar_gif_url/lightning.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"discussion"	{ return "<img src=$navbar_gif_url/group.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"task"		{ return "<img src=$navbar_gif_url/tick.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"news"		{ return "<img src=$navbar_gif_url/exclamation.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"note"		{ return "<img src=$navbar_gif_url/pencil.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"reply"		{ return "<img src=$navbar_gif_url/arrow_rotate_clockwise.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"tick"		{ return "<img src=$url/tick.gif width=14 heigth=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"wrong"		{ return "<img src=$url/delete.gif width=14 heigth=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"turn"		{ return "<img src=$url/turn.gif widht=15 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"tool"		{ return "<img src=$url/tool.15.gif widht=20 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-folder"	{ return "<img src=$url/exp-folder.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-minus"	{ return "<img src=$url/exp-minus.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-unknown"	{ return "<img src=$url/exp-unknown.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-line"	{ return "<img src=$url/exp-line.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-excel"	{ return "<img src=$url/$name.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-word"	{ return "<img src=$url/$name.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-text"	{ return "<img src=$url/$name.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-pdf"	{ return "<img src=$url/$name.gif width=19 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"profile"	{ return "<img src=$navbar_gif_url/user.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"member"	{ return "<img src=$url/m.gif width=19 heigth=13 border=$border title=\"$alt\" alt=\"$alt\">" }
	"key-account"	{ return "<img src=$url/k.gif width=18 heigth=13 border=$border title=\"$alt\" alt=\"$alt\">" }
	"project-manager" { return "<img src=$url/p.gif width=17 heigth=13 border=$border title=\"$alt\" alt=\"$alt\">" }

	"anon_portrait" { return "<img width=98 height=98 src=$url/anon_portrait.gif border=$border title=\"$alt\" alt=\"$alt\">" }

	"left-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"left-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"right-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"right-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-sel-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-notsel-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-sel-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-notsel-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }

	"admin"		{ return "<img src=$navbar_gif_url/tux.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"customer"	{ return "<img src=$navbar_gif_url/coins.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"employee"	{ return "<img src=$navbar_gif_url/user_orange.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"freelance"	{ return "<img src=$navbar_gif_url/time.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"freelance"	{ return "<img src=$navbar_gif_url/time.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"senman"	{ return "<img src=$navbar_gif_url/user_suit.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"proman"	{ return "<img src=$navbar_gif_url/user_comment.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"accounting"	{ return "<img src=$navbar_gif_url/money_dollar.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"sales"		{ return "<img src=$navbar_gif_url/telephone.png width=19 heigth=19 border=$border title=\"$alt\" alt=\"$alt\">" }

	"bb_clear"	{ return "<img src=$url/$name.gif width=$width heigth=$height border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_red"	{ return "<img src=$url/$name.gif width=$width heigth=$height border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_blue"	{ return "<img src=$url/$name.gif width=$width heigth=$height border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_yellow"	{ return "<img src=$url/$name.gif width=$width heigth=$height border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_purple"	{ return "<img src=$url/$name.gif width=$width heigth=$height border=$border title=\"$alt\" alt=\"$alt\">" }


	"comp_add"	{ return "<img src=$navbar_gif_url/comp_add.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_left" { return "<img src=$navbar_gif_url/$name.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_right" { return "<img src=$navbar_gif_url/$name.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_up"	{ return "<img src=$navbar_gif_url/$name.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_down" { return "<img src=$navbar_gif_url/$name.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_minimize"	{ return "<img src=$navbar_gif_url/$name.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_maximize"	{ return "<img src=$navbar_gif_url/$name.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"comp_delete"	{ return "<img src=$navbar_gif_url/comp_delete.png width=16 heigth=16 border=$border title=\"$alt\" alt=\"$alt\">" }

	default		{ return "" }
    }
}



# --------------------------------------------------------
# HTML Components
# --------------------------------------------------------

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
<A HREF=/intranet/admin/categories/?select_category_type=[ns_urlencode $category_type]>[im_gif new "Admin category type"]</A>"
    }
    return $html
}


ad_proc -public im_gif_cleardot { {width 1} {height 1} {alt ""} } {
    Creates an &lt;IMG ... &gt; tag of a given size
} {
    set url "/intranet/images"
    return "<img src=$url/cleardot.gif width=$width height=$height title=\"$alt\" alt=\"$alt\">"
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

ad_proc -public im_table_with_title { 
    title 
    body 
} {
    Returns a two row table with background colors
} {
    if {"" == $body} { return "" }

    set page_url [im_component_page_url]

    return "
<table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
<tr>
   <td class=tableheader align=left width='99%'>$title</td>
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

ad_proc -public im_user_navbar { default_letter base_url next_page_url prev_page_url export_var_list {select_label ""} } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/users/.
    The lower part of the navbar also includes an Alpha bar.<br>
    Default_letter==none marks a special behavious, printing no alpha-bar.

    @param select_label Label of a menu item to highlight
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
    set parent_menu_sql "select menu_id from im_menus where label='user'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]
    set navbar [im_sub_navbar $parent_menu_id "" $alpha_bar "tabnotsel" $select_label]

    return $navbar
}


ad_proc -public im_project_navbar { 
    {-navbar_menu_label "projects"}
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    @param default_letter none marks a special behavious, hiding the alpha-bar.
    @navbar_menu_label Determines the "parent menu" for the menu tabs for 
                       search shortcuts, defaults to "projects".
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
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
    set parent_menu_sql "select menu_id from im_menus where label=:navbar_menu_label"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]
    
    ns_set put $bind_vars letter $default_letter
    ns_set delkey $bind_vars project_status_id

    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

    return $navbar
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

    set standard "$tdsp$nosel<a href='index?view_name=project_list'>[_ intranet-core.Standard]</a></td>"
    set status "$tdsp$nosel<a href='index?view_name=project_status'>[_ intranet-core.Status]</a></td>"
    set costs "$tdsp$nosel<a href='index?view_name=project_costs'>[_ intranet-core.Costs]</a></td>"

    switch $section {
"Standard" {set standard "$tdsp$sel [_ intranet-core.Standard]</td>"}
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



ad_proc -public im_company_navbar { default_letter base_url next_page_url prev_page_url export_var_list {select_label ""} } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/companies/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
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
    set parent_menu_sql "select menu_id from im_menus where label='companies'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]
    set navbar [im_sub_navbar $parent_menu_id "" $alpha_bar "tabnotsel" $select_label]

    return $navbar
}



ad_proc -public im_admin_navbar { {select_label ""} } {
    Setup a sub-navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
    # select the administration menu items
    set parent_menu_sql "select menu_id from im_menus where name='Admin'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]

    return [im_sub_navbar $parent_menu_id "" "" "pagedesriptionbar" $select_label]
}



ad_proc -public im_sub_navbar { parent_menu_id {bind_vars ""} {title ""} {title_class "pagedesriptionbar"} {select_label ""} } {
    Setup a sub-navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
    @param parent_menu_id id of the parent menu in im_menus
    @param bind_vars a list of variables to pass-through
    @title string to go into the line below the menu tabs
    @title_class CSS class of the title line
} {
#    ns_log Notice "im_sub_navbar: parent_menu_id=$parent_menu_id, bind_vars=$bind_vars, title=$title, select_label=$select_label"

    set user_id [ad_get_user_id]
    set url_stub [ns_conn url]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    # Start formatting the menu bar
    set navbar ""
    set found_selected 0
    set selected 0
    set old_sel "notsel"
    set cur_sel "notsel"
    set ctr 0


    # Replaced the db_foreach by this construct to save
    # the relatively high amount of SQLs to get the menus
    set menu_list_list [util_memoize "im_sub_navbar_menu_helper $user_id $parent_menu_id" 60]
    foreach menu_list $menu_list_list {

	set menu_id [lindex $menu_list 0]
	set package_name [lindex $menu_list 1]
	set label [lindex $menu_list 2]
	set name [lindex $menu_list 3]
	set url [lindex $menu_list 4]
	set visible_tcl [lindex $menu_list 5]

	if {"" != $visible_tcl} {
	    # Interpret empty visible_tcl menus as always visible
	    
	    set errmsg ""
	    set visible 0
	    if [catch {
	    	set visible [expr $visible_tcl]
	    } errmsg] {
		ad_return_complaint 1 "<pre>$errmsg</pre>"	    
	    }
	    	    
	    if {!$visible} { continue }
	}	
	
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

        if {[string equal $label $select_label]} {
	    
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

        set name_key "intranet-core.[lang::util::suggest_key $name]"
        set name [lang::message::lookup "" $name_key $name]

        if {$selected} {
            set html "$sel$a_white href=\"$url\"/><nobr>$name</nobr></a></td>\n"
        } else {
            set html "$nosel<a href=\"$url\"><nobr>$name</nobr></a></td>\n"
        }

        append navbar "<td>[im_gif $gif]</td>$html"
        incr ctr
    }

    # Show the ending triangle GIF only if there were entries
    if {$ctr > 0} {
	append navbar "<td>[im_gif "right-$cur_sel"]</td>"
    }

    return "
      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR>
          <TD align=right>
	    <div id=subnavbar_class>
            <table border=0 cellspacing=0 cellpadding=0>
              <tr height=19>
                $navbar
              </tr>
            </table>
	    </div>
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

ad_proc -private im_sub_navbar_menu_helper { user_id parent_menu_id } {
    Get the list of menus in the sub-navbar for the given user.
    This routine is cached and called every approx 60 seconds
} {

    # ToDo: Remove with version 4.0 or later
    # Update from 3.2.2 to 3.2.3 adding the "enabled_p" field:
    # We need to be able to read the old DB model, otherwise the
    # users won't be able to upgrade...
    set enabled_present_p [util_memoize "db_string enabled_enabled \"
        select  count(*)
	from	user_tab_columns
        where   lower(table_name) = 'im_component_plugins'
                and lower(column_name) = 'enabled_p'
    \""]
    if {$enabled_present_p} {
        set enabled_sql "and enabled_p = 't'"
    } else {
        set enabled_sql ""
    }

    set menu_select_sql "
	select
		menu_id,
		package_name,
		label,
		name,
		url,
		visible_tcl
	from
		im_menus m
	where
		parent_menu_id = :parent_menu_id
		$enabled_sql
		and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
	order by
		 sort_order
    "

    return [db_list_of_lists subnavbar_menus $menu_select_sql]
}





ad_proc -public im_navbar { { main_navbar_label "" } } {
    Setup a top navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
    ns_log Notice "im_navbar: main_navbar_label=$main_navbar_label"
    set user_id [ad_get_user_id]
    set url_stub [ns_conn url]
    set page_title [ad_partner_upvar page_title]
    set section [ad_partner_upvar section]
    set return_url [im_url_with_query]

    # There are two ways to publish a context bar:
    # 1. Via "context_bar". This var contains a fully formatted context bar
    # 2. Via "context". "Context" contains a list of lists, with the last
    #    element being a single name
    #
    set context_bar [ad_partner_upvar context_bar]

    if {"" == $context_bar} {
	set context [ad_partner_upvar context]
	if {"" == $context} {
	    set context [list $page_title]
	}

	set context_root [list [list "/intranet/" "&\#93;project-open&\#91;"]]
	set context [concat $context_root $context]
	set context_bar [im_context_bar_html $context]
    }

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"

    set navbar ""
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label='main'" -default 0]

    # make sure only one field gets selected so...
    # .. check for the first complete match between menu and url.
    set ctr 0
    set selected 0
    set found_selected 0
    set old_sel "notsel"
    set cur_sel "notsel"

    # select the toplevel menu items
    set menu_list_list [util_memoize "im_sub_navbar_menu_helper $user_id $main_menu_id" 60]
    foreach menu_list $menu_list_list {

        set menu_id [lindex $menu_list 0]
        set package_name [lindex $menu_list 1]
        set label [lindex $menu_list 2]
        set name [lindex $menu_list 3]
        set url [lindex $menu_list 4]
        set visible_tcl [lindex $menu_list 5]

	# Shift the old value of cur_sel to old_val
	set old_sel $cur_sel
	set cur_sel "notsel"

	# Find out if we need to highligh the current menu item
	set selected 0
	set url_length [expr [string length $url] - 1]
	set url_stub_chopped [string range $url_stub 0 $url_length]

	# Check if we should select this one:
	set select_this_one 0
	if {[string equal $label $main_navbar_label]} { set select_this_one 1 }

        if {!$found_selected && $select_this_one} {
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

        set name_key "intranet-core.[lang::util::suggest_key $name]"
        set name [lang::message::lookup "" $name_key $name]

        if {$selected} {
            set html "$sel$a_white href=\"$url\"/><nobr>$name</nobr></a></td>\n"
        } else {
	    set html "$nosel<a href=\"$url\"><nobr>$name</nobr></a></td>\n"
	}

        append navbar "<td>[im_gif $gif]</td>$html"
	incr ctr
    }
    if {"" != $navbar} {
	append navbar "<td>[im_gif "right-$cur_sel"]</td>"
    }

    set page_url [im_component_page_url]

    set add_stuff_text [lang::message::lookup "" intranet-core.Add_Stuff "Add Stuff"]
    set reset_stuff_text [lang::message::lookup "" intranet-core.Reset_Stuff "Reset"]

    set add_comp_url [export_vars -base "/intranet/components/add-stuff" {page_url return_url}]
    set reset_comp_url [export_vars -base "/intranet/components/component-action" {page_url {action reset} {plugin_id 0} return_url}]

    # Maintenance Bar -
    # Display a maintenance message in red when performing updates etc...   
    set maintenance_message [ad_parameter -package_id [im_package_core_id] MaintenanceMessage "" ""]
    set maintenance_message [string trim $maintenance_message]
    set maintenance_bar ""
    if {"" != $maintenance_message} {
	set maintenance_bar "
	<TR>
          <td colspan=2 class=maintenancebar>
		$maintenance_message
          </td>
	</TR>
        "
    }

    set add_components "
	<nobr>
	<a href=\"$reset_comp_url\">$reset_stuff_text</a>
	<a href=\"$add_comp_url\">[im_gif comp_add $add_stuff_text]</a>
	<a href=\"$add_comp_url\">$add_stuff_text</a>
	</nobr>
    "

    return "
      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR>
          <TD align=left>
	    <div id=navbar_class>
            <table border=0 cellspacing=0 cellpadding=0>
              <tr height=19>
                $navbar
              </tr>
            </table>
	    </div>
          </TD>
	  <td align=right>
	    <div id=navbar_right_class>
	     $add_components
	    </div>
	  </td>
        </TR>
        <TR>
          <td colspan=2 class=pagedesriptionbar>
            <table cellpadding=1 width='100%'>
              <tr>
                <td class=pagedesriptionbar valign=middle>
                  $page_title
                </td>
                <td class=pagedesriptionbar valign=middle align=right>
                  $context_bar
                </td>
              </tr>
            </table>
          </td>
        </TR>
        $maintenance_bar
      </table>\n"
}


ad_proc -public im_header { { page_title "" } { extra_stuff_for_document_head "" } } {
    The default header for ProjectOpen
} {
    set user_id [ad_get_user_id]
    set user_name [im_name_from_user_id $user_id]

    # Is any of the "search" package installed?
    set search_installed_p [llength [info procs im_package_search_id]]

    if { [empty_string_p $page_title] } {
	set page_title [ad_partner_upvar page_title]
    }
    set context_bar [ad_partner_upvar context_bar]
    set page_focus [ad_partner_upvar focus]
    if {$search_installed_p && [empty_string_p $page_focus] } {
	# Default: Focus on Search form at the top of the page
	set page_focus "surx.query_string"
    }
    if { [empty_string_p $extra_stuff_for_document_head] } {
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    }

    # --------------------------------------------------------
    set search_form ""
    if {[im_permission $user_id "search_intranet"] && $user_id > 0 && $search_installed_p} {
	set search_form "
	    <nobr>
	      <form action=/intranet/search/go-search method=post name=surx>
                <input class=surx name=query_string size=15 value=\"[_ intranet-core.Search]\" onClick=\"javascript:this.value = ''\">
	<!--
                <select class=surx name=target>
                  <option class=surx selected value=content>[_ intranet-core.Intranet_content]</option>
                  <option class=surx value=users>[_ intranet-core.Intranet_users]</option>
                  <option class=surx value=htsearch>[_ intranet-core.All_documents_in_H]</option>
                  <option class=surx value=google>[_ intranet-core.The_web_with_Google]</option>
                </select>
	-->
		<input type=hidden name=target value=content>
                <input alt=go type=submit value=Go name='image'>
              </form>
	    </nobr>
        "
    }

    # Determine a pretty string for the type of user that it is:
    set user_profile "[_ intranet-core.User]"
    if {[im_permission $user_id "freelance"]} {
	set user_profile "[_ intranet-core.Freelance]"
    }
    if {[im_permission $user_id "client"]} {
	set user_profile "[_ intranet-core.Client]"
    }
    if {[im_permission $user_id "employee"]} {
	set user_profile "[_ intranet-core.Employee]"
    }
    if {[ad_user_group_member [im_admin_group_id] $user_id]} {
	set user_profile "[_ intranet-core.Admin]"
    }
    if {[im_site_wide_admin_p $user_id]} {
	set user_profile "[_ intranet-core.SiteAdmin]"
    }

    append extra_stuff_for_document_head [im_stylesheet]
    append extra_stuff_for_document_head "<script src=\"/resources/acs-subsite/core.js\" language=\"javascript\"></script>\n"
    append extra_stuff_for_document_head "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n"
    append extra_stuff_for_document_head "<script src=\"/intranet/js/showhide.js\" language=\"javascript\"></script>\n"

    append extra_stuff_for_document_head "<!--\[if lt IE 7.\]>\n<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>\n<!\[endif\]-->\n"
    # append extra_stuff_for_document_head "<script src=\"http://simile.mit.edu/timeline/api/timeline-api.js\" language=\"javascript\"></script>\n"
    # append extra_stuff_for_document_head "<script src=\"/intranet-timeline/timeline.js\" language=\"javascript\"></script>\n"

    if {[llength [info procs im_amberjack_header_stuff]]} {
        append extra_stuff_for_document_head [im_amberjack_header_stuff]
    }

    set extra_stuff_for_body "onLoad=\"javascript:initPortlet();\" "

    set change_pwd_url "/intranet/users/password-update?user_id=$user_id"

    # Enable "Users Online" mini-component for OpenACS 5.1 only
    set users_online_str ""

    set proc "num_users"
    set namespace "whos_online"

    if {[string equal $proc [namespace eval $namespace "info procs $proc"]]} {
	set num_users_online [lc_numeric [whos_online::num_users]]
	if {1 == $num_users_online} { 
	    set users_online_str "<A href=/intranet/whos-online>[_ intranet-core.lt_num_users_online_user]</A><BR>\n"
	} else {
	    set users_online_str "<A href=/intranet/whos-online>[_ intranet-core.lt_num_users_online_user_1]</A><BR>\n"
	}
    }
    
    set logout_pwchange_str "
	<a href='/intranet/users/view?user_id=$user_id'>[lang::message::lookup "" intranet-core.My_Account "My Account"]</a> |
	<a href='/register/logout'>[_ intranet-core.Log_Out]</a> |
	<a href=$change_pwd_url>[_ intranet-core.Change_Password]</a> 
    "

    # Disable who's online for "anonymous visitor"
    if {0 == $user_id} {
	set users_online_str ""
	set logout_pwchange_str ""
    }

    # --------------------------------------------------------
    # Header Plugins
    #
    set any_perms_set_p [im_component_any_perms_set_p]
    set plugin_sql "
	select	c.*,
		im_object_permission_p(c.plugin_id, :user_id, 'read') as perm
	from	im_component_plugins c
	where	location like 'header%'
	order by sort_order
    "

    set plugin_left_html ""
    set plugin_right_html ""
    db_foreach get_plugins $plugin_sql {

	if {$any_perms_set_p > 0} {
	    if {"f" == $perm} { continue }
	}

	ns_log Notice "im_component_bay: component_tcl=$component_tcl, location=$location"
	if { [catch {

	    # "uplevel" evaluates the 2nd argument!!
	    switch $location {
		"header-left" {
		    append plugin_left_html [uplevel 1 $component_tcl]
		}
		default {
		    append plugin_right_html [uplevel 1 $component_tcl]
		}
	    }

	} err_msg] } {
	    set plugin_right_html "<table>\n<tr><td><pre>$err_msg</pre></td></tr></table>\n"
	    set plugin_right_html [im_table_with_title $plugin_name $plugin_right_html]
        }
    }

    return "
[ad_header -focus $page_focus -extra_stuff_for_body $extra_stuff_for_body $page_title $extra_stuff_for_document_head]
<div id=header_class>
<table border=0 cellspacing=0 cellpadding=0 width='100%'>
  <tr>
    <td>[im_logo]</td>
    <td>$plugin_left_html</td>
    <td align=left valign=middle> 
      <div id=whosonline_class>
      <span class=small>
        <nobr>$users_online_str</nobr>
        <nobr>$user_profile: $user_name</nobr><br>
        <nobr>$logout_pwchange_str</nobr>
      </span>
      </div>
    </td>
    <td valign=middle align=right> 
	$search_form 
	$plugin_right_html
    </TD>
  </tr>
</table>
</div>
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
                <td class=tabnotsel><a href=/intranet/>[_ intranet-core.Home]</a></td><td>&nbsp;</td>
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



ad_proc -public im_footer {
} {
    Default ProjectOpen footer.
} {
    set amberjack_body_stuff ""
    if {[llength [info procs im_amberjack_before_body]]} {
	set amberjack_body_stuff [im_amberjack_before_body]
    }

    return "
      <div id=footer_klass>
      <TABLE border=0 cellPadding=5 cellSpacing=0 width='100%'>
        <TBODY> 
          <TR>
            <TD>[_ intranet-core.Comments] [_ intranet-core.Contact]: 
          <A href='mailto:[ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]'>
          [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]
          </A> 
           </TD>
        </TR>
      </TBODY>
    </TABLE>
    </div>
  $amberjack_body_stuff</BODY>
</HTML>
"
}


ad_proc -public im_stylesheet {} {
    Intranet CSS style sheet. 
} {
    set system_css [ad_parameter -package_id [im_package_core_id] SystemCSS "" "/intranet/style/style.default.css"]
    set calendar_css ""
    if {[llength [info procs im_package_calendar_id]]} {
	set calendar_css "<link rel=StyleSheet type=text/css href=\"/calendar/resources/calendar.css\">"
    }

    return "
<link rel=StyleSheet type=text/css href=\"/resources/acs-subsite/site-master.css\" media=all>
<link rel=StyleSheet href=\"$system_css\" type=text/css media=screen>
$calendar_css
<script src=\"/resources/acs-subsite/core.js\" language=\"javascript\"></script>
"

# <link rel=StyleSheet type=text/css href=\"/resources/acs-templating/lists.css\" media=all>
# <link rel=StyleSheet type=text/css href=\"/resources/acs-templating/forms.css\" media=all>
# <link rel=StyleSheet type=text/css href=\"/resources/acs-subsite/default-master.css\" media=all>

}


ad_proc -public im_logo {} {
    Intranet System Logo
} {
    set system_logo [ad_parameter -package_id [im_package_core_id] SystemLogo "" "/intranet/images/project_open.38.10frame.gif"]
    set system_logo_link [ad_parameter -package_id [im_package_core_id] SystemLogoLink "" "http://www.project-open.com/"]
    
    return "\n<a href=\"$system_logo_link\"><img src=$system_logo border=0></a>\n"
}



ad_proc -public im_navbar_gif_url {} {
    Path to access the Navigation Bar corner GIFs
} {
    return [util_memoize "im_navbar_gif_url_helper" 60]
}

ad_proc -public im_navbar_gif_url_helper {} {
    Path to access the Navigation Bar corner GIFs
} {
    set navbar_gif_url "/intranet/images/[ad_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "/intranet/images/navbar_default"]"
    set org_navbar_gif_url $navbar_gif_url

    # Old parameter? Shell out a warning and use the last part
    set navbar_pieces [split $navbar_gif_url "/"]
    set navbar_pieces_len [llength $navbar_pieces]
    if {$navbar_pieces_len > 1} {
	set navbar_gif_url [lindex $navbar_pieces [expr $navbar_pieces_len-1] ]
	ns_log Notice "im_navbar_gif_url: Found old-stype SystemNavbarGifPath parameter - using only last part: '$org_navbar_gif_url' -> '$navbar_gif_url'"
    }

    return $navbar_gif_url
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
	lappend html_list "<b>[_ intranet-core.All]</b>"
    } else {
	lappend html_list "<a href=${url}letter=all>All</a>"
    }
    if { [string compare $letter "scroll"] == 0 } {
	lappend html_list "<b>[_ intranet-core.Scroll]</b>"
    } else {
	lappend html_list "<a href=${url}letter=scroll>[_ intranet-core.Scroll]</a>"
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
	set letter_key "intranet-core.[lang::util::suggest_key $letter]"
	set letter_trans [lang::message::lookup "" $letter_key $letter]
	if {[string equal $letter $default_letter]} {
	    append html "<font color=white>$letter_trans</font> &nbsp; \n"
	} else {
	    set url "$target_url?letter=$letter&$param_html"
	    append html "<A HREF=$url>$letter_trans</A>&nbsp;\n"
	}
    }
    append html ""
    return $html
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
	set report_url "http://projop.dnsalias.com/intranet-forum/forum/new-system-incident"
    } 

    set error_info ""
    if {![ad_parameter -package_id [ad_acs_kernel_id] "RestrictErrorsToAdminsP" "" 0] || [permission::permission_p -object_id [ad_conn package_id] -privilege admin] } {
	set error_info $message
    }
    
    ns_returnerror 500 "
[im_header_emergency "[_ intranet-core.Request_Error]"]
<form method=post action=$report_url>
[export_form_vars error_url error_info error_first_names error_last_name error_user_email system_url publisher_name core_version]
[_ intranet-core.lt_This_file_has_generat]  
<input type=submit value='[_ intranet-core.Report_this_error]' />
</form>
<hr />
<blockquote><pre>[ns_quotehtml $error_info]</pre></blockquote>
[im_footer]"
}



ad_proc -public im_context_bar {
    {-from_node ""}
    -node_id
    -separator
    args
} {
    Returns a Yahoo-style hierarchical navbar. 
    This is the project-open specific version of the OpenACS ad_context_bar.
    Here we actually don't want to show anything about "admin".

    'args' can be either one or more lists, or a simple string.

    @param node_id If provided work up from this node, otherwise the current node
    @param from_node If provided do not generate links to the given node and above.
    @param separator The text placed between each link (passed to ad_context_bar_html 
           if provided)
    @return an html fragment generated by ad_context_bar_html

    @see ad_context_bar_html
} {
    if { ![exists_and_not_null node_id] } {
        set node_id [ad_conn node_id]
    }

    set context [list [list "/intranet/" "&\#93;project-open&\#91;"]]

    if {[llength $args] == 0} {
        # fix last element to just be literal string
        set context [lreplace $context end end [lindex [lindex $context end] 1]]
    } else {
        if ![string match "\{*" $args] {
            # args is not a list, transform it into one.
            set args [list $args]
        }
    }

    if { [info exists separator] } {
        return [im_context_bar_html -separator $separator [concat $context $args]]
    } else {
        return [im_context_bar_html [concat $context $args]]
    }
}


ad_proc -public im_context_bar_html {
    {-separator " : "}
    context
} {
    Generate the an html fragement for a context bar.
    This is the ProjectOpen specific variant of the OpenACS ad_context_bar_html
    This is the function that takes a list in the format
    <pre>
    [list [list url1 text1] [list url2 text2] ... "terminal text"]
    <pre>
    and generates the html fragment.  In general the higher level
    proc ad_context_bar should be
    used, and then only in the sitewide master rather than on
    individual pages.

    @param separator The text placed between each link
    @param context list as with ad_context_bar
    @return html fragment
    @see ad_context_bar
} {
    set out {}
    foreach element [lrange $context 0 [expr [llength $context] - 2]] {
        append out "<a class=contextbar href=\"[lindex $element 0]\">[lindex $element 1]</a>$separator"
    }
    append out "<span class=contextbar>[lindex $context end]</span>"
    return $out
}


ad_proc -public im_project_on_track_bb {
    {-size 16}
    on_track_status_id
    { alt_text "" }
} {
    Returns a traffic light GIF from "Big Brother" (bb)
    in green, yellow or red
} {
    set color "clear"
    if {$on_track_status_id == [im_project_on_track_status_green]} { set color "green" }
    if {$on_track_status_id == [im_project_on_track_status_yellow]} { set color "yellow" }
    if {$on_track_status_id == [im_project_on_track_status_red]} { set color "red" }

    set border 0
    return [im_gif "bb_$color" $alt_text $border $size $size]
}

# Compatibility
# ToDo: remove
ad_proc -public in_project_on_track_bb {
    {-size 16}
    on_track_status_id
    { alt_text "" }
} {
    Compatibility
} {
    return [im_project_on_track_bb -size $size $on_track_status_id $alt_text]
}



# --------------------------------------------------------
# HTML depending on browser
# --------------------------------------------------------


ad_proc -public im_html_textarea_wrap  { } {
    Returns a suitable value for the <textarea wrap=$wrap> wrap
    value. Default is "soft", which is interpreted by both 
    Firefox and IE5/6 as to NOT to convert displayed line wraps
    into line breaks in the textarea breaks.
    Reference: http://de.selfhtml.org/html/formulare/eingabe.htm
} {
    return "soft"
}

