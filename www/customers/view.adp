<master src="../master">
<property name="title">Clients</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    @left_column;noquote@
    <%= [im_component_bay left] %>

  </td>
  <td valign=top>

    @projects_html;noquote@
    @company_members_html;noquote@
    @customer_members_html;noquote@
    <!-- Component Bay Right -->
    <%= [im_component_bay right] %>
    <!-- End Component Bay Right -->

  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

