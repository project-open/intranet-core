<% set page_title "V[string range [im_core_version] 0 5]" %>
<%= [im_header -loginpage $page_title] %>
<%= [im_navbar -loginpage_p 1] %>

<div id="slave">
<div id="fullwidth-list-no-side-bar" class="fullwidth-list-no-side-bar" style="visibility: visible;">

<table cellSpacing=2 cellPadding=2 width="100%" border="0">
<tr valign="top">
<td vAlign=top width="50%">

	<table cellSpacing=1 cellPadding=1 border="0" width="100%">
	<tr><td colspan="4" class=tableheader align="center"><b>]po[ Demo Accounts</b></td></tr>
	<tr>
		<td class="tableheader" align="center">Username</td>
		<td class="tableheader" align="center">Email</td>
		<td class="tableheader" align="center">Password</td>
	</tr>
	<multiple name=users>
		<if @users.rownum@ odd><tr class="list-plain"></if>
		<else><tr class="list-plain"></else>
		<td class="list-narrow">@users.user_name@</td>
		<td class="list-narrow">@users.email@</td>
		<td class="list-narrow">@users.demo_password@</td>
		</tr>
	</multiple>
	</table>

	<br>
</td>
<td width="50%">

	<table cellSpacing=1 cellPadding=1 border="0">
	<tr><td class=tableheader><b>Intranet Login</b></td></tr></tr>
	<tr><td class=tablebody>
<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">
	</td></tr>
	<tr><td>
		&nbsp;<br><font color=red>Please select one of the demo accounts from the left hand side.&nbsp;<br></font>
	</td></tr>
	</table>

	<br>&nbsp;<br>

	<table cellSpacing=1 cellPadding=1 border="0">
	<tr><td colspan="2" class=tableheader><b>Browser URL</b></td></tr>
	<tr>
		<td class=tablebody>Browser URL</td>
		<td class=tablebody><%= $url %></td>
	</tr>
	<tr>
		<td colspan="2" class=tablebody><small>
		Please enter this URL into the browser on your desktop computer<br>
		in order to access the application.
		</small></td>
	</tr>
	</table>

	<br>&nbsp;<br>

	<table cellSpacing=1 cellPadding=1 border="0">
	<tr><td colspan="2" class=tableheader><b>System Parameters</b></td></tr>
	<tr>
		<td class=tablebody>IP-Address</td>
		<td class=tablebody><%= $ip_address %></td>
	</tr>
	<tr>
		<td colspan="2" class=tablebody><small>
		This is the IP address that this Virtual Machine has obtained automatically via DHCP.
		</small></td>
	</tr>
	<tr>
		<td class=tablebody>Total Memory</td>
		<td class=tablebody><%= $total_memory %> MByte</td>
	</tr>
	<tr>
		<td colspan="2" class=tablebody><small>
		The total memory of the server.<br>
		We recommend atleast 4096 MByte for a production server.
		</small></td>
	</tr>
	</table>

<td>
</tr>
</table>


<table cellSpacing=0 cellPadding=5 width="100%" border="0">
  <tr><td>
	<br><br><br>
	Comments? Contact: 
	<A href="mailto:support@project-open.com">support@project-open.com</A>
  </td></tr>
</table>


</div>
</div>

<%= [im_footer] %>
