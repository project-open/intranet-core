<master src="master">
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>


<p><listtemplate name="online_users"></listtemplate></p>

<if @not_shown@>
<p>
@not_shown@ user(s) not shown.
</p>

</if>
