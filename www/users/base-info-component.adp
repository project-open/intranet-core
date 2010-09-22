<if @read@>
<formtemplate id="userinfo"></formtemplate>
@contact_html;noquote@
</if>
<else>
	<p><%= [lang::message::lookup "" intranet-core.Insufficent_permissions_for_username "Insufficient permissions to see the details of user @user_name_pretty@."] %>
	</p>
</else>
