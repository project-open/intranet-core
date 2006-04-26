<master src="../master">
<property name="title">@company_name@</property>
<property name="main_navbar_label">companies</property>

<!-- left - right - bottom  design -->

<img src="/intranet/images/cleardot.gif" width=2 height=2>
<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width='50%'>

   <table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
     <tr><td colspan=2 class=tableheader>Company Information</td></tr>
     <tr><td>
        <table>
        @left_column;noquote@
        <if @dynamic_fields_p@>
            <formtemplate id="company_view" style="standard-withouttabletab"></formtemplate>
        </if>
	@left_column_action;noquote@
        </table>
      </td></tr>
    </table>

    <img src="/intranet/images/cleardot.gif" width=2 height=2>

    <%= [im_component_bay left] %>
  </td>
  <td width=2>&nbsp;</td>
  <td valign=top>

    @projects_html;noquote@
    @company_members_html;noquote@
    @company_clients_html;noquote@
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


