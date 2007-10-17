jQuery.noConflict();
jQuery().ready(function(){

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
    cornersObj.applyCornersToAll();

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

    settings = {
      tl: false,
      tr: false,
      bl: { radius: 10 },
      br: { radius: 10 },  
      antiAlias: true,
      autoPad: false
    }

    var cornersObj = new curvyCorners(settings, 
       document.getElementById("slave")
    );
    cornersObj.applyCornersToAll();

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

   settings = {
      tl: { radius: 10 },
      tr: { radius: 10 },
      bl: false,
      br: false,
      antiAlias: true,
      autoPad: false
    };

    var cornersObj = new curvyCorners(settings, 
       "component_header_rounded"
    );
    cornersObj.applyCornersToAll();

   settings = {
      tl: false,
      tr: false, 
      bl: { radius: 10 },
      br: { radius: 10 },
      antiAlias: true,
      autoPad: false
    };

    var cornersObj = new curvyCorners(settings, 
       "component_footer"
    );
    cornersObj.applyCornersToAll();

    roundFilter();
 
    // -------------------------------------------------------

    /* sliding filters are disabled 

    jQuery(".filter-block").toggle(function(){
	jQuery(".filter").css("overflow","hidden");

        jQuery(".filter").animate({ 
	   width: "10px"
	}, 2000 );
        jQuery(".fullwidth-list").animate({ 
	   marginRight: "20px"
	}, 2000 );
    },function(){
	jQuery(".filter").css("overflow","none");

        jQuery(".fullwidth-list").animate({ 
	   marginRight: "260px"
	}, 2000 );
        jQuery(".filter").animate({ 
	   width: "250px"
	}, 2000 );
	roundFilter();
    });

    */


});

function roundFilter(){
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
    cornersObj.applyCornersToAll();


};





