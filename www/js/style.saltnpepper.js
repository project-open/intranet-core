/*   START: NEW SIDEBAR */

var isExtended = 1;
var height = 370;
var width = 200;
var slideDuration = 750;
var opacityDuration = 1500;

/* 

Structure in original: 

<div id="sideBar">
	<a href="#" id="sideBarTab"><img src="images/slide-button.gif" alt="sideBar" title="sideBar" /></a>
	<div id="sideBarContents" style="width:0px;">
		<div id="sideBarContentsInner">
			<h2>side<span>bar</span></h2> ... 
		
     sideBar = filter-list
  	 sideBarTab = a href -> button
  	 sideBarContents ->filter 
  	 sideBarContentsInner -> filter-block
*/

function extendContract(){
	if(isExtended == 0){
		sideBarSlide(0, height, 0, width);
		sideBarOpacity(0, 1);
		isExtended = 1;
		// move main part
		jQuery(".fullwidth-list").animate({marginLeft: "234px"}, slideDuration );
		// make expand tab arrow image face left (inwards)
		$('#sideBarTab').children().get(0).src = $('#sideBarTab').children().get(0).src.replace(/(\.[^.]+)$/, '-active$1');
	}
	else{
		sideBarSlide(height, 0, width, 0);
		sideBarOpacity(1, 0);
		isExtended = 0;
		jQuery(".fullwidth-list").animate({marginLeft: "24px"}, slideDuration );
		// make expand tab arrow image face right (outwards)
		$('#sideBarTab').children().get(0).src = $('#sideBarTab').children().get(0).src.replace(/-active(\.[^.]+)$/, '$1');
	}
}

function sideBarSlide(fromHeight, toHeight, fromWidth, toWidth) {
	 // alert('in: sideBarSlide');
	// $("sideBarContents").css ({'height': fromHeight, 'width': fromWidth});
	// $("#sideBarContents").animate( { 'height': toHeight, 'width': toWidth }, { 'queue': false, 'duration': slideDuration }, "linear" );
	$("sidbar").css ({'height': fromHeight, 'width': fromWidth});
	$("#sidebar").animate( { 'height': toHeight, 'width': toWidth }, { 'queue': false, 'duration': slideDuration }, "linear" );

}

function sideBarOpacity(from, to){
	// $("#sideBarContents").animate( { 'opacity': to }, opacityDuration, "linear" );
	$("#filter").animate( { 'opacity': to }, opacityDuration, "linear" );

}

$(function(){
  	// Document is ready
	/* $('#sideBarTab').click( function() { extendContract(); return false; }); */
	$('#sideBarTab').click( function() { extendContract(); return false; }); 
});




/*   END: NEW SIDEBAR */

/*

jQuery.noConflict();
jQuery().ready(function(){
    // sliding filters 

    jQuery(".filter > .filter-block:first").prepend('<div class="filter-button"></div>');

    if (poGetCookie("filterState")=="hidden") {
       jQuery(".filter").css("left","-240px");
       jQuery(".fullwidth-list").css("marginLeft","20px");
       jQuery(".filter-button").css(
          "background","url('arrow_comp_right.png') no-repeat"
       );
    } else {
       jQuery(".filter-button").css(
          "background","url('arrow_comp_left.png') no-repeat"
       );
    }
	
  
    jQuery(".filter-button").click(function(){
        if (jQuery(".filter").css("left")!="0px") {
           jQuery(".fullwidth-list").animate({
              marginLeft: "260px"
              }, 1000 );
           jQuery(".filter").animate({
              left: "0px"
              }, 1000 );

           jQuery(".filter-button").css(
             "background","url('arrow_comp_left.png') no-repeat"
           );

           poSetCookie("filterState","",0);
        } else {

           jQuery(".filter").animate({
              left: "-240px"
           }, 1000 );
           jQuery(".fullwidth-list").animate({
              marginLeft: "20px"
           }, 1000 );

           jQuery(".filter-button").css(
             "background","url('arrow_comp_right.png') no-repeat"
           );

           poSetCookie("filterState","hidden",20);
        }
    });


    jQuery("#header_skin_select > form > select").change(function(){
       jQuery("#header_skin_select > form").submit();
    });

    jQuery(".component_icons").css("opacity","0.1");

    jQuery(".component_header").hover(function(){
       jQuery(".component_icons",this).stop().fadeTo("fast",1);
    },function(){
       jQuery(".component_icons",this).stop().fadeTo("normal",0.1);
    });

    jQuery(".component-parking div").click(function(){
       jQuery(".component-parking ul").slideToggle();
    });

*/

jQuery.noConflict();
jQuery().ready(function(){
	
	jQuery("#header_skin_select > form > select").change(function(){
	jQuery("#header_skin_select > form").submit();
	});
	
	jQuery(".component-parking div").click(function(){	
	jQuery(".component-parking ul").slideToggle();
	});
	
	/*In order to make this work we need to re-order DIVs*/
	var node_insert_after=document.getElementById("slave");
	var node_to_move=document.getElementById("fullwidth-list");
	document.getElementById("monitor_frame").insertBefore(node_to_move, node_insert_after.nextSibling);

});



function poGetCookie(c_name)
{
if (document.cookie.length>0)
  {
  c_start=document.cookie.indexOf(c_name + "=")
  if (c_start!=-1)
    {
    c_start=c_start + c_name.length+1
    c_end=document.cookie.indexOf(";",c_start)
    if (c_end==-1) c_end=document.cookie.length
    return unescape(document.cookie.substring(c_start,c_end))
    }
  }
return ""
}

function poSetCookie(c_name,value,expiredays)
{
var exdate=new Date()
exdate.setDate(exdate.getDate()+expiredays)
document.cookie=c_name+ "=" +escape(value)+
((expiredays==null) ? "" : ";expires="+exdate.toGMTString())
}




 


