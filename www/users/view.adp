<master src="../master">
<property name="title">#intranet-core.Users#</property>
<property name="main_navbar_label">user</property>

<%= $user_navbar_html %>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <%= $user_basic_info_html %>

<if @dynamic_fields_p@>
    <table cellspacing=0 cellpadding=0>
    <tr>
      <td class=rowtitle>
        Additional Information
      </td>
    </tr>
    <tr><td>
      <formtemplate id="person_view"></formtemplate>
    </td></tr>
    </table>
    <br>
</if>

    <%= $user_l10n_html %>
    <%= $profile_html %>
    <%= $contact_html %>
    <%= $admin_links %>
    <%= [im_component_bay left] %>

  </td>
  <td valign=top>
    <%= $portrait_html %>
    <%= $projects_html %>
    <%= $companies_html %>
    <%= $forum_html %>
    <%= $filestorage_html %>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>

  <%= [im_component_bay bottom] %>

</td></tr>
</table>



