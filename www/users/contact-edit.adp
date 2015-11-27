<!-- packages/intranet-core/www/users/contact-edit.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context_bar;literal@</property>
<property name="main_navbar_label">user</property>

<form action=contact-edit-2 method=POST>
<%= [export_vars -form {user_id}] %>
<table cellpadding="0" cellspacing="2" border="0">
<tr valign="top">
  <td>@contact_html;noquote@</td>
  <td>@home_html;noquote@</td>
  <td>@work_html;noquote@</td>
</tr>
<tr>
  <td colspan="3">@note_html;noquote@</td>
</tr>
</table>
<input type="submit" name="submit" value="#intranet-core.Submit#">
</form>
