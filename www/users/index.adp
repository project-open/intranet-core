<master src="../master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">user</property>

<!--
<if "" ne @action_html@>
<p>
@action_html;noquote@
</p>
</if>
-->

<%= [im_gif cleardot "" 0 1 3] %>

<table cellspacing=0 cellpadding=0>
<tr valign=top>
  <td>
	<form method=get action='/intranet/users/index' name=filter_form>
	<%= [export_form_vars start_idx order_by how_many letter] %>
	<input type=hidden name=view_name value="user_list">
	<table border=0 cellpadding=0 cellspacing=0>
	<tr valign=top>
	  <td colspan='2' class=rowtitle align=center>
	    #intranet-core.Filter_Users#
	  </td>
	</tr>
	<tr>
	  <td>#intranet-core.User_Types#  &nbsp;</td>
	  <td>
	    <%= [im_select user_group_name $user_types ""] %>
	    <input type=submit value=Go name=submit>
	  </td>
	</tr>
	</table>
	</form>
  </td>

<if "" ne @admin_html@>

  <td>&nbsp;</td>

  <td valign=top>
    <table border=0 cellpadding=0 cellspacing=0>
    <tr valign=top>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Users#
      </td>
    </tr>
    <tr valign=top>
      <td>
        @admin_html;noquote@
      </td>
    </tr>
    </table>
  </td>

</if>

</tr>
</table>
@page_body;noquote@