# /packages/intranet-core/tcl/intranet-util-procs.tcl
#
# Copyright (C) 2004 various authors
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
    ]project-open[ utility routines.

    @author various@arsdigita.com
    @author christof.damian@project-open.com
}

ad_proc -public multirow_sort_tree {
    { -integer:boolean 0 }
    { -nosort:boolean 0 }
    multirow_name 
    id_name 
    parent_name
    order_by
} {
    multirow_sort_tree sorts a multirow with a tree structure to make
    displaying it easy. It also adds columns for the level and the row 
    number. 

    arguments:
    multirow_name : the name of the multirow
    id_name       : name of the id column
    parent_name   : name of the parent_id column
    order_by      : name of the field to sort children of the same parent 
                    by
    integer       : order_by is sorted by integer sort (boolean)
    nosort        : disable the final sorting of the multirow (boolean)
                    the information to do the sort is in tree_order and 
                    tree_level
} {
    if {$integer_p} {
	set sortopt "-integer"
    } else {
	set sortopt ""
    }

    array set id_to_row {}
    array set children {}
    array set order {}
    set row 1
    template::multirow foreach $multirow_name {
	eval set id $$id_name
	set id_to_row($id) $row

	eval set parent_id $$parent_name
	eval set tmp $$order_by
	if { $tmp=="" } {
	    set tmp 0
	}
	set order($id) $tmp
	lappend children($parent_id) $id

	incr row
    }

    # find the root elements
    set roots [list]
    foreach parent_id [array names children] {
	if {![info exists id_to_row($parent_id)]} {
	    foreach i $children($parent_id) {
		lappend roots [list $i 0 $order($i)]
	    }
	}
    }

    set roots [eval lsort -decreasing $sortopt -index 2 \$roots]

    template::multirow extend $multirow_name tree_order tree_level

    # recurse through list
    set row 1
    while {$roots!=""} {
	# pop
	set tmp [lindex $roots end]
	set roots [lrange [lindex [list $roots [unset roots]] 0] 0 end-1]
	
	unlist $tmp id level
	
	template::multirow set $multirow_name $id_to_row($id) tree_order $row
	template::multirow set $multirow_name $id_to_row($id) tree_level $level

	if {[info exists children($id)]} {
	    set slist [list]
	    foreach i $children($id) {
		lappend slist [list $i $order($i)]
	    }
	    foreach i [eval lsort -decreasing $sortopt -index 1 \$slist] {
		lappend roots [list [lindex $i 0] [expr $level+1]]
	    }
	}

	incr row
    }
    
    if {!$nosort_p} {
	template::multirow sort $multirow_name -integer tree_order
    }
}



ad_proc -public unlist {list args} {
    this procedure takes a list and any number of variable names in the 
    caller's environment, and sets the variables to successive elements 
    from the list:

    unlist {scrambled corned buttered} eggs beef toast
    # $eggs = scrambled
    # $beef = corned
    # $toast = buttered
} {
    foreach value $list name $args {
	if {![string length $name]} return
	upvar 1 $name var
	set var $value
    }
}