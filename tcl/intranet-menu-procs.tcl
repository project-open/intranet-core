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
	"

	set ctr 0
	db_foreach update_menus $sql {
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
    {-no_uls 0}
    parent_menu_label 
    bind_vars 
} {
    Returns all subitems of a menus as LIs, suitable
    to be added to index screens (costs) etc. 
} {
    set user_id [ad_get_user_id]
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
	    # ad_return_complaint 1 $visible_tcl
	    set visible 0
	    set errmsg ""
	    if [catch {	set visible [expr $visible_tcl] } errmsg] {
		ad_return_complaint 1 "<pre>$visible_tcl\n$errmsg</pre>"
	    }
	    if {!$visible} { continue }
	}

	regsub -all " " $name "_" name_key
	foreach var [ad_ns_set_keys $bind_vars] {
	    set value [ns_set get $bind_vars $var]
	    append url "&$var=[ad_urlencode $value]"
	}

	append result "<li><a href=\"$url\">[lang::message::lookup "" intranet-invoices.$name_key $name]</a></li>\n"
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
    {-class "" }
    {-pretty_name "" }
    label
} {
    Returns a <li><a href=URL>Name</a> for the menu.
    Attention, not closing </li>!
} {
    set current_user_id [ad_get_user_id]
    set menu_id 0
    db_0or1row menu_info "
	select	m.*
	from	im_menus m
	where	m.label = :label and
		(m.enabled_p is null or m.enabled_p = 't') and
		im_object_permission_p(m.menu_id, :current_user_id, 'read') = 't'
    "
    if {0 == $menu_id} { return "" }

    if {"" != $visible_tcl} {
	set visible 0
	set errmsg ""

	if [catch { 
	    set visible [expr $visible_tcl] 
	} errmsg] { 
	    ns_log Error "im_menu_li: Error with visible_tcl: $visible_tcl: '$errmsg'" 
#	    ad_return_complaint 1 "<pre>$visible_tcl\n$errmsg</pre>" 
	}
	if {!$visible} { return "" }
    }

    set class_html ""
    if {"" != $class} { set class_html "class='$class'" }
    return "<li $class_html><a href=\"$url\">$name</a>\n"
}

