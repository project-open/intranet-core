<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Menu_Backup_Restore#</property>
<property name="admin_navbar_label">admin_backup</property>

<form action="backup-2" method=POST>

<table cellpadding=1 cellspacing=1 border=0>
<tr class=rowtitle>
  <td class=rowtitle colspan=9 align=center>
    Backup Objects
  </td>
</tr>
@object_list_html;noquote@
<tr>
  <td colspan=2 align=right>
    <input type=submit name=submit value="Backup">
  </td>
</tr>
</table>

</form>


<blockquote>
The backup procedure can take several minutes
to complete, depending on the amount of data 
in your system.<br>
Please don't interrupt this proces until you 
see a screen confirming the successful execution.<br>
Otherwise your backup will only be partial and
a complete restore won't be possible.
</blockquote>




