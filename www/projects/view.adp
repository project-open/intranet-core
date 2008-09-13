<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<!-- 
  There are two "views" on this page: "Summary" and "Files".
  More views may be added by extension modules, but they are
  dealt with in the own pages.
-->
<% if {"" == $view_name || [string equal $view_name "standard"]} { %>

	<table cellpadding=0 cellspacing=0 border=0 width="100%">
	<tr>
	  <td valign=top width='50%'>

	    <!--Project Base Data -->
	    <%= [im_table_with_title "Main Data" $project_base_data_html] %>

	    <!-- Left Component Bay -->
	    <%= [im_component_bay left] %>
	  </td>
	  <td width=2>&nbsp;</td>
	  <td valign=top>

	  <%= [im_box_header [lang::message::lookup "" intranet-core.Sub_Projects "Sub-Projects"]] %>
  	     

<if @subproject_filtering_enabled_p@>
		<table>
		<form action="@current_url;noquote@" method=GET>
		<%= [export_form_vars project_id] %>
		<tr>
		<td class=form-label>#intranet-core.Status#</td>
		<td class=form-widget>
		<%= [im_category_select -include_empty_p 1 "Intranet Project Status" subproject_status_id $subproject_status_id] %>
		<input type=submit value="Go">
		</td>
		</tr>
		</form>
		</table>
</if>
		<%= [im_project_hierarchy_component -project_id $project_id -subproject_status_id $subproject_status_id] %>

	    @admin_html_content;noquote@


            <%= [im_box_footer] %>

	    <!-- Right Component Bay -->
	    <%= [im_component_bay right] %>

	  </td>
	</tr>
	</table><br>

	<table cellpadding=0 cellspacing=0 border=0 width='100%'>
	<tr><td>
	  <!-- Bottom Component Bay -->
	  <%= [im_component_bay bottom] %>
	</td></tr>
	</table>

<% } elseif {[string equal "files" $view_name]} { %>

	<%= [im_component_insert "Project Filestorage Component"] %>

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

