/*   START: NEW SIDEBAR */

var height = 600;
var width = 243;
var slideDuration = 200;
var opacityDuration = 200;
var rv = 0;
var isExtended = 1;
var sidebarMarginLeftExtended = '253px';
var sidebarMarginLeft = '25px';

function extendContract(){
    if (document.getElementById("sideBarTab") != null) {
	var node_to_move=document.getElementById("sidebar");
	if(isExtended == 0){

	    // extend 
	    if (document.getElementById('sidebar').getAttribute('savedHeight') != null) height = document.getElementById('sidebar').getAttribute('savedHeight') ;
	    sideBarSlide(0, height, 0, width);
	    sideBarOpacity(0,1);
	    isExtended = 1;

	    // move main part
	    $(".fullwidth-list").animate({marginLeft: sidebarMarginLeftExtended}, slideDuration );

	    // make expand tab arrow image face left (inwards)
	    $('#sideBarTab').children().get(0).src = $('#sideBarTab').children().get(0).src.replace(/(\.[^.]+)$/, '-active$1');
	    document.getElementById('slave_content').style.visibility='visible';

	    // [temp] set back to height=auto when animation is done, should be triggered based on event  
	    var time_out=setTimeout("document.getElementById('sidebar').style.height='auto'",2500);

	    // Store status 
	    poSetCookie('isExtendedCookie',1,90);

	    // Set sidebar graphics
	    $('#sideBarTabImage').hide();
	    $('#sideBarTab').hide();
	    $('#sidebar-close-button').fadeTo( "2000",0.5);

	} else {
	    // collapse
	    document.getElementById('sidebar').setAttribute('savedHeight',document.getElementById('sidebar').offsetHeight);
	    sideBarSlide(height, 135, width, 0);
	    sideBarOpacity(1,0);
	    isExtended = 0;
	    $(".fullwidth-list").animate({marginLeft: sidebarMarginLeft}, slideDuration );
	    // make expand tab arrow image face right (outwards)
	    $('#sideBarTab').children().get(0).src = $('#sideBarTab').children().get(0).src.replace(/-active(\.[^.]+)$/, '$1');
	    document.getElementById('slave_content').style.visibility='hidden';
	    poSetCookie('isExtendedCookie',0,90);
	    $('#sideBarTabImage').fadeTo( "2000",1);
	    // $('#sideBarTabImage').show();
            $('#sideBarTabImage').show();
            $('#sideBarTab').show();
	};
    };
};

function sideBarSlide(fromHeight, toHeight, fromWidth, toWidth) {
    $("sidbar").css ({'height': fromHeight, 'width': fromWidth});
    $("#sidebar").animate( { 'height': toHeight, 'width': toWidth }, { 'queue': false, 'duration': slideDuration }, "linear" );
};

function sideBarOpacity(from, to) {
	$("#sideBarContents").animate( { 'opacity': to }, opacityDuration, "linear" );
};

/*   END: SIDEBAR */


jQuery().ready(function(){

    // Build smartmenu
    $(function() {
	    $('#navbar_main').smartmenus({
		    subMenusSubOffsetX: 2,
		    subMenusSubOffsetY: -5 
	    });
    });
	
    $("#header_skin_select > form > select").change(function() {
	$("#header_skin_select > form").submit();
    });
    
    $(".component-parking div").click(function() {	
	$(".component-parking ul").slideToggle();
    });
    
    /* In order to make this skin work we need to re-order DIVs */
    var node_insert_after=document.getElementById("slave");
    var node_to_move=document.getElementById("fullwidth-list");
    if (node_insert_after != null && node_to_move != null) {
	document.getElementById("monitor_frame").insertBefore(node_to_move, node_insert_after.nextSibling);
        document.getElementById('fullwidth-list').style.visibility='visible';
    };
    
    node_insert_after=document.getElementById("main_header");
    node_to_move=document.getElementById("navbar_sub_wrapper");
    if (node_insert_after != null && node_to_move != null) {
        document.getElementById("main").insertBefore(node_to_move, node_insert_after.nextSibling);
    };
    
    /* BUG TRACKER */
    var node_insert_after=document.getElementById("slave_content");
    var node_to_move=document.getElementById("bug-tracker-navbar");
    if (node_insert_after != null && node_to_move != null) {
	document.getElementById("slave").insertBefore(node_to_move, node_insert_after.nextSibling);
    };
    
    if (document.getElementById("fullwidth-list") == null){
	if (document.getElementById("slave_content") != null) {
	    document.getElementById('slave_content').style.position='relative';	
	};
    };
    
    // Avoid larger screens in IE 
    if (navigator.appName == 'Microsoft Internet Explorer') {
	var ua = navigator.userAgent;
	var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
	if (re.exec(ua) != null)
	    rv = parseFloat( RegExp.$1 );
    };

    // Setting width=100% in IE10 leads again to the large screen ...  
    if ( rv!=0 && document.getElementById("fullwidth-list") != null && rv<10) {
	document.getElementById('fullwidth-list').style.width='100%';
    };
    
    // $(".component_icons").css("opacity","1.1");

    $(".icon_seperator").css('visibility', 'hidden');
    $(".icon_left").css('visibility', 'hidden');
    $(".icon_up").css('visibility', 'hidden');
    $(".icon_down").css('visibility', 'hidden');
    $(".icon_right").css('visibility', 'hidden');
    $(".icon_close").css('visibility', 'hidden');
    $(".icon_help").css('visibility', 'hidden');
    $(".icon_wrench").css('visibility', 'hidden');
    $(".icon_minimize").css('visibility', 'hidden');
    $(".icon_maximize").css('visibility', 'hidden');

    $(".component_header",this).hover(function() {
	if ($(this).width() < 400) {
	    $(this).children().first().css('visibility', 'hidden');
	};
	$(this).children().find(".icon_seperator").css('visibility', 'visible');
	$(this).children().find(".icon_left").css('visibility', 'visible');
	$(this).children().find(".icon_up").css('visibility', 'visible');
	$(this).children().find(".icon_down").css('visibility', 'visible');
	$(this).children().find(".icon_right").css('visibility', 'visible');
	$(this).children().find(".icon_close").css('visibility', 'visible');
	$(this).children().find(".icon_help").css('visibility', 'visible');
	$(this).children().find(".icon_wrench").css('visibility', 'visible');
	$(this).children().find(".icon_minimize").css('visibility', 'visible');
	$(this).children().find(".icon_minimize").css('visibility', 'visible');
	$(this).children().find(".icon_maximize").css('visibility', 'visible');
	$(this).children().find('.icon_help').css('visibility', 'visible');
	// $(this).children().find('.icon_config').css('visibility', 'hidden');
        // $(".component_icons",this).stop().fadeTo("fast",1);

    },function(){
       // $(".component_icons",this).stop().fadeTo("normal",0.1);
        $(this).children().first().css('visibility', 'visible');
        $(this).children().find(".icon_seperator").css('visibility', 'hidden');
        $(this).children().find(".icon_left").css('visibility', 'hidden');
        $(this).children().find(".icon_up").css('visibility', 'hidden');
        $(this).children().find(".icon_down").css('visibility', 'hidden');
        $(this).children().find(".icon_right").css('visibility', 'hidden');
        $(this).children().find(".icon_close").css('visibility', 'hidden');
        $(this).children().find(".icon_help").css('visibility', 'hidden');
        $(this).children().find(".icon_wrench").css('visibility', 'hidden');
        $(this).children().find(".icon_minimize").css('visibility', 'hidden');
        $(this).children().find(".icon_minimize").css('visibility', 'hidden');
        $(this).children().find(".icon_maximize").css('visibility', 'hidden');
        $(this).children().find('.icon_help').css('visibility', 'hidden');
        // $(this).children().find('.icon_config').css('visibility', 'visible');
    });

    $(".component-parking div").click(function(){
       $(".component-parking ul").slideToggle();
    });

    isExtendedCookie = poGetCookie('isExtendedCookie');
    if (isExtendedCookie == '') {
	    isExtendedCookie = 1;
    }
    if (isExtendedCookie == 0) {
        extendContract();
    } 

    if (isExtended == 1) {
	if (document.getElementById("slave_content") != null) {
	    document.getElementById('slave_content').style.visibility='visible';
	}

        $('#sideBarTabImage').hide();
        $('#sideBarTab').hide();
	$('#sidebar-close-button').fadeTo( "2000",0.5);
    }
    
    var input_list = document.getElementsByTagName("input");
    for (var i = 0; i < input_list.length; i++) {
        if (input_list[i].getAttribute('type') == 'submit') {
	    $(input_list[i]).addClass('form-button40');
 	};
    };
    
    $('#sideBarTab').click( function() { 
	extendContract(); 
	return false; 
    });

    $('#sidebar-close-button').click( function() {
        extendContract();
        return false;
    });

    setFooter();


});

function setFooter() {
    window.setTimeout(function () {
	if (document.getElementById("sidebar") != null) {
	    if (document.getElementById("footer") != null){
		var absolut_position_top_sidebar = $("#sidebar").height() + $("#sidebar").offset().top; 
		var absolut_position_top_footer = $("#footer").offset().top;
		if (absolut_position_top_sidebar > absolut_position_top_footer) {
		    var diff_footer_sidebar = absolut_position_top_sidebar - absolut_position_top_footer;
		    var current_top_margin = $("#footer").css("margin-top"); 
		    var new_margin_top = parseFloat(diff_footer_sidebar) + parseFloat(current_top_margin) + 20;
		    var new_margin_top_str = new_margin_top.toString() + 'px';
		    $("#footer").css('margin-top',new_margin_top_str);
		}; 
	    };
	};
    }, 500);
};

function poGetCookie(c_name) {
    if (document.cookie.length > 0 ) {
	c_start=document.cookie.indexOf(c_name + "=");
	if (c_start != -1) {
	    c_start=c_start + c_name.length + 1;
	    c_end=document.cookie.indexOf(";",c_start);
	    if (c_end==-1) c_end=document.cookie.length;
	    return unescape(document.cookie.substring(c_start,c_end));
	};
    };
    return "";
};

function poSetCookie(c_name,value,expiredays) {
    var exdate=new Date();
    exdate.setDate(exdate.getDate()+expiredays);
    document.cookie=c_name+ "=" +escape(value) + ((expiredays==null) ? "" : ";expires="+exdate.toGMTString());
};
