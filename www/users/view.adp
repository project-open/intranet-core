<master src="../master">
<property name="title">Companies</property>

<%= $user_navbar_html %>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    $user_basic_info_html
    $contact_html
    <%= [im_component_bay left] %>

  </td>
  <td valign=top>
    $admin_links
    $projects_html
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>

  $freelance_skills
  <%= [im_component_bay bottom] %>

</td></tr>
</table>


