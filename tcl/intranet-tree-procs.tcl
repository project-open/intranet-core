# tcl/ad-trees.tcl

ad_library {

<a href="http://www.photo.net/photo/pcd4228/joshua-tree-10.4.jpg"><img WIDTH=256 HEIGHT=331 src="http://www.photo.net/photo/pcd4228/joshua-tree-10.2.jpg" align=right ALT="Joshua Tree.  Joshua Tree National Park."></a>

Provides functions for
<ul>
<li>retrieving trees from the database: <i>db_tree</i>
<li>manipulating trees: <i>tree_map</i>, <i>tree_height</i>, <i>tree_width</i>
<li>printing trees as HTML tables: <i>tree_to_table</i> and <i>tree_to_horizontal_table</i>
</ul>

Trees are represented with the following structure:
<pre>
tree = root
     | {root {list of subtrees}}
     </pre>
     A leaf is represented by the element itself.
     Otherwise, a tree is a list whose first element is the root
     and whose subsequent elements represent the subtrees of the root.

     <h4>Example:</h4>
<pre>
  5
 / \ 
4   7     is represented by   5 4 {7 {6 2 3 9} 8}
   / \ 
  6   8
 /|\  
2 3 9
</pre>

    @creation-date 2000 April 06
    @author Mark Dettinger (mdettinger@arsdigita.com)
    @cvs-id ad-trees.tcl,v 3.5.2.4 2000/07/29 05:35:03 mdetting Exp
}

# --------------------------------------------------------------------------------
# Tcl Trees
# --------------------------------------------------------------------------------

ad_proc -public tree_map {func tree} "applies a function to each element of a tree" {
    set root [$func [head $tree]]
    set subtrees [map [bind tree_map $func] [tail $tree]]
    cons $root $subtrees
}

# database_to_tcl_tree has been replaced by db_tree.
# It remains only for backwards compatibility.

ad_proc -deprecated -warn database_to_tcl_tree {sql} "takes a 'connect by' SQL query and returns the result as a tree" {
    # Augment the SQL query by selecting the level.
    regsub select $sql "select level," sql
    # query the database
    set list [db_list_of_lists ad_tree_database_to_tcl_tree $sql]
    # Construct a tree from the result.
    # Afterwards, eliminate the level attribute in the tree.
    tree_map tail [tree_make $list head]
}

ad_proc -public db_tree {sql_name sql args} {
    Takes a 'connect by' SQL query and returns the result as a tree.<br>
    A tree is either just one element or a list whose first element is the root
    and whose subsequent elements are the subtrees of the root.

    <h4>Example (taken from <a href="http://photo.net/sql/trees.html">http://photo.net/sql/trees.html</a>)</h4>

    <pre>    
    % db_tree org_chart_get "select slave_id from corporate_slaves
                             start with slave_id = 1
                             connect by prior slave_id = supervisor_id"
    1 2 {3 {4 5}} {6 7 8}
    </pre>
    This result represents the tree
    <pre>
      1
     /|\ 
    2 3 6
      | |\ 
      4 7 8
      |
      5
    </pre>
} {
    ad_arg_parser { bind } $args

    # Augment the SQL query by selecting the level.
    regsub select $sql "select level," sql

    # query the database
    if { [info exists bind] } {
	set list [db_list_of_lists ad_tree_db_tree_query $sql -bind $bind]
    } else {
	set list [db_list_of_lists ad_tree_db_tree_query $sql]
    }

    # Construct a tree from the result.
    # Afterwards, eliminate the level attribute in the tree.
    tree_map tail [tree_make $list head]
}

# --------------------------------------------------------------------------------
# computing the height and width of a tree
# --------------------------------------------------------------------------------

ad_proc -public tree_height {tree} "returns the height of a tree" {
    if { [empty_string_p $tree] } { return 0 }
    expr 1+[fold max 0 [map tree_height [tail $tree]]]
}

ad_proc -public tree_width {tree} "returns the width of a tree" {
    if { [empty_string_p $tree] } { return 0 }
    max 1 [sum [map tree_width [tail $tree]]]
}

# --------------------------------------------------------------------------------
# printing a tree as an indented list
# --------------------------------------------------------------------------------

ad_proc -public tree_print {tree {indent 0}} "prints a tree" {
    set result ""
    for {set i 0} {$i<$indent} {incr i} { 
	append result " "
    }
    append result [head $tree]\n
    foreach t [tail $tree] {
	append result [print_tree $t [expr $indent+2]]
    }
    return $result
}

# --------------------------------------------------------------------------------
# printing a tree as an HTML table (root on top)
# --------------------------------------------------------------------------------

ad_proc tree_level {tree n {result {}}} "returns the n-th level of a tree (where 0 is the root tree) as a list of trees" {
    if { [empty_string_p $tree] } { return $result }
    if { $n==0 } {
	lappend result $tree
    } else {
	foreach subtree [tail $tree] {
	    set result [tree_level $subtree [expr $n-1] $result]
	}
    }
    return $result
}

ad_proc -public tree_to_table {tree} {
    Generates a table display of the given tree (with the root on top).
} {
    set h [tree_height $tree]
    set result "<table border>\n"
    for {set level 0} {$level<$h} {incr level} {
	append result "<tr>\n"
	foreach subtree [tree_level $tree $level] {
	    if { [llength $subtree]==1 } {
		set rowspan [expr $h-$level]
	    } else {
		set rowspan 1
	    }	    
	    append result "  <td valign=top align=center rowspan=$rowspan colspan=[tree_width $subtree]>[head $subtree]</td>\n"	    
	}
	append result "</tr>\n"
    }
    append result "</table>\n"
    return $result
}

# --------------------------------------------------------------------------------
# printing a tree as an HTML table (root on left side)
# --------------------------------------------------------------------------------

ad_proc -public tree_to_horizontal_table {tree print} {
    Generates a table display of the given tree;
    root on left side like in the 
    <a href="/intranet/employees/org-chart">org chart</a>.
    <p>
    <i>print</i> is a binary function that is applied to
    each tree element before it is printed. The arguments
    of <i>print</i> are the element itself and the element's
    row span in the tree. See <a href="/api-doc/proc-view?proc=im_print_employee">
    im_print_employee</a> for an example.
} {
    set result "<table border>\n<tr>\n"
    append result [tree_to_htable $tree [tree_height $tree] 0 $print ""]
    append result "</tr>\n</table>\n"
    return $result
}

ad_proc tree_to_htable {tree height new_row_p print result} {
    auxiliary function of <i>tree_to_horizontal_table</i>
} {
    if { $new_row_p } { 
	append result "</tr>\n<tr>\n" 
    }
    if { [llength $tree]==1 } {
	set colspan $height
    } else {
	set colspan 1
    }
    set rowspan [tree_width $tree]
    append result "  <td rowspan=$rowspan colspan=$colspan>[$print [head $tree] $rowspan]</td>\n"
    set new_row_p 0
    foreach subtree [tail $tree] {
	append result [tree_to_htable $subtree [expr $height-1] $new_row_p $print ""] 
	set new_row_p 1
    }
    return $result
}

# --------------------------------------------------------------------------------
# Auxiliary Functions
# --------------------------------------------------------------------------------

ad_proc tree_make {xs {node_level head}} "Generates a tree from a level sequence that was returned by a 'connect by' SQL query." {
    set root [head $xs]
    set subtrees [map tree_make [tree_group [tail $xs] $node_level]]
    cons $root $subtrees
}

ad_proc tree_group {xs {node_level id}} "Divides a list into groups.
The first element of the list provides the key value that starts a new group.
Example: tree_group {1 2 3 2 1 2 1 1 2 2} = {1 2 3 2} {1 2} 1 {1 2 2}
The optional argument node_level is a function that extracts the
value of an element. By default, this is the identity function id.
Example: tree_group {{a 1} {b 2} {c 1}} snd = {{a 1} {b 2}} {c 1}" {
    if { $xs=={} } return {}
    set key [$node_level [head $xs]]
    set list {}
    set sublist {}
    foreach x $xs {
	if { $sublist=={} || [$node_level $x]!=$key } {
	    lappend sublist $x
	} else {
	    lappend list $sublist
	    set sublist [list $x]
	}
    }
    lappend list $sublist
    return $list
}

