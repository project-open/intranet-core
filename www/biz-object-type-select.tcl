# /packages/intranet-core/www/biz-object-type-select.tcl
#
# Copyright (c) 2008 ]project-open[
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
    We get redirected here from any object's "New" page if there
    are DynFields per object subtype and no type is specified.

    @param object_type The type of object. From the object type
                       we can deduce the category holding it's
                       type options.
    @param type_id_var The variable from the target New page
                       that represents the object's type_id.
                       Example: absence_type_id for the 
                       "im_absence" object type.
    @param return_url Return URL
    @param project_id  Optional parameter to display a suitable
    	   	       project menu to give users the illusion
		       to stay within their project.

    @author christof.damian@project-open.com
} {
    object_type
    type_id_var
    return_url
    project_id:optional
    user_id_from_search:optional
    { pass_through_variables "" }
    { exclude_category_ids {} }
}

# No permissions necessary, that's handled by the object's new page
# Here we just select an object_type_id for the given object.

if {[catch {db_1row otype_info "
	select	pretty_name as object_type_pretty
	from	acs_object_types
	where	object_type = '$object_type'
"} err_msg]} {
   ad_return_complaint 1 "
        <b>[lang::message::lookup "" intrant-core.Internal_Error "Internal Error"]</b>:<br>
        [lang::message::lookup "" intrant-core.Object_Type_not_found "
       		Didn't find object_type '%object_type%'.
	"]
   "
   ad_script_abort
}

# Check for the list of categories to exclude.
set exclude_ids [list 0]
foreach id $exclude_category_ids {
    if {"" != $id && [string is integer $id]} { lappend exclude_ids $id}
}

regsub -all " " $object_type_pretty "_" object_type_pretty_key
set object_type_l10n [lang::message::lookup "" intranet-core.$object_type_pretty_key $object_type_pretty]
set page_title [lang::message::lookup "" intranet-core.Please_Select_Type_for_Object "Please select a type of %object_type_l10n%"]
set context_bar [im_context_bar $page_title]

set object_type_category [im_dynfield::type_category_for_object_type -object_type $object_type]


set category_select_html ""

set sql "
	select	c.*
	from	im_categories c
	where	c.category_type = :object_type_category
		and (c.enabled_p is null or c.enabled_p = 't')
		and c.category_id not in ([join $exclude_ids ","])
	order by
		sort_order, category
"
db_foreach cats $sql {

    regsub -all " " $category "_" category_key
    set category_l10n [lang::message::lookup "" intranet-core.category_key $category]
    set category_comment_key ${category_key}_comment

    set comment $category_description
    if {"" == $comment} { set comment " " }
    set comment [lang::message::lookup "" intranet-core.$category_comment_key $comment]

    append category_select_html "
	<tr>
		<td>
		<nobr>
		<input type=radio name=$type_id_var value=$category_id>$category_l10n</input>
		&nbsp;
		</nobr>
		</td>
		<td>$comment</td>
	</tr>
    "

}
