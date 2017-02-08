<master src="/packages/intranet-core/www/master">
<property name="doc(title)">@page_title@</property>
<property name="main_navbar_label">master_data</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="sub_navbar">@sub_navbar;literal@</property>
<property name="header_stuff">@header_stuff;literal@</property>
<property name="show_context_help_p">@show_context_help_p;literal@</property>

<h1>Master Data</h1>

@help_html;literal@


<table>
  <tr class="list-header">
    <th class="list-narrow">#intranet-core.Object_Type#</th>
    <th class="list-narrow">#intranet-dynfield.Pretty_Name#</th>
    <th class="list-narrow">Count</th>
  </tr>
  <multiple name=otypes>

<!--
          <if @last_section@ ne @otypes.section@>
	    <tr class="list-narrow"><td colspan=99 align=center><h2>@otypes.section@</h2></td></tr>
	  </if>
-->
          <if @otypes.rownum@ odd>
            <tr class="list-odd">
          </if> <else>
            <tr class="list-even">
          </else>

          <td class="list-narrow">
            <if "" ne @otypes.url@><a href="@otypes.url@" target="_"></if>
                @otypes.object_type@
            <if "" ne @otypes.url@></a></if>
          </td>
          <td class="list-narrow">
            <if "" ne @otypes.url@><a href="@otypes.url@" target="_"></if>
              @otypes.pretty_name@
            <if "" ne @otypes.url@></a></if>
          </td> 
          <td class="list-narrow">
                @otypes.cnt@
          </td>
          <% set last_section $otypes(section) %>

  </multiple>
</multiple>
</table>
