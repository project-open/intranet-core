# /www/admin/components/edit.tcl
#
# Copyright (C) 2004 various parties
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
    Displays and edits the location of one component plugins.
    @param plugin_id Which component is being worked on

    @author unknown@arsdigita.com
    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
    @author mai-bee@gmx.net
} {
    { plugin_id:naturalnum ""}
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "<li>You need to be a system administrator to see this page">
    return
}

if {"" == $plugin_id} { 
    set plugin_id [db_nextval "acs_object_id_seq"] 
    set new_p 1
} else {
    set new_p 0
}

# ---------------------------------------------------------------
# Format Component Data 
# ---------------------------------------------------------------

set page_title "Component Edit"
set context_bar [im_context_bar $page_title]

set plugin_name "Please enter a title"
set sort_order "0"
set page_url "/intranet/index"
set location "left"
set title_tcl ""
set component_tcl "Please enter TCL code here that returns the portlet contents. Example: im_ad_hoc_query -format html \"select * from groups\""
set enabled_p "t"
set package_name "intranet-core"
set menu_name ""
set menu_sort_order 0

db_0or1row category_properties "
	select
		c.*
	from
		im_component_plugins c
	where
		c.plugin_id = :plugin_id
"

# if [catch { } errmsg] {
#     ad_return_complaint 1 "<li>Internal Error<br>
#         Component \#$plugin_id does not exist (anymore)"
#     ad_script_abort
# }

set left_selected ""
set right_selected ""
set bottom_selected ""
set top_selected ""
set none_selected ""
set files_selected ""
set header_left_selected ""
set header_right_selected ""

switch $location {
    "left" { set left_selected " selected" }
    "right" { set right_selected " selected" }
    "bottom" { set bottom_selected " selected" }
    "top" { set top_selected " selected" }
    "none" { set none_selected " selected" }
    "files" { set none_selected " selected" }
    "header-left" { set header_left_selected " selected" }
    "header-right" { set header_right_selected " selected" }
}

if {$enabled_p} {
    set enabled_checked "checked"
    set disabled_checked ""
} else {
    set enabled_checked ""
    set disabled_checked "checked"
}


set page_body "
<form action=\"edit-2.tcl\" method=POST>
[export_form_vars plugin_id return_url]

<TABLE border=0>
<TBODY>
  <TR>
    <TD class=rowtitle align=middle colSpan=2>Component</TD></TR>
  <TR class=rowodd>
    <TD>Package Name</TD>
    <TD>$package_name<input type=hidden name=package_name value='$package_name'></TD></TR>
  <TR class=roweven>
    <TD>Name</TD>
    <TD><input type=text name=plugin_name value=\"$plugin_name\" size=60></TD></TR>
  <TR class=roweven>
    <TD>Enabled?</TD>
    <TD>
        <input type=radio name=enabled_p value=t $enabled_checked>Enabled
        <input type=radio name=enabled_p value=f $disabled_checked>Not Enabled
    </TD></TR>
  <TR class=rowodd>
    <TD>Location</TD>
    <TD><select name=location size=1>
        <option $left_selected>left</option>
        <option $right_selected>right</option>
        <option $top_selected>top</option>
        <option $bottom_selected>bottom</option>
        <option $files_selected>files</option>
        <option $header_left_selected>header-left</option>
        <option $header_right_selected>header-right</option>
        <option $none_selected>none</option>
        </select>
    </TD></TR>
  <TR class=roweven>
    <TD>Sort Order</TD>
    <TD><input type=text name=sort_order value=$sort_order></TD></TR>
  <TR class=rowodd>
    <TD>URL</TD>
    <TD><input type=text name=page_url value=\"$page_url\" size=60></TD>
  </TR>
  <TR class=roweven>
    <TD>Title TCL</TD>
    <TD><textarea name=title_tcl cols=60 rows=5>$title_tcl</textarea></TD>
  </TR>
  <TR class=rowodd>
    <TD>Component TCL</TD>
    <TD><textarea name=component_tcl cols=60 rows=10>$component_tcl</textarea></TD>
  </TR>
  <TR class=roweven>
    <TD>Menu Name</TD>
    <TD><input type=text name=menu_name value=$menu_name></TD></TR>
  <TR class=rowodd>
    <TD>Menu Sort Order</TD>
    <TD><input type=text name=menu_sort_order value=$menu_sort_order></TD></TR>

</TBODY>
</TABLE>
"

if {$new_p} {
    append page_body "<input type=submit name=submit value=Create>"
} else {
    append page_body "<input type=submit name=submit value=Update><input type=submit name=submit value=Delete>"
}

append page_body "</form>"


ad_return_template