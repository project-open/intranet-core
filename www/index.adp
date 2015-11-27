<master>
<property name="doc(title)">#intranet-core.Home#</property>
<property name="main_navbar_label">home</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="sub_navbar">@sub_navbar;literal@</property>
<property name="header_stuff">@header_stuff;literal@</property>
<property name="show_context_help_p">@show_context_help_p;literal@</property>

<% if {"" == $view_name || [string equal $view_name "standard"]} { %>

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
  <td colspan="3">
    <%= [im_component_bay top] %>
  </td>
</tr>
<tr>
  <td valign="top" width="50%">
    @admin_guide_html;noquote@
    <%= [im_component_bay left] %>
  </td>
  <td width=2>&nbsp;</td>
  <td valign="top" width="50%">

    <if "" ne @upgrade_message@>
        <%= [im_table_with_title "Upgrade Information" $upgrade_message] %>
    </if>

    <%= [im_component_bay right] %>
  </td>
</tr>
<tr>
  <td colspan="3">
    <%= [im_component_bay bottom] %>
  </td>
</tr>
</table>

<% } elseif {[string equal "component" $view_name]} { %>

   <%= [im_component_page -plugin_id $plugin_id -return_url "/intranet/index"] %>

<% } %>

