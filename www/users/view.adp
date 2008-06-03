<master src="../master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">user</property>

<%= $user_navbar_html %>

<!-- left - right - bottom  design -->

<img src="/intranet/images/cleardot.gif" width=2 height=2>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width='50%'>

    <table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
     <tr><td colspan=2 class=tableheader>Basic Information</td></tr>
     <tr><td>
        <table>
    
    <%= $user_basic_info_html %>
    <%= $user_basic_profile_html %>
    <if @dynamic_fields_p@>
      <formtemplate id="person_view" style="standard-withouttabletab"></formtemplate>
    </if>
    <%= $user_basic_edit_html %>

	</table>

    <%= $user_l10n_html %>

      </td></tr>
    </table>

    <img src="/intranet/images/cleardot.gif" width=2 height=2>

    <table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
    <tr><td colspan=2 class=tableheader>Contact Information</td></tr>
    <tr><td>
    <%= $contact_html %>
    </td></tr>
    </table>

    <img src="/intranet/images/cleardot.gif" width=2 height=2>

    <table cellpadding=2 cellspacing=0 border=1 frame=void width='100%'>
    <tr><td colspan=2 class=tableheader>Administration</td></tr>
    <tr><td>
    <%= $admin_links %>
    </td></tr>
    </table>

    <img src="/intranet/images/cleardot.gif" width=2 height=2>

    <%= [im_component_bay left] %>

  </td>
  <td width=2>&nbsp;</td>
  <td valign=top>
    <%= $portrait_html %>
    <%= $projects_html %>
    <%= $companies_html %>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>

  <%= [im_component_bay bottom] %>

</td></tr>
</table>



