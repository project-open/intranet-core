<master>
<property name="doc(title)">@page_title@</property>
<property name="main_navbar_label">companies</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="sub_navbar">@sub_navbar_html;literal@</property>

<if 0 eq @plugin_id@>
	<table cellpadding="0" cellspacing="0" border="0" width="100%">
	<tr>
	  <td colspan="3">
	    <%= [im_component_bay top] %>
	  </td>
	</tr>
	<tr>
	  <td valign="top" width="50%">
	    <%= [im_component_bay left] %>
	  </td>
	  <td width=2>&nbsp;</td>
	  <td valign="top" width="50%">
	    <%= [im_component_bay right] %>
	  </td>
	</tr>
	<tr>
	  <td colspan="3">
	    <%= [im_component_bay bottom] %>
	  </td>
	</tr>
	</table>
</if>
<else>
        <%= [im_component_page -plugin_id $plugin_id -return_url $return_url] %>
</else>


