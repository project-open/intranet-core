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
  <td valign=top width="300px">
	<%= [im_box_header $page_title] %>
	<listtemplate name="templates"></listtemplate>
	<%= [im_box_footer] %>

	<p>&nbsp;</p>
	<%= [im_component_bay left] %>
  </td>
  <td valign="top">
	<%= [im_box_header [lang::message::lookup "" intranet-core.Template_Help "Help"]] %>
	In this screen you can manage templates for financial documents including invoices, quotes, purchase orders etc.<br>
	These templates are available in the screen where you can create new financial documents.<br>
	To activate templates newly uploaded please <a href="/intranet/admin/categories/index.tcl?select_category_type=Intranet Cost Template">create a category</a> for them.
	You have the option to use either HTML ('.adp') or OpenOffice '.odt' format.<br>
	To download a template please choose from the right-mouse click menu option "Save as" and change file name to the name shown in the table.<br>
	For details on templates please see the
	<a href="http://www.project-open.org/en/category_intranet_cost_template">online documentation</a>.
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




