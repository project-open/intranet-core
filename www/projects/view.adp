<master src="../master">
<property name="title">Companies</property>

<!-- left - right - bottom  design -->

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

