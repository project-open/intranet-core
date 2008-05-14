<master src="master">
<property name=title>#intranet-core.Add_a_user#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>

<H1>#intranet-core.Send_Notification#</H1>
#intranet-core.lt_first_names_from_sear#
</p>

<form method="post" action="member-notify">
@export_vars;noquote@

<table cellspacing=0 cellpadding=0>
<tr>
<td>
	<textarea name=subject rows=1 cols=70 wrap="<%=[im_html_textarea_wrap]%>">
	#intranet-core.lt_role_name_of_object_n#
	</textarea>
</td>
</tr>
<tr>
<td>
	<textarea name=message rows=10 cols=70 wrap="<%=[im_html_textarea_wrap]%>">
	#intranet-core.lt_Dear_first_names_from#
	</textarea>
</td>
</tr>
<tr>
<td align=right>
	<input type="submit" value="Send Email" />
	<input type=checkbox name=send_me_a_copy value=1 checked>
	<%= [lang::message::lookup "" intranet-core.Send_me_a_copy "Send me a copy"] %>
</td>
</tr>
</table>

</form>
</p>



