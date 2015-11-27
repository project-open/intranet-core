<master src="master">
<property name="doc(title)">#intranet-core.Add_a_user#</property>
<property name="context">@context;literal@</property>
<property name="main_navbar_label">user</property>

<H1>#intranet-core.Send_Notification#</H1>
#intranet-core.lt_first_names_from_sear#
</p>

<table>
<form method="post" action="member-notify">
@export_vars;noquote@

<tr>
  <td>
<textarea name=subject rows=1 cols=70 wrap="<%=[im_html_textarea_wrap]%>">
#intranet-core.lt_role_name_of_object_n#
</textarea>
  </td>
</tr>

<tr>
  <td>
	<textarea name=message rows=15 cols=90 wrap="<%=[im_html_textarea_wrap]%>">#intranet-core.lt_Dear_first_names_from#</textarea>
  </td>
</tr>

<tr>
  <td>
  	<center>
	<table cellpadding="0" cellspacing="0" border="0">
	<tr>
		<td valign='top'>
		    <input type="submit" value="#intranet-core.Send_Email#" /><br>
		    <input type="checkbox" name="send_me_a_copy" value="1" checked>
		    <%= [lang::message::lookup "" intranet-core.Send_me_a_copy "Send me a copy"] %>&nbsp;&nbsp;
		</td>
		<td valign='top'>
		    <input type="submit" value="<%= [lang::message::lookup "" intranet-core.DoNotSendNotificationMail "Do NOT notify"] %>" name="cancel">
		</td>
	</tr>
	</table>
	</center>
  </td>
</tr>
</form>
</table>

</p>



