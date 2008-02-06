<master src="master">
<property name="title">#intranet-core.Add_new_member#</property>
<property name="main_navbar_label">user</property>

<h2>@page_title@</h2>

<table cellpadding=0 cellspacing=0 border=0>
<tr>
   <td valign=top colspan=2>
	<%= [im_component_bay top] %>
   </td>
</tr>
<tr>
  <td valign=top>
    <%= $locate_form %>
    <%= [im_component_bay left] %>
  </td>
  <td valign=top>
    <%= $select_form %>
    <%= [im_component_bay right] %>
  </td>
</tr>
<tr>
   <td valign=top colspan=2>
	<%= [im_component_bay bottom] %>
   </td>
</tr>
</table>

