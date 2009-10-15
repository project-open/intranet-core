<master>
<property name="title">#intranet-core.Home#</property>
<property name="main_navbar_label">home</property>
<property name="header_stuff">@header_stuff;noquote@</property>

<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
  <td colspan=3>

<if "" ne @browser_warning_msg@>
   <%= [im_box_header $browser_warning] %>
   <font color=red>
   <h3>@browser_warning@</h3>
   @browser_warning_msg;noquote@
   </font>
   <%= [im_box_footer] %>
</if>

    <%= [im_component_bay top] %>
  </td>
</tr>
<tr>
  <td valign="top" width="50%">
    <%= [im_component_bay left] %>
  </td>
  <td width=2>&nbsp;</td>
  <td valign="top" width="50%">

    <if "" ne @upgrade_message@>
        <%= [im_table_with_title "Upgrade Information" $upgrade_message] %>
    </if>

    <%= [im_component_bay right] %>
  </td>
</tr>
<tr>
  <td colspan=3>
    <%= [im_component_bay bottom] %>
  </td>
</tr>
</table>

