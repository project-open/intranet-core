<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <H2>@page_title;noquote@</H2>
    <ul>
      <li>
	<A href="../users/">#intranet-core.lt_Manage_Individual_Use#</A><br>
	#intranet-core.lt_Here_you_can_manage_u#
      <li>
	<A href="profiles/">#intranet-core.Manage_Profiles#</A><br>
	#intranet-core.lt_Configure_site-wide_d#
      <li>
	<A href="menus/">#intranet-core.Manage_Menus#</A><br>
	#intranet-core.lt_Edit_menus_and_change#
      <li>
	<A href="parameters/">#intranet-core.lt_Manage_Global_System_#</A><br>
	#intranet-core.lt_Change_the_system_par#
      <li>
	<A href="components/">#intranet-core.lt_Manage_Component_Layo#</A><br>
	#intranet-core.lt_Change_the_position_o#
      <li>
	<A href=flush_cache>#intranet-core.lt_Flush_Permission_Cach#</A><br>
	#intranet-core.lt_Flush_cleanup_the_per#
      <li>
	<A href=/admin/>#intranet-core.lt_Manage_the_OpenACS_Pl#</A><br>
	#intranet-core.lt_Here_you_find_advance# 
	<A href=http://www.openacs.org>#intranet-core.OpenACS_platform#</A>.
      <li>
	<A href=/acs-admin/developer>#intranet-core.lt_Manage_OpenACS_Develo#</A><br>
	#intranet-core.lt_Here_you_find_advance_1# 
	<A href=http://www.openacs.org>#intranet-core.OpenACS_platform#</A>.
      <li>
	<A href=backup/pg_dump>#intranet-core.PostgreSQL_Backup#</A><br>
	#intranet-core.PostgreSQL_Backup_blurb# 

<if [db_table_exists im_dynval_vars]>
      <li>
	<a href=/intranet-dynvals/admin/>#intranet-core.Administer_DynVals#</a><br>
	#intranet-core.lt_Modify_the_access_per#
</if>

<!--
      <li>
	<a href=/intranet/projects/import-project-txt>
	  #intranet-core.lt_Import_Projects_from_#
      </a>
-->
    </ul>
    <%= [im_component_bay left] %>

<!--
<b>#intranet-core.Dangerous#</b>
    <ul>
	<li>
	  <a href=/intranet/anonymize>#intranet-core.lt_Anonymize_this_server#</a>
	  #intranet-core.lt_This_command_destroys#
    </ul>
-->

  </td>
  <td valign=top>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


