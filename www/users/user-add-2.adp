<master src="../master">
<property name=title>#intranet-core.Add_a_user#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>


<p>
#intranet-core.lt_first_names_last_name#
</p>

<p>
<form method="post" action="user-add-3">

<%= [export_form_vars email first_names last_name user_id return_url] %>

<textarea name=message rows=10 cols=70 wrap="<%=[im_html_textarea_wrap]%>">#intranet-core.lt_first_names_last_name_1#</textarea>

<center>
<input type="submit" name=submit_nosend value="Don't Send Email" />
<input type="submit" name=submit_send value="Send Email" />
</center>

</form>
</p>



