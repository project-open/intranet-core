<%= [im_header $title $header_stuff] %>
<%= [im_navbar $main_navbar_label] %>
<%= $sub_navbar %>

<if @show_left_navbar_p@>
	<div id="slave">
	<div id="slave_content">
	<div class="filter-list" id="filter-list">
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
				<%= [im_navbar_tree -label "main"] %>
	
			</div>
		</div>
		<div class="fullwidth-list" id="fullwidth-list">
			<slave>
		</div>
	</div>
	</div>
	</div>
</if>
<else>
	<div class="fullwidth-list-no-side-bar" id="fullwidth-list">
		<slave>
	</div>

</else>
<%= [im_footer] %>











