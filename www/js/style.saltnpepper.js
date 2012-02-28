/*   START: NEW SIDEBAR */

var height = 600;
var width = 243;
var slideDuration = 1;
var opacityDuration = 1500;
var rv = 0;
isExtended = 1;

function extendContract(){
	if (document.getElementById("sideBarTab") != null) {
	        var node_to_move=document.getElementById("sidebar");
		if(isExtended == 0){
			if (document.getElementById('sidebar').getAttribute('savedHeight') != null) height = document.getElementById('sidebar').getAttribute('savedHeight') ;
			sideBarSlide(0, height, 0, width);
			sideBarOpacity(0, 1);
			isExtended = 1;
			// move main part
			jQuery(".fullwidth-list").animate({marginLeft: "288px"}, slideDuration );
			// make expand tab arrow image face left (inwards)
			$('#sideBarTab').children().get(0).src = $('#sideBarTab').children().get(0).src.replace(/(\.[^.]+)$/, '-active$1');
			document.getElementById('slave_content').style.visibility='visible';
			// [temp] set back to height=auto when animation is done, should be triggered based on event  
			var time_out=setTimeout("document.getElementById('sidebar').style.height='auto'",2500);
			poSetCookie('isExtendedCookie',1,90);
		}
		else {

			document.getElementById('sidebar').setAttribute('savedHeight',document.getElementById('sidebar').offsetHeight);
			sideBarSlide(height, 135, width, 0);
			sideBarOpacity(1, 0);
			isExtended = 0;
			jQuery(".fullwidth-list").animate({marginLeft: "30px"}, slideDuration );
			// make expand tab arrow image face right (outwards)
			$('#sideBarTab').children().get(0).src = $('#sideBarTab').children().get(0).src.replace(/-active(\.[^.]+)$/, '$1');
			// alert('hide');
			document.getElementById('slave_content').style.visibility='hidden';
			poSetCookie('isExtendedCookie',0,90);
		}
		// document.getElementById('fullwidth-list').style.visibility='visible';
	}
}

function sideBarSlide(fromHeight, toHeight, fromWidth, toWidth) {
	$("sidbar").css ({'height': fromHeight, 'width': fromWidth});
	$("#sidebar").animate( { 'height': toHeight, 'width': toWidth }, { 'queue': false, 'duration': slideDuration }, "linear" );

}

function sideBarOpacity(from, to){
	// $("#sideBarContents").animate( { 'opacity': to }, opacityDuration, "linear" );
	$("#filter").animate( { 'opacity': to }, opacityDuration, "linear" );
}

$(function(){
  	// Document is ready
	$('#sideBarTab').click( function() { 
		extendContract(); 
		return false; });
});

/*   END: NEW SIDEBAR */


/*  START: USER FEEDBACK BAR  */

function removeParameter(url, parameter)
{
  var urlparts= url.split('?');

  if (urlparts.length>=2)
  {
      var urlBase=urlparts.shift(); //get first part, and remove from array
      var queryString=urlparts.join("?"); //join it back up

      var prefix = encodeURIComponent(parameter)+'=';
      var pars = queryString.split(/[&;]/g);
      for (var i= pars.length; i-->0;)               //reverse iteration as may be destructive
          if (pars[i].lastIndexOf(prefix, 0)!==-1)   //idiom for string.startsWith
              pars.splice(i, 1);
      url = urlBase+'?'+pars.join('&');
  }
  return url;
}

/* END: START USER FEEDBACK BAR  */


// check this http://www.nabble.com/%22$(document).ready(function()-%7B%22-giving-error-%22$-is-not-a-function%22----what-am-I-doing-wrong--td17139297s27240.html
// jQuery.noConflict();

jQuery().ready(function(){
	
	jQuery("#header_skin_select > form > select").change(function(){
	jQuery("#header_skin_select > form").submit();
	});
	
	jQuery(".component-parking div").click(function(){	
	jQuery(".component-parking ul").slideToggle();
	});
	

	/* In order to make this skin work we need to re-order DIVs */
	var node_insert_after=document.getElementById("slave");
	var node_to_move=document.getElementById("fullwidth-list");
	if (node_insert_after != null && node_to_move != null) {
	   document.getElementById("monitor_frame").insertBefore(node_to_move, node_insert_after.nextSibling);
           document.getElementById('fullwidth-list').style.visibility='visible';
           document.getElementById('footer').style.visibility='visible';
	}
	
        node_insert_after=document.getElementById("main_header");
        node_to_move=document.getElementById("navbar_sub_wrapper");
	// alert (node_insert_after);
	// alert (node_to_move);
        if (node_insert_after != null && node_to_move != null) {
           // alert('inserting');
           document.getElementById("main").insertBefore(node_to_move, node_insert_after.nextSibling);
        }
	
	/* BUG TRACKER */
	var node_insert_after=document.getElementById("slave_content");
	var node_to_move=document.getElementById("bug-tracker-navbar");
	if (node_insert_after != null && node_to_move != null) {
	   document.getElementById("slave").insertBefore(node_to_move, node_insert_after.nextSibling);
	}

	if (document.getElementById("fullwidth-list") == null){
		if (document.getElementById("slave_content") != null) {
			document.getElementById('slave_content').style.position='relative';	
		}
	}

	// Avoid larger screens in IE 
	if (navigator.appName == 'Microsoft Internet Explorer') {
	    var ua = navigator.userAgent;
	    var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
	    if (re.exec(ua) != null)
	    rv = parseFloat( RegExp.$1 );
	}
	if ( rv!=0 && document.getElementById("fullwidth-list") != null ) {
		document.getElementById('fullwidth-list').style.width='100%';
	}

    jQuery(".component_icons").css("opacity","0.1");
    jQuery(".component_header").hover(function(){
       jQuery(".component_icons",this).stop().fadeTo("fast",1);
    },function(){
       jQuery(".component_icons",this).stop().fadeTo("normal",0.1);
    });

    jQuery(".component-parking div").click(function(){
       jQuery(".component-parking ul").slideToggle();
    });

	isExtendedCookie = poGetCookie('isExtendedCookie');
	if (isExtendedCookie == '') {
		isExtendedCookie = 1;
	}
        if  ( isExtendedCookie == 0 ) {
                extendContract();
        }
        if(isExtended == 1){
		if (document.getElementById("slave_content") != null) {
			document.getElementById('slave_content').style.visibility='visible';
		}
	}

	// clean return_url, remove attribute(s)! feedback_message_key
        try {
                var elements = document.getElementsByTagName('input');
                for (var i=0; i<elements.length; i++) {
                        if ( elements[i].attributes.getNamedItem("type") ) {
                            if ( elements[i].attributes.getNamedItem("type").value == 'hidden' ) {
                                if ( elements[i].attributes.getNamedItem("name").value == 'return_url' ) {
                                        // console.log(elements[i].attributes.getNamedItem("value").value);
                                        var decodedUri = decodeURIComponent(elements[i].attributes.getNamedItem("value").value);
                                        elements[i].value = removeParameter(decodedUri,'feedback_message_key');
                                        // console.log(elements[i].attributes.getNamedItem("value").value);
                                };
                            };
                        };
                };
        } catch (err) {
                // alert('error cleaning return_url:'+err)
        };

	var input_list = document.getElementsByTagName( "input" );
	for(var i = 0; i < input_list.length; i++) {
        	if (input_list[i].getAttribute('type') == 'submit') {
	        	jQuery(input_list[i]).addClass('form-button40');
 		};
	};
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



