<master src="master">
<property name="doc(title)">#intranet-core.Add_new_member#</property>
<property name="main_navbar_label">user</property>

<h2>@page_title@</h2>

<if "" eq @return_url@>
<font color=red>
No return_url specified.<br>
The referring page as not passed a 'return_url' field<br>
to this page. Please keep your browser open and call your<br>
System Administrator, so that he or she can reproduce the<br>
error. Thanks!<br>&nbsp;<br>
</font>
</if>

<table cellpadding="0" cellspacing="0" border="0">
<tr>
	     <td valign="top"><%= $locate_form %></td>
	     <td valign="top"><%= $employee_form %></td>
<!--	     <td valign="top"><%= $skill_profile_form %></td> fraber 2023-02-20: ToDo: Move skill select to separate portlet -->
</tr>
<tr>
   <td valign="top" colspan="2">
	<%= [im_component_bay top] %>
   </td>
</tr>
<tr>
  <td valign="top">
    <%= [im_component_bay left] %>
  </td>
  <td valign="top">
    <%= [im_component_bay right] %>
  </td>
</tr>
<tr>
   <td valign="top" colspan="2">
	<%= [im_component_bay bottom] %>
   </td>
</tr>
</table>
