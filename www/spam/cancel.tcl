# /www/intranet/spam/cancel.tcl

ad_page_contract {
    Purpose: Cancels action to send spam

    @param return_url The url to go to.

    @author mbryzek@arsdigita.com
    @creation-date 3/15/2000

    @cvs-id cancel.tcl,v 1.3.6.4 2000/08/16 21:25:04 mbryzek Exp
} {
    {return_url [im_url_stub]}
    
}

ad_returnredirect $return_url
