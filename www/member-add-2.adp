<master src="master">
<property name=title>Add a user</property>
<property name="context">@context;noquote@</property>

<H1>Send Notification</H1>
@first_names@ @last_name@ has been added to @system_name@.
Edit the message below and hit "Send Email" to 
notify this user.
</p>

<form method="post" action="member-notify">
@export_vars;noquote@

<textarea name=subject rows=1 cols=70 wrap=hard>
@role_name@ of @object_name@
</textarea>

<textarea name=message rows=10 cols=70 wrap=hard>
Dear @first_names@,

You have been added as a @role_name@
to @object_name@
in @system_name@ 
at @object_url@

Please click on the link above for details.

Best regards,
@current_user_name@
</textarea>

<center>
<input type="submit" value="Send Email" />
</center>

</form>
</p>


