<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>


<%
set menu_label "project_summary"
# ad_return_complaint 1 "'$menu_label'"
switch $view_name {
    "files" { set menu_label "project_files" }
    "finance" { set menu_label "project_finance" }
    default { set menu_label "project_summary" }
}
%>

<br>
<%= [im_sub_navbar $parent_menu_id $bind_vars "" "pagedesriptionbar" $menu_label] %>


<!-- 
  There are two "views" on this page: "Summary" and "Files".
  More views may be added by extension modules, but they are
  dealt with in the own pages.
-->
<% if {"" == $view_name || [string equal $view_name "standard"]} { %>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>
    @project_base_data_html;noquote@
    <%= [im_component_bay left] %>
  </td>
  <td valign=top>
    @admin_html;noquote@
    @hierarchy_html;noquote@
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>
<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

<% } elseif {[string equal "files" $view_name]} { %>

  <%= [im_component_insert "Project Filestorage Component"] %>

<% } elseif {[string equal "sales" $view_name]} { %>

  <%= [im_component_insert "Project Sales Filestorage Component"] %>

<% } elseif {[string equal "finance" $view_name]} { %>

  <%= [im_component_insert "Project Finance Component"] %>

<% } elseif {[string equal "status" $view_name]} { %>

  <%= [im_component_insert "Project Translation Error Component"] %>
  <%= [im_component_insert "Project Translation Task Status"] %>

<% } %>

