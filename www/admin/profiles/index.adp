<master src="../master">
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="admin_navbar_label">admin_profiles</property>


<include src="/packages/intranet-core/www/admin/permissions/perm-include" mode="@mode@" object_id="@subsite_id@" privs="@privs@" user_add_url="/admin/permissions-user-add" return_url="@url_stub@">

