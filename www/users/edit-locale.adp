<master src="../master">
<property name="title">#intranet-core.Users#</property>
<property name="main_navbar_label">user</property>


<if @admin_p@>
  <div style="float: right;">
    <a href="admin" class="button">Administration</a>
  </div>
</if>

<formtemplate id="locale"></formtemplate>