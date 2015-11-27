<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">projects</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="sub_navbar">@sub_navbar;literal@</property>
<property name="show_context_help_p">@show_context_help_p;literal@</property>

<% if {"" == $view_name || [string equal $view_name "standard"]} { %>

<%= [im_component_bay top] %>
<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
  <td valign="top" width="50%">
    <%= [im_component_bay left] %>
  </td>
  <td width="2">&nbsp;</td>
  <td valign="top">
	<%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr><td>
  <!-- Bottom Component Bay -->
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

<% } elseif {[string equal "files" $view_name]} { %>

	<div id="position_filestorage_view_files">
	<%= [im_component_insert "Project Filestorage Component"] %>
	</div>

<% } elseif {[string equal "sales" $view_name]} { %>

	<%= [im_component_insert "Project Sales Filestorage Component"] %>

<% } elseif {[string equal "finance" $view_name]} { %>

	<%= [im_component_insert "Project Finance Component"] %>

<% } elseif {[string equal "gantt" $view_name]} { %>

	<%= [im_component_insert "Project Gantt Resource Component"] %>

<% } elseif {[string equal "status" $view_name]} { %>

	<%= [im_component_insert "Project Translation Error Component"] %>
	<%= [im_component_insert "Project Translation Task Status"] %>

<% } elseif {[string equal "component" $view_name]} { %>

   <%= [im_component_page -plugin_id $plugin_id -return_url "/intranet/projects/view?project_id=$project_id"] %>
<% } %>

