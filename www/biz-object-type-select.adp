<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title] %>

<form action='@return_url;noquote@' method=POST>
<%= [export_form_vars user_id_from_search project_id] %>

<table cellspacing=2 cellpadding=2>
@pass_through_html;noquote@
@category_select_html;noquote@
<tr>
    <td>&nbsp;</td>
    <td>
	<input type=submit value='<%= [lang::message::lookup "" intranet-core.Continue "Continue"] %>'>
    </td>
</tr>
</table>

</form>

<%= [im_box_footer] %>

