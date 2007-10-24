<master src="../master">
<property name="title">#intranet-core.Offices#</property>
<property name="main_navbar_label">offices</property>

<!-- left - right - bottom  design -->

<table cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
  <td valign=top>
    <%= [im_box_header [_ intranet-core.Office_Information]] %>
    <%= $office_html %>
    <%= [im_box_footer] %>
    <%= [im_component_bay left] %>

  </td>
  <td valign=top>
    <%= [im_component_bay right] %>

    <%= [im_box_header [_ intranet-core.all_offices]] %>

    <p>
      #intranet-core.See_the_list_of# <A href=/intranet/offices/>#intranet-core.all_offices# </A>
    </p>
    <%= [im_box_footer] %>

  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>

  <%= [im_component_bay bottom] %>

</td></tr>
</table>

