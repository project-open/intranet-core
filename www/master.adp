<%= [im_header -show_context_help_p $show_context_help_p $title $header_stuff] %>

<if @user_messages:rowcount@ ne 0>
    <if @feedback_behaviour_key@ eq 0>
        <span id="ajax-status-message" class="critical-notice"><multiple name="user_messages">@user_messages.message;noquote@</multiple></span>
    </if>
    <if @feedback_behaviour_key@ eq 1>
        <span id="ajax-status-message" class="warning-notice"><multiple name="user_messages">@user_messages.message;noquote@</multiple></span>
    </if>
    <if @feedback_behaviour_key@ eq 2>
        <span id="ajax-status-message" class="feedback-notice"><multiple name="user_messages">@user_messages.message;noquote@</multiple></span>
    </if>

</if>

<%= [im_navbar -show_context_help_p $show_context_help_p $main_navbar_label] %>
<%= $sub_navbar %>

<if @show_left_navbar_p@>
	<div id="slave">
	<div id="slave_content">
	<div class="filter-list" id="filter-list">
		<a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="<%=[lang::message::lookup "" intranet-core.Click_To_Show_Side_Menu "Click to show side menu"]%>" alt="sideBar" src="/intranet/images/navbar_default/nav-hamburger-active.png"></a>
		<div class="filter" id="sidebar">
			<div id="sideBarContentsInner">
			     <div title="<%=[lang::message::lookup "" intranet-core.Click_To_Close_Side_Menu "Click to close side menu"]%>" id="sidebar-close-button"></div>
			     <%= $left_navbar %>
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
    <if @feedback_behaviour_key@ eq 0>
    	<!--Critical Err, feedback bar remains -->
    	<script type="text/javascript">
            $('#general_messages_icon_span').click( function() { $('#ajax-status-message').fadeIn(); return false; } );
            $('#general_messages_icon_span').html('&nbsp;<span style="cursor: pointer;"><%=[im_gif "error" ""]%></span>');
	</script>
     </if>

     <if @feedback_behaviour_key@ eq 1 or @feedback_behaviour_key@ eq 2>
        <!-- Serious Err or simple Message , feedback bar disappears -->
	<script type="text/javascript">
		$('#ajax-status-message').delay(8000).fadeOut();
		window.setTimeout(function () {
	                // A red dot will briefly appear to drive the attention to a an "Warning icon" that remains on the upper left corner site, near the search bar  
		     	$('#general_messages_icon_span').html('<span style="border-radius: 50%; width: 200px; height: 200px; background: none repeat scroll 0 0 red;">&nbsp;&nbsp;&nbsp;&nbsp;</span>').hide().fadeIn(500);
		}, 8000);

		window.setTimeout(function () {
		     $('#general_messages_icon_span').fadeOut(500);
		}, 8500);

		window.setTimeout(function () {
			$('#general_messages_icon_span').html('&nbsp;<span style="cursor: pointer;"><%=[im_gif "error" ""]%></span>');
			$('#general_messages_icon_span').fadeIn();
			$('#general_messages_icon_span').click( function() { $('#ajax-status-message').fadeIn(); return false; } );
			/*
			$('#general_messages_icon_span').click( function() {
				window.location = "/intranet/report-error";
				return false;
			} );
			*/
		}, 8800);
    </script>
    </if>
</if>

