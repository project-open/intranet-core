<master src="../master">
<property name="doc(title)">#intranet-core.Add_a_user#</property>
<property name="context">@context;literal@</property>
<property name="main_navbar_label">user</property>


<p>
#intranet-core.lt_first_names_last_name#
</p>

<p>
<form method="post" action="user-add-3">

<%= [export_vars -form {email first_names last_name user_id return_url}] %>

<textarea name=message rows=10 cols=70 wrap="<%=[im_html_textarea_wrap]%>">#intranet-core.lt_first_names_last_name_1#</textarea>

<center>
<input type="submit" name="submit_nosend" value="#intranet-core.Dont_Send_Email#" />
<input type="submit" name="submit_send" value="#intranet-core.Send_Email#" />
</center>

</form>
</p>



