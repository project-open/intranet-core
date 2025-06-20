#!/bin/sh

# This script expects the html files to be synced to www.project-open.com  
# in folder /web/ponet/www-httrack/www.project-open.net/en

# ---------------------
# Defaults
# ---------------------

curdir='/web/ponet/www-httrack/www.project-open.net/en'

# ---------------------
# Export
# ---------------------
echo "\n\n\n"
echo "-----------------------------------------------------------------------------------------------------------------"
echo "Start httrack ..."

# Only /en [DEFAULT]
/usr/bin/httrack "http://www.project-open.net/" -v -i -c8 -r5 -K --disable-security-limits -F "ponet-httrack" -O "/web/ponet/www-httrack" "-*.project-open.net/*" "+*.project-open.net/en/*"

# Single Page 
# /usr/bin/httrack "http://www.project-open.net/" -v -i -c50 -r5 -K --disable-security-limits -F "ponet-httrack" -O "/web/ponet/www-httrack" "-*.project-open.net/*" "+*.project-open.net/en/page-intranet-cost-center-index"

# Entire Site  
# /usr/bin/httrack "http://www.project-open.net" -v -i -c50 -r5 -K --disable-security-limits -F "ponet-httrack" -O "/web/ponet/www-httrack" "+*.project-open.net/*" 

echo "Finished httrack"

# ---------------------
# Cleaning up 
# ---------------------

echo "Start dos2unix ..."
find ${curdir} -type f -name '*.html' -exec dos2unix {} \;
echo "Finished dos2unix"


# remove special chars
echo "Start removing special chars ..."
find ${curdir} -name '*.html' -exec sed -i 's/\xc2//g' {} \;
# This one is currently causing problems: /en/partner-cognovis
find ${curdir} -name '*.html' -exec sed -i 's/\xad//g' {} \;
echo "Finished removing special chars."


# Remove the ALL domain URLS 
echo "Start removing domain URLS ..."
find ${curdir} -name '*.html' -exec sed -i 's/href="http:\/\/www.project-open.net/href="/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href='\''http:\/\/www.project-open.net/href='\''/g' {} \;
echo "Finishing removing domain URLS"

# Change URLs on sitemap.xml files
find ${curdir} -name 'site*.xml' -exec sed -i 's/www.project-open.net/www.project-open.com/g' {} \;


# Re-establish URL's that need to point to www.project-open.net 
echo "Start re-establishing .net Domains ..."
find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/register/href='\''http:\/\/www.project-open.net\/register/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/register/href="http:\/\/www.project-open.net\/register/g' {} \;

find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/api-doc/href='\''http:\/\/www.project-open.net\/api-doc/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/api-doc/href="http:\/\/www.project-open.net\/api-doc/g' {} \;

find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/intranet-forum/href='\''http:\/\/www.project-open.net\/intranet-forum/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/intranet-forum/href="http:\/\/www.project-open.net\/intranet-forum/g' {} \;

find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/documentation/href='\''http:\/\/www.project-open.net\/documentation/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/documentation/href="http:\/\/www.project-open.net\/documentation/g' {} \;

find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/intranet-idea-management/href='\''http:\/\/www.project-open.net\/intranet-idea-management/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/intranet-idea-management/href="http:\/\/www.project-open.net\/intranet-idea-management/g' {} \;

find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/register/href='\''http:\/\/www.project-open.net\/register/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/register/href="http:\/\/www.project-open.net\/register/g' {} \;

find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/intranet-helpdesk/href='\''http:\/\/www.project-open.net\/intranet-helpdesk/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/intranet-helpdesk/href="http:\/\/www.project-open.net\/intranet-helpdesk/g' {} \;

# Spacer 
find ${curdir} -name '*.html' -exec sed -i 's/\/intranet-crm-tracking\/download\/spacer.gif/http:\/\/www.project-open.net\/intranet-crm-tracking\/download\/spacer.gif/g' {} \;

# Get files stored in DB from .net (AACHEN)
find ${curdir} -name '*.html' -exec sed -i 's/href='\''\/en\/download\/file/href='\''http:\/\/www.project-open.net\/en\/download\/file/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/href="\/en\/download\/file/href="http:\/\/www.project-open.net\/en\/download\/file/g' {} \;

echo "Finishing saving .net Domains ..."

# Clean links (&amp; -> &)
# find ${curdir} -name '*.html' -exec sed -i '/www.project-open.net\/api-doc\/proc-view/s/\&amp;/\&/g' {} \;

# Get JS includes also from .com
find ${curdir} -name '*.html' -exec sed -i 's/src="http:\/\/www.project-open.net/src="/g' {} \;
find ${curdir} -name '*.html' -exec sed -i 's/src='\''http:\/\/www.project-open.net\/js/src='\''/g' {} \;

# Adjust Folder 
# ~find ${curdir} -name '*.html' -exec sed -i 's/en-edit/en/g' {} \;

# Whatever httrack does or users create in XOWIKI:
# Never, ever overwrite pages on .com that are NOT managed by XOWIKI

echo "Start removing pages that are maintained outside XOWIKI"
# rm ${curdir}/company/index.html
rm -rf ${curdir}/company/legal.html
rm -rf ${curdir}/company/project-open-contact-thank.html
rm -rf ${curdir}/company/project-open-contact.html
rm -rf ${curdir}/customers/index.html
rm -rf ${curdir}/customers/success-story-comsys.html
rm -rf ${curdir}/customers/success-story-leinhaeuser.html
rm -rf ${curdir}/customers/success-story-milengo.html
rm -rf ${curdir}/customers/success-story-qabiria.html
rm -rf ${curdir}/misc/project-open-privacy.html
rm -rf ${curdir}/misc/project-open-register-tour.html
rm -rf ${curdir}/misc/samples.html
rm -rf ${curdir}/modules/index.html
rm -rf ${curdir}/products/editions.html
rm -rf ${curdir}/services/index.html
rm -rf ${curdir}/services/project-open-consulting.html
rm -rf ${curdir}/services/project-open-hosting-saas.html
rm -rf ${curdir}/services/project-open-support.html
rm -rf ${curdir}/solutions/enterprise-project-management/index.html
rm -rf ${curdir}/solutions/index.html
rm -rf ${curdir}/solutions/itsm/index.html
rm -rf ${curdir}/solutions/professional-service-automation/index.html
rm -rf ${curdir}/solutions/project-management-office/index.html
# Avoid worst case: Overwriting /index.html
rm -rf /web/ponet/www-httrack/www.project-open.net/index.html


# Graphics etc. shouldn't be stored in XOWIKI file manager anymore
# Some files cause a 404 and create a HTML file 
# ToDo: move them to ~/img and change links in cr_revisions 
rm -rf ${curdir}/download/file/*.* 

echo "Finished removing pages that are maintained outside XOWIKI"

echo "Start removing pages w/o suffix ..."
# remove files without suffix. They are created due to malformed links and cause problems 
# when there are two files with the same file nam 
find /web/ponet/www-httrack/www.project-open.net/en -type f ! -name "*.*" -exec rm -f {} \;
echo "Finished removing pages w/o suffix"

# ---------------------
# Sync
# ---------------------

echo "Start syncing (lftp) ..."
lftp -c "open -u p7828024,secret sftp://home29702754.1and1-data.host; mirror -c -R -L -v /web/ponet/www-httrack/www.project-open.net/en/ /www.project-open.com/en/"
echo "Done syncing (lftp)"


# ----------------------------------------
# Finishing up
# ----------------------------------------

echo "Now removing www-httrack"
rm -rf /web/ponet/www-httrack/*
echo "Removed www-httrack"

# ----------------------------------------
# End 
# ----------------------------------------

echo "**** Script finished *** "

# ----------------------------------------
# TO-DO: Sync Images
# ----------------------------------------

# Clarify: Causes issues with directory permissions 
# lftp -c "open -u p7828024,secret sftp://project-open.com; mirror -c -R -L -v /web/ponet/www/images/ /www.project-open.com/images/" &
# lftp -c "open -u p7828024,secret sftp://project-open.com; mirror -c -R -L -v /web/ponet/www/img/ /www.project-open.com/img/" &

# Sync download folder 
# lftp -c "open -u p7828024,secret sftp://project-open.com; mirror -c -R -L -v /web/ponet/www-httrack/www.project-open.net/download/ /www.project-open.com/download/" & 

# ---------------------
# G A R B A G E
# ---------------------

# Adjust DIR strcuture to fit .com 
# rm -rf /web/ponet/www-httrack/www.project-open.net/en/*
# Just in case no /en was found recreate it 
# mkdir /web/ponet/www-httrack/www.project-open.net/en/
# cp -r /web/ponet/www-httrack/www.project-open.net/en-edit/* /web/ponet/www-httrack/www.project-open.net/en/  

