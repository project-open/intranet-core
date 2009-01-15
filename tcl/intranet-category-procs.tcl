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
    
    Functions for dealing with im_categories
    
    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
}


ad_proc -public im_category_from_id { 
    {-translate_p 1}
    {-locale ""}
    category_id 
} {
    Get a category_name from 
} {
    if {"" == $category_id} { return "" }
    if {0 == $category_id} { return "" }
    set category_name [util_memoize "db_string cat \"select im_category_from_id($category_id)\" -default {}"]
    set category_key [lang::util::suggest_key $category_name]
    if {$translate_p} {
	set category_name [lang::message::lookup $locale intranet-core.$category_key $category_name]
    }

    return $category_name
}

ad_proc -public im_category_from_category {
    {-category ""}
} {
    Get the category_id from a category
    
    @param category Name of the category. This is not translated!
} {
    if {$category eq ""} {return ""}
    return [util_memoize [list db_string cat "select category_id from im_categories where category = '$category'" -default {}]]
}


# Hierarchical category select:
# Uses the im_category_hierarchy table to determine
# the hierarchical structure of the category type.
#
ad_proc im_category_select {
    {-translate_p 1}
    {-multiple_p 0}
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-plain_p 0}
    {-super_category_id 0}
    {-cache_interval 3600}
    category_type
    select_name
    { default "" }
} {
    Hierarchical category select:
    Uses the im_category_hierarchy table to determine
    the hierarchical structure of the category type.

    @param multiple_p You can select multiple categories
} {
    return [util_memoize [list im_category_select_helper -multiple_p $multiple_p -translate_p $translate_p -include_empty_p $include_empty_p -include_empty_name $include_empty_name -plain_p $plain_p -super_category_id $super_category_id $category_type $select_name $default] $cache_interval ]
}

ad_proc im_category_select_helper {
    {-translate_p 1}
    {-multiple_p 0}
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-plain_p 0}
    {-super_category_id 0}
    {-cache_interval 3600}
    category_type
    select_name
    { default "" }
} {
    Returns a formatted "option" widget with hierarchical
    contents.
    @param super_category_id determines where to start in the category hierarchy
} {
    if {$plain_p} {
	return [im_category_select_plain -translate_p $translate_p -include_empty_p $include_empty_p -include_empty_name $include_empty_name $category_type $select_name $default]
    }

    set super_category_sql ""
    if {0 != $super_category_id} {
	set super_category_sql "
	    and category_id in (
		select child_id
		from im_category_hierarchy
		where parent_id = :super_category_id
	    )
	"
    }

    # Read the categories into the a hash cache
    # Initialize parent and level to "0"
    set sql "
        select
                category_id,
                category,
                category_description,
                parent_only_p,
                enabled_p
        from
                im_categories
        where
                category_type = :category_type
		and enabled_p = 't'
		$super_category_sql
        order by lower(category)
    "
    db_foreach category_select $sql {
        set cat($category_id) [list $category_id $category $category_description $parent_only_p $enabled_p]
        set level($category_id) 0
    }

    # Get the hierarchy into a hash cache
    set sql "
        select
                h.parent_id,
                h.child_id
        from
                im_categories c,
                im_category_hierarchy h
        where
                c.category_id = h.parent_id
                and c.category_type = :category_type
		$super_category_sql
        order by lower(category)
    "

    # setup maps child->parent and parent->child for
    # performance reasons
    set children [list]
    db_foreach hierarchy_select $sql {
	if {![info exists cat($parent_id)]} { continue}
	if {![info exists cat($child_id)]} { continue}
        lappend children [list $parent_id $child_id]
    }

    # Calculate the level(category) and direct_parent(category)
    # hash arrays. Please keep in mind that categories from a DAG 
    # (directed acyclic graph), which is a generalization of a tree, 
    # with "multiple inheritance" (one category may have more then
    # one direct parent).
    # The algorithm loops through all categories and determines
    # the depth-"level" of the category by the level of a direct
    # parent+1.
    # The "direct_parent" relationship is different from the
    # "category_hierarchy" relationship stored in the database: 
    # The category_hierarchy is the "transitive closure" of the
    # "direct_parent" relationship. This means that it also 
    # contains the parent's parent of a category etc. This is
    # useful in order to quickly answer SQL queries such as
    # "is this catagory a subcategory of that one", because the
    # this can be mapped to a simple lookup in category_hierarchy 
    # (because it contains the entire chain). 

    set count 0
    set modified 1
    while {$modified} {
        set modified 0
        foreach rel $children {
            set p [lindex $rel 0]
            set c [lindex $rel 1]
            set parent_level $level($p)
            set child_level $level($c)
            if {[expr $parent_level+1] > $child_level} {
                set level($c) [expr $parent_level+1]
                set direct_parent($c) $p
                set modified 1
            }
        }
        incr count
        if {$count > 1000} {
            ad_return_complaint 1 "Infinite loop in 'im_category_select'<br>
            The category type '$category_type' is badly configured and contains
            and infinite loop. Please notify your system administrator."
            return "Infinite Loop Error"
        }
#	ns_log Notice "im_category_select: count=$count, p=$p, pl=$parent_level, c=$c, cl=$child_level mod=$modified"
    }

    set base_level 0
    set html ""
    if {$include_empty_p} {
        append html "<option value=\"\">$include_empty_name</option>\n"
        if {"" != $include_empty_name} {
            incr base_level
        }
    }

    # Sort the category list's top level. We currently sort by category_id,
    # but we could do alphabetically or by sort_order later...
    set category_list [array names cat]
    set category_list_sorted [lsort $category_list]

    # Now recursively descend and draw the tree, starting
    # with the top level
    foreach p $category_list_sorted {
        set p [lindex $cat($p) 0]
        set enabled_p [lindex $cat($p) 4]
	if {"f" == $enabled_p} { continue }
        set p_level $level($p)
        if {0 == $p_level} {
            append html [im_category_select_branch -translate_p $translate_p $p $default $base_level [array get cat] [array get direct_parent]]
        }
    }

    if {$multiple_p} {
	set select_html "<select name=\"$select_name\" multiple=\"multiple\">"
    } else {
	set select_html "<select name=\"$select_name\">"
    }
	return "
$select_html
$html
</select>
"

}


ad_proc im_category_select_branch { 
    {-translate_p 0}
    parent 
    default 
    level 
    cat_array 
    direct_parent_array 
} {
    Returns a list of html "options" displaying an options hierarchy.
} {
    if {$level > 10} { return "" }

    array set cat $cat_array
    array set direct_parent $direct_parent_array

    set category [lindex $cat($parent) 1]
    if {$translate_p} {
	set category_key "intranet-core.[lang::util::suggest_key $category]"
	set category [lang::message::lookup "" $category_key $category]
    }

    set parent_only_p [lindex $cat($parent) 3]

    set spaces ""
    for {set i 0} { $i < $level} { incr i} {
	append spaces "&nbsp; &nbsp; &nbsp; &nbsp; "
    }

    set selected ""
    if {$parent == $default} { set selected "selected" }
    set html ""
    if {"f" == $parent_only_p} {
        set html "<option value=\"$parent\" $selected>$spaces $category</option>\n"
	incr level
    }


    # Sort by category_id, but we could do alphabetically or by sort_order later...
    set category_list [array names cat]
    set category_list_sorted [lsort $category_list]

    foreach cat_id $category_list_sorted {
	if {[info exists direct_parent($cat_id)] && $parent == $direct_parent($cat_id)} {
	    append html [im_category_select_branch -translate_p $translate_p $cat_id $default $level $cat_array $direct_parent_array]
	}
    }

    return $html
}


ad_proc im_category_select_plain { 
    {-translate_p 1} 
    {-include_empty_p 1} 
    {-include_empty_name "--_Please_select_--"} 
    category_type 
    select_name 
    { default "" } 
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type

    set sql "
	select *
	from
		(select
			category_id,
			category,
			category_description
		from
			im_categories
		where
			category_type = :category_type
			and (enabled_p = 't' OR enabled_p is NULL)
		) c
	order by lower(category)
    "

    return [im_selection_to_select_box -translate_p $translate_p -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars category_select $sql $select_name $default]
}


ad_proc im_category_select_multiple { 
    {-translate_p 1}
    category_type 
    select_name 
    { default "" } 
    { size "6"} 
    { multiple ""}
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
	     from im_categories
	     where category_type = :category_type
	     order by lower(category)"
    return [im_selection_to_list_box -translate_p $translate_p $bind_vars category_select $sql $select_name $default $size multiple]
}    


ad_proc -public template::widget::im_category_tree { element_reference tag_attributes } {
    Category Tree Widget

    @param category_type The name of the category type (see categories
	   package) for valid choice options.

    The widget takes a tree from the categories package and displays all
    of its leaves in an indented drop-down box. For details on creating
    and modifying widgets please see the documentation.
} {
    upvar $element_reference element
    if { [info exists element(custom)] } {
	set params $element(custom)
    } else {
	return "Intranet Category Widget: Error: Didn't find 'custom' parameter.<br>
	Please use a Parameter such as:
	<tt>{custom {category_type \"Intranet Company Type\"}} </tt>"
    }

    # Get the "category_type" parameter that defines which
    # category to display
    set category_type_pos [lsearch $params category_type]
    if { $category_type_pos >= 0 } {
	set category_type [lindex $params [expr $category_type_pos + 1]]
    } else {
	return "Intranet Category Widget: Error: Didn't find 'category_type' parameter"
    }

    # Get the "plain_p" parameter to determine if we should
    # display the categories as an (ordered!) plain list
    # instead of a hierarchy.
    #
    set plain_p 0
    set plain_p_pos [lsearch $params plain_p]
    if { $plain_p_pos >= 0 } {
	set plain_p [lindex $params [expr $plain_p_pos + 1]]
    }

    # Get the "translate_p" parameter to determine if we should
    # translate the category items
    #
    set translate_p 0
    set translate_p_pos [lsearch $params translate_p]
    if { $translate_p_pos >= 0 } {
	set translate_p [lindex $params [expr $translate_p_pos + 1]]
    }

    # Get the "include_empty_p" parameter to determine if we should
    # include an empty first line in the widget
    #
    set include_empty_p 1
    set include_empty_p_pos [lsearch $params include_empty_p]
    if { $include_empty_p_pos >= 0 } {
	set include_empty_p [lindex $params [expr $include_empty_p_pos + 1]]
    }

    array set attributes $tag_attributes
    set category_html ""
    set field_name $element(name)

    set default_value_list $element(values)

    set default_value ""
    if {[info exists element(value)]} {
	set default_value $element(values)
    }

    if {0} {
	set debug ""
	foreach key [array names element] {
	    set value $element($key)
	    append debug "$key = $value\n"
	}
	ad_return_complaint 1 "<pre>$element(name)\n$debug\n</pre>"
	return
    }


    if { "edit" == $element(mode)} {
	append category_html [im_category_select -translate_p 1 -include_empty_p $include_empty_p -include_empty_name "" -plain_p $plain_p $category_type $field_name $default_value]


    } else {
	if {"" != $default_value && "\{\}" != $default_value} {
	    append category_html [db_string cat "select im_category_from_id($default_value) from dual" -default ""]
	}
    }
    return $category_html
}


ad_proc -public im_category_is_a { 
    child
    parent
    { category_type "" }
} {
    Returns 1 if the first category "is_a" second category.
    Can be called with two integers (third argument empty) or
    with two categories plus the category type as the third argument.
} {
    if {$child == $parent} { return 1 }

    if {"" == $category_type} {
	if {![string is integer $child]} { ad_return_complaint 1 "First argument is not an integer" }
	if {![string is integer $parent]} { ad_return_complaint 1 "First argument is not an integer" }

	return [db_string is_a "
		select	count(*)
		from	im_category_hierarchy
		where	parent_id = :parent
			and child_id = :child
        " -default 0]
    }

    set child_id [db_string child "select category_id from im_categories where category = :child and category_type = :category_type" -default ""]
    set parent_id [db_string child "select category_id from im_categories where category = :parent and category_type = :category_type" -default ""]

    if {"" == $child_id} { ad_return_complaint 1 "<b>Internal Error</b>:<br>im_category_is_a: Category '$child' is not part of '$category_type'" }
    if {"" == $parent_id} { ad_return_complaint 1 "<b>Internal Error</b>:<br>im_category_is_a: Category '$parent' is not part of '$category_type'" }

    return [db_string is_a "
	select	count(*)
	from	im_category_hierarchy
	where	parent_id = :parent_id 
		and child_id = :child_id
    " -default 0]
}


# ---------------------------------------------------------------
# Category Hierarchy Helper
# ---------------------------------------------------------------

ad_proc -public im_sub_categories {
    category_list
} {
    Takes a single category or a list of categories and
    returns a list of the transitive closure (all sub-
    categories) plus the original input categories.
} {
    # Add a dummy value so that an empty input list doesn't
    # give a syntax error...
    lappend category_list 0
    
    # Check security. category_list should only contain integers.
    if {[regexp {[^0-9\ ]} $category_list match]} { 
	im_security_alert \
	    -location "im_category_subcategories" \
	    -message "Received non-integer value for category_list" \
	    -value $category_list
	return [list]
    }

    set closure_sql "
	select	category_id
	from	im_categories
	where	category_id in ([join $category_list ","])
      UNION
	select	child_id
	from	im_category_hierarchy
	where	parent_id in ([join $category_list ","])
    "

    set result [db_list category_trans_closure $closure_sql]

    # Avoid SQL syntax error when the result is used in a where x in (...) clause
    if {"" == $result} { set result [list 0] }

    return $result
}

