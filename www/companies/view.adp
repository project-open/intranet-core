<master src="../master">
<property name="doc(title)">@company_name;literal@</property>
<property name="main_navbar_label">companies</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="sub_navbar">@sub_navbar;literal@</property>

<!-- left - right - bottom  design -->

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
  <td valign="top" width="50%">
    <%= [im_component_bay left] %>
  </td>
  <td width="2">&nbsp;</td>
  <td valign="top">
    <!-- Component Bay Right -->
    <%= [im_component_bay right] %>
    <!-- End Component Bay Right -->
  </td>
</tr>
</table>

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


