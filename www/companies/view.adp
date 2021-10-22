<master>
<property name="doc(title)">@company_name;literal@</property>
<property name="main_navbar_label">companies</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="sub_navbar">@sub_navbar;literal@</property>

<% if {"" eq $view_name || "standard" eq $view_name} { %>
	
		<table cellpadding="0" cellspacing="0" border="0" width="100%">
		<tr><td>
		  <%= [im_component_bay top] %>
		</td></tr>
		</table>
		
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
		</table>
		
		<table cellpadding="0" cellspacing="0" border="0" width="100%">
		<tr><td>
		  <%= [im_component_bay bottom] %>
		</td></tr>
		</table>


<% } elseif {"files" eq $view_name} { %>

	<div id="position_filestorage_view_files">
	<%= [im_component_insert "Companies Filestorage Component"] %>
	</div>

<% } else { %>

   <%= [im_component_page -plugin_id $plugin_id -return_url "/intranet/companies/view?company_id=$company_id"] %>

<% } %>


