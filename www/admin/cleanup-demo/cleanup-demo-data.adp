<master src="../master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<!-- left - right - bottom  design -->

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <H2><font color=red>@page_title;noquote@</font></H2>


    <h3><font color=red>
      Are you really sure to delete all data in your system?
    </font></h3>

    <form action=cleanup-demo-data-2 method=GET>
    <center><input type=submit value="Cleanup All Data in the System"></center>
    </form>

  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


