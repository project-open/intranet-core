<!-- packages/intranet-core/www/users/contact-edit.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">user</property>

<form action=contact-edit-2 method=POST>
<%= [export_form_vars user_id] %>
<table cellpadding=0 cellspacing=2 border=0>
<tr valign=top>
  <td>@contact_html;noquote@</td>
  <td>@home_html;noquote@</td>
  <td>@work_html;noquote@</td>
</tr>
<tr>
  <td colspan=3>@note_html;noquote@</td>
</tr>
</table>
<input type=submit name=submit value=Submit>
</form>

