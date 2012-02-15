# /packages/intranet-core/tcl/intranet-menu-procs.tcl
#
# Copyright (C) 2004 ]project-open[
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
    Library with auxillary routines related to im_menus.

    @author frank.bergmann@project-open.com
}


ad_proc -public im_menu_update_hierarchy {

} {
    Reprocesses the menu hierarchy to calculate the right menu codes
} {
    # Reset all tree_sortkey to null to indicate that the menu_items
    # need to be "processed"
    db_dml reset_menu_hierarchy "
	update im_menus
	set tree_sortkey = null
    "

    # Prepare the top menu
    set start_menu_id [db_string start_menu_id "select menu_id from im_menus where label='top'" -default 0]
    db_dml update_top_menu "update im_menus set tree_sortkey='.' where menu_id = :start_menu_id"

    set maxlevel 9
    set chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz"
    set continue 1
    set level 0
    while {$continue && $level < $maxlevel} {
	set continue 0
	# Get all menu items that have not been processed yet
	# (tree_sortkey is null) with parents that have been
	# processed already (tree_sortkey is not null)
	set sql "
		select
			m.menu_id,
			mm.menu_id as parent_id,
			mm.tree_sortkey as parent_sortkey
		from
			im_menus m,
			im_menus mm
		where
			m.parent_menu_id = mm.menu_id
			and m.tree_sortkey is null
			and mm.tree_sortkey is not null
		order by
			parent_sortkey, m.sort_order
	"

	set ctr 0
	set old_parent_sortkey ""
	db_foreach update_menus $sql {

	    if {$old_parent_sortkey != $parent_sortkey} {
                set old_parent_sortkey $parent_sortkey
                set ctr 0
            }

	    # the new tree_sortkey is the parents tree_sortkey plus a
	    # current letter starting with "A", "B", ...
	    set tree_sortkey "$parent_sortkey[string range $chars $ctr $ctr]"

	    db_dml update_menu "update im_menus set tree_sortkey=:tree_sortkey where menu_id=:menu_id"
	    incr ctr
	    set continue 1
	}
	incr level
    }
}



ad_proc -public im_menu_parent_options { {include_empty 0} } {
    Returns a list of all menus,
    ordered and indented according to hierarchy.
} {
    set start_menu_id [db_string start_menu_id "select menu_id from im_menus where label='top'" -default 0]

    set parent_options_sql "
	select
		m.name,
		m.menu_id,
		m.label,
		length(tree_sortkey) as indent_level
	from
		im_menus m
	where
		(enabled_p is null or enabled_p = 't')
	order by
		tree_sortkey
    "

    set parent_options [list]
    db_foreach parent_options $parent_options_sql {
	set spaces ""
	set suggest_name  [lang::util::suggest_key $name]
	set l10n_name [lang::message::lookup "" intranet-core.$suggest_name $name]
	for {set i 0} {$i < $indent_level} { incr i } {
	    append spaces "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	}
	lappend parent_options [list "$spaces$l10n_name - $label" $menu_id]
    }
    return $parent_options
}


ad_proc -public im_menu_ul_list { 
    {-no_cache:boolean}
    {-package_key "intranet-core" }
    {-no_uls 0}
    {-check_parent_enabled:boolean}
    parent_menu_label 
    bind_vars 
} {
    Returns all subitems of a menus as LIs, suitable
    to be added to index screens (costs) etc. 
    @param check_parent_enabled Make sure the parent is enabled. If not return ""
} {
    if {$check_parent_enabled_p} {
	set enabled_p [db_0or1row parent_enabled "
		select	menu_id
		from	im_menus
		where	label = :parent_menu_label and (enabled_p is null or enabled_p = 't')
	"]
	if {!$enabled_p} { return "" }
    }

    set user_id [ad_get_user_id]
    set locale [lang::user::locale -user_id $user_id]

set no_cache_p 1
    if {$no_cache_p} {
	set result [im_menu_ul_list_helper -package_key $package_key -locale $locale $user_id $no_uls $parent_menu_label $bind_vars]
    } else {
	set result [util_memoize [list im_menu_ul_list_helper -package_key $package_key -locale $locale $user_id $no_uls $parent_menu_label $bind_vars] 3600]
    }
    return $result
}

ad_proc -public im_menu_ul_list_helper {
    {-locale "" }
    {-package_key "intranet-core" }
    user_id
    no_uls
    parent_menu_label 
    bind_vars
} {
    Returns all subitems of a menus as LIs, suitable
    to be added to index screens (costs) etc. 
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }
    set admin_p [im_is_user_site_wide_or_intranet_admin [ad_get_user_id]]

    array set bind_vars_hash $bind_vars
    set parent_menu_id [db_string parent_admin_menu "select menu_id from im_menus where label=:parent_menu_label" -default 0]

    set menu_select_sql "
	select	m.*
	from	im_menus m
	where	parent_menu_id = :parent_menu_id and
		(enabled_p is null or enabled_p = 't') and
		im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
	order by sort_order
    "

    # Start formatting the menu bar
    if {!$no_uls} {set result "<ul>\n" }
    set ctr 0
    db_foreach menu_select $menu_select_sql {
	if {"" != $visible_tcl} {
	    set visible 0
	    set errmsg ""
	    if [catch {	set visible [expr $visible_tcl] } errmsg] {
		ad_return_complaint 1 "<pre>$visible_tcl\n$errmsg</pre>"
	    }
	    if {!$visible} { continue }
	}

	regsub -all {[^0-9a-zA-Z]} $name "_" name_key
	foreach var [array names bind_vars_hash] {

	    # Make sure the URL has got a "?"
	    if {![regexp {\?} $url match]} { append url "?" }

	    # Does the link already include a variable?
	    # The we have to add a "&"
	    if {[regexp {\?(.)+} $url match]} { append url "&" }

	    set value $bind_vars_hash($var)
	    append url "$var=[ad_urlencode $value]"
	}

	set admin_url [export_vars -base "/intranet/admin/menus/index" {menu_id return_url}]
	set admin_html "<a href='$admin_url'>[im_gif wrench]</a>"
	if {!$admin_p} { set admin_html "" }
    
	append result "<li><a href=\"$url\">[lang::message::lookup "" $package_name.$name_key $name]</a> $admin_html</li>\n"
	incr ctr
    }
    if {!$no_uls} {append result "</ul>\n" }

    if {0 == $ctr} { set result "" }
    return $result
}



# --------------------------------------------------------
# Shortcut functions for NavBar purposes
# --------------------------------------------------------


ad_proc -public im_menu_url { 
    label 
} {
    Extracts the URL of the menu with label
} {
    set url [db_string url "select url from im_menus where label=:label" -default ""]
    return $url
}

ad_proc -public im_menu_name { 
    label 
} {
    Extracts the Name of the menu with label
} {
    set name [db_string url "select name from im_menus where label=:label" -default ""]
#    set name_key "intranet-core.[lang::util::suggest_key $name]"
#    set name [lang::message::lookup "" $name_key $name]
    return $name
}

ad_proc -public im_menu_li { 
    {-user_id "" }
    {-locale "" }
    {-package_key "intranet-core" }
    {-class "" }
    {-pretty_name "" }
    label
} {
    Returns a <li><a href=URL>Name</a> for the menu.
    Attention, not closing </li>!
} {
    return [util_memoize [list im_menu_li_helper -user_id $user_id -locale $locale -package_key $package_key -class $class -pretty_name $pretty_name $label]]
}

ad_proc -public im_menu_li_helper { 
    {-user_id "" }
    {-locale "" }
    {-package_key "intranet-core" }
    {-class "" }
    {-pretty_name "" }
    label
} {
    Returns a <li><a href=URL>Name</a> for the menu.
    Attention, not closing </li>!
} {
    if {"" == $user_id} { set user_id [ad_get_user_id] }
    if {"" == $locale} { set locale [lang::user::locale -user_id $user_id] }

    set menu_id 0
    db_0or1row menu_info "
	select	m.*
	from	im_menus m
	where	m.label = :label and
		(m.enabled_p is null or m.enabled_p = 't') and
		im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
    "
    if {0 == $menu_id} { return "" }

    if {"" != $visible_tcl} {
	set visible 0
	set errmsg ""

	if [catch { 
	    set visible [expr $visible_tcl] 
	} errmsg] { 
	    ns_log Error "im_menu_li: Error with visible_tcl: $visible_tcl: '$errmsg'" 
	}
	if {!$visible} { return "" }
    }

    set class_html ""
    if {"" != $class} { set class_html "class='$class'" }
    regsub -all {[^0-9a-zA-Z]} $name "_" name_key
    return "<li $class_html><a href=\"$url\">[lang::message::lookup "" "$package_key.$name_key" $name]</a>\n"
}

