<%= [im_header $title $header_stuff] %>
<%= [im_navbar -show_context_help_p $show_context_help_p $main_navbar_label] %>
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

<if @show_navbar_p@ and @show_left_navbar_p@>	
				<hr/>
				<div class="filter-block">
					<div class="filter-title">#intranet-core.Home#</div>
				</div>
				<%= [im_navbar_tree -label "main"] %>
</if>

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











