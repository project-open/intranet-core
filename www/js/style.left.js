// check this http://www.nabble.com/%22$(document).ready(function()-%7B%22-giving-error-%22$-is-not-a-function%22----what-am-I-doing-wrong--td17139297s27240.html
// jQuery.noConflict();


jQuery().ready(function(){


        var node_insert_after=document.getElementById("fullwidth-list");
        var node_to_move=document.getElementById("footer");
	var node_div_block=document.getElementById("filter-list");
        if (node_insert_after != null && node_to_move != null && node_div_block != null) {
           node_div_block.insertBefore(node_to_move, node_insert_after.nextSibling);
        }


    /* auto-change skin-select */ 	
    jQuery("#header_skin_select > form > select").change(function(){
       jQuery("#header_skin_select > form").submit();
    });

    /* sliding filters */
    jQuery(".filter > .filter-block:first").prepend('<div class="filter-button"></div>');

    if (poGetCookie("filterState")=="hidden") {
       jQuery(".filter").css("left","-240px");
       jQuery(".fullwidth-list").css("marginLeft","20px");
       jQuery(".filter-button").css(
          "background","url('/intranet/images/navbar_default/arrow_comp_right.png') no-repeat"
       );
    } else {
       jQuery(".filter-button").css(
          "background","url('/intranet/images/navbar_default/arrow_comp_left.png') no-repeat"
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
             "background","url('/intranet/images/navbar_default/arrow_comp_left.png') no-repeat"
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
             "background","url('/intranet/images/navbar_default/arrow_comp_right.png') no-repeat"
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

    /* rounded corners **********************************/

    settings = {
      tl: { radius: 10 },
      tr: { radius: 10 },
      bl: false,
      br: false,
      antiAlias: true,
      autoPad: true
    }

    var cornersObj = new curvyCorners(settings, 
       document.getElementById("header_class")
    );


    settings = {
      tl: { radius: 5 },
      tr: { radius: 5 },
      bl: false,
      br: false,
      antiAlias: true,
      autoPad: false
    }

    var cornersObj = new curvyCorners(settings, 
       "navbar_selected"
    );
    cornersObj.applyCornersToAll();

    if (document.getElementById("header_logout_tab")) {

    settings = {
      tl: false,
      tr: false,
      bl: { radius: 10 },
      br: { radius: 10 },  
      antiAlias: true,
      autoPad: false
    };

    var cornersObj = new curvyCorners(settings, 
       document.getElementById("header_logout_tab"),
       document.getElementById("header_settings_tab")
    );
    cornersObj.applyCornersToAll();
    }


  settings = {
      tl: { radius: 10 },
      tr: { radius: 10 }, 
      bl: { radius: 10 },
      br: { radius: 10 },
      antiAlias: true,
      autoPad: false
    };

    var cornersObj = new curvyCorners(settings, 
       "filter"
    );

	//  rounded corners script set width to 100%, let's roll that back:
	document.getElementById('header_settings_tab').style.width='auto';
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



