<master src="master">
<property name="title">@page_title@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title] %>

<table>
<form action='@return_url;noquote@' method=POST>
<tr>
    <td><%= [lang::message::lookup "" intranet-core.Select_Type "Select Type"] %></td>
    <td><%= [im_category_select $object_type_category $type_id_var] %></td>
</tr>
<tr>
    <td>&nbsp;</tr>
    <td>
	<input type=submit value='<%= [lang::message::lookup "" intranet-core.Continue "Continue"] %>'>
    </td>
</tr>
</form>
</table>


<%= [im_box_footer] %>

