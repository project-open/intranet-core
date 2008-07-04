<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title] %>

<table cellspacing=2 cellpadding=2>
<form action='@return_url;noquote@' method=POST>
@category_select_html;noquote@
<tr>
    <td>&nbsp;</tr>
    <td>
	<input type=submit value='<%= [lang::message::lookup "" intranet-core.Continue "Continue"] %>'>
    </td>
</tr>
</form>
</table>


<%= [im_box_footer] %>

