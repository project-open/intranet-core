# /www/admin/categories/edit-parentage.tcl
ad_page_contract {

  Form for adding parents to and removing parents from a category.

  @param category_id Which category is being worked on

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id edit-parentage.tcl,v 3.3.2.6 2000/09/22 01:34:27 kevin Exp
} {

  category_id:naturalnum,notnull

}

set category [db_string category_name "
SELECT c.category
FROM categories c
WHERE c.category_id = :category_id" ]

set parentage_lines [ad_category_parentage_list $category_id]

set parentage_html ""

if { [llength $parentage_lines] == 0 } {
    append parentage_html "<li>none\n"

} else {
    foreach parentage_line $parentage_lines {
	set n_generations [llength $parentage_line]
	set n_generations_excluding_self [expr $n_generations - 1]

	set parentage_line_html [list]
	for { set i 0 } { $i < $n_generations_excluding_self } { incr i } {
	    set ancestor [lindex $parentage_line $i]
	    set ancestor_category_id [lindex $ancestor 0]
	    set ancestor_category [lindex $ancestor 1]
	    lappend parentage_line_html \
		    "<a href=\"one?category_id=$ancestor_category_id\">$ancestor_category</a>"
	}

	#  Display the category itself, but w/o hyperlink
	lappend parentage_line_html [lindex [lindex $parentage_line end] 1]

	if { [llength $parentage_line_html] == 0 } {
	    append parentage_html "<li>none\n"
	} else {
	    set parent_category_id [lindex [lindex $parentage_line [expr $n_generations - 2]] 0]

	    append parentage_html "<li>[join $parentage_line_html " : "] &nbsp; &nbsp; (<a href=\"remove-link-to-parent?[export_url_vars category_id parent_category_id]\">remove link to this parentage line</a>)\n"
	}
    }
}



doc_return  200 text/html "[ad_admin_header "Edit parentage"]

<h2>Edit parentage for $category</h2>

<p>

[ad_admin_context_bar [list "index" "Categories"] [list "one?[export_url_vars category_id]" $category] "Edit parentage"]

<hr>

Lines of parentage:

<ul>

$parentage_html

<p>
<li> <a href=\"add-link-to-parent?[export_url_vars category_id]\">
Define a parent</a>
</ul>

[ad_admin_footer]
"
