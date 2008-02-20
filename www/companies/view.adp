<master src="../master">
<property name="title">@company_name@</property>
<property name="main_navbar_label">companies</property>

<!-- left - right - bottom  design -->

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
  <td valign="top" width="50%">
     <%= [im_box_header "Company Information"] %>
        <table>
        @left_column;noquote@
	@left_column_action;noquote@
        </table>
    <%= [im_box_footer] %>
    <%= [im_component_bay left] %>
  </td>
  <td width="2">&nbsp;</td>
  <td valign="top">

    @projects_html;noquote@
    @company_members_html;noquote@
    @company_clients_html;noquote@
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


