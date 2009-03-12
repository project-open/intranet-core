<%= [im_header $title $header_stuff] %>
<%= [im_navbar $main_navbar_label] %>
<%= $sub_navbar %>

<div id="slave">
<div id="slave_content">

<!-- intranet/www/master.adp before slave -->
<div class="filter-list">
	<a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>
	<div class="filter" id="sidebar">
		<div id="sideBarContentsInner">

			<!-- Left Navigation Bar -->
			<%= $left_navbar %>
			<!-- End Left Navigation Bar -->

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









