<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Menu_Restore#</property>
<property name="admin_navbar_label">admin_backup</property>

<form action="restore-2" method=POST>
<%= [export_form_vars path] %>

<table cellpadding=1 cellspacing=1 border=0>
<tr class=rowtitle>
  <td class=rowtitle colspan=9 align=center>
    Restore Objects
  </td>
</tr>
@object_list_html;noquote@
<tr>
  <td colspan=2 align=right>
    <input type=submit name=submit value="Restore">
  </td>
</tr>
</table>

</form>

<h1>Attention</h1>
<blockquote>
By "restoring" data you are going to overwrite the data in this system.
All changes made to your system since the backup are going to be lost.
<p>
This restore process can take several minutes of even hours.
Please do not interrupt the browser.
<p>

<font color=red>Please make sure you know exactly what you are doing.</font>
</blockquote>




