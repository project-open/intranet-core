<master src="../master">
<property name=title>#intranet-core.Add_a_user#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>


<p>
#intranet-core.lt_first_names_last_name#
</p>

<p>
<form method="post" action="user-add-3">
<input type="hidden" name="referer" value="@referer@"></input>
#intranet-core.lt_export_varsnoquoteMes#
<textarea name=message rows=10 cols=70 wrap=hard>
#intranet-core.lt_first_names_last_name_1#
</textarea>

<center>
<input type="submit" value="Send Email" />
</center>

</form>
</p>



