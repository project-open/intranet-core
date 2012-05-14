<master src="../master">
  <property name="title">@page_title@</property>
<property name="admin_navbar_label">admin_categories</property>

<if "t" eq @constant_p@>
<p><font color=red>
<b>
This category is a "constant".<br>
Modifying the category (deleting, changing the name or the nr.) WILL BREAK your system.<br>
However, it is OK to:
<ul>
<li>Change the "Enabled" status to "Enabled" or "Not Enabled",
<li>Modify the "Category Translation" or
<li>Change the sort order
</ul>
</font></p>
<br>
</if>


<form @form_action_html;noquote@ method=POST>
<table border=0 cellpadding=0 cellspacing=1>
  <tr>
    <td class=rowtitle colspan=2 align=center>#intranet-core.Category#</td>
  </tr>
  <tr>
    <td>#intranet-core.Category_Type#</td>
    <td>@category_type_select;noquote@</td>
  </tr>
  <tr class=roweven>
    <td>#intranet-core.Category_Nr#</td>
    <td><input size=10 name=category_id value="@category_id@"></td>
  </tr>
  <tr class=rowodd>
    <td>#intranet-core.Category_name#</td>
    <td><input size=40 name=category value="@category@"></td>
  </tr>
  <tr class=rowodd>
    <td>Enabled</td>
    <td>
	<input type=radio name=enabled_p value="t" @enabled_p_checked@>
	Enabled 
	<input type=radio name=enabled_p value="f" @enabled_p_unchecked@>
	Not Enabled 
    </td>
  </tr>
  <tr class=rowodd>
    <td>Sort Order</td>
    <td><input size=5 name=sort_order value="@sort_order@"></td>
  </tr>
  <tr class=roweven>
    <td>
      #intranet-core.Category_translation#<br>
      <%= [im_gif help "The English 'translation' should be identical with the category name"] %>
    </td>
    <td>
      @category_translation_component;noquote@
   </td>
  </tr>

  <tr class=rowodd>
    <td>Int1</td>
    <td><input size=20 name=aux_int1 value="@aux_int1@"></td>
  </tr>
  <tr class=roweven>
    <td>Int2</td>
    <td><input size=20 name=aux_int2 value="@aux_int2@"></td>
  </tr>

  <tr class=rowodd>
    <td>String1</td>
    <td><input size=60 name=aux_string1 value="@aux_string1@"></td>
  </tr>
  <tr class=roweven>
    <td>String2</td>
    <td><input size=60 name=aux_string2 value="@aux_string2@"></td>
  </tr>


  <tr class=rowodd>
    <td>#intranet-core.Category_description#</td>
    <td>
      <textarea name=category_description rows=5 cols=50 wrap="<%=[im_html_textarea_wrap]%>">@descr@</textarea>
    </td>
  </tr>
<% if {"" != $hierarchy_component} { %>
  <tr class=roweven>
    <td>#intranet-core.Parent_Categories#</td>
    <td>
      <select name=parents size=20 multiple>
      @hierarchy_component;noquote@
      </select>
    </td>
  </tr>
<% } %>
<tr class=roweven>
  <td colspan=2>
	<input type=submit name=submit value="#intranet-core.Submit#" $input_form_html>
  </td>
</tr>

</table>

</form>
@delete_action_html;noquote@

