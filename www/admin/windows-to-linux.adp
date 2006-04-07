<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<h1>Convert Parameters to Linux</h1>

<table cellpadding=0 cellspacing=0 border=0 width=80%>
<tr>
  <td colspan=2 valign=top>
<p>
This page automates the steps that you would have to take
manually to run a preconfigured
<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>
installation with Linux. In particular this command does:
<ul>
<li>Convert all pathes from C:/ProjectOpen/... to /web/&lt;server&gt;/...
<li>Converts the /usr/find command to /usr/bin/find/
</ul>
</p>
</td>
</tr>

<tr>
  <td align=left>Server Name</td>
  <td align=left>
    <form action=windows-to-linux-2 method=POST>
    <input type=text name=server_name value="@server_name@"><br>
    <input type=submit>
    </form>
  </td>
</tr>

</table>


