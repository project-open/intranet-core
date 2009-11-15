<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_templates</property>

<table cellpadding=1 cellspacing=1 border=0 width="100%">
<tr>
  <td colspan=2>
	<%= [im_component_bay top] %>
  </td>
</tr>
<tr>
  <td valign=top width="50%">
	<%= [im_box_header $page_title] %>
	<listtemplate name="templates"></listtemplate>	
	<%= [im_box_footer] %>

	<p>&nbsp;</p>
	<%= [im_component_bay left] %>
  </td>
  <td valign=top width="50%">
	<%= [im_box_header [lang::message::lookup "" intranet-core.Template_Help "Help"]] %>
	In this screen you can manage Invoicing templates.<br>
	These templates are available in the invoice page as option to render your invoice
	in HTML or OpenOffice '.odt' format.<br>
	For details on templates please see the
	<a href="http://www.project-open.org/documentation/category_intranet_cost_template">online documentation</a>.
	<%= [im_box_footer] %>

	<%= [im_component_bay right] %>
  </td>
</tr>
<tr>
  <td colspan=2>
	<%= [im_component_bay bottom] %>
  </td>
</tr>
</table>




