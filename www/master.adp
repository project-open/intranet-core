<%= [im_header $title $header_stuff] %>

<if @user_messages:rowcount@ ne 0>

<span id="ajax-status-message" class="warning-notice">
  <multiple name="user_messages">
        @user_messages.message@<br>
  </multiple>
</span>

</if>

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

<if @show_feedback_p@ eq "1">
		@feedback_url;noquote@
                <script type="text/javascript">
                        $(document).ready(function () {
                                /* Set up feedback box on right side */
                                $('#feedback-badge-right').feedbackBadge({
                                        css3Safe: $.browser.safari ? true : false, //this trick prevents old safari browser versions to scroll properly
                                        float: 'right'
                                });
                                $(window).scroll(function () {
                                        var topMargin = ($(window).height() - $('#popup').height())/2 + $(window).scrollTop();
                                        $('#popup').css('margin-top', topMargin);
                                });
                        });
                </script>

</if>

<%= [im_footer] %>

<if @user_messages:rowcount@ ne 0>
<script type="text/javascript">
    $('#general_messages_icon').html('&nbsp;<%=[im_gif "error" ""]%>');
	$('#general_messages_icon').click( function() { $('#ajax-status-message').fadeIn(); return false; } );
    $('#ajax-status-message').delay(8000).fadeOut();
</script>
</if>

