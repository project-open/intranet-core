# /packages/intranet-core/www/master.tcl

if { ![info exists header_stuff] } {
    set header_stuff {}
}


append header_stuff "

<script type=\"text/javascript\">
      _editor_url = \"/resources/acs-templating/xinha-nightly/\";
      _editor_lang = \"en\";
</script>
<script type=\"text/javascript\" src=\"/resources/acs-templating/xinha-nightly/htmlarea.js\"></script>
"


