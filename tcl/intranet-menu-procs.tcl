# /packages/intranet-core/tcl/intranet-menu-procs.tcl
#
# Copyright (C) 2004 Project/Open
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

ad_proc -public im_menu_parent_options { {include_empty 0} } {
    Returns a list of all menus,
    ordered and indented according to hierarchy.
} {

    set start_menu_id [db_string start_menu_id "select menu_id from im_menus where label='main'" -default 0]

    set parent_options_sql "
	select
		m.name,
		m.menu_id,
		m.label,
		(level-1) as indent_level
	from
		im_menus m
	start with
		menu_id = :start_menu_id
	connect by
		parent_menu_id = PRIOR menu_id"

    set parent_options [list]
    db_foreach parent_options $parent_options_sql {
	set spaces ""
	for {set i 0} {$i < $indent_level} { incr i } {
	    append spaces "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
	}
	lappend parent_options [list "$spaces$name - $label" $menu_id]
    }
    return $parent_options
}



