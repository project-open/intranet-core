# /packages/intranet-core/www/projects/project-type-select.tcl
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
    @param translate_p Should the categories be passed through
           the localization system? Default is 1
    @param package_key Required for localization. Specifies from
           which package to take the translation.

    @author christof.damian@project-open.com
    @author frank.bergmann@project-open.com
} {
    object_type
    type_id_var
    return_url
    project_id:optional
    { user_id_from_search:integer ""}
    { pass_through_variables "" }
    { exclude_category_ids {} }
    { translate_p 1 }
    { package_key "intranet-core" }
    { default_category_id 0}
}

# --------------------------------------------------------------
#
# --------------------------------------------------------------

# No permissions necessary, that's handled by the object's new page
# Here we just select an object_type_id for the given object.
set admin_p [im_is_user_site_wide_or_intranet_admin [ad_conn user_id]]
set system_id [im_system_id]
set po_net "http://www.project-open.net/en"
set po_gantt [export_vars -base "$po_net/project-type-gantt" {system_id}]
set po_agile [export_vars -base "$po_net/project-type-agile" {system_id}]
set po_mixed [export_vars -base "$po_net/project-type-mixed" {system_id}]
set po_maint [export_vars -base "$po_net/project-type-maintenance" {system_id}]
set po_trans [export_vars -base "$po_net/project-type-translation" {system_id}]
set click_me_l10n [lang::message::lookup "" intranet-core.Click_me "Click me for more information"]

set translation_p [db_string translation_p "select count(*) from apm_packages where package_key = 'intranet-translation'"]

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
set page_title [lang::message::lookup "" intranet-core.Project_Type_Select_Title "How do you want to get your work done?"]
if { [info exists user_id_from_search] && "" != $user_id_from_search && 0 != $user_id_from_search} {
    set user_name_from_search [acs_object_name $user_id_from_search]
    append page_title [lang::message::lookup "" intranet-timesheet2.for_user_name_from_search " for %user_name_from_search%"]
}
set context_bar [im_context_bar $page_title]
set object_type_category [im_dynfield::type_category_for_object_type -object_type $object_type]


# -----------------------------------------------------------
# Pass throught the values of pass_through_variables
# We have to take the values of these vars directly
# from the HTTP session.
# -----------------------------------------------------------


set form_vars [ns_conn form]
set pass_through_html ""
foreach var $pass_through_variables {
   set value [ns_set get $form_vars $var]
   append pass_through_html "
	<input type=hidden name=\"$var\" value=\"[ns_quotehtml $value]\">
   "
}



# -----------------------------------------------------------
# Gantt Project Subtypes
# -----------------------------------------------------------

set gantt_project_subtypes_html ""
set gantt_project_subtypes_sql "
        select	category_id,
                category,
                category_description
        from	im_categories
        where	(enabled_p = 't' OR enabled_p is NULL) and
		category_id not in ([join $exclude_ids ","]) and
		category_id in (select im_sub_categories([im_project_type_gantt])) and
		category_id not in ([im_project_type_gantt]) and
		category_id not in ([im_project_type_opportunity], [im_project_type_campaign], [im_project_type_milestone])
        order by lower(category)
"
db_foreach gantt $gantt_project_subtypes_sql {
    set category_l10n $category
    append gantt_project_subtypes_html "<tr valign=top>\n"
    append gantt_project_subtypes_html "<td><input type=\"radio\" name=\"project_type_id\" value=\"$category_id\" onclick=\"window.scrollTo(0, document.body.scrollHeight);\"></td>\n"
    append gantt_project_subtypes_html "<td><div style='margin-left: 20px;'><b>$category_l10n</b><br>\n"
    append gantt_project_subtypes_html $category_description
    append gantt_project_subtypes_html "</div></td>\n"
    append gantt_project_subtypes_html "</tr>\n"
}

if {"" ne $gantt_project_subtypes_html} {
   set gantt_project_subtypes_html "<tr><td></td><td colspan=2>Sub-Types:</td></tr>\n$gantt_project_subtypes_html"
}


# -----------------------------------------------------------
# Agile Project Subtypes
# -----------------------------------------------------------

set agile_project_subtypes_html ""
set agile_project_subtypes_sql "
        select	category_id,
                category,
                category_description
        from	im_categories
        where	(enabled_p = 't' OR enabled_p is NULL) and
		category_id not in ([join $exclude_ids ","]) and
		category_id in (select im_sub_categories([im_project_type_agile])) and
		category_id not in ([im_project_type_agile]) and
		category_id not in ([im_project_type_opportunity], [im_project_type_campaign], [im_project_type_milestone])
        order by lower(category)
"
db_foreach agile $agile_project_subtypes_sql {
    set category_l10n $category
    append agile_project_subtypes_html "<tr valign=top>\n"
    append agile_project_subtypes_html "<td><input type=\"radio\" name=\"project_type_id\" value=\"$category_id\" onclick=\"window.scrollTo(0, document.body.scrollHeight);\"></td>\n"
    append agile_project_subtypes_html "<td><div style='margin-left: 20px;'><b>$category_l10n</b><br>\n"
    append agile_project_subtypes_html $category_description
    append agile_project_subtypes_html "</div></td>\n"
    append agile_project_subtypes_html "</tr>\n"
}
if {"" ne $agile_project_subtypes_html} {
   set agile_project_subtypes_html "<tr><td></td><td colspan=2>Sub-Types:</td></tr> \n $agile_project_subtypes_html"
}






# -----------------------------------------------------------
# Trans Project Subtypes
# -----------------------------------------------------------

set trans_project_subtypes_html ""
set trans_project_subtypes_sql "
        select	category_id,
                category,
                category_description
        from	im_categories
        where	(enabled_p = 't' OR enabled_p is NULL) and
		category_id not in ([join $exclude_ids ","]) and
		category_id in (select im_sub_categories([im_project_type_translation])) and
		category_id not in ([im_project_type_translation])
        order by lower(category)
"
db_foreach trans $trans_project_subtypes_sql {
    set category_l10n $category
    append trans_project_subtypes_html "<tr valign=top>\n"
    append trans_project_subtypes_html "<td><input type=\"radio\" name=\"project_type_id\" value=\"$category_id\" onclick=\"window.scrollTo(0, document.body.scrollHeight);\"></td>\n"
    append trans_project_subtypes_html "<td><div style='margin-left: 20px;'><b>$category_l10n</b><br>\n"
    append trans_project_subtypes_html $category_description
    append trans_project_subtypes_html "</div></td>\n"
    append trans_project_subtypes_html "</tr>\n"
}

if {"" ne $trans_project_subtypes_html} {
   set trans_project_subtypes_html "<tr><td></td><td colspan=2>Sub-Types:</td></tr>\n$trans_project_subtypes_html"
}









# -----------------------------------------------------------
# 
# -----------------------------------------------------------

# Read the categories into the a hash cache
# Initialize parent and level to "0"
set category_select_sql "
        select
                category_id,
                category,
                category_description,
                parent_only_p,
                enabled_p,
		sort_order
        from
                im_categories
        where
                category_type = :object_type_category
		and (enabled_p = 't' OR enabled_p is NULL)
		and category_id not in ([join $exclude_ids ","])
		and category_id not in ([im_project_type_opportunity], [im_project_type_campaign], [im_project_type_milestone])
        order by lower(category)
"
db_foreach category_select $category_select_sql {
    set cat($category_id) [list $category_id $category $category_description $parent_only_p $enabled_p $sort_order]
    set level($category_id) 0
}

# Get the hierarchy into a hash cache
set hierarchy_sql "
        select
                h.parent_id,
                h.child_id
        from
                im_categories c,
                im_category_hierarchy h
        where
                c.category_id = h.parent_id
                and c.category_type = :object_type_category
        order by lower(category)
"

# setup maps child->parent and parent->child for
# performance reasons
set children [list]
db_foreach hierarchy_select $hierarchy_sql {
    if {![info exists cat($parent_id)]} { continue}
    if {![info exists cat($child_id)]} { continue}
    lappend children [list $parent_id $child_id]
}

set count 0
set modified 1
while {$modified} {
    set modified 0
    foreach rel $children {
	set p [lindex $rel 0]
	set c [lindex $rel 1]
	set parent_level $level($p)
	set child_level $level($c)
	if {[expr {$parent_level+1}] > $child_level} {
	    set level($c) [expr {$parent_level+1}]
	    set direct_parent($c) $p
	    set modified 1
	}
    }
    incr count
    if {$count > 1000} {
	ad_return_complaint 1 "Infinite loop in 'im_category_select'<br>
            The category type '$object_type_category' is badly configured and contains
            and infinite loop. Please notify your system administrator."
	return "Infinite Loop Error"
    }
    #	ns_log Notice "im_category_select: count=$count, p=$p, pl=$parent_level, c=$c, cl=$child_level mod=$modified"
}



# Sort the category list's top level. We currently sort by category_id,
# but we could do alphabetically or by sort_order later...
set category_list_sorted [array names cat]


set base_level 0
set category_select_html ""


# Now recursively descend and draw the tree, starting
# with the top level
set top_list [list]
foreach p $category_list_sorted {
    set enabled_p [lindex $cat($p) 4]
    if {"f" == $enabled_p} { continue }
    set p_level $level($p)
    if {0 == $p_level} {
        lappend top_list [list $p [lindex $cat($p) 5]]
    }
}

foreach toplist [lsort -index 1 $top_list] {
    set p [lindex $toplist 0]
    append category_select_html [im_biz_object_category_select_branch -translate_p $translate_p -package_key $package_key -type_id_var $type_id_var $p $default_category_id $base_level [array get cat] [array get direct_parent]]
}


set admin_url [export_vars -base "/intranet/admin/categories/index" {{select_category_type $object_type_category}}]
set admin_html "<a href=$admin_url>[im_gif -translate_p 1 wrench "Modify the name and description of the shown objects types"]</a>"
if {$admin_p} { append page_title $admin_html }
