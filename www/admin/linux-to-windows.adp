<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_home</property>

<h1>Convert Parameters to Windows</h1>

<table cellpadding=0 cellspacing=0 border=0 width=80%>
<tr>
  <td colspan=2 valign=top>
<p>
This page automates the steps that you would have to take
manually to run a preconfigured
<span class=brandsec>&\#93;</span><span class=brandfirst>project-open</span><span class=brandsec>&\#91;</span>
installation from Linux with Windows. In particular this command does:
<ul>
<li>Convert all pathes from /web/&lt;server&gt;/... to C:/project-open/... 
<li>Converts the /usr/bin/find command to /bin/find
</ul>
</p>
</td>
</tr>

<tr>
  <td align=left>Server Name</td>
  <td align=left>
    <form action=linux-to-windows-2 method=POST>
    <input type=text name=install_dir value="@install_dir@"> (something like: "c:/project-open" with forward slashes)
    <br>
    <input type=submit>
    </form>
  </td>
</tr>

</table>


