<master src="../master">
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
<property name="admin_navbar_label">admin_profiles</property>


<include src="/packages/intranet-core/www/admin/permissions/perm-include" object_id="@subsite_id@" privs="@privs@" user_add_url="/admin/permissions-user-add" return_url="@url_stub@">

