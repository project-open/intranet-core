<master src="../master">
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>
  <property name="admin_navbar_label">admin_components</property>


<form action=add-stuff-2 method=post>
<%= [export_form_vars return_url] %>

<table class="list">

  <tr class="list-header">
    <th class="list-narrow">#intranet-core.Name#</th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Package "Package"] %></th>
    <th class="list-narrow"><%= [lang::message::lookup "" intranet-core.Location "Location"] %></th>
    <th class="list-narrow">#intranet-core.Sel#</th>
  </tr>

  <multiple name=components>
	  <if @components.rownum@ odd>
	    <tr class="list-odd">
	  </if> <else>
	    <tr class="list-even">
	  </else>
	      <td class="list-narrow">
	      <a href=edit?plugin_id=@components.plugin_id@>
		@components.plugin_name@
	      </a>
	    </td>
	    <td class="list-narrow">
		@components.package_name@
	    </td>
	    <td class="list-narrow">
		@components.location@
	    </td>
	    <td class="list-narrow">
		<input type="checkbox" name="plugin_id.@components.plugin_id@">
	    </td>
	  </tr>
	  </multiple>
  <tr>
    <td colspan=4 align=right>
      <input type=submit value="<%= [lang::message::lookup "" intranet-core.Add_to_Page "Add to Page"] %>">
    </td>
  </tr>
</table>
</form>

