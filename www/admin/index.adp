<master src="master">
<property name="title">@page_title;noquote@</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <H2>@page_title;noquote@</H2>
    <ul>
      <li>
	<A href="../users/">Manage Individual Users</A><br>
	Here you can manage users one-by-one.
      <li>
	<A href=permissions/permissions>Manage Profiles</A><br>
	Profiles are a kind of groups to which users can belong.
	Profiles define the which actions that a user can perform.
      <li>
	<A href=user_matrix/>Manage the User Matrix</A><br>
	Define which users can see or manage wich other users.
      <li>
	<A href=categories>Manage Categories</A><br>
	Categories define the types and stati of business objects.
      <li>
	<A href=/admin/>Manage the OpenACS Platform</A><br>
	Here you find advance management and configuration options
	of the underlying 
	<A href=http://www.openacs.org>OpenACS platform</A>.
      <li>
	<A href=/acs-admin/developer>Manage OpenACS Development</A><br>
	Here you find advance software configuration options
	of the underlying 
	<A href=http://www.openacs.org>OpenACS platform</A>.
	<li>
	  <a href=/intranet/projects/import-project-txt>Import Projects from H:\\</a>


      </ul>
<b>Dangerous!!</b>
      <ul>
	<li>
	  <a href=/intranet/anonymize>Anonymize this server (Test servers only)</a>
	  This command destroys your entire server, replacing all strings (project
	  names, customer names, users, descriptions, ...) by "anonymized" random 
	  strings in order to generate a demo system.
    </ul>
    <%= [im_component_bay left] %>
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

