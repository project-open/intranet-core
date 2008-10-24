<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context@</property>
<property name="admin_navbar_label">admin_components</property>

<P>
<table>
<tr>
<td width="50%">

</td>
<td width="50%">

	<table>
	<form action=index method=GET>
	<tr><td colspan=2 class=rowtitle><%= [lang::message::lookup "" intranet-core.Filter_Components "Filter Components"] %></td><td></tr>

	<tr class=roweven>
	<td><%= [lang::message::lookup "" intranet-core.Package "Package"] %></td>
	<td><%= [im_select -ad_form_option_list_style_p 1 package_key $package_options $package_key] %></td>
	</tr>

	<tr class=rowodd>
	<td><%= [lang::message::lookup "" intranet-core.Location "Location"] %></td>
	<td><%= [im_select -ad_form_option_list_style_p 1 component_location $location_options $component_location] %></td>
	</tr>

	<tr class=roweven>
	<td><%= [lang::message::lookup "" intranet-core.Component_Page "Page"] %></td>
	<td><%= [im_select -ad_form_option_list_style_p 1 component_page $page_options $component_page] %></td>
	</tr>

	<tr><td></td><td><input type=submit></td></tr>
	</form>
	</table>


</td>
</tr>
<td colspan=3>

	<table width="800">
	@table_header;noquote@
	@table;noquote@
	</table>

</td>
</tr>
</table>
