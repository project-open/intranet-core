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
    {-translate_p 1} 
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
    set navbar_postfix [ad_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "navbar_default"]
    set navbar_gif_url "/intranet/images/[im_navbar_gif_url]"
    set base_path "[acs_root_dir]/packages/intranet-core/www/images/"
    set navbar_path "[acs_root_dir]/packages/intranet-core/www/images/[im_navbar_gif_url]"

    if { $translate_p && ![empty_string_p $alt] } {
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
	"freelance"	{ return "<img src=$navbar_gif_url/time.png width=19 height=19 border=$border title=\"$alt\" alt=\"$alt\">" }
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
    set user_id [ad_maybe_redirect_for_registration]
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    if {$user_admin_p} {
	set html "
<A HREF=\"/intranet/admin/categories/?select_category_type=[ns_urlencode $category_type]\">[im_gif new "Admin category type"]</A>"
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

	return "  
[im_header]
[im_navbar]
[value_if_exists page_body]
[value_if_exists page_content]
[im_footer]\n"
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
    set user_id [ad_get_user_id]
    set url_stub [ns_urldecode [im_url_with_query]]
#    ns_log Notice "im_user_navbar: url_stub=$url_stub"

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
    set user_id [ad_get_user_id]
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
	set new_office [im_navbar_tab "new" [im_gif new "Add a new office"] false]
    } else {
	set new_office ""
    }

    return  "
<div id=\"navbar_sub_wrapper\">
   $alpha_bar
   <ul id=\"navbar_sub\">
      $standard
      $new_office
   </ul>
</div>
"
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
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label='companies'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]
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
    Determines where to link to www.project-open.org for help.
    The Wiki convention for page is "page_" followed by the URL
    of the page with all non-alphanum characters replaced by "_":
    http://www.project-open.org/en/page_intranet_invoices_view
} {
    # Get the URL from the connection
    if {"" == $url} { set url [ad_conn url] }

    # Does the URL has a trailing "/". That's the case for
    # the "index" pages sometimes.
    if {[regexp {/$} $url match]} { set url "${url}index" }

    # Replace "/" by "_" to create
    regsub -all "/" $url "_" url
    regsub -all {\-} $url "_" url

    # Add the constant part in front of the url:
    set url "http://www.project-open.org/en/page$url"

    # Return the finished URL
    return $url
}


ad_proc -public im_navbar_tab {
    url
    name
    selected
} {} {
    if {$selected} {
	return "<li class=\"selected\"><div class=\"navbar_selected\"><a href=\"$url\"><span>$name</span></a></div></li>\n"
    }
    return "<li class=\"unselected\"><div class=\"navbar_unselected\"><a href=\"$url\"><span>$name</span></a></div></li>\n"
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
    set user_id [ad_get_user_id]
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set locale [lang::user::locale -user_id $user_id]
    set url_stub [ns_conn url]

    # Start formatting the menu bar
    set navbar ""
    set found_selected 0
    set selected 0



    if {"" == $current_plugin_id} { set current_plugin_id 0 }

    # Replaced the db_foreach by this construct to save
    # the relatively high amount of SQLs to get the menus
    set menu_list_list [util_memoize [list im_sub_navbar_menu_helper -locale $locale $user_id $parent_menu_id]]

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
	set url_length [expr [string length $url] - 1]
	set url_stub_chopped [string range $url_stub 0 $url_length]

	if {[string equal $label $select_label] && $current_plugin_id == 0} {
	    
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
	if {[string equal $base_url ""]} {
	    set base_url $plugin_url
	}

	set components_sql "
	    SELECT 
			p.plugin_id AS plugin_id,
			p.plugin_name AS plugin_name,
			p.menu_name AS menu_name
	    FROM 
			im_component_plugins p,
			im_component_plugin_user_map u
	    WHERE
			(enabled_p is null OR enabled_p = 't')
			AND p.plugin_id = u.plugin_id 
			AND page_url = '$plugin_url'
			AND u.location = 'none' 
			AND u.user_id = $user_id
	    ORDER by 
			p.menu_sort_order, p.sort_order
	"

	set navbar_components_list [util_memoize [list db_list_of_lists navbar_components $components_sql]]

	foreach comp_tuple $navbar_components_list {
	    set plugin_id [lindex $comp_tuple 0]
	    set plugin_name [lindex $comp_tuple 1]
	    set menu_name [lindex $comp_tuple 2]

	    set url [export_vars -quotehtml -base $base_url {plugin_id {view_name "component"}}]
	    if {[string equal $menu_name ""]} {
		set menu_name [string map {"Project" "" "Component" "" "  " " "} $plugin_name] 
	    }
	    append navbar [im_navbar_tab $url $menu_name [expr $plugin_id==$current_plugin_id]]
	}
    }

    if {$show_help_icon_p} {
	set help_text [lang::message::lookup "" intranet-core.Navbar_Help_Text "Click here to get help for this page"]
	append navbar [im_navbar_tab [im_navbar_help_link] [im_gif help $help_text] 0]
    }

    if {$admin_p} {
	set admin_text [lang::message::lookup "" intranet-core.Navbar_Admin_Text "Click here to configure this navigation bar"]
	set admin_url [export_vars -base "/intranet/admin/menus/index" {{top_menu_id $parent_menu_id}}]
	append navbar [im_navbar_tab $admin_url [im_gif wrench $admin_text] 0]
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
    user_id 
    parent_menu_id 
} {
    Get the list of menus in the sub-navbar for the given user.
    This routine is cached and called every approx 60 seconds
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

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
	set enabled_sql "and (enabled_p is null OR enabled_p = 't')"
    } else {
	set enabled_sql ""
    }

    set menu_select_sql "
	select	menu_id,
		package_name,
		label,
		name,
		url,
		visible_tcl
	from	im_menus m
	where	parent_menu_id = :parent_menu_id
		$enabled_sql
		and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
	order by
		 sort_order
    "
    set result [db_list_of_lists subnavbar_menus $menu_select_sql]
    return $result
}

ad_proc -public im_navbar { 
    { -loginpage:boolean 0 }
    { -show_context_help_p 0 }
    { main_navbar_label "" } 
} {
    Setup a top navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
#    ns_log Notice "im_navbar: main_navbar_label=$main_navbar_label"

    set user_id [ad_get_user_id]
    set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
    set locale [lang::user::locale -user_id $user_id]
    if {![info exists loginpage_p]} { set loginpage_p 0 }

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
    set main_menu_id [util_memoize [list db_string main_menu "select menu_id from im_menus where label='main'" -default 0]]

    # make sure only one field gets selected so...
    # .. check for the first complete match between menu and url.
    set ctr 0
    set selected 0
    set found_selected 0
    set old_sel "notsel"
    set cur_sel "notsel"

    # select the toplevel menu items
    set menu_list_list [util_memoize [list im_sub_navbar_menu_helper -locale $locale $user_id $main_menu_id] 60]

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

	if {!$loginpage_p && "register" != [string range [ns_conn url] 1 8] } {
	    append navbar [im_navbar_tab $url $name $selected]
	}
	incr ctr
    }


    if {$admin_p} {
	set admin_text [lang::message::lookup "" intranet-core.Navbar_Admin_Text "Click here to configure this navigation bar"]
	set admin_url [export_vars -base "/intranet/admin/menus/index" {{top_menu_id $main_menu_id} {top_menu_depth 1} return_url }]
	append navbar [im_navbar_tab $admin_url [im_gif wrench $admin_text] 0]
    }

    set page_url [im_component_page_url]

    # Maintenance Bar -
    # Display a maintenance message in red when performing updates etc...   
    set maintenance_message [ad_parameter -package_id [im_package_core_id] MaintenanceMessage "" ""]
    set maintenance_message [string trim $maintenance_message]

    set user_id [ad_get_user_id]
    set user_name [im_name_from_user_id $user_id]

    set context_help_html ""
    set context_comment_html ""

    if {$show_context_help_p} {
	set context_help_html "
	    <div id=\"main_users_online\">
	      <a href=\"[im_navbar_help_link]\">&nbsp; [im_gif help [lang::message::lookup "" intranet-core.Context_Help "Context Help"]]</a>
	    </div>
	"
    }

    set show_context_comment_p 1
    if {$show_context_comment_p} {
	set context_comment_html "
	    <div id=\"main_users_online\">
	      <a href=\"[export_vars -base "/intranet/report-bug-on-page" {{page_url [im_url_with_query]}}]\">&nbsp; [im_gif bug [lang::message::lookup "" intranet-core.Report_a_bug_on_this_page "Report a bug on this page"]]</a>
	    </div>
	"
    }

    set main_users_and_search "
	  <div id=\"main_users_and_search\">
	    <div id=\"main_users_online\">
    " 
    if { "register" != [string range [ns_conn url] 1 8] } {
	append main_users_and_search [lang::message::lookup "" intranet-core.Welcome_User_Name "Welcome %user_name%"]
    }	

    append main_users_and_search "
	    </div>
	    $context_help_html
	    $context_comment_html
	    <div id=\"main_users_online\">
    "
    if { "register" != [string range [ns_conn url] 1 8] } {
	    append main_users_and_search  "&nbsp;[im_header_users_online_str]"
    }

    append main_users_and_search "
	    </div>
	    <div id=\"main_search\">
	      [im_header_search_form]
	    </div>
	  </div>
    "

    if {$loginpage_p} {
	set user_id 0
	set main_users_and_search ""
    }

    return "
	    <div id=\"main\">
	       <div id=\"navbar_main_wrapper\">
		  <ul id=\"navbar_main\">
		     $navbar
		  </ul>
	       </div>
	       <div id=\"main_header\">
		  <div id=\"main_title\">
		     $page_title
		  </div>
		  <div id=\"main_context_bar\">
		     $context_bar
		  </div>
		  <div id=\"main_maintenance_bar\">
		     $maintenance_message
		  </div>
		  <div id=\"main_portrait_and_username\">
		  <p id=\"main_username\">
		    Welcome, [im_name_from_user_id $user_id]
		  </p>
		  </div>
		  $main_users_and_search
		  <div id=\"main_header_deco\"></div>
	       </div>
	    </div>
    "

    # Disabled the portrait 
    set ttt {
		  <div id=\"main_portrait\">
		    [im_portrait_or_anon_html $user_id Portrait]
		  </div>
    }


}


ad_proc -public im_design_user_profile_string { 
    -user_id:required
} {
    Determine a pretty string for the type of user that it is:
} {
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
    set user_id [ad_get_user_id]
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
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set plugin_left_html ""
    set plugin_right_html ""

    # Any permissions set at all? We'll disable perms in this case.
    set any_perms_set_p [im_component_any_perms_set_p]

    set plugin_sql "
	select	c.*,
		im_object_permission_p(c.plugin_id, :user_id, 'read') as perm
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
    Returns the formatted HTML for the "My Account - Change password - Reset Portlets - Add Portlet"
    header panel.
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

    set logout_pwchange_str "
	<a href=\"/intranet/users/view?user_id=$user_id\">[lang::message::lookup "" intranet-core.My_Account "My Account"]</a> |
    "
    if {!$ldap_installed_p} {
	append logout_pwchange_str "<a href=\"$change_pwd_url\">[_ intranet-core.Change_Password]</a> | "
    }

    # Disable who's online for "anonymous visitor"
    if {0 == $user_id} {
	set users_online_str ""
	set logout_pwchange_str ""
	set reset_stuff_link ""
	set add_stuff_link ""
	set log_out_link ""
    }

    set header_buttons "
      <div id=\"header_buttons\">
	<div id=\"header_logout_tab\">
	    <div id=\"header_logout\">
                $log_out_link
	    </div>
	</div>
	 <div id=\"header_settings_tab\">
	    <div id=\"header_settings\">
	       $logout_pwchange_str
	       $reset_stuff_link
	       $add_stuff_link
	    </div>
	 </div>
      </div>
    "
}


ad_proc -public im_header { 
    { -no_head_p "0"}
    { -no_master_p "0"}
    { -loginpage:boolean 0 }
    { -body_script_html "" }
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
    set user_id [ad_get_user_id]
    if {0 != $user_id} { set untrusted_user_id $user_id }
    set user_name [im_name_from_user_id $user_id]
    set return_url [im_url_with_query]

    # Is any of the "search" package installed?
    set search_installed_p [llength [info procs im_package_search_id]]

    if { [empty_string_p $page_title] } {
	set page_title [ad_partner_upvar page_title]
    }
    set context_bar [ad_partner_upvar context_bar]
    set page_focus [ad_partner_upvar focus]

    # --------------------------------------------------------------
    if {$search_installed_p && [empty_string_p $page_focus] } {
	# Default: Focus on Search form at the top of the page
	set page_focus "surx.query_string"
    }
    if { [empty_string_p $extra_stuff_for_document_head] } {
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    }

    # The document language is always set from [ad_conn lang] which by default 
    # returns the language setting for the current user.  This is probably
    # not a bad guess, but the rest of OpenACS must override this setting when
    # appropriate and set the lang attribxute of tags which differ from the language
    # of the page.  Otherwise we are lying to the browser.
    set doc(lang) [ad_conn language]
    
    # Determine if we should be displaying the translation UI
    #
    if {[im_openacs54_p] && [lang::util::translator_mode_p]} {
	template::add_footer -src "/packages/acs-lang/lib/messages-to-translate"
    }
    
    set search_form [im_header_search_form]
    set user_profile [im_design_user_profile_string -user_id $untrusted_user_id]

    append extra_stuff_for_document_head [im_stylesheet]

    append extra_stuff_for_document_head "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n"
    append extra_stuff_for_document_head "<!--\[if lt IE 7.\]>\n<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>\n<!\[endif\]-->\n"


    # OpenACS 5.4 Header stuff
    if {[im_openacs54_p]} {

	# Determine if developer support is installed and enabled
	#
	set developer_support_p [expr { [llength [info procs ::ds_show_p]] == 1 && [ds_show_p] }]
	if {$developer_support_p} {
	    template::head::add_css -href "/resources/acs-developer-support/acs-developer-support.css" -media "all"
	    template::add_header -src "/packages/acs-developer-support/lib/toolbar"
	    template::add_footer -src "/packages/acs-developer-support/lib/footer"
	}

	template::head::add_css -href "/resources/acs-subsite/default-master.css" -media "all"

	# Extract multirows for header META, CSS, STYLE & SCRIPT etc. from global variables
	template::head::prepare_multirows
	set event_handlers [template::get_body_event_handlers]

	template::multirow foreach meta {
	    set row "<meta"
	    if {"" != $http_equiv} {  append row " http_equiv='$http_equiv'" }
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
	
    }

    if {[llength [info procs im_amberjack_header_stuff]]} {
	append extra_stuff_for_document_head [im_amberjack_header_stuff]
    }

    # --------------------------------------------------------------
    set users_online_str [im_header_users_online_str]

    # Get the contents of the header plugins
    array set header_plugins [im_header_plugins]
    set plugin_right_html $header_plugins(right)
    set plugin_left_html $header_plugins(left)

    set page_url [im_component_page_url]
    set logo [im_logo]

    # The horizonal component
    set header_buttons [im_header_logout_component -page_url $page_url -return_url $return_url -user_id $user_id]
    if {$loginpage_p} { set header_buttons "" }

    set header_skin_select [im_skin_select_html $untrusted_user_id [im_url_with_query]]
    if {$header_skin_select != ""} {
	set header_skin_select "<span id='skin_select'>[_ intranet-core.Skin]:</span> $header_skin_select"
    }
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

    set header_html ""
    if {[im_openacs54_p]} {
	set header_html [template::get_header_html]
    }

    return "
	[ad_header $page_title $extra_stuff_for_document_head]
	$body_script_html
	$header_html
	<div id=\"monitor_frame\">
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
	      $header_buttons   
	      <div id=\"header_skin_select\">
		 $header_skin_select
	      </div>   
	   </div>
    "
}


ad_proc -private im_header_users_online_str { } {
    A string to display the number of online users
} {
    # Enable "Users Online" mini-component for OpenACS 5.1 only
    set users_online_str ""

    set proc "num_users"
    set namespace "whos_online"

    if {[string equal $proc [namespace eval $namespace "info procs $proc"]]} {
	set num_users_online [lc_numeric [whos_online::num_users]]
	if {1 == $num_users_online} { 
	    set users_online_str "<A href=\"/intranet/whos-online\">[_ intranet-core.lt_num_users_online_user]</A><BR>\n"
	} else {
	    set users_online_str "<A href=\"/intranet/whos-online\">[_ intranet-core.lt_num_users_online_user_1]</A><BR>\n"
	}
    }

    return $users_online_str

}

ad_proc -private im_header_search_form { } {
    Search form for header of page
} {
    set user_id [ad_get_user_id]
    set search_installed_p [llength [info procs im_package_search_id]]

    if {[im_permission $user_id "search_intranet"] && $user_id > 0 && $search_installed_p} {
	set alt_go [lang::message::lookup "" intranet-core.Search_Go_Alt "Search through all full-text indexed objects."]
	return "
	      <form action=\"/intranet/search/go-search\" method=\"post\" name=\"surx\">
		<input class=surx name=query_string size=15 value=\"[_ intranet-core.Search]\" onClick=\"javascript:this.value = ''\">
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

    set amberjack_body_stuff ""
    if {[llength [info procs im_amberjack_before_body]]} {
	set amberjack_body_stuff [im_amberjack_before_body]
    }

    set footer_html ""
    if {[im_openacs54_p]} {
        set footer_html [template::get_footer_html]
    }

    return "
    </div> <!-- monitor_frame -->
    <div class=\"footer_hack\">&nbsp;</div>	
    <div id=\"footer\">
       [_ intranet-core.Comments] [_ intranet-core.Contact]: 
       <a href=\"mailto:[ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]\">
	  [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@localhost"]
       </a> 
    </div>
  $amberjack_body_stuff
  $footer_html
  </BODY>
</HTML>
"
}


ad_proc -public im_stylesheet {} {
    Intranet CSS style sheet. 
} {
    set user_id [ad_get_user_id]
    set html ""
    set openacs54_p [im_openacs54_p]

    # --------------------------------------------------------------------
    set skin_name [im_user_skin $user_id]
    set skin_path "[acs_root_dir]/packages/intranet-core/www/js/style.$skin_name.js"
    set skin_exists_p [util_memoize [list file exists $skin_path]]

    if {$skin_exists_p} {
	set skin $skin_name
    } else {
	set skin "default"
    }

   # set system_css "/intranet/style/style.$skin.css"
   set system_css "/intranet/style/style.$skin.css"

    if {[llength [info procs im_package_calendar_id]]} {
	if {$openacs54_p} { 
	    template::head::add_css -href "/calendar/resources/calendar.css" -media "screen" -order "3" 
# # 	} else {
# # 	    append html "<link rel=StyleSheet type=text/css href=\"/calendar/resources/calendar.css\" media=screen>\n"
# # 	}
# #     }

     if {$openacs54_p} { template::head::add_css -href "/intranet/style/print.css" -media "print" -order "4" } else { append html "<link rel=StyleSheet type=text/css href=\"/intranet/style/print.css\" media=print>\n" }


# #    set bug_tracker_installed_p [expr {[llength [info procs ::ds_show_p]] == 1 && [ds_show_p]}]
# #    ad_return_complaint 1 $bug_tracker_installed_p


    # --------------------------------------------------------------------
    # Add standard meta tags
    if {$openacs54_p} { template::head::add_meta -name generator -lang en -content "OpenACS version [ad_acs_version]" }
    append html ""

    # --------------------------------------------------------------------
    if {$openacs54_p} { template::head::add_css -href $system_css -media "screen" -order "6" } else { append html "<link rel=StyleSheet type=text/css href=\"$system_css\" media=screen>\n" }

    set css "/resources/acs-subsite/site-master.css"
#    if {$openacs54_p} { template::head::add_css -href $css -media "screen" } else { append html "<link rel=StyleSheet type=text/css href=\"$css\" media=screen>\n" }

    if {$openacs54_p} { template::head::add_css -href "/resources/acs-templating/mktree.css" -media "screen" -order "5" } else { append html "<link rel=StyleSheet type=text/css href=\"/resources/acs-templating/mktree.css\" media=screen>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/intranet/js/jquery.min.js" -order "1" } else { append html "<script type=text/javascript src=\"/intranet/js/jquery.min.js\"></script>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/intranet/js/showhide.js" -order "5" } else { append html "<script type=text/javascript src=\"/intranet/js/showhide.js\"></script>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/resources/diagram/diagram/diagram.js" -order "4" } else { append html "<script type=text/javascript src=\"/resources/diagram/diagram/diagram.js\"></script>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/resources/acs-subsite/core.js" -order "6" } else { append html "<script type=text/javascript src=\"/resources/acs-subsite/core.js\"></script>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/intranet/js/rounded_corners.inc.js" -order "3" } else { append html "<script type=text/javascript src=\"/intranet/js/rounded_corners.inc.js\"></script>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/resources/acs-templating/mktree.js" -order "2" } else { append html "<script type=text/javascript src=\"/resources/acs-templating/mktree.js\"></script>\n" }

    if {$openacs54_p} { template::head::add_javascript -src "/intranet/js/style.$skin.js" -order "7" } else { append html "<script type=text/javascript src=\"/intranet/js/style.$skin.js\"></script>\n" }
   
    if {$openacs54_p} {
	if {$openacs54_p} { template::head::add_css -href "/resources/acs-templating/lists.css" -media "screen" } else { append html "<link rel=StyleSheet type=text/css href=\"/resources/acs-templating/lists.css\" media=screen>\n" }
	if {$openacs54_p} { template::head::add_css -href "/resources/acs-templating/forms.css" -media "screen" } else { append html "<link rel=StyleSheet type=text/css href=\"/resources/acs-templating/forms.css\" media=screen>\n" }
    }

#    append html "<!--\[if lt IE 8\]>\n<script type=\"text/javascript\" src=\"/intranet/js/ie-7-or-lower-specific.js\" />\n<!\[endif\]-->\n"

    # temporary include V3.4, can be replaced in V4.0 using template::head::add_javascript
    if {[llength [info procs im_project_personal_active_projects_component_reinisch]]} {
	append html "<link rel=StyleSheet type=text/css href=\"/intranet-cust-reinisch/style/reinisch.css\" />\n"

	append html "<script language='javascript' src='/intranet-cust-reinisch/js/yui/build/yahoo-dom-event/yahoo-dom-event.js'></script>\n"
	append html "<script language='javascript' src='/intranet-cust-reinisch/js/yui/build/element/element-beta-min.js'></script>\n"
	append html "<script language='javascript' src='/intranet-cust-reinisch/js/yui/build/tabview/tabview-min.js'></script>\n"
    }
    return $html
}


ad_proc -public im_logo {} {
    Intranet System Logo
} {
    set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]
    set system_logo [ad_parameter -package_id [im_package_core_id] SystemLogo "" ""]
    set system_logo_link [ad_parameter -package_id [im_package_core_id] SystemLogoLink "" "http://www.project-open.com/"]

    if {[string equal $system_logo ""]} {
	set user_id [ad_get_user_id]
	set skin_name [im_user_skin $user_id]
	
	if {[file exists "[acs_root_dir]/packages/intranet-core/www/images/logo.$skin_name.gif"]} {
	    set system_logo "$system_url/intranet/images/logo.$skin_name.gif"
	} else {
	    set system_logo "$system_url/intranet/images/logo.default.gif"
	}
    }
    # if { "0" != [ad_get_user_id] } {
	return "\n<a href=\"$system_logo_link\"><img id='intranetlogo' src=\"$system_logo\" alt=\"logo\" border='0'></a>\n"
    # } else {
    #	return "\n<a href=\"$system_logo_link\"><img id='intranetlogo' src=\"logo.gif\" alt=\"logo\" border='0'></a>\n"
    # }
}


ad_proc -public im_navbar_gif_url {} {
    Path to access the Navigation Bar corner GIFs
} {
    set user_id [ad_get_user_id]
    set locale [lang::user::locale -user_id $user_id]

    return [util_memoize [list im_navbar_gif_url_helper -locale $locale -user_id $user_id] 60]
}

ad_proc -public im_navbar_gif_url_helper {
    {-user_id "" }
    {-locale "" }
} {
    Path to access the Navigation Bar corner GIFs
} {
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set navbar_gif_url "/intranet/images/[ad_parameter -package_id [im_package_core_id] SystemNavbarGifPath "" "/intranet/images/navbar_default"]"
    set org_navbar_gif_url $navbar_gif_url

    # Old parameter? Shell out a warning and use the last part
    set navbar_pieces [split $navbar_gif_url "/"]
    set navbar_pieces_len [llength $navbar_pieces]
    if {$navbar_pieces_len > 1} {
	set navbar_gif_url [lindex $navbar_pieces [expr $navbar_pieces_len-1] ]
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
	append url "$query_args&amp;"
    }
    
    set html_list [list]
    foreach l [im_all_letters_lowercase] {
	if { [lsearch -exact $initial_list $l] == -1 } {
	    # This means no user has this initial
	    lappend html_list "<font color=gray>$l</font>"
	} elseif { [string compare $l $letter] == 0 } {
	    lappend html_list "<b>$l</b>"
	} else {
	    lappend html_list "<a href=\"${url}letter=$l\">$l</a>"
	}
    }
    if { [empty_string_p $letter] || [string compare $letter "all"] == 0 } {
	lappend html_list "<b>[_ intranet-core.All]</b>"
    } else {
	lappend html_list "<a href=\"${url}letter=all\">All</a>"
    }
    if { [string compare $letter "scroll"] == 0 } {
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
    if {[string equal "none" $default_letter]} { return "&nbsp;" }

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
    set param_html [join $params "&amp;"]

    set html "<ul id=\"alphabar\">"

    if {![string equal $prev_page_url ""]} {
	append html "<li><a href=\"$prev_page_url\">&lt;&lt</a></li>"
    }

    # "no_alpha" is a special value for an alpha-bar without letter and only back/forth
    if {![string equal "no_alpha" $default_letter]} {
	foreach letter $alpha_list {
	    set letter_key "intranet-core.[lang::util::suggest_key $letter]"
	    set letter_trans [lang::message::lookup "" $letter_key $letter]
	    if {[string equal $letter $default_letter]} {
		append html "<li class=\"selected\"><div class=\"navbar_selected\"><a href=\"$url\">$letter_trans</a></div></li>\n"
	    } else {
		set url "$target_url?letter=$letter&amp;$param_html"
		append html "<li class=\"unselected\"><a href=\"$url\">$letter_trans</a></li>\n"
	    }
	}
    }

    if {![string equal $next_page_url ""]} {
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
	set report_url "http://www.project-open.net/intranet-forum/forum/new-system-incident"
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
	[export_form_vars return_url user_id]
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



ad_proc -public im_browser_version { } {
    Extracts the browser identifcation from the User-Agent HTTP header
} {
    # Extract variables from form and HTTP header
    set header_vars [ns_conn headers]

    set body ""
    #foreach var [ad_ns_set_keys $header_vars] {
    #    set value [ns_set get $header_vars $var]
    #    append body "<tr><td>$var</td><td>$value</td></tr>\n"
    #}

    # Get intersting info
    set user_agent [ns_set get $header_vars "User-Agent"]
    append body "<tr><td>User-Agent</td><td>$user_agent</td></tr>\n"
    
    set mozilla_version ""
    if {[regexp {Mozilla/(.\..)} $user_agent match mozilla_version]} {
	append body "<tr><td>Mozilla</td><td>$mozilla_version</td></tr>\n"
    }
    
    set firefox_version ""
    set chrome_version ""
    set msie_version ""
    set opera_version ""
    set lynx_version ""

    set browser "Other"
    set version "0.0.0"
    
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