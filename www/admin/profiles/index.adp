<master src="../master">
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
<property name="admin_navbar_label">admin_profiles</property>


<table width="100%">
<tr>
  <td width="50%">

<table>
<tr>
  <td class=rowtitle>Administration Options</td>
</tr>
<tr>
  <td>
    <ul>
    <li><a
    href="/intranet/admin/profiles/new?group_type_exact_p=t&group_type=im_profile">Add a new profile</a>
    </ul>
  </td>
</tr>
</table>


</td>
</tr>
</table>


<include src="/packages/intranet-core/www/admin/permissions/perm-include" object_id="@subsite_id@" privs="@privs@" user_add_url="/admin/permissions-user-add" return_url="@url_stub@">

