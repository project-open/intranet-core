<master src="../master">
<property name="title">#intranet-core.Companies#</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">companies</property>

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
	  <td>#intranet-core.View_1#  &nbsp;</td>
	  <td><%= [im_select view_type $view_types ""] %></td>
	</tr>
	<tr>
	  <td>#intranet-core.Company_Status_1#  &nbsp;</td>
	  <td><%= [im_category_select -include_empty_p 1 "Intranet Company Status" status_id $status_id] %></td>
	</tr>
	<tr>
	  <td>#intranet-core.Company_Type_1#  &nbsp;</td>
	  <td>
	    <%= [im_category_select -include_empty_p 1 "Intranet Company Type" type_id $type_id] %>
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

<br>
<%= [im_company_navbar "" "/intranet/companies/" $next_page_url $previous_page_url [list order_by how_many view_name view_type status_id type_id] $menu_select_label] %>

<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>


