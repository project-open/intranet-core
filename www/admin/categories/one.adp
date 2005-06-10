<master src="../master">
  <property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_categories</property>

<form @form_action_html;noquote@ method=GET>
<table border=0 cellpadding=0 cellspacing=1>
  <tr>
    <td class=rowtitle colspan=2 align=center>#intranet-core.Category#</td>
  </tr>

<if 0 eq @new_category@>
  @category_type_select;noquote@
</if>
<else>
  <td>
    New Category Type
  </td>
  <td>
    <input type=text name=category_type size=50 value="">
  </td>
</else>

  <tr>
    <td>#intranet-core.Category_Nr#</td>
    <td><input size=10 name=category_id value="@category_id@"></td>
  </tr>
  <tr>
    <td>#intranet-core.Category_name#</td>
    <td><input size=40 name=category value="@category@"></td>
  </tr>
  <tr>
    <td>
      #intranet-core.Category_translation#
      <%= [im_gif help "The English 'translation' should be identical with the category name"] %>
    </td>
    <td>
      @category_translation_component;noquote@
   </td>
  </tr>
  <tr>
    <td>#intranet-core.Category_description#</td>
    <td>
      <textarea name=category_description rows=5 cols=50 wrap=soft>@descr@
      </textarea>
    </td>
  </tr>
<% if {"" != $hierarchy_component} { %>
  <tr>
    <td>#intranet-core.Parent_Categories#</td>
    <td>
      <select name=parents size=20 multiple>
      @hierarchy_component;noquote@
      </select>
    </td>
  </tr>
<% } %>

</table>

<input type=hidden name=enabled_p value="t">
<input type=submit name=submit value="#intranet-core.Create_Category#" $input_form_html>
</form>
@delete_action_html;noquote@

<h2>Please Note</h2>
<p><blockquote>
Categories are frequently cached for performance reasons.<br>
You may have to restart the server after adding or modifying a category <br>
in order for the changes to take effect.
</blockquote></p>
