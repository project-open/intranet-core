<master src="master">
<property name="title">Home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>
    @project_filter_html;noquote@
    @project_list_html;noquote@
    <%= [im_component_bay left] %>
  </td>
  <td valign=top>
    @forum_component;noquote@
    @hours_component;noquote@
    @administration_component;noquote@
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

