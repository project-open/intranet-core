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


<img src="/intranet/images/cleardot.gif" width=2 height=2>

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

	<table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
	<tr>
	   <td class=tableheader align=left width='99%'><%= [lang::message::lookup "" intranet-core.Sub_Projects "Sub-Projects"] %></td>
	</tr>
	<tr>
	  <td class=tablebody><font size=-1>

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
		<table class="list">
		  <tr class="list-header">
		    <th class="list-narrow"> &nbsp; </th>
		    <th class="list-narrow">#intranet-core.Project#</th>
		    <th class="list-narrow">#intranet-core.Name#</th>
		    <th class="list-narrow">#intranet-core.Status#</th>
		  </tr>
		  <multiple name=subprojects>

		  <if @subprojects.subproject_bold_p@>
		    <tr class="list-bold">
		  </if>
		  <else>
			  <if @subprojects.rownum@ odd>
			    <tr class="list-odd">
			  </if> <else>
			    <tr class="list-even">
			  </else>
		  </else>

		  <td class="list-narrow">
		    <if @subprojects.subproject_bold_p@>
		      <%= [im_gif arrow_right] %>
		    </if>
		  </td>
		  <td class="list-narrow">
		      <a href="@subprojects.subproject_url@">@subprojects.subproject_nr@</a>
		  </td>
		  <td class="list-narrow">
		      @subprojects.subproject_indent;noquote@
		      <a href="@subprojects.subproject_url@">@subprojects.subproject_name@</a>
		  </td>
		  <td class="list-narrow">
			<%= [im_category_from_id @subprojects.subproject_status_id@] %>
		  </td>
		  </tr>
		  </multiple>

		</table>

	    @admin_html_content;noquote@

	</font></td>
	</tr>
	</table>

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

<% } %>

