# /packages/intranet-core/www/admin/categories/index.tcl
#
# Copyright (C) 2004 ]project-open[
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

ad_page_contract {
  Home page for category administration.

  @author sskracic@arsdigita.com
  @author michael@yoon.org
  @author guillermo.belcic@project-open.com
  @author frank.bergmann@project-open.com
  @author klaus.hofeditz@project-open.com

} {
    { select_category_type "All" }
}

set user_id [auth::require_login]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set return_url [im_url_with_query]


set page_title [lang::message::lookup "" intranet-core.Category_Types "Category Types"]
if {"All" != $select_category_type} { set page_title [lang::message::lookup "" intranet-core.One_Category_Type "%select_category_type%"] }
set context_bar [im_context_bar $page_title]
set context ""
set page_focus "category_select_form.select_category_type"
set new_href "one"

set bgcolor(0) " class=rowodd"
set bgcolor(1) " class=roweven"

set show_add_new_category_p 1
if {"" == $select_category_type} { set show_add_new_category_p 0 }
if {"All" == $select_category_type} { set show_add_new_category_p 0 }

# Calculate the URL in the online help for this category
regsub -all " " [string tolower $select_category_type] "-" category_key
set category_help_url "https://www.project-open.com/en/category-$category_key"

# Include JS for tablesorter
template::head::add_javascript -src "/intranet/js/jquery.tablesorter.min.js" -order 10000

# ------------------------------------------------------------------
# Filter
# ------------------------------------------------------------------

set form_id "filter"
set action_url "/intranet/admin/categories/index"
set form_mode "edit"

set select_category_types_sql "
	select distinct
		c.category_type as cat_type
	from	im_categories c
	group by c.category_type
	order by c.category_type asc
" 
set cat_options [list [list All All]]
db_foreach cats $select_category_types_sql {
    lappend cat_options [list $cat_type $cat_type]
}

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export { }\
    -form {
        {select_category_type:text(select),optional {label "[lang::message::lookup {} intranet-core.Cat_Type {Cat Type}]"} {options $cat_options}}
    }

template::element::set_value $form_id select_category_type $select_category_type



# ---------------------------------------------------------------
# Render Category List
# ---------------------------------------------------------------

if {$show_add_new_category_p} {

    set category_list_html "
	<table id='myTable' class='tablesorter' border=0>
	<thead>
	<tr>
	  <th style='min-width:35px'>Id</th>
	  <th style='min-width:35px'>En</th>
	  <th style='min-width:75px'>Category</th>
	  <th style='min-width:60px'>Sort<br>Order</th>
	  <th style='min-width:50px'>Is-A</th>
	  <th style='min-width:50px'>Int1</th>
	  <th style='min-width:50px'>Int2</th>
	  <th style='min-width:60px'>String1</th>
	  <th style='min-width:60px'>String2</th>
	  <th style='min-width:60px'>Visible TCL</th>
    "

    if {"All" eq $select_category_type} {
	append category_list_html "<th style='min-width:100px'>Category Type</th>"
    }
    append category_list_html "<th style='min-width:90px'>Description</th></thead></tr>"

    # Now let's generate the sql query
    set criteria [list]
    set bind_vars [ns_set create]
    
    set category_type_criterion "1=1"
    if {"All" ne $select_category_type } {
	set category_type_criterion "c.category_type = :select_category_type"
    }
    
    set ctr 1
    set old_id 0
    db_foreach category_select {} {

	incr ctr

	if {"" == $enabled_p } { set enabled_p "t" }
	set toggle_url [export_vars -base "/intranet/admin/categories/toggle" {category_id return_url enabled_p}]

	if {$old_id == $category_id} {
	    # We got another is-a for the same category
	    append category_list_html "
	<tbody>
        <tr $bgcolor([expr {$ctr % 2}])>
	  <td></td>
	  <td></td>
	  <td></td>
	  <td></td>
	  <td><A href=\"/intranet/admin/categories/one?category_id=$parent_id\">$parent</a></td>
	  <td></td>
	  <td></td>
	  <td></td>
	  <td></td>
	  <td></td>
	    "
	    if {"All" eq $select_category_type} {
		append category_list_html "<td></td>"
	    }
	    append category_list_html "<td></td></tr>\n"
	    continue
	}

	if {"t" eq $enabled_p} { 
	    set enabled_html "<b><font>t</font></b>"
	} else {
	    set enabled_html "<b><font color=red>f</font></b>"
	}

	append category_list_html "
	<tr $bgcolor([expr {$ctr % 2}])>
	  <td>$category_id</td>
	  <td><a href='$toggle_url'>$enabled_html</a></td>
	  <td><a href=\"one.[export_vars -base tcl {category_id}]\">$category</A></td>
	  <td>$sort_order</td>
	  <td><A href=\"/intranet/admin/categories/one?category_id=$parent_id\">$parent</A></td>
	  <td>$aux_int1 $aux_int1_cat</td>
	  <td>$aux_int2 $aux_int2_cat</td>
	  <td>$aux_string1</td>
	  <td>$aux_string2</td>
	  <td>$visible_tcl</td>
        "
	if {"All" eq $select_category_type} {
	    append category_list_html "<td>$select_category_type</td>"
	}
	append category_list_html "<td>$category_description</td></tr>\n"
	set old_id $category_id
    }
    
    append category_list_html "</tbody></table>"
    
    if {"All" ne $select_category_type } {
	set category_type $select_category_type
	
	set new_href [export_vars -base "one" {{category_type $select_category_type}}]
	
	append category_list_html "
	<ul>
	  <a href=\"$new_href\">
	  Add a category
	  </a>
	</ul>
	"

	set object_type [im_category_object_type -category_type $select_category_type]
	if {$object_type ne ""} {
	    set tam_href [export_vars -base "/intranet-dynfield/attribute-type-map" {object_type}]
	    append category_list_html "
	        <ul>
		   <a href=\"$tam_href\">
		  <b>Attribute-Type-Map</b>
		  </a>
		</ul>
	    "
	}
    }
}


if {!$show_add_new_category_p} {

    list::create \
	-name categories \
	-multirow category_types \
	-row_pretty_plural "Category Types" \
	-elements {
	    cnt {
		label "Count"
	    }
	    category_type {
		label "Category Type"
		link_url_eval $category_type_url
	    }
	    help_link {
		label "Help Link"
		link_url_eval $help_link_url
	    }
	}

    db_multirow -extend { category_type_url help_link help_link_url } category_types select_category_types {
		select
			count(*) as cnt,
			category_type
		from	im_categories
		group by
			category_type
		order by
			category_type
    } {
	set category_type_url [export_vars -base "/intranet/admin/categories/index" {{select_category_type $category_type}}]
	set help_link [lang::message::lookup "" intranet-core.Context_Help "Context Help"]
	regsub -all { } $category_type {-} category_type_regsub
	set help_link_url "https://www.project-open.com/en/category-[string tolower $category_type_regsub]"
    }
    
	    
    set category_list_html "empty"
}


# ------------------------------------------------------------------
# NavBar
# ------------------------------------------------------------------

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate style=tiny-plain-po id="filter"></formtemplate>}]
set filter_html $__adp_output

if {$show_add_new_category_p} {
    set admin_html "<li><a href='$new_href'>Add a new category type</a>  "
} else {
    set admin_html "<li><a href='one?new_category=1'>Add a new Category Type</a>"
}

if {"All" != $select_category_type && "" != $select_category_type} {
    append admin_html "<li><a href='[export_vars -base "/intranet/admin/categories/batch-import" {category_type}]'>Batch import categories for this type</a>"
}

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
        <div class='filter-block'>
                <div class='filter-title'>
                   [lang::message::lookup "" intranet-core.Filter_Categories "Filter Categories"]
                </div>
		$filter_html
        </div>
      <hr/>
      <div class='filter-block'>
	<div class='filter-title'>
		[lang::message::lookup "" intranet-exchange-rate.Admin_Links "Admin Links"]
	</div>
	<ul>
		$admin_html
	</ul>
      </div>
"


