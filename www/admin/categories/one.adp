<master src="../master">
  <property name="title">@page_title@</property>

<form @form_action_html;noquote@ method=GET>
@export_form_vars;noquote@
<table border=0 cellpadding=0 cellspacing=1>
  <tr>
    <td class=rowtitle colspan=2 align=center>Category</td>
  </tr>
  @select_categories;noquote@
  <tr>
    <td>Category Nr.</td>
    <td><input size=10 name=category_id value="@category_id@"></td>
  </tr>
  <tr>
    <td>Category name</td>
    <td><input size=40 name=category value="@category@"></td>
  </tr>
  <tr>
    <td>Category description</td>
    <td>
      <textarea name=category_description rows=5 cols=50 wrap=soft>@descr@
      </textarea>
    </td>
  </tr>
<% if {"" != $hierarchy_component} { %>
  <tr>
    <td>Parents</td>
    <td>
      <select name=parents size=20 multiple>
      @hierarchy_component;noquote@
      </select>
    </td>
  </tr>
<% } %>

</table>

<input type=hidden name=enabled_p value="t">
<input type=submit name=submit $input_form_html>
</form>
@delete_action_html;noquote@
