<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@user_navbar_html;literal@</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="show_context_help_p">@show_context_help_p;literal@</property>

<% if {"" == $view_name || [string equal $view_name "standard"]} { %>
<%= [im_component_bay top] %>
<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
  <td valign="top" width="50%">
    <%= [im_component_bay left] %>
  </td>

  <td width=2>&nbsp;</td>
  <td valign="top">
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>
<table cellpadding="0" cellspacing="0" border="0">
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

<% } elseif {[string equal "component" $view_name]} { %>
   <%= [im_component_page -plugin_id $plugin_id -return_url "/intranet/users/view?user_id=$user_id"] %>
<% } %>

