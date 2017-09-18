# /packages/intranet-core/tcl/intranet-design.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4

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
# Categories & Constants
# --------------------------------------------------------

# 40000-40999  Intranet Skin (1000)

ad_proc -public im_skin_default {} { return 40000 }
ad_proc -public im_skin_left_blue {} { return 40005 }
ad_proc -public im_skin_right_blue {} { return 40010 }
ad_proc -public im_skin_light_green {} { return 40015 }
ad_proc -public im_skin_saltnpepper {} { return 40020 }

# --------------------------------------------------------
# im_gif - Try to return the best matching GIF...
# --------------------------------------------------------

ad_proc -public im_gif { 
    {-translate_p 0} 
    {-locale ""}
    {-type "gif"}
    {-debug 0 }
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
    if {$debug} { ns_log Notice "im_gif: name=$name" }

    set url "/intranet/images"
    set navbar_postfix [im_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "navbar_default"]
    set navbar_gif_url "/intranet/images/[im_navbar_gif_url]"
    set base_path "[acs_root_dir]/packages/intranet-core/www/images/"
    set navbar_path "[acs_root_dir]/packages/intranet-core/www/images/[im_navbar_gif_url]"

    if { $translate_p && $alt ne "" } {
	set alt_key "intranet-core.[lang::util::suggest_key $alt]"
	set alt [lang::message::lookup $locale $alt_key $alt]
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
    if {[util_memoize [list file exists $png_path]]} {
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
    if {[util_memoize [list file exists $gif_path]]} {
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
    set gif_exists_p [util_memoize [list file readable $gif_file]]

    set png_file "$navbar_path/${name}.png"
    set png_exists_p [util_memoize [list file readable $png_file]]

    if {$gif_exists_p} { 
	return "<img src=\"$navbar_gif_url/$name.gif\" border=0 title=\"$alt\" alt=\"$alt\">" 
    }

    if {$png_exists_p} { 
	return "<img src=\"$navbar_gif_url/$name.png\" border=0 title=\"$alt\" alt=\"$alt\">" 
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
	"delete" 	{ return "<img src=$url/delete.gif width=14 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"help"		{ return "<img src=$navbar_gif_url/help.png border=$border title=\"$alt\" alt=\"$alt\">" }
	"error"         { return "<img src=$navbar_gif_url/error.png border=$border title=\"$alt\" alt=\"$alt\">" }	
	"category"	{ return "<img src=$url/help.gif width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"new"		{ return "<img src=$url/new.gif width=13 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"open"		{ return "<img src=$url/open.gif width=16 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"save"		{ return "<img src=$url/save.gif width=14 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"incident"	{ return "<img src=$navbar_gif_url/lightning.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"discussion"	{ return "<img src=$navbar_gif_url/group.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"task"		{ return "<img src=$navbar_gif_url/tick.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"news"		{ return "<img src=$navbar_gif_url/newspaper.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"note"		{ return "<img src=$navbar_gif_url/note.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"incident_add"	{ return "<img src=$navbar_gif_url/lightning_add.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"discussion_add" { return "<img src=$navbar_gif_url/group_add.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"task_add"	{ return "<img src=$navbar_gif_url/tick_add.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"news_add"	{ return "<img src=$navbar_gif_url/newspaper_add.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"note_add"	{ return "<img src=$navbar_gif_url/note_add.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"reply"		{ return "<img src=$navbar_gif_url/arrow_rotate_clockwise.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"tick"		{ return "<img src=$url/tick.gif width=14 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"wrong"		{ return "<img src=$url/delete.gif width=14 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"turn"		{ return "<img src=$url/turn.gif widht=15 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }
	"tool"		{ return "<img src=$url/tool.15.gif widht=20 height=15 border=$border title=\"$alt\" alt=\"$alt\">" }

	"exp-folder"	{ return "<img src=$url/exp-folder.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-minus"	{ return "<img src=$url/exp-minus.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-unknown"	{ return "<img src=$url/exp-unknown.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-line"	{ return "<img src=$url/exp-line.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-excel"	{ return "<img src=$url/$name.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-word"	{ return "<img src=$url/$name.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-text"	{ return "<img src=$url/$name.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-pdf"	{ return "<img src=$url/$name.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-odp"	{ return "<img src=$url/exp-ppt.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-odt"	{ return "<img src=$url/exp-word.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"exp-ods"	{ return "<img src=$url/exp-excel.gif width=19 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }

	"profile"	{ return "<img src=$navbar_gif_url/user.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"member"	{ return "<img src=$url/m.gif width=19 height=13 border=$border title=\"$alt\" alt=\"$alt\">" }
	"key-account"	{ return "<img src=$url/k.gif width=18 height=13 border=$border title=\"$alt\" alt=\"$alt\">" }
	"project-manager" { return "<img src=$url/p.gif width=17 height=13 border=$border title=\"$alt\" alt=\"$alt\">" }

	"anon_portrait" { return "<img width=98 height=98 src=$url/anon_portrait.gif border=$border title=\"$alt\" alt=\"$alt\">" }

	"left-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"left-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"right-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"right-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }

	"middle-sel-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-notsel-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-sel-sel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"middle-notsel-notsel"	{ return "<img src=$navbar_gif_url/$name.gif width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }

	"admin"		{ return "<img src=$navbar_gif_url/tux.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"customer"	{ return "<img src=$navbar_gif_url/coins.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"employee"	{ return "<img src=$navbar_gif_url/user_orange.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"freelance"	{ return "<img src=$navbar_gif_url/time.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"helpdesk"	{ return "<img src=$navbar_gif_url/monitor_lightning.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"senman"	{ return "<img src=$navbar_gif_url/user_suit.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"proman"	{ return "<img src=$navbar_gif_url/user_comment.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"accounting"	{ return "<img src=$navbar_gif_url/money_dollar.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"sales"		{ return "<img src=$navbar_gif_url/telephone.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
	"house"		{ return "<img src=$navbar_gif_url/house.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"key"		{ return "<img src=$navbar_gif_url/key.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }

	"bb_clear"	{ return "<img src=\"$url/$name.gif\" width=$width height=\"$height\" border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_red"	{ return "<img src=\"$url/$name.gif\" width=$width height=\"$height\" border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_blue"	{ return "<img src=\"$url/$name.gif\" width=$width height=\"$height\" border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_yellow"	{ return "<img src=\"$url/$name.gif\" width=$width height=\"$height\" border=$border title=\"$alt\" alt=\"$alt\">" }
	"bb_purple"	{ return "<img src=\"$url/$name.gif\" width=$width height=\"$height\" border=$border title=\"$alt\" alt=\"$alt\">" }


	"comp_add"	{ return "<img src=$navbar_gif_url/comp_add.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_left" { return "<img src=$navbar_gif_url/$name.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_right" { return "<img src=$navbar_gif_url/$name.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_up"	{ return "<img src=$navbar_gif_url/$name.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_down" { return "<img src=$navbar_gif_url/$name.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_minimize"	{ return "<img src=$navbar_gif_url/$name.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"arrow_comp_maximize"	{ return "<img src=$navbar_gif_url/$name.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }
	"comp_delete"	{ return "<img src=$navbar_gif_url/comp_delete.png width=16 height=16 border=$border title=\"$alt\" alt=\"$alt\">" }

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
    set user_id [auth::require_login]
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {$user_admin_p} {
	set html "
<A HREF=\"/intranet/admin/categories/?select_category_type=[ns_urlencode $category_type]\">[im_gif -translate_p 1 new "Admin category type"]</A>"
    }
    return $html
}


ad_proc -public im_gif_cleardot { {width 1} {height 1} {alt "spacer"} } {
    Creates an &lt;IMG ... &gt; tag of a given size
} {
    set url "/intranet/images"
    return "<img src=\"$url/cleardot.gif\" width=\"$width\" height=\"$height\" title=\"$alt\" alt=\"$alt\">"
}


ad_proc -public im_return_template {} {
    Wrapper that adds page contents to header and footer<p>
    040221 fraber: Should not be called anymore - should
    be replaced by .adp files containing the same calls...
} {
    uplevel { 
	    return "[im_header]\n[im_navbar]\n[value_if_exists page_body]\n[value_if_exists page_content]\n[im_footer]\n"	    
    }
}


ad_proc -public im_tablex {
    {content "no content?"} 
    {pad "0"} 
    {col ""} 
    {spa "0"} 
    {bor "0"} 
    {wid "100%"}
} {
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
    return "[im_box_header $title]$body[im_box_footer]"
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
    set user_id [ad_conn user_id]
    set url_stub [ns_urldecode [im_url_with_query]]
#    ns_log Notice "im_user_navbar: url_stub=$url_stub"

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label='user'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

    return $navbar
}


ad_proc -public im_project_navbar { 
    {-navbar_menu_label "projects"}
    {-current_plugin_id 0}
    {-plugin_url "/intranet/projects/index"}
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
    set user_id [ad_conn user_id]
    set url_stub [ns_urldecode [im_url_with_query]]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label = '$navbar_menu_label'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    
    ns_set put $bind_vars letter $default_letter
    ns_set delkey $bind_vars project_status_id

    set navbar [im_sub_navbar -components -current_plugin_id $current_plugin_id -plugin_url $plugin_url $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

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
    set user_id [ad_conn user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{office%5flist} { set section "Standard" }
	default {
	    set section "Standard"
	}
    }

    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    set standard [im_navbar_tab "index?view_name=project_list" [_ intranet-core.Standard] [string equal $section "Standard"]]
    set status [im_navbar_tab "index?view_name=project_status" [_ intranet-core.Status] false]
    set costs [im_navbar_tab "index?view_name=project_costs" [_ intranet-core.Costs] false]

    if {[im_permission $user_id add_offices]} {
	set new_office [im_navbar_tab "new" [im_gif -translate_p 1 new "Add a new office"] false]
    } else {
	set new_office ""
    }


    if { [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "LegacyFrameworkVersion4P" -default 1] } {
            return  "
                <div id=\"navbar_sub_wrapper\">
                   $alpha_bar
                   <ul id=\"navbar_sub\">
                      $standard
                      $new_office
                   </ul>
                </div>
         "
    } else {
	    return  "
		<div class=\"navbar_sub_wrapper_sm\">
		   $alpha_bar
		   <ul id=\"navbar_main\" class=\"sm\">
		      $standard
		      $new_office
		   </ul>
		</div>
    	 "
    }
}


ad_proc -public im_company_navbar { 
    {-current_plugin_id "" }
    {-plugin_url "" }
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/companies/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.
} {
    # -------- Defaults -----------------------------
    set user_id [ad_conn user_id]
    set url_stub [ns_urldecode [im_url_with_query]]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label='companies'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]

    set navbar [im_sub_navbar \
		    -components \
		    -current_plugin_id $current_plugin_id \
		    -plugin_url $plugin_url \
		    $parent_menu_id \
		    $bind_vars \
		    $alpha_bar \
		    "tabnotsel" \
		    $select_label \
    ]

    return $navbar
}

ad_proc -public im_admin_navbar { 
    {select_label ""} 
} {
    Setup a sub-navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
    set html "
	   <div class=\"filter\" id=\"sidebar\">
 		<div id=\"sideBarContentsInner\">
	      <div class=\"filter-block\">
		 <div class=\"filter-title\">
		    [lang::message::lookup "" intranet-core.Admin_Menu "Admin Menu"]
		 </div>
	<ul class=mktree>
    "

    # Disabled - no need to show the same label again
    if {0 && "" != $select_label} {
	append html "
	[im_menu_li -class liOpen $select_label]
		<ul>
		[im_navbar_write_tree -label $select_label]
		</ul>
	"
    }

    append html "
	      </div>
	   </div>
	</div>
    "
    return $html
}


ad_proc -public im_admin_navbar_component { } {
    Component version of the im_admin_navbar to test the
    auto-extend possibilities of mktree 
} {
    set title "Admin Navbar"
    return "
	<ul class=mktree>
	[im_menu_li -class liOpen admin]
		<ul>
		[im_navbar_write_tree -label "admin" -maxlevel 0]
		</ul>
	[im_menu_li -class liOpen openacs]
		<ul>
		[im_navbar_write_tree -label "openacs" -maxlevel 0]
		</ul>
	</ul>
    "
}


ad_proc -public im_navbar_help_link { 
    {-url "" }
} {
    Determines where to link to www.project-open.com for help.
    The Wiki convention for page is "page_" followed by the URL
    of the page with all non-alphanum characters replaced by "-":
    http://www.project-open.com/en/page-intranet-invoices-view
} {
    # Get the URL from the connection
    if {"" == $url} { set url [ad_conn url] }

    # Does the URL has a trailing "/". That's the case for
    # the "index" pages sometimes.
    if {[regexp {/$} $url match]} { set url "${url}index" }

    # Replace "/" by "_" to create
    regsub -all "/" $url "-" url
    regsub -all {_} $url "-" url

    # Add the constant part in front of the url:
    set url "http://www.project-open.net/en/page$url"

    # Return the finished URL
    return $url
}


ad_proc -public im_navbar_tab {
    url
    name
    selected
} {
    Creates <li> menu item  
} {
    # ds_comment "$name / $selected / $url"
    if {$selected} {
	set selected "selected"
        set navbar_selected "navbar_selected"
    } else {
	set selected "unselected"
	set navbar_selected "navbar_unselected"
    }
  
    if { [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "LegacyFrameworkVersion4P" -default 1] } {
	return "<li class=\"$selected\"><div class=\"$navbar_selected\"><a href=\"$url\"><span>$name</span></a></div></li>\n"
    } else {
	return "<li class=\"$selected\"><a href=\"$url\"><span>$name</span></a></li>\n"
    }
}


ad_proc -public im_sub_navbar { 
    {-components:boolean 0}
    {-show_help_icon:boolean 0}
    {-current_plugin_id ""}
    {-base_url ""}
    {-plugin_url "/intranet/projects/view"}
    {-menu_gif_type "none"}
    parent_menu_id 
    {bind_vars ""} 
    {title ""} 
    {title_class "pagedesriptionbar"} 
    {select_label ""} 
} {
    Setup a sub-navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
    @param menu_gif_type One of "small", "medium", "large" or "" for none.
    @param parent_menu_id id of the parent menu in im_menus
    @param bind_vars a list of variables to pass-through
    @title string to go into the line below the menu tabs
    @title_class CSS class of the title line
} {
    set user_id [ad_conn user_id]
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set locale [lang::user::locale -user_id $user_id]
    set url_stub [ns_conn url]

    # Skip the Admin submenu
    set admin_menu_id [im_menu_id_from_label "admin"]
    if {$parent_menu_id eq $admin_menu_id} { return "" }


    # Start formatting the menu bar
    set navbar ""
    set found_selected 0
    set selected 0

    if {"" == $current_plugin_id} { set current_plugin_id 0 }

    # Replaced the db_foreach by this construct to save
    # the relatively high amount of SQLs to get the menus
    set menu_list_list [util_memoize [list im_sub_navbar_menu_helper -locale $locale -bind_vars $bind_vars $user_id $parent_menu_id]]

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
		ad_return_complaint 1 "im_sub_navbar: Error evaluating menu visible_tcl expression:<br>
                <pre>visible_tcl=$visible_tcl</pre><br>Error:<br><pre>$errmsg</pre>"
	    }
	    	    
	    if {!$visible} { continue }
	}	

	set bind_vars_copy ""
	catch { set bind_vars_copy [ns_set copy $bind_vars] }

	# Check if the URL contains var=value pairs
	# and overwrite bind_vars with these to avoid double variables
	if {[regexp {^([^\?]+)\?(.*)$} $url match url_base kv_pairs]} {
	    foreach kv_pair [split $kv_pairs "&"] {
		if {[regexp {^([^=]+)\=(.*)$} $kv_pair match key value]} {
		    catch { ns_set delkey $bind_vars_copy $key }
		    catch { ns_set put $bind_vars_copy $key $value }
		}
	    }
	    set url $url_base
	}

	# append a "?" if not yet part of the URL
	if {![regexp {\?} $url match]} { append url "?" }

	# Construct the URL
	if {"" != $bind_vars_copy && [ns_set size $bind_vars_copy] > 0} {
	    for {set i 0} {$i < [ns_set size $bind_vars_copy]} {incr i} {
		append url "&amp;[ns_set key $bind_vars_copy $i]=[ns_urlencode [ns_set value $bind_vars_copy $i]]"
	    }
	}

	# Find out if we need to highligh the current menu item
	set selected 0
	set url_length [expr {[string length $url] - 1}]
	set url_stub_chopped [string range $url_stub 0 $url_length]

	if {$label eq $select_label && $current_plugin_id == 0} {
	    
	    # Make sure we only highligh one menu item..
	    set found_selected 1
	    # Set for the other IF-clause later in this loop
	    set selected 1
	}

	set name_key "intranet-core.[lang::util::suggest_key $name]"
	set name [lang::message::lookup "" $name_key $name]

	append navbar [im_navbar_tab $url $name $selected]
    }

    if {$components_p} {
	if {$base_url eq ""} {
	    set base_url $plugin_url
	}

	set components_sql "
	    SELECT	p.plugin_id AS plugin_id,
			p.plugin_name AS plugin_name,
			p.menu_name AS menu_name
	    FROM	im_component_plugins p,
			im_component_plugin_user_map u
	    WHERE	(enabled_p is null OR enabled_p = 't')
			AND p.plugin_id = u.plugin_id 
			AND page_url = '$plugin_url'
			AND u.location = 'none' 
			AND u.user_id = $user_id
	    ORDER by 	p.menu_sort_order, p.sort_order
	"

	set navbar_components_list [util_memoize [list db_list_of_lists navbar_components $components_sql]]

	foreach comp_tuple $navbar_components_list {
	    set plugin_id [lindex $comp_tuple 0]
	    set plugin_name [lindex $comp_tuple 1]
	    set menu_name [lindex $comp_tuple 2]

	    regsub -all {[^0-9a-zA-Z]} $plugin_name "_" plugin_name_subs
	    set plugin_name_key "intranet-core.${plugin_name_subs}"
	    set plugin_name [lang::message::lookup "" $plugin_name_key $plugin_name]

	    set url [export_vars -quotehtml -base $base_url {plugin_id {view_name "component"}}]
	    if {$menu_name eq ""} {
		set menu_name [string map {"Project" "" "Component" "" "  " " "} $plugin_name] 
	    }
	    append navbar [im_navbar_tab $url $menu_name [expr {$plugin_id==$current_plugin_id}]]
	}
    }

    if {$show_help_icon_p} {
	set help_text [lang::message::lookup "" intranet-core.Navbar_Help_Text "Click here to get help for this page"]
	append navbar [im_navbar_tab [im_navbar_help_link] [im_gif -translate_p 0 help $help_text] 0]
    }

    if {$admin_p} {
	set admin_text [lang::message::lookup "" intranet-core.Navbar_Admin_Text "Click here to configure this navigation bar"]
	set admin_url [export_vars -base "/intranet/admin/menus/index" {{top_menu_id $parent_menu_id}}]
	append navbar [im_navbar_tab $admin_url [im_gif -translate_p 0 wrench $admin_text] 0]
    }

    return "
         <div id=\"navbar_sub_wrapper\">
            <span id='titleSubmenu'>$title</span>
            <ul id=\"navbar_sub\">
              $navbar
            </ul>
         </div>
        "
}


ad_proc -private im_sub_navbar_menu_helper { 
    {-locale "" }
    {-bind_vars "" }
    user_id 
    parent_menu_id 
} {
    Get the list of menus in the sub-navbar for the given user.
    This routine is cached and called every approx 60 seconds
} {
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set menu_select_sql "
	select	menu_id,
		package_name,
		label,
		name,
		url,
		visible_tcl
	from	im_menus m
	where	parent_menu_id = :parent_menu_id and
		(enabled_p is null OR enabled_p = 't') and 
		acs_permission__permission_p(m.menu_id, :user_id, 'read')
	order by
		 sort_order
    "
    set result [list]
    db_foreach subnavbar_menus $menu_select_sql {

	# Interpret empty visible_tcl menus as always visible
	if {"" != $visible_tcl} {
	    set errmsg ""
	    set visible $admin_p; # Visible for admins, but not for normal users
	    if [catch {
		set visible [expr $visible_tcl]
	    } errmsg] {
		ns_log Error "im_sub_navbar_menu_helper: Error evalualuating menu visible_tcl=$visible_tcl: $errmsg"
		append name ": Error in $visible_tcl"
	    }
	    	    
	    if {!$visible} { continue }
	}

	lappend result [list $menu_id $package_name $label $name $url $visible_tcl]

    }
    return $result
}





ad_proc -public im_menu_admin_admin_links {
} {
    Return a list of admin links to be added to the "admin" menu
} {
    set result_list {}
    set current_user_id [ad_conn user_id]
    set return_url [im_url_with_query]

    # Append user-defined menus
    set bind_vars [list return_url $return_url]
    set links [im_menu_ul_list -no_uls 1 -list_of_links 1 "admin" $bind_vars]
    foreach link $links {
	lappend result_list $link
    }

    return $result_list
}




ad_proc -public im_navbar {
    { -loginpage_p 0 }
    { -loginpage 0 }
    { -show_context_help_p 0 }
    { main_navbar_label "" }
} {
    Setup a top navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
    The sub-menus basically consist of the "admin" section of the 
    respective page and direct sub-menus used in the sub-navbar
    tabs. Some of these links are unsuitable for a main menus, so
    they can be excluded.
    loginpage parameter is deprecated!
} {
    set user_id [ad_conn user_id]
    set locale [lang::user::locale -user_id $user_id]
    set page_url [im_component_page_url]
    if {$loginpage ne 0} { set loginpage_p $loginpage }
    set navbar [util_memoize [list im_navbar_helper -user_id $user_id -locale $locale -loginpage_p $loginpage_p -show_context_help_p $show_context_help_p -page_url $page_url $main_navbar_label]]
    return $navbar
}


ad_proc -public im_navbar_helper {
    { -user_id "" } 
    { -locale "" }
    { -page_url "" }
    { -loginpage_p 0 }
    { -show_context_help_p 0 }
    { main_navbar_label "" }
} {
    Cache helper for im_navbar
} {
    if {"" eq $user_id} { set user_id [ad_conn user_id] }
    if {"" eq $locale} { set locale [lang::user::locale -user_id $user_id] }
    if {"" eq $page_url} { set page_url [im_component_page_url] }
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {![info exists loginpage_p]} { set loginpage_p 0 }
    if {1 ne $loginpage_p} { set loginpage_p 0 }
    set ldap_installed_p [util_memoize [list db_string ldap_installed "select count(*) from apm_enabled_package_versions where package_key = 'intranet-ldap'" -default 0]]
    set url_stub [ns_conn url]
    set page_title [ad_partner_upvar page_title]
    set section [ad_partner_upvar section]
    set return_url [im_url_with_query]
    set main_menu_id [db_string main_menu "select menu_id from im_menus where label='main'" -default 0]
    set main_menu_enabled_p [db_string main_menu_enabled "select count(*) from im_menus where menu_id = :main_menu_id and enabled_p = 't'"]
    set maintenance_message [string trim [im_parameter -package_id [im_package_core_id] MaintenanceMessage "" ""]]

    # Don't show menus with the following labels:
    set skip_labels {
	users_admin users_employees users_freelancers users_unassigned users_all users_companies
	projects_admin projects_open projects_closed projects_potential
	companies_admin customers_active customers_inactive customers_potential
    }
    foreach skip_label $skip_labels { set skip_hash($skip_label) 1 }
    
    # Get toplevel menu items
    set menu_list_list [im_sub_navbar_menu_helper -locale $locale $user_id $main_menu_id]
    
    set navbar {}
    foreach menu_list $menu_list_list {
	set menu_id [lindex $menu_list 0]
	set package_name [lindex $menu_list 1]
	set label [lindex $menu_list 2]
	set name [lindex $menu_list 3]
	set url [lindex $menu_list 4]
	set visible_tcl [lindex $menu_list 5]
	set selected "unselected"

	# Find out if we need to highligh the current menu item
	if {$label eq $main_navbar_label} { set selected "selected" }
	
	# Set Menu Item Name 
	set name_key "intranet-core.[lang::util::suggest_key $name]"
	set name [lang::message::lookup "" $name_key $name]

	ns_log Notice "im_navbar_helper: label=$label, url=$url"
	
	# No menues on register and login page 
	if {!$loginpage_p && "register" != [string range [ns_conn url] 1 8] } {

	    # Manually define the "admin" links for important tabs
	    set admin_menu_list {}
	    if {$admin_p} {
		catch {
		    switch $label {
			"crm" { set admin_menu_list [im_menu_crm_admin_links] }
			"conf_items" { set admin_menu_list [im_menu_conf_items_admin_links] }
			"companies" { set admin_menu_list [im_menu_companies_admin_links] }
			"finance" { set admin_menu_list [im_menu_finance_admin_links] }
			"helpdesk" { set admin_menu_list [im_menu_tickets_admin_links] }
			"projects" { set admin_menu_list [im_menu_projects_admin_links] }
			"timesheet2_timesheet" { set admin_menu_list [im_menu_timesheet_admin_links] }
			"timesheet2_absences" { set admin_menu_list [im_menu_absences_admin_links] }
			"user" { set admin_menu_list [im_menu_users_admin_links] }
		    }
		} err_msg
	    }

	    lappend navbar [im_navbar_main_submenu \
				-admin_menu_list $admin_menu_list \
				-menu_id $menu_id \
				-user_id $user_id \
				-url $url \
				-name $name \
				-label $label \
				-selected $selected \
				-skip_labels [array get skip_hash] \
	   ]
	}	
    }


    if {$main_menu_enabled_p && !$loginpage_p && "register" ne [string range [ns_conn url] 1 8] } {
	lappend navbar "<li class='unselected'><a href='/intranet/users/view?user_id=$user_id'>
		<span>[lang::message::lookup "" intranet-core.MySettings "My Settings"]</span></a>
		<ul><li class='unselected'><a href='/intranet/users/view?user_id=$user_id'>[_ intranet-core.My_Account]</a></li>
    	    "
	# Allow changing PW only when LDAP is not installed  
	if {!$ldap_installed_p} { 
	   lappend navbar "<li class='sm-submenu-item'><a href='/intranet/users/password-update?user_id=$user_id'>[_ intranet-core.Change_Password]</a></li>"
	}
	
	if {$admin_p} {
	    set admin_text [lang::message::lookup "" intranet-core.Navbar_Admin_Text "Click here to configure this navigation bar"]
	    set admin_url [export_vars -base "/intranet/admin/menus/index" {{top_menu_id $main_menu_id} {top_menu_depth 1} return_url }]
	    lappend navbar "<li class='unselected'><a href=\"$admin_url\"><span>[im_gif -translate_p 0 wrench $admin_text]</span></a></li>"
	}
	lappend navbar "</ul>"
    }

    return "
	    <div id=\"main\">
	       <div id=\"navbar_main_wrapper\">
		  <ul id=\"navbar_main\" class=\"sm\">[join $navbar "\n\n"]</ul>
	       </div>
	       <div id=\"main_header\">
                  <div id=\"main_maintenance_bar\">$maintenance_message</div>
	       </div>
	    </div>
    "
}


ad_proc -public im_navbar_main_submenu {
    { -admin_menu_list {}}
    { -user_id "" }
    -menu_id:required
    -url:required 
    -name:required
    -label:required
    -selected:required
    { -skip_labels {}}
} {
    Builds the sub-menu items for each of the main tabs in im_navbar.
} {
    if {"" == $user_id} { set user_id [ad_conn user_id] }

    # Check for sub-menus
    set tab_menu [im_navbar_main_submenu_recursive -no_outer_ul_p 1 -locale locale -user_id $user_id -menu_id $menu_id -skip_labels $skip_labels]

    # Add the "admin links" 
    set tab_admin ""
    foreach admin_menu_list_item $admin_menu_list {
	set item_text [lindex $admin_menu_list_item 0]
	set item_url [lindex $admin_menu_list_item 1]
	set item "<li class='unselected'><a href='$item_url'><span>$item_text</span></a></li>\n"
	# Add a "wrench" with a link to admin the menu
	if {4 == [llength $admin_menu_list_item] } {
	    set wrench_url [lindex $admin_menu_list_item 3]
	    set item "<li class='unselected'>
		<div class=\"sm-po-sub-menu-item\">
			<div class='sm-po-sub-menu-item-name'><a href='$item_url'>$item_text</a></div>
			<div class='sm-po-sub-menu-item-wrench'><img src=\"/intranet/images/navbar_default/wrench.png\" alt=\"\"onclick=\"location.href='$wrench_url';\"/></div>
		</div>
		</li>\n"
	}
	append tab_admin $item
    }

    # Join tab_admin and tab_menu together
    if {"" ne $tab_admin && "" ne $tab_menu} {
	# There are both sub-menus and admin menus, so join together with a separator
	set tab $tab_menu
	append tab "<li class=\"unselected divider\"><hr/></li>\n"
	append tab $tab_admin
    } else {
	# Only one of the two components contains data, so just join together
	set tab $tab_admin
	append tab $tab_menu
    }


    if {"" eq $tab} { 
	# Use simplified tab if there are no sub-elements at all
	set tab "<li class='$selected'><a href='$url'><span>$name</span></a></li>" 
    } else {
	# Main level of the tab. Opens up a UL for sub-elements
	set tab "<li class='$selected'><a class='has-submenu' href='$url'><span>$name</span></a>\n<ul>\n$tab\n</ul>\n"
    }

    return $tab
}


ad_proc -public im_navbar_main_submenu_recursive {
    {-no_outer_ul_p 0}
    -locale:required
    -user_id:required
    -menu_id:required
    {-skip_labels {}}
} {
    Builds menu HTML code for all sub-items of the menu_id provided. 
    Optimized for smartmenus.org
} {
    array set skip_hash $skip_labels

    set menu_list_list [util_memoize [list im_sub_navbar_menu_helper -locale $locale $user_id $menu_id]]
    set output_ul ""
    foreach menu_list $menu_list_list {
	set menu_id [lindex $menu_list 0]
	set package_name [lindex $menu_list 1]
	set label [lindex $menu_list 2]
	set name [lindex $menu_list 3]
	set url [lindex $menu_list 4]
	set visible_tcl [lindex $menu_list 5]
	set selected "unselected"

	# Skip if part of the hash
	if {[info exists skip_hash($label)]} { continue }

	regsub -all {[^0-9a-zA-Z]} $name "_" name_key
	set name_l10n [lang::message::lookup "" $package_name.$name_key $name]

	# Check for sub items 
	set count [db_string sql "select count(*) from im_menus where parent_menu_id = $menu_id" -default 0]
	if {$count} {
	    append output_ul "<li class='unselected'><a class='has-submenu' href='$url'><span>$name_l10n</span></a>\n"
	    append output_ul [im_navbar_main_submenu_recursive -locale $locale -user_id $user_id -menu_id $menu_id -skip_labels $skip_labels]
	    append output_ul "</li>\n"
	} else {
	    append output_ul "<li class='unselected'><a href='$url'><span>$name_l10n</span></a></li>\n"
	}   
    }

    if {$no_outer_ul_p} {
	return $output_ul
    } else {
	return "<ul>\n$output_ul\n</ul>\n"
    }
}




ad_proc -public im_design_user_profile_string { 
    -user_id:required
} {
    Determine a pretty string for the type of user that it is:
} {
    if {"" eq $user_id} { return "" }

    set group_sql "
	select	g.group_name,
		CASE 
			WHEN group_name = 'P/O Admins' THEN 100
			WHEN group_name = 'Senior Managers' THEN 90
			WHEN group_name = 'Project Managers' THEN 80
			WHEN group_name = 'Accounting' THEN 70
			WHEN group_name = 'Sales' THEN 60
			WHEN group_name = 'HR Managers' THEN 50
			WHEN group_name = 'Helpdesk' THEN 40
			WHEN group_name = 'Freelancers' THEN 30
			WHEN group_name = 'Customers' THEN 30
			WHEN group_name = 'Partners' THEN 30
			WHEN group_name = 'Employees' THEN 10
			WHEN group_name = 'Registered Users' THEN 10
			WHEN group_name = 'The Public' THEN 5
		ELSE 0 END as sort_order
	from	acs_rels r, 
		groups g,
		im_profiles p
	where
		g.group_id = p.profile_id and
		r.object_id_one = g.group_id and 
		r.rel_type = 'membership_rel' and 
		r.object_id_two = $user_id
	order by
		sort_order DESC;
    "
    set group_names [util_memoize [list db_list memberships $group_sql] 120]
    set group_name [lindex $group_names 0]
    regsub -all " " $group_name "_" group_key
    set user_profile [lang::message::lookup "" intranet-core.group_key $group_name]
    return $user_profile
}


ad_proc -public im_header_plugins { 
} {
    Determines the contents for left & right header plugins.
    Returns an array with keys "left" and "right"
} {
    set user_id [ad_conn user_id]
    set locale [lang::user::locale -user_id $user_id]

    return [util_memoize [list im_header_plugins_helper -locale $locale -user_id $user_id]]
}

ad_proc -public im_header_plugins_helper { 
    {-user_id "" }
    {-locale "" }
} {
    Determines the contents for left & right header plugins.
    Returns an array with keys "left" and "right"
} {
    if {"" == $user_id} { set user_id [ad_conn user_id] }
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set plugin_left_html ""
    set plugin_right_html ""

    # Any permissions set at all? We'll disable perms in this case.
    set any_perms_set_p [im_component_any_perms_set_p]

    set plugin_sql "
	select	c.*,
		acs_permission__permission_p(c.plugin_id, :user_id, 'read') as perm
	from	im_component_plugins c
	where	location like 'header%'
	order by sort_order
    "
    db_foreach get_plugins $plugin_sql {

	if {$any_perms_set_p > 0} { if {"f" == $perm} { continue } }
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

    return [list left $plugin_left_html right $plugin_right_html]
}


ad_proc -public im_header_logout_component {
    -page_url:required
    -return_url:required
    -user_id:required
} {
    Switch - Redesigning Navbar/Header for version 5    
} {
    # LDAP installed?
    set ldap_sql "select count(*) from apm_enabled_package_versions where package_key = 'intranet-ldap'"
    set ldap_installed_p [util_memoize [list db_string otp_installed $ldap_sql -default 0]]
    
    set change_pwd_url "/intranet/users/password-update?user_id=$user_id"
    set add_comp_url [export_vars -quotehtml -base "/intranet/components/add-stuff" {page_url return_url}]
    set reset_comp_url [export_vars -quotehtml -base "/intranet/components/component-action" {page_url {action reset} {plugin_id 0} return_url}]
    
    set add_stuff_text [lang::message::lookup "" intranet-core.Add_Portlet "Add Portlet"]
    set reset_stuff_text [lang::message::lookup "" intranet-core.Reset_Portlets "Reset Portlets"]
    set reset_stuff_link "<a href=\"$reset_comp_url\">$reset_stuff_text</a> |\n"
    set add_stuff_link "<a href=\"$add_comp_url\">$add_stuff_text</a>\n"
    set log_out_link "<a class=\"nobr\" href='/register/logout'>[_ intranet-core.Log_Out]</a>\n"
    
    # Disable who's online for "anonymous visitor"
    if {0 == $user_id} {
	set log_out_link ""
    }
    return $log_out_link
}

ad_proc -public im_header { 
    { -no_head_p "0"}
    { -no_master_p "0"}
    { -loginpage:boolean 0 }
    { -body_script_html "" }
    { -show_context_help_p 0 }
    { page_title "" } 
    { extra_stuff_for_document_head "" } 
} {
    The default header for ]project-open[.<br>

    You can't just replace this function by a "blank_master.ad"
    or similar, because this procedure is called both "stand alone"
    from a report pages (HTTP streaming without template!) and as
    part of an OpenACS template.

} {
    im_performance_log -location im_header
    
    upvar head_stuff head_stuff
    
    # --------------------------------------------------------------
    # Defaults & Security
    set untrusted_user_id [ad_conn untrusted_user_id]
    set user_id [ad_conn user_id]
    if {0 != $user_id} { set untrusted_user_id $user_id }
    set user_name [im_name_from_user_id $user_id]
    set return_url [im_url_with_query]
    
    # Is any of the "search" package installed?
    set search_installed_p [llength [info procs im_package_search_id]]
    
    if { $page_title eq "" } {
	set page_title [ad_partner_upvar page_title]
    }
    set context_bar [ad_partner_upvar context_bar]
    set page_focus [ad_partner_upvar focus]
    
    # Get browser inf   
    set browser_version [im_browser_version]
    set browser [lindex $browser_version 0]
    set version [lindex $browser_version 1]
    set version_pieces [split $version "."]
    set version_major [lindex $version_pieces 0]
    set version_minor [lindex $version_pieces 1]

    # --------------------------------------------------------------
    
    if {$search_installed_p && $page_focus eq "" } {
	# Default: Focus on Search form at the top of the page
	set page_focus "surx.query_string"
    }
    if { $extra_stuff_for_document_head eq "" } {
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    }

    # ns_log Notice "intranet-design-procs:: Browser: $browser, version_major: $version_major"

    # Avoid Quirks mode with IE<10 due to missing doctype 
    # DOCTYPE definition might be added to document in multiple places. 
    
    if {[catch {
	if { "msie" == $browser && $version_major < 10 } {
	    # ns_log Notice "intranet-design-procs:: Setting META TAG" 
	    set extra_stuff_for_document_head "<meta http-equiv=\"X-UA-Compatible\" content=\"IE=10\" />\n"
	}
    } err_msg]} {
	ns_log Error "intranet-design-procs: Error handling browser version"
	return
    }
    
    # The document language is always set from [ad_conn lang] which by default 
    # returns the language setting for the current user.  This is probably
    # not a bad guess, but the rest of OpenACS must override this setting when
    # appropriate and set the lang attribxute of tags which differ from the language
    # of the page.  Otherwise we are lying to the browser.
    set doc(lang) [ad_conn language]
    
    # Determine if we should be displaying the translation UI
    if {"1" eq [lang::util::translator_mode_p]} { template::add_footer -src "/packages/acs-lang/lib/messages-to-translate" }
    set search_form [im_header_search_form]
    set user_profile [im_design_user_profile_string -user_id $untrusted_user_id]
    
    append extra_stuff_for_document_head [im_stylesheet]
    append extra_stuff_for_document_head "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n"
    append extra_stuff_for_document_head "<!--\[if lt IE 7.\]>\n<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>\n<!\[endif\]-->\n"
    
    # Developer support is installed and enabled
    template::head::add_css -href "/resources/acs-developer-support/acs-developer-support.css" -media "all"
    set developer_support_p [expr { [llength [info procs ::ds_show_p]] == 1 && [ds_show_p] }]
    if {$developer_support_p} {
	if {$developer_support_p} {
	    if { !$no_head_p } { template::add_header -src "/packages/acs-developer-support/lib/toolbar" }
	    template::add_footer -src "/packages/acs-developer-support/lib/footer"
	}
    }
    
    template::head::add_css -href "/resources/acs-subsite/default-master.css" -media "all"
    
    # Extract multirows for header META, CSS, STYLE & SCRIPT etc. from global variables
    template::head::prepare_multirows
    set event_handlers [template::get_body_event_handlers]
    
    template::multirow foreach meta {
	set row "<meta"
	if {"" != $http_equiv} {  append row " http-equiv='$http_equiv'" }
	if {"" != $name} {  append row " name='$name'" }
	if {"" != $scheme} {  append row " scheme='$scheme'" }
	if {"" != $lang} {  append row " lang='$lang'" }
	append row " content='$content'>\n"
	append extra_stuff_for_document_head $row
    }
    
    template::multirow foreach link {
	set row "<link rel='$rel' href='$href'"
	if {"" != $lang} {  append row " lang='$lang'" }
	if {"" != $title} {  append row " title='$title'" }
	if {"" != $type} {  append row "  type='$type'" }
	if {"" != $media} {  append row " media='$media'" }
	append row ">\n"
	append extra_stuff_for_document_head $row
    }
    
    template::multirow foreach headscript {
	set row "<script type='$type'"
	if {"" != $src} {  append row " src='$src'" }
	if {"" != $charset} {  append row " charset='$charset'" }
	if {"" != $defer} {  append row " defer='$defer'" }
	append row ">"
	if {"" != $content} {  append row " $content" }
	append row "</script>\n"
	append extra_stuff_for_document_head $row
    }
    
    # --------------------------------------------------------------
    
    
    # Get the contents of the header plugins
    array set header_plugins [im_header_plugins]
    set plugin_right_html $header_plugins(right)
    set plugin_left_html $header_plugins(left)
    
    set page_url [im_component_page_url]
    set logo [im_logo]
    set report_bug_lnk ""


    # Feedback Bar Icon 
    set feedback_bar_icon "<span id=\"general_messages_icon\"><span id=\"general_messages_icon_span\"></span></span>&nbsp;"
    
    # Welcome 
    set welcome_txt "<span class='header_welcome'>" 
    append welcome_txt "<a href=\"/intranet/users/view?user_id=$untrusted_user_id\">[lang::message::lookup "" intranet-core.Welcome_User_Name "Welcome %user_name%"]</span></a> |"

    set users_online_txt ""
    if { "register" != [string range [ns_conn url] 1 8] } { set users_online_txt "&nbsp;[im_header_users_online_str] |" }
    
    # Report BUG 
    if {!$loginpage_p} {
	set report_bug_btn_link [export_vars -base "/intranet/report-bug-on-page" {{page_url [im_url_with_query]}}]
	set report_bug_lnk "&nbsp;<a href=\"$report_bug_btn_link\">[lang::message::lookup "" intranet-core.Report_a_bug_on_this_page "Report a bug on this page"]</a> |"
    }
    
    # Context help 
    if { $show_context_help_p } {
	set context_help_lnk "&nbsp;<a href=\"[im_navbar_help_link]\">[lang::message::lookup "" intranet-core.Context_Help "Context Help"]</a> |"
    } else {
	set context_help_lnk ""
    }
    
    # Logout 
    set logout_lnk "&nbsp;[im_header_logout_component -page_url $page_url -return_url $return_url -user_id $user_id]"
    
    # Portlets 
    set reset_stuff_link ""
    set add_stuff_link ""

    regsub -all {[^a-z0-9\-\/]} $page_url "" page_url_mangled
    set show_portlets_sql "select count(*) from im_component_plugins where page_url = '$page_url_mangled'"
    set show_portlets_p [util_memoize [list db_string show_portlets_p $show_portlets_sql -default 0]]

    if { "register" != [string range [ns_conn url] 1 8] && $show_portlets_p } { 
	set add_comp_url [export_vars -quotehtml -base "/intranet/components/add-stuff" {page_url return_url}]
	set reset_comp_url [export_vars -quotehtml -base "/intranet/components/component-action" {page_url {action reset} {plugin_id 0} return_url}]
	set add_stuff_text [lang::message::lookup "" intranet-core.Add_Portlet "Add Portlet"]
	set reset_stuff_text [lang::message::lookup "" intranet-core.Reset_Portlets "Reset Portlets"]
	set reset_stuff_link "&nbsp;<a href=\"$reset_comp_url\">$reset_stuff_text</a>&nbsp;|"
	set add_stuff_link "&nbsp;<a href=\"$add_comp_url\">$add_stuff_text</a>&nbsp;|"
    }

    # Build buttons 
    if {$loginpage_p} { 
	set header_buttons "" 
    } else {
	set header_buttons "${welcome_txt}${users_online_txt}${add_stuff_link}${reset_stuff_link}${context_help_lnk}${report_bug_lnk}<span class='header_logout'>$logout_lnk</span>"
    }
    
    set header_skin_select [im_skin_select_html $untrusted_user_id [im_url_with_query]]
    if {$header_skin_select ne ""} {
	set header_skin_select "<span id='skin_select'>[_ intranet-core.Skin]:</span> $header_skin_select"
    }
    # fraber 121020: disable skin, because the others do not work
    set header_skin_select ""
    if {$loginpage_p} { set header_skin_select "" }
    
    # --------------------------------------------------------------------
    # Temporary (?) fix to get xinha working
    
    if {[info exists ::acs_blank_master(xinha)]} {
	set xinha_dir /resources/acs-templating/xinha-nightly/
	set xinha_lang [lang::conn::language]
	
	# We could add site wide Xinha configurations (.js code) into xinha_params
	set xinha_params ""
	
	# Per call configuration
	set xinha_plugins $::acs_blank_master(xinha.plugins)
	set xinha_options $::acs_blank_master(xinha.options)
	
	# HTML ids of the textareas used for Xinha
	set htmlarea_ids '[join $::acs_blank_master__htmlareas "','"]'
	
	append extra_stuff_for_document_head "
	    	   <script type=\"text/javascript\">
	    	   	   _editor_url = \"$xinha_dir\";
			   _editor_lang = \"$xinha_lang\";
	    	   </script>
		   <script type=text/javascript src=\"${xinha_dir}htmlarea.js\"></script>
		   "

	set xi "HTMLArea"
	append body_script_html "
	        <script type='text/javascript'>
		<!--
		 xinha_editors = null;
		 xinha_init = null;
		 xinha_config = null;
		 xinha_plugins = null;
		 xinha_init = xinha_init ? xinha_init : function() {
		    xinha_plugins = xinha_plugins ? xinha_plugins : \[$xinha_plugins\];
	
		    // THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  
		    if(!$xi.loadPlugins(xinha_plugins, xinha_init)) return;
	
		    xinha_editors = xinha_editors ? xinha_editors :\[ $htmlarea_ids \];
		    xinha_config = xinha_config ? xinha_config() : new $xi.Config();
		    $xinha_params
		    $xinha_options
		    xinha_editors = $xi.makeEditors(xinha_editors, xinha_config, xinha_plugins);
		    $xi.startEditors(xinha_editors);
		 }
		 window.onload = xinha_init;
		 // -->
		 </script>
		 <textarea id=\"holdtext\" style=\"display: none;\" rows=\"1\" cols=\"1\"></textarea>
	   "
    }

    im_performance_log -location im_header_end
    
    set header_html [template::get_header_html]
    
    set return_html "
		<!DOCTYPE html>
		<head>
		$extra_stuff_for_document_head
		<title>$page_title</title>
		</head>
		$body_script_html
		$header_html
		<div id=\"monitor_frame\">
    	"

    if { !$no_head_p } {
	append return_html "
	      <div id=\"header_class\">
	      <div id=\"header_logo\">
		 $logo
	      </div>
	      <div id=\"header_plugin_left\">
		 $plugin_left_html
	      </div>
	      <div id=\"header_plugin_right\">
		 $plugin_right_html
	      </div>
	      <div class=\"header_line\">
			<table cellpadding='0' cellspacing='0' border='0'>
			<tr>
			<td>$feedback_bar_icon</td>
			<td><span class='header_buttons'>$header_buttons</span></td>
			</tr>
			<tr>
			<td colspan=2><div id=\"main_search\">[im_header_search_form]</div></td>
			</tr>
			</table>
	      </div>
	      <div id=\"header_skin_select\">
		 $header_skin_select
	      </div>   
	   </div>
    	 "
    }
    return $return_html

}



ad_proc -private im_header_users_online_str { } {
    A string to display the number of online users
} {
    # Enable "Users Online" mini-component for OpenACS 5.1 only
    set users_online_str ""

    set proc "num_users"
    set namespace "whos_online"

    if {$proc eq [namespace eval $namespace "info procs $proc"]} {
	set num_users_online [lc_numeric [whos_online::num_users]]
	if {1 == $num_users_online} { 
	    set users_online_str "<a href=\"/intranet/whos-online\">[_ intranet-core.lt_num_users_online_user]</a>\n"
	} else {
	    set users_online_str "<a href=\"/intranet/whos-online\">[_ intranet-core.lt_num_users_online_user_1]</a>\n"
	}
    }

    return $users_online_str

}


ad_proc -private im_header_search_form {} {
    Search form for header of page
} {
    set user_id [ad_conn user_id]
    set search_installed_p [llength [info procs im_package_search_id]]

    if {[im_permission $user_id "search_intranet"] && $user_id > 0 && $search_installed_p} {
	set alt_go [lang::message::lookup "" intranet-core.Search_Go_Alt "Search through all full-text indexed objects."]
	return "
	      <form action=\"/intranet/search/go-search\" method=\"post\" name=\"surx\">
		<input class=surx name=query_string size=40 value=\"[_ intranet-core.Search]\" onClick=\"javascript:this.value = ''\">
		<input type=\"hidden\" name=\"target\" value=\"content\">
		<input alt=\"$alt_go\" type=\"submit\" value=\"[_ intranet-core.Action_Go]\" name=\"image\">
	      </form>
	"
    }
    return ""
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

      <table border=0 cellspacing=0 cellpadding=0 width=\"100%\">
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
	    <table cellpadding=1 width=\"100%\">
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
    im_performance_log -location im_footer


    set footer_html ""
    if {[im_openacs54_p]} {
        set footer_html [template::get_footer_html]
    }

    return "
    </div> <!-- monitor_frame -->
    <div class=\"footer_hack\">&nbsp;</div>	
    <div id=\"footer\" style=\"visibility: visible\">
       [_ intranet-core.Comments] [_ intranet-core.Contact]: 
       <a href=\"mailto:[im_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]\">
	  [im_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]</a>.
    </div>
  $footer_html
  </BODY>
</HTML>
"
}


ad_proc -public im_stylesheet {} {
    Intranet CSS style sheet. 
} {
    set user_id [ad_conn user_id]
    set html ""
    set openacs54_p [im_openacs54_p]
    set css "/resources/acs-subsite/site-master.css"

    # Setting Skin 
    set skin_name [im_user_skin $user_id]
    set skin_name_version [im_user_skin_version $user_id]
    set skin_path "[acs_root_dir]/packages/intranet-core/www/js/style.$skin_name.js"
    set skin_exists_p [util_memoize [list file exists $skin_path]]
    if {$skin_exists_p} { set skin $skin_name } else { set skin "default" }
    set system_css "/intranet/style/style.$skin.css?v=$skin_name_version"

    # META Tags
    template::head::add_meta -name generator -lang en -content "OpenACS version [ad_acs_version]" 

    # Include Default JS/CSS 
    if {[llength [info procs im_package_calendar_id]] && [permission::permission_p -object_id [package_calendar_id] -privilege read]} { 
	template::head::add_css -href "/calendar/resources/calendar.css" -media "screen" -order "5" 
    }
    template::head::add_css -href "/intranet/style/print.css" -media "print" -order "10" 
    template::head::add_css -href "/resources/acs-templating/mktree.css" -media "screen" -order "15" 
    template::head::add_css -href "/intranet/style/smartmenus/sm-core-css.css" -media "screen" -order "25"
    template::head::add_css -href "/intranet/style/smartmenus/sm-simple/sm-simple.css" -media "screen" -order "30"
  
    template::head::add_css -href $system_css -media "screen" -order "40" 
    template::head::add_css -href "/resources/acs-templating/lists.css" -media "screen" 
    template::head::add_css -href "/resources/acs-templating/forms.css" -media "screen" 

    template::head::add_javascript -src "/intranet/js/jquery.min.js" -order "10" 

    template::head::add_javascript -src "/resources/acs-templating/mktree.js" -order "20" 
    template::head::add_javascript -src "/intranet/js/rounded_corners.inc.js" -order "30" 
    template::head::add_javascript -src "/resources/diagram/diagram/diagram.js" -order "40" 
    template::head::add_javascript -src "/intranet/js/showhide.js" -order "50" 
    template::head::add_javascript -src "/resources/acs-subsite/core.js" -order "60" 
    template::head::add_javascript -src "/intranet/js/smartmenus/jquery.smartmenus.min.js" -order "70" 
    template::head::add_javascript -src "/intranet/js/style.$skin.js" -order "999" 
	
    return $html
}


ad_proc -public im_logo {} {
    Intranet System Logo
} {
    set system_url [im_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
    set system_logo [im_parameter -package_id [im_package_core_id] SystemLogo "" ""]
    set system_logo_link [im_parameter -package_id [im_package_core_id] SystemLogoLink "" "http://www.project-open.com/"]

    if {$system_logo eq ""} {
	set user_id [ad_conn user_id]
	set skin_name [im_user_skin $user_id]
	
	if {[file exists "[acs_root_dir]/packages/intranet-core/www/images/logo.$skin_name.gif"]} {
	    set system_logo "$system_url/intranet/images/logo.$skin_name.gif"
	} else {
	    set system_logo "$system_url/intranet/images/logo.default.gif"
	}
    }
    # if { "0" != [ad_conn user_id] } {
	return "\n<a href=\"$system_logo_link\"><img id='intranetlogo' src=\"$system_logo\" alt=\"logo\" border='0'></a>\n"
    # } else {
    #	return "\n<a href=\"$system_logo_link\"><img id='intranetlogo' src=\"logo.gif\" alt=\"logo\" border='0'></a>\n"
    # }
}


ad_proc -public im_navbar_gif_url {} {
    Path to access the Navigation Bar corner GIFs
} {
    set user_id [ad_conn user_id]
    set locale [lang::user::locale -user_id $user_id]

    return [util_memoize [list im_navbar_gif_url_helper -locale $locale -user_id $user_id] 60]
}

ad_proc -public im_navbar_gif_url_helper {
    {-user_id "" }
    {-locale "" }
} {
    Path to access the Navigation Bar corner GIFs
} {
    if {"" == $user_id} { set user_id [ad_conn user_id] }
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set navbar_gif_url "/intranet/images/[im_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "/intranet/images/navbar_default"]"
    set org_navbar_gif_url $navbar_gif_url

    # Old parameter? Shell out a warning and use the last part
    set navbar_pieces [split $navbar_gif_url "/"]
    set navbar_pieces_len [llength $navbar_pieces]
    if {$navbar_pieces_len > 1} {
	set navbar_gif_url [lindex $navbar_pieces $navbar_pieces_len-1]
#	ns_log Notice "im_navbar_gif_url: Found old-stype SystemNavbarGifPath parameter - using only last part: '$org_navbar_gif_url' -> '$navbar_gif_url'"
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

    set min_records [im_parameter -package_id [im_package_core_id] NumberResultsPerPage "" 50]
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
    if { $query_args ne "" } {
	append url "$query_args&amp;"
    }
    
    set html_list [list]
    foreach l [im_all_letters_lowercase] {
	if {$l ni $initial_list} {
	    # This means no user has this initial
	    lappend html_list "<font color=gray>$l</font>"
	} elseif { $l eq $letter  } {
	    lappend html_list "<b>$l</b>"
	} else {
	    lappend html_list "<a href=\"${url}letter=$l\">$l</a>"
	}
    }
    if { $letter eq "" || $letter eq "all"  } {
	lappend html_list "<b>[_ intranet-core.All]</b>"
    } else {
	lappend html_list "<a href=\"${url}letter=all\">All</a>"
    }
    if { $letter eq "scroll"  } {
	lappend html_list "<b>[_ intranet-core.Scroll]</b>"
    } else {
	lappend html_list "<a href=\"${url}letter=scroll\">[_ intranet-core.Scroll]</a>"
    }
    return [join $html_list " | "]
}

ad_proc im_alpha_bar { 
    {-prev_page_url ""}
    {-next_page_url ""}
    target_url 
    default_letter 
    bind_vars
} {
    Returns a horizontal alpha bar with links
    @param default_letter none: no alpha bar at all no_alpha: only back/forth
} {
    set alpha_list [im_all_letters_lowercase]
    set alpha_list [linsert $alpha_list 0 All]
    set default_letter [string tolower $default_letter]

    # "none" is a special value for no alpha-bar at all
    if {"none" eq $default_letter} { return "&nbsp;" }

    ns_set delkey $bind_vars "letter"
    set params [list]
    set len [ns_set size $bind_vars]
    for {set i 0} {$i < $len} {incr i} {
	set key [ns_set key $bind_vars $i]
	set value [ns_set value $bind_vars $i]
	if {$value ne "" } {
	    lappend params "$key=[ns_urlencode $value]"
	}
    }
    set param_html [join $params "&amp;"]

    set html "<ul id=\"alphabar\">"

    if {$prev_page_url ne "" } {
	append html "<li><a href=\"$prev_page_url\">&lt;&lt</a></li>"
    }

    # "no_alpha" is a special value for an alpha-bar without letter and only back/forth
    if {"no_alpha" ne $default_letter } {
	foreach letter $alpha_list {
	    set letter_key "intranet-core.[lang::util::suggest_key $letter]"
	    set letter_trans [lang::message::lookup "" $letter_key $letter]
	    if {$letter eq $default_letter} {
		append html "<li class=\"selected\"><div class=\"navbar_selected\"><a href=\"$url\">$letter_trans</a></div></li>\n"
	    } else {
		set url "$target_url?letter=$letter&amp;$param_html"
		append html "<li class=\"unselected\"><a href=\"$url\">$letter_trans</a></li>\n"
	    }
	}
    }

    if {$next_page_url ne "" } {
	append html "<li><a href=\"$next_page_url\">&gt;&gt</a></li>"
    }

    append html "</ul>"
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
    set system_url [im_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
    set publisher_name [im_parameter -package_id [ad_acs_kernel_id] PublisherName "" ""]
    set core_version "2.0"
    set error_user_id [ad_conn user_id]
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

    set report_url [im_parameter -package_id [im_package_core_id] "ErrorReportURL" "" ""]
    if { $report_url eq "" } {
	ns_log Error "Automatic Error Reporting Misconfigured.  Please add a field in the acs/rp section of form ErrorReportURL=http://your.errors/here."
	set report_url "http://www.project-open.net/intranet-forum/forum/new-system-incident"
    } 

    set error_info ""
    if {![im_parameter -package_id [ad_acs_kernel_id] "RestrictErrorsToAdminsP" "" 0] || [permission::permission_p -object_id [ad_conn package_id] -privilege admin] } {
	set error_info $message
    }
    
    ns_returnerror 500 "
[im_header_emergency "[_ intranet-core.Request_Error]"]
<form method=post action=$report_url>
[export_vars -form {error_url error_info error_first_names error_last_name error_user_email system_url publisher_name core_version}]
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
    if { (![info exists node_id] || $node_id eq "") } {
	set node_id [ad_conn node_id]
    }

    set context [list [list "/intranet/" "&\#93;project-open&\#91;"]]

    if {[llength $args] == 0} {
	# fix last element to just be literal string
	set context [lreplace $context end end [lindex $context end 1]]
    } else {
	if {![string match "\{*" $args]} {
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
    foreach element [lrange $context 0 [llength $context]-2] {
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
    return [im_gif -translate_p 0 "bb_$color" $alt_text $border $size $size]
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

ad_proc -public im_box_header { 
    title 
    {icons ""}
} {
} {
     return " 
	<div class=\"component\">

	<table width=\"100%\">
	<tr>
	<td>
	  <div class=\"component_header_rounded\" >
	    <div class=\"component_header\">
	      <div class=\"component_title\">$title</div>
	      <div class=\"component_icons\">$icons</div>
	    </div>
	  </div>
	</td>
	</tr>
	<tr>
	<td colspan=2>
	  <div class=\"component_body\">"
}

ad_proc -public im_box_footer {} {
} {
    return "
	  </div>
	  <div class=\"component_footer\">
	    <div class=\"component_footer_hack\"></div>
	  </div>

	</td>
	</tr>
	</table>
	</div>
    "
}

ad_proc -public im_user_skin { user_id } {
    Returns the name of the current skin
} {
    set locale [lang::user::locale -user_id $user_id]
    return [util_memoize [list im_user_skin_helper -locale $locale $user_id]]
}

ad_proc -public im_user_skin_version { user_id } {
    Returns the name of the current skin version 
} {
    return [util_memoize [list im_user_skin_version_helper $user_id]]
}


ad_proc -public im_user_skin_helper { 
    {-locale "" }
    user_id 
} {
    Returns the name of the current skin - uncached
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set skin_name ""
    set skin_id_exists_p [im_column_exists users skin_id]
    if {$skin_id_exists_p} {
	set skin_name [db_string sid "select im_category_from_id(skin_id) from users where user_id = :user_id" -default ""]
    }
#    if {"" == $skin_name} { set skin_name "default" }
    if {"" == $skin_name} { set skin_name "saltnpepper" }
    return $skin_name
}

ad_proc -public im_user_skin_version_helper {
    user_id
} {
    Returns the version number of the current skin - uncached
} {
    set skin_id_exists_p [im_column_exists users skin_id]
    if {$skin_id_exists_p} {
	# Get Skin Name for this user 
	set skin_name [im_user_skin $user_id]
	if {"" == $skin_name} { set skin_name "saltnpepper" }
        set skin_name_version [db_string sid "select aux_string1 from im_categories where category_type = 'Intranet Skin' and category = :skin_name" -default 0]
	if { "" == $skin_name_version } { return 0 } else { return $skin_name_version }
    } else {
	return 0 
    }
}

ad_proc -public im_skin_select_html { 
    user_id 
    return_url 
} {
    if {!$user_id} { return "" }
    if {![string is integer $user_id]} { im_security_alert -location "im_skin_select_html" -message "user_is is not an integer" -value $user_id -severity "Normal" }

    set skin_id_exists_p [im_column_exists users skin_id]
    if {!$skin_id_exists_p} {
	im_permission_flush
	return "Error: Column users.skin_id doesn't exist.<br>Please run intranet-core V3.4.0.4.0 upgrade script."
    }

   set current_skin_id [util_memoize [list db_string skin_id "select skin_id from users where user_id = $user_id" -default ""] 60]

   set skin_select_html "
	<form method=\"GET\" action=\"/intranet/users/select-skin\">
	[export_vars -form {return_url user_id}]
	[im_category_select \
		-translate_p 1 \
		-include_empty_p 0 \
		-plain_p 0 \
		-cache_interval 3600 \
		"Intranet Skin" \
		skin_id \
		$current_skin_id \
	]
       <input type=submit value=\"[_ intranet-core.Change]\">
       </form>
    "
    
    return $skin_select_html
}



ad_proc -public im_browser_is_mobile_p {
    {-user_agent ""}
} {
    Returns true if mobile browser or tablet
} {
    if {"" == $user_agent} {
	# Extract variables from form and HTTP header
	set header_vars [ns_conn headers]
	set user_agent [string tolower [ns_set get $header_vars "User-Agent"]]
    }

    set mobile_p [regexp {(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|\/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|cond|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|topl|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto} $user_agent match]
    ns_log Notice "im_browser_is_mobile_p: user_agent=$user_agent, mobile_p=$mobile_p"

    return $mobile_p
}

ad_proc -public im_browser_version { } {
    Extracts the browser identifcation from the User-Agent HTTP header
} {
    # Extract variables from form and HTTP header
    set header_vars [ns_conn headers]
    set user_agent [ns_set get $header_vars "User-Agent"]
    
    set mozilla_version ""
    set firefox_version ""
    set chrome_version ""
    set msie_version ""
    set opera_version ""
    set lynx_version ""

    set browser "Other"
    set version "0.0.0"
    
    if {[regexp {Mozilla/(.\..)} $user_agent match mozilla_version]} {
	set browser "mozilla"
	set browser_version $mozilla_version
    }
    
    if {[regexp {Firefox/([0-9_\-\.]+)} $user_agent match firefox_version]} {
	set browser "firefox"
	set version $firefox_version
    }
    
    if {[regexp {Chrome/([0-9_\-\.]+)} $user_agent match chrome_version]} {
	set browser "chrome"
	set version $chrome_version
    }
    
    if {[regexp {Opera/([0-9_\-\.]+)} $user_agent match opera_version]} {
	set browser "opera"
	set version $opera_version
    }
    
    if {[regexp {Lynx/([0-9_\-\.]+)} $user_agent match lynx_version]} {
	set browser "lynx"
	set version $lynx_version
    }
    
    if {[regexp {MSIE\W([0-9_\-\.]+)} $user_agent match msie_version]} {
	set browser "msie"
	set version $msie_version
    }

    return [list $browser $version]
}


ad_proc -public im_browser_warning { } {
    Return "", or a warning string if the user is running an unsupported browser
} {
    set browser_version [im_browser_version]
    set browser [lindex $browser_version 0]
    set version [lindex $browser_version 1]
    
    set version_pieces [split $version "."]
    set version_major [lindex $version_pieces 0]
    set version_minor [lindex $version_pieces 1]
    
#    ad_return_complaint 1 "browser_version=$browser_version, $browser=$browser, version_major=$version_major, version_minor=$version_minor"

    set po "&\#93;project-open&\#91;"
    set msg [lang::message::lookup "" intranet-core.Browser_Warning_Msg "Your browser '%browser% %version_major%.x' may not render all pages correctly with this version of $po. <br>We recommend you to upgrade your browser to a more recent version."]
    
    switch $browser {
	firefox {
	    # Firefox 1.x may give trouble
	    switch $version_major {
		1 { return $msg }
	    }
	}
	chrome {
	    # Should be updated, so don't show anything
	}
	opera {
	    # Should update regularly, so don't show any warning
	}
	lynx {
	    # Text browser, that's a tough fucker...
	}
	msie {
	    # 7.0 and 8.0 are OK, but 6.x may give some issues
	    switch $version_major {
		3 { return $msg }
		4 { return $msg }
		5 { return $msg }
		6 { return $msg }
	    }
	}
	default {
	    # unknown browser - no warning
	}
    }

    # Nothing, return an empty string by default (no problem with the current browser).
    return ""
}


ad_proc -public im_browser_warning_component { } {
    Returns a warning message for old browsers
    that may not display all contents correctly
} {
    set browser_warning [im_browser_warning]
    if {"" == $browser_warning} { return "" }

    return "
	<font color=red>
	[im_browser_warning]
	</font>
    "
}


ad_proc -public im_color_code {
    color
    schema
} {
    Returns color code based on pre-defined schemas
    WIP - add & adjust colors on a need base. 
} {
    switch $schema {
	default {
	    switch $color {
		"red_light" {
		    return "f7cac9"
		}
		"red" {
		    return "f7786b"
		}
                "red_dark" {
                    return "dd4132"
                }
                "blue_light" {
                    return "98ddde"
                }
		"blue" {
		    return "91a8d0"
		}
		"blue_dark" {
		    return "034f84"
		}
                "yellow_light" {
                    return "fae03c"
                }
                "yellow" {
                    return "fae03c"
                }
                "yellow_dark" {
                    return "fae03c"
                }
                "grey_light" {
                    return "9896a4"
                }
                "grey" {
                    return "9896a4"
                }
                "grey_dark" {
                    return "9896a4"
                }
                "brown_light" {
                    return "b18f6a"
                }
                "brown" {
                    return "b18f6a"
                }
                "brown_dark" {
                    return "b18f6a"
                }
                "green_light" {
                    return "79c753"
                }
                "green" {
                    return "79c753"
                }
                "green_dark" {
                    return "79c753"
                }
		default {
                    return "ffffff"
		}
	    }
	}
    }
}

