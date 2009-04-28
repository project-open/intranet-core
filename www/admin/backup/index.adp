<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Menu_Backup_Restore#</property>
  <property name="admin_navbar_label">admin_backup</property>

<table cellpadding=1 cellspacing=1 border=0>
<tr>
  <td valign=top>

	<%= [im_component_bay left] %>

	<h1>Postgres Backup/Restore</h1>
	<ul>
	    <li>Current backup path: @backup_path@
	    <if @not_backup_path_exists_p@>
	    <li>
		<font color=red>
			Backup path doesn't exist - please correct the
			<a href="/intranet/admin/parameters">BackupBasePathUnix parameter</a>.
		</font>
	    </if>

	</ul>
	<p>&nbsp;</p>
	<listtemplate name="backup_files"></listtemplate>	

  </td>

</tr>

<!--
<tr>
  <td valign=top>
	<table cellpadding=1 cellspacing=1 border=0 width=100%>
	<tr class=rowtitle>
	  <td class=rowtitle align=center>Backup Admin
	  </td>
	</tr>
	<tr>
	  <td valign=top>
	    <ul>
		<li>Current backup path: @backup_path@
	    </ul>
	  </td>
	</tr>
	</table>
  </td>
</tr>
-->

</table>




