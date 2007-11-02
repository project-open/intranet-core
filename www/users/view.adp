<master src="../master">
<property name="title">#intranet-core.Users#</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@user_navbar_html;noquote@</property>

<!-- left - right - bottom  design -->

<img src="/intranet/images/cleardot.gif" width=2 height=2>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width='50%'>

    <%= [im_box_header "Basic Information"] %>     

        <table>
    
    <%= $user_basic_info_html %>
    <%= $user_basic_profile_html %>
    <if @dynamic_fields_p@>
      <formtemplate id="person_view" style="standard-withouttabletab"></formtemplate>
    </if>
    <%= $user_basic_edit_html %>

	</table>

    <%= $user_basic_skin_html %>

    <%= $user_l10n_html %>

    <%= [im_box_footer] %>

    <%= [im_table_with_title "Contact Information" $contact_html] %>
    <%= [im_table_with_title "Administration" $admin_links] %>
    <%= [im_component_bay left] %>

  </td>
  <td width=2>&nbsp;</td>
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



