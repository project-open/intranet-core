<master src="../master">
<property name="title">#intranet-core.Companies#</property>
<property name="context">#intranet-core.context#</property>

<table border=0 cellpadding=0 cellspacing=0>
<tr>
  <td>


	<form method=get action='/intranet/companies/index' name=filter_form>
	<%= [export_form_vars start_idx order_by how_many letter view_name] %>
	<table border=0 cellpadding=0 cellspacing=0>
	<tr> 
	  <td colspan='2' class=rowtitle align=center>
	    #intranet-core.Filter_Companies#
	  </td>
	</tr>
	<tr>
	  <td valign=top>#intranet-core.View_1# </td>
	  <td valign=top><%= [im_select view_type $view_types ""] %></td>
	</tr>
	<tr>
	  <td valign=top>#intranet-core.Company_Status_1# </td>
	  <td valign=top><%= [im_select status_id $status_types ""] %></td>
	</tr>
	<tr>
	  <td valign=top>#intranet-core.Company_Type_1# </td>
	  <td valign=top>
	    <%= [im_select type_id $company_types ""] %>
	    <input type=submit value=Go name=submit>
	  </td>
	</tr>
	</table>
	</form>


  </td>
  <td>&nbsp;</td>
  <td valign=top>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Companies#
      </td>
    </tr>
    <tr>
      <td>
        @admin_html;noquote@
      </td>
    </tr>
    </table>
  </td>
</tr>
</table>


<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>


