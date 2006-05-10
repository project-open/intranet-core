<master>

<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>

<form action=widgets-delete method=post>

<table class="list">

  <tr class="list-header">
    <th class="list-narrow">#intranet-dynfield.Name#</th>
    <th class="list-narrow">#intranet-dynfield.Pretty_Name#</th>
    <th class="list-narrow">#intranet-dynfield.Storage_Type#</th>
    <th class="list-narrow">#intranet-dynfield.ACS_Datatype#</th>
    <th class="list-narrow">#intranet-dynfield.SQL_Datatype#</th>
    <th class="list-narrow">#intranet-dynfield.OACS_Widget#</th>
    <th class="list-narrow">#intranet-dynfield.Parameters#</th>
    <th class="list-narrow">#intranet-dynfield.Del#</th>
  </tr>

  <multiple name=widgets>
  <if @widgets.rownum@ odd>
    <tr class="list-odd">
  </if> <else>
    <tr class="list-even">
  </else>
  
    <td class="list-narrow">
      <a href=widget-new?widget_id=@widgets.widget_id@>
	@widgets.widget_name@
      </a>
    </td>
    <td class="list-narrow">
	@widgets.pretty_name@
    </td>
    <td class="list-narrow">
	@widgets.storage_type@
    </td>
    <td class="list-narrow">
	@widgets.acs_datatype@
    </td>
    <td class="list-narrow">
	@widgets.sql_datatype@
    </td>
    <td class="list-narrow">
	@widgets.widget@
    </td>
    <td class="list-narrow">
	@widgets.parameters@
    </td>
    <td class="list-narrow">
	<input type="checkbox" name="widget_id.@widgets.widget_id@">
    </td>

  </tr>
  </multiple>
</table>

<table width=100%>
  <tr>
    <td colspan=99 align=right>
      <input type=submit value="Delete Selected Widgets">
    </td>
  </tr>
</table>

</form>


<ul>
<li><A href=widget-new>#intranet-dynfield.Create_a_new_Widget#</a>
</ul>

