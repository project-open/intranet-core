<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title] %>

<form action='@return_url;noquote@' method='post'>
<table cellspacing='2' cellpadding='2'>
<%= [export_form_vars user_id_from_search] %>
@pass_through_html;noquote@

<!-- ToDo: replace with variables from HTTP form -->

@category_select_html;noquote@
<tr>
    <td>&nbsp;</td>
    <td>
	<input type=submit value='<%= [lang::message::lookup "" intranet-core.Continue "Continue"] %>'>
    </td>
</tr>
</form>
</table>

<%= [im_box_footer] %>

