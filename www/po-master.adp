<%= [im_header $title $header_stuff] %>
<%= [im_navbar $main_navbar_label] %>
<%= $sub_navbar %>

<div id="slave">
<div id="slave_content">

<!-- intranet/www/master.adp before slave -->
<div class="filter-list">
        <a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_default/nav-hamburger-active.png"></a>
	<div class="filter" id="sidebar">
		<div id="sideBarContentsInner">
			<div title="<%=[lang::message::lookup "" intranet-core.Click_To_Close_Side_Menu "Click to close side menu"]%>" id="sidebar-close-button"></div>
			<%= $left_navbar %>
			<div class="filter-block">
				<div class="filter-title">#intranet-core.Home#</div>
			</div>
			<hr/>
			@navbar_tree;noquote@
		</div>
	</div>
	<div class="fullwidth-list" id="fullwidth-list">


<h1><font color=red>Old Master Template</font></h1>
<p><font color=red>
Please contact your SysAdmin and tell him to change the parameter <br>
'intranet-subsite.DefaultMaster' to '/packages/intranet-core/www/master'.<br>
</font></p>


<slave>
	</div>
</div>
<!-- intranet/www/master.adp after slave -->

</div>
</div>
<%= [im_footer] %>
