<master src="master">
<property name="title">#intranet-core.Home#</property>
<property name="main_navbar_label">home</property>
<property name="header_stuff">@header_stuff;noquote@</property>

<!-- left - right - bottom  design -->



<if @show_left_functional_menu_p@>

<div class="filter-list">

  <a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>

  <div class="filter" id="sidebar">
    <div id="sideBarContentsInner">
      <div class="filter-block">
        <div class="filter-title">#intranet-core.Home#</div>
      </div>
      <hr/>
      <%= [im_navbar_tree -label "main"] %>
    </div>
  </div>

  <div class="fullwidth-list" id="fullwidth-list">
</if>


	<table cellpadding=0 cellspacing=0 border=0 width="100%">
	<tr>
	  <td colspan=3>
	    <%= [im_component_bay top] %>
	  </td>
	</tr>
	<tr>
	  <td valign="top" width="50%">
	    <%= [im_component_bay left] %>
	  </td>
	  <td width=2>&nbsp;</td>
	  <td valign="top" width="50%">

	    <if "" ne @upgrade_message@>
	        <%= [im_table_with_title "Upgrade Information" $upgrade_message] %>
	    </if>

	    <%= [im_component_bay right] %>
	  </td>
	</tr>
	<tr>
	  <td colspan=3>
	    <%= [im_component_bay bottom] %>
	  </td>
	</tr>
	</table>


<if @show_left_functional_menu_p@>
  </div>
</div>

</if>





