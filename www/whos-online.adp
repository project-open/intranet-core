<master src="master">
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>
<property name="main_navbar_label">user</property>


<p><listtemplate name="online_users"></listtemplate></p>

<if @not_shown@>
<p>
@not_shown@ <%= [lang::message::lookup "" intranet-core.User_s_not_shown "user(s) not shown"] %>.
</p>
</if>
