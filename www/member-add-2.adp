<master src="master">
<property name=title>#intranet-core.Add_a_user#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>

<H1>#intranet-core.Send_Notification#</H1>
#intranet-core.lt_first_names_from_sear#
</p>

<form method="post" action="member-notify">
@export_vars;noquote@

<textarea name=subject rows=1 cols=70 wrap=hard>
#intranet-core.lt_role_name_of_object_n#
</textarea>

<textarea name=message rows=10 cols=70 wrap=hard>
#intranet-core.lt_Dear_first_names_from#
</textarea>

<center>
<input type="submit" value="Send Email" />
</center>

</form>
</p>



