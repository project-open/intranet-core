<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Menu_Restore#</property>

<form action="restore-2" method=POST>

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
By "restoring" data you are going to overwrite the data
in this system.
All changes made to your system since the backup
are going to be lost.<br>

<font color=red>Please make sure you know exactly what you are doing.</font>
</blockquote>




