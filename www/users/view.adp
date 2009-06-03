<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@user_navbar_html;noquote@</property>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width='50%'>


    <%= [im_box_header [lang::message::lookup "" intranet-core.Basic_Information "Basic Information"]] %>

	        <table>
		    <%= $user_basic_info_html %>
		    <%= $user_basic_profile_html %>
		    <formtemplate id="person_view" style="standard-withouttabletab"></formtemplate>
		    
		    <tr>
		    <td class=form-label>&nbsp;</td>
		    <td class=form-widget>
			<form action=new method=POST>
			<%= [export_form_vars user_id return_url] %>
			<input type=submit value=<%=[lang::message::lookup "" intranet-core.Edit Edit]%>>
			</form>
		    </td>
		    </tr>
		</table>


    <%= [im_box_footer] %>


    <%= $user_l10n_html %>

    <%= [im_table_with_title [lang::message::lookup "" intranet-core.Contact_Information "Contact Information"] $contact_html] %>

    <%= [im_box_header [_ intranet-core.Skin]] %>     
    <table cellpadding=1 cellspacing=1 border=0>
    <tr> 
	<td colspan=2 class=rowtitle align=center>#intranet-core.Skin#</td>
    </tr>
    <tr>
	<td>#intranet-core.Skin#</td>
	<td><%= [im_skin_select_html $user_id $return_url] %></td>
    </tr>
    <tr><td colspan=2></td></tr>
    </table>
    <%= [im_box_footer] %>


    <%= [im_table_with_title [lang::message::lookup "" intranet-core.Administration "Administration"] $admin_links] %>
    <%= [im_component_bay left] %>

  </td>

  <td width=2>&nbsp;</td>
  <td valign=top>

    <%= $portrait_html %>
    <%= $projects_html %>
    <%= $companies_html %>
    <%= [im_component_bay right] %>

  </td>
</tr>
</table><br>


<table cellpadding=0 cellspacing=0 border=0>
<tr><td>

  <%= [im_component_bay bottom] %>

</td></tr>
</table>
