<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="admin_navbar_label">admin_menus</property>

<h2>@page_title@</h2>

<li><a href="<%= [export_vars -base "/intranet/admin/permissions/one" {{object_id menu_id}}]%>">Detailed Permissions</a><br>&nbsp;

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<property name="focus">@focus;noquote@</property>
<formtemplate id="menu"></formtemplate>

