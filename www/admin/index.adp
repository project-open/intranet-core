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

