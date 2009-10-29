# /packages/intranet-core/tcl/intranet-transform-procs.tcl
#
# Copyright (c) 2007 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_library {
    Procedures for automatic import of CSV data into ]po[.
    Allow several types of transformations.

    @author frank.bergmann@project-open.com
}

ad_proc -public im_transform_trim { string } {
    "Trim" transformation function - returns the same argument as imput
    just with spaces at the beginning and end cut off.
    Returns a {result_list error_list} structure where:
        result_list     contains just the input string and
        error_list      is an empty list
} {
    return [list [string trim $string] {}]
}


ad_proc -public im_transform_komma2dot { string } {
    Converts "," into ".". This is useful when transforming values from
    a European Excel spreadsheet (123,456) into po with American format
    (123.456).
} {
    set string [string map -nocase {"," "."} $string]
    return [list [string trim $string] {}]
}


ad_proc -public im_transform_email2user_id { email } {
    Email -> User_id transformation function -
    Attempts to identify the right user_id for the given string.
    Performs some guesswork to deal with common issues...
    Returns a user_id_list, error_msg structure where:
        user_id_list is empty if no email found
        user_id_list contains exactly one entry if the entry was found
        user_id_list may contain multiple entries in case of error/multiple entries
    error_msg is a list of error messages
} {
    # Remove trailing and preceeding spaces
    set email [string trim $email]
    if {"" == $email} { return [list [list] [list "Empty email"]] }

    # Try with exact email matching
    set user_id [db_string uid "select party_id from parties where email = :email" -default 0]
    if {0 != $user_id} { return [list [list $user_id] [list]] }

    # Convert to lower case
    set email [string tolower $email]

    # Try case insensitive email matching
    set user_id [db_string uid "select party_id from parties where lower(email) = :email" -default 0]
    if {0 != $user_id} { return [list [list $user_id] [list]] }

    return [list [list] [list "Didn't find email"]]
}

ad_proc im_transform_language2iso639 { str } {
    Transforms a Spanisch language specs into PO standard language code
} {
    set str [string map -nocase {"." ""} $str]
    set str [im_mangle_unicode_accents [string tolower $str]]

    switch $str {
        aleman                  { return "de" }
        albano                  { return "sr" }
        afrikaans               { return "af" }
        arabe                   { return "ar" }
        armenio                 { return "hy" }
        bielorruso              { return "be" }
        bosnio                  { return "bs" }
        bulgaro                 { return "bg" }
        "bulgaro/ruso"          { return "ru_BG" }
        castellano              { return "es" }
        "castellano (mx)"       { return "es_MX" }
        "castellano (latinoamericano)"  { return "es_LA" }
        catalan                 { return "ca_ES" }
        checo                   { return "cs" }
        chino                   { return "cn_CN" }
        "chino simplificado"    { return "cn_CN" }
        "chino tradicional"     { return "tw_TW" }
        coreano                 { return "ko" }
        croata                  { return "hr" }
        danes                   { return "da" }
        eslovaco                { return "sk" }
        esloveno                { return "sl" }
        estonio                 { return "et" }
        euskera                 { return "eu" }
        farsi                   { return "fa" }
        finish                  { return "fi" }
        finnish                 { return "fi" }
        fines                   { return "fi" }
        flamenco                { return "nl_BE" }
        frances                 { return "fr" }
        "frances canada"        { return "fr_CA" }
        "frances canadiense"    { return "fr_CA" }
        "frances suizo"         { return "fr_CH" }
        "frances (dominique)"   { return "fr" }
        "frances solo juridica" { return "fr" }
        gallego                 { return "gl" }
        griego                  { return "el" }
        hebreo                  { return "he" }
        hindi                   { return "hi" }
        holandes                { return "nl" }
        hungaro                 { return "hu" }
        ingles                  { return "en" }
        "ingles simplificado"   { return "en" }
        "ingles uk"             { return "en_UK" }
        "ingles (*)"            { return "en" }
        "ingles us"             { return "en_US" }
        "ingles (us)"           { return "en_US" }
        "islandes"              { return "is" }
        italiano                { return "it" }
        italaliano              { return "it" }
        japones                 { return "ja" }
        kurdo                   { return "ku" }
        lituano                 { return "lt" }
        leton                   { return "lv" }
        moldavo                 { return "mo" }
        neerlandes              { return "nl" }
        noruego                 { return "no" }
        polaco                  { return "pl" }
        portugues               { return "pt" }
        "portugues eu"          { return "pt" }
        "portugues br"          { return "pt_BR" }
        "portugues (br)"        { return "pt_BR" }
        "portugues brasil"      { return "pt_BR" }
        "portugues (brasileiro)" { return "pt_BR" }
        "portugues (brasileno)" { return "pt_BR" }
        "potugues br"           { return "pt_BR" }
        rumano                  { return "ro" }
        ruso                    { return "ru" }
        serbio                  { return "sr" }
        serbio-croata           { return "sh" }
        sueco                   { return "sv" }
        urdu                    { return "ur" }
        tedesco                 { return "de" }
        thai                    { return "th" }
        turco                   { return "tr" }
        turkmeno                { return "tk" }
        ucraniano               { return "uk" }
        valenciano              { return "ca" }
    }
    return $str
}


