<master src="../master">
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Menu_Backup_Restore#</property>
  <property name="admin_navbar_label">admin_backup</property>

<table cellpadding=1 cellspacing=1 border=0>
<tr>
  <td valign=top>


	<table cellpadding=1 cellspacing=1 border=0 width=100%>
	<tr class=rowtitle>
	  <td class=rowtitle align=center>Restore Data
	  </td>
	</tr>
	<tr>
	  <td>
	    @backup_sets_html;noquote@
	  </td>
	</tr>
	</table>


	<%= [im_component_bay left] %>

  </td>

</tr>
<tr>

  <td valign=top>

	<table cellpadding=1 cellspacing=1 border=0 width=100%>
	<tr class=rowtitle>
	  <td class=rowtitle align=center>Backup Data
	  </td>
	</tr>
	<tr>
	  <td valign=top>
	    <ul>
	      <li>
		<A href="backup">Backup</a> the current application data
	    </ul>
	  </td>
	</tr>
	</table>

  </td>
</tr>
</table>




