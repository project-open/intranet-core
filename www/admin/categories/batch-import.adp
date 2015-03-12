<master src="../master">
<property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_categories</property>

<h1>@page_title@</h1>

<p>
Please enter categories line-by-line in the text box below.<br>
]po[ will create new categories for each line with consecutive<br>
category IDs.
</p>

<form action="/intranet/admin/categories/batch-import-2" method=POST>
<%= [export_form_vars category_type] %>
<table border=0 cellpadding=0 cellspacing=1>
  <tr class=rowodd>
    <td>#intranet-core.Category_Type#</td>
    <td>@category_type@</td>
  </tr>
  <tr class=roweven>
    <td>Categories</td>
    <td>
      <textarea name=categories rows=10 cols=50 wrap="<%=[im_html_textarea_wrap]%>">Enter categories here line by line</textarea>
    </td>
  </tr>
  <tr class=rowodd>
  <td colspan=2>
	<input type=submit name=submit value="#intranet-core.Submit#">
  </td>
</tr>
</table>
</form>

