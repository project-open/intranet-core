<master src="../master">
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<property name="admin_navbar_label">admin_menus</property>

<h2>@page_title@</h2>

<if 0 ne @object_id@>
<li><a href="<%= [export_vars -base "/intranet/admin/permissions/one" {object_id}]%>">Detailed Permissions</a><br>&nbsp;
</if>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<property name="focus">@focus;literal@</property>
<formtemplate id="menu"></formtemplate>

