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
    @author malte.sussdorff@project-open.com
}


ad_proc -public im_category_from_id { 
    {-translate_p 1}
    {-package_key "intranet-core" }
    {-locale ""}
    {-empty_default ""}
    category_id 
} {
    Convert a category_id integer into a category name.
} {
    if {![string is integer $category_id]} { return $category_id }
    if {"" == $category_id} { return $empty_default }
    if {0 == $category_id} { return $empty_default }
    set category_name [util_memoize "db_string cat \"select im_category_from_id($category_id)\" -default {}"]
    set category_key [lang::util::suggest_key $category_name]
    if {$translate_p} {
	if {"" == $locale} { set locale [lang::user::locale -user_id [ad_get_user_id]] }
	set category_name [lang::message::lookup $locale "$package_key.$category_key" $category_name]
    }

    return $category_name
}

ad_proc -public im_id_from_category { 
    { -list_p 1}
    category
    category_type
} {
    Convert a category_name into a category_id.
    Returns "" if the category isn't found.
} {
    return [util_memoize [list im_id_from_category_helper -list_p $list_p $category $category_type]]
}

ad_proc -public im_id_from_category_helper { 
    { -list_p 0}
    category
    category_type
} {
    Convert a category_name into a category_id.
    Returns "" if the category isn't found.
} {
    set id [db_string id_from_cat "
		select	category_id
		from	im_categories
		where	category = :category and
			category_type = :category_type
    " -default ""]
    if {"" != $id} { return $id }

    if {$list_p} {
	set results [list]
	foreach cat $category {
	    set id [db_string id_from_cat "
		select	category_id
		from	im_categories
		where	category = :cat and
			category_type = :category_type
            " -default ""]
	    if {"" != $id} { lappend results $id }
	}
	return $results
    }
    return ""
}



ad_proc -public im_category_from_category {
    {-category ""}
} {
    Get the category_id from a category
    
    @param category Name of the category. This is not translated!
} {
    if {$category eq ""} {return ""}
    return [util_memoize [list db_string cat "
	select	category_id
	from	im_categories
	where	category = '$category'
    " -default {}]]
}


# Hierarchical category select:
# Uses the im_category_hierarchy table to determine
# the hierarchical structure of the category type.
#
ad_proc im_category_select {
    {-no_cache:boolean}
    {-translate_p 1}
    {-package_key "intranet-core" }
    {-multiple_p 0}
    {-include_empty_p 0}
    {-include_empty_name "All"}
    {-plain_p 0}
    {-super_category_id 0}
    {-cache_interval 3600}
    {-locale "" }
    category_type
    select_name
    { default "" }
} {
    Hierarchical category select:
    Uses the im_category_hierarchy table to determine
    the hierarchical structure of the category type.

    @param multiple_p You can select multiple categories
} {
    if {"" == $locale} { set locale [lang::user::locale -user_id [ad_get_user_id]] }

    if {$no_cache_p} {
	return [im_category_select_helper -multiple_p $multiple_p -translate_p $translate_p -package_key $package_key -locale $locale -include_empty_p $include_empty_p -include_empty_name $include_empty_name -plain_p $plain_p -super_category_id $super_category_id $category_type $select_name $default]
    } else {
	return [util_memoize [list im_category_select_helper -multiple_p $multiple_p -translate_p $translate_p -package_key $package_key -locale $locale -include_empty_p $include_empty_p -include_empty_name $include_empty_name -plain_p $plain_p -super_category_id $super_category_id $category_type $select_name $default] $cache_interval ]
    }
}

ad_proc im_category_select_helper {
    {-translate_p 1}
    {-package_key "intranet-core" }
    {-locale "" }
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
	return [im_category_select_plain -translate_p $translate_p -package_key $package_key -locale $locale -include_empty_p $include_empty_p -include_empty_name $include_empty_name $category_type $select_name $default]
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
		and (enabled_p = 't' OR enabled_p is NULL)
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
            append html [im_category_select_branch -translate_p $translate_p -package_key $package_key -locale $locale $p $default $base_level [array get cat] [array get direct_parent]]
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
    {-package_key "intranet-core" }
    {-locale "" }
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
	set category_key "$package_key.[lang::util::suggest_key $category]"
	set category [lang::message::lookup $locale $category_key $category]
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
	    append html [im_category_select_branch -translate_p $translate_p -package_key $package_key -locale $locale $cat_id $default $level $cat_array $direct_parent_array]
	}
    }

    return $html
}


ad_proc im_category_select_plain { 
    {-translate_p 1} 
    {-package_key "intranet-core" }
    {-locale "" }
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

    return [im_selection_to_select_box -translate_p $translate_p -package_key $package_key -locale $locale -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars category_select $sql $select_name $default]
}


ad_proc im_category_select_multiple { 
    {-translate_p 1}
    {-locale ""}
    category_type 
    select_name 
    { default "" } 
    { size "6"} 
    { multiple ""}
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "
	select	category_id,
		category
	from	im_categories
	where	category_type = :category_type
		and (enabled_p = 't' OR enabled_p is NULL)
	order by lower(category)"
    return [im_selection_to_list_box -translate_p $translate_p -locale $locale $bind_vars category_select $sql $select_name $default $size multiple]
}


ad_proc -public template::widget::im_category_tree { 
    element_reference 
    tag_attributes 
} {
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

    # Get the "package_key" parameter to determine in which package
    # to translate the category items
    #
    set package_key "intranet-core"
    set package_key_pos [lsearch $params "package_key"]
    if { $package_key_pos >= 0 } {
	set package_key [lindex $params [expr $package_key_pos + 1]]
    }

    # Get the "include_empty_p" parameter to determine if we should
    # include an empty first line in the widget
    #
    set include_empty_p 1
    set include_empty_p_pos [lsearch $params include_empty_p]
    if { $include_empty_p_pos >= 0 } {
	set include_empty_p [lindex $params [expr $include_empty_p_pos + 1]]
    }

    # Get the "include_empty_name" parameter to determine if we should
    # include an empty first line in the widget
    #
    set include_empty_name ""
    set include_empty_name_pos [lsearch $params include_empty_name]
    if { $include_empty_name_pos >= 0 } {
	set include_empty_name [lindex $params [expr $include_empty_name_pos + 1]]
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
	append category_html [im_category_select -translate_p 1 -package_key $package_key -include_empty_p $include_empty_p -include_empty_name $include_empty_name -plain_p $plain_p $category_type $field_name $default_value]
    } else {
	if {"" != $default_value && "\{\}" != $default_value} {
	    append category_html [im_category_from_id $default_value]
	}
    }
    return $category_html
}


ad_proc -public template::widget::im_checkbox {
    element_reference
    tag_attributes
} {
    Render a checkbox input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    if { [exists_and_not_null element(custom)] } {

	set params $element(custom)

	# Get the "checked" parameter that defines if the checkbox should
	# be checked
        set checked ""
	set checked_pos [lsearch $params checked]
	if { $checked_pos >= 0 } {
	    set checked [lindex $params [expr $checked_pos + 1]]
	}

	if {"" != $checked} {
	    lappend tag_attributes checked
	    lappend tag_attributes $checked
	}
    }

    ns_log Notice "template::widget::checkbox: element=[array get element]"
    ns_log Notice "template::widget::checkbox: tag_attributes=$tag_attributes, elem_ref=$element_reference"
    
    return [input checkbox element $tag_attributes]
}



ad_proc -public im_category_is_a { 
    child
    parent
    { category_type "" }
} {
    Cached version of im_category_is_a
} {
    return [util_memoize [list im_category_is_a_helper $child $parent $category_type]]
}

ad_proc -public im_category_is_a_helper { 
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



ad_proc -public im_category_get_key_value_list {
    { category_type "" }
} {
        set sql "

        select
                category_id,
                category
        from
                im_categories
        where
                category_type = '$category_type'
        "
    set category_list [list]
    db_foreach category_select $sql {
        lappend category_list [list $category_id $category]
    }
        return $category_list
}


# ---------------------------------------------------------------
# Category Hierarchy Helper
# ---------------------------------------------------------------

ad_proc -public im_sub_categories {
    {-include_disabled_p 0}
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
    im_security_alert_check_integer \
	-location "im_sub_categories" \
	-value $category_list

    # Should we include disabled categories? This is necessary for
    # example if we want to disable all sub-categories of a top category
    set enabled_check "and (c.enabled_p = 't' OR c.enabled_p is NULL)"
    if {$include_disabled_p} { set enabled_check "" }

    set closure_sql "
	select	category_id
	from	im_categories c
	where	c.category_id in ([join $category_list ","])
		$enabled_check
      UNION
	select	h.child_id
	from	im_categories c,
		im_category_hierarchy h
	where	h.parent_id in ([join $category_list ","])
		and h.child_id = c.category_id
		$enabled_check
    "

    set result [db_list category_trans_closure $closure_sql]

    # Avoid SQL syntax error when the result is used in a where x in (...) clause
    if {"" == $result} { set result [list 0] }

    return $result
}


ad_proc -public im_category_parents {
    {-include_disabled_p 0}
    category
} {
    Returns a list of all parents of a specific category
} {
    return [util_memoize [list im_category_parents_helper -include_disabled_p $include_disabled_p $category]]
}


ad_proc -public im_category_parents_helper {
    {-include_disabled_p 0}
    category
} {
    Returns a list of all parents of a specific category
} {
    set disabled_sql "and (enabled_p = 't' OR enabled_p is null)"
    if {$include_disabled_p} { set disabled_sql "" }
    set parent_category_sql "
	select	category_id
	from	im_categories
	where	category_id in (
			select	parent_id
			from	im_category_hierarchy
			where	child_id = :category
		)
		$disabled_sql
    "
    return [db_list parent_categories $parent_category_sql]
}


ad_proc -public im_category_object_type {
    {-category_type}
} {
    Returns the object_type for a category_type when it is used as a type category type like "Intranet Project Type". Empty String otherwise
    @param category_type The category type like "Intranet Project Type"
} {
    return [util_memoize [list db_string object_type "
	select	object_type
	from	acs_object_types
	where	type_category_type = '$category_type' 
	limit 1
    " -default ""]]
}




ad_proc im_biz_object_category_select_branch { 
    {-translate_p 0}
    {-package_key "intranet-core" }
    {-type_id_var "category_id" }
    parent 
    default 
    level 
    cat_array 
    direct_parent_array 
} {
    Recursively descend the category tree.
    Returns a list of html "input type=radio" displaying an options hierarchy.
} {
    if {$level > 10} { return "" }

    array set cat $cat_array
    array set direct_parent $direct_parent_array

    set category [lindex $cat($parent) 1]
    set category_description [lindex $cat($parent) 2]
    if {$translate_p} {
	set category_key "$package_key.[lang::util::suggest_key $category]"
	set org_category $category
	set category [lang::message::lookup "" $category_key $category]
	set category_description_key "$package_key.[lang::util::suggest_key $org_category]-Message"
	set category_description "[lang::message::lookup "" $category_description_key " $category_description"]"
    }

    set parent_only_p [lindex $cat($parent) 3]

    set spaces ""
    for {set i 0} { $i < $level} { incr i} {
	append spaces "&nbsp; &nbsp; &nbsp; &nbsp; "
    }

    set selected ""
    if {$parent == $default} { set selected "selected" }
    set html ""
    set class "plain"
    if {0 == $level} { set class "rowtitle" }
    if {"f" == $parent_only_p} {
        set html "
	<tr class=$class>
	<td class=$class><nobr> 
	<input type=radio name=\"$type_id_var\" value=$parent $selected >$spaces $category </input>&nbsp;
	</nobr></td>
	<td class=$class>$category_description</td>
	</tr>
	"
	incr level
    }

    # Sort by category_id, but we could do alphabetically or by sort_order later...
    set category_list [array names cat]

    set sub_list [list]
    foreach cat_id $category_list {
        if {[info exists direct_parent($cat_id)] && $parent == $direct_parent($cat_id)} {
            lappend sub_list [list $cat_id [lindex $cat($cat_id) 5]]
        }
    }

    foreach sublist [lsort -index 1 $sub_list] {
        set cat_id [lindex $sublist 0]
        append html [im_biz_object_category_select_branch -translate_p $translate_p -package_key $package_key -type_id_var $type_id_var $cat_id $default $level $cat_array $direct_parent_array]
    }
    return $html
}

