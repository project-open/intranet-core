#!/bin/bash

cvs checkout -r b3-5-0-patches acs-admin
cvs checkout -r b3-5-0-patches acs-api-browser
cvs checkout -r b3-5-0-patches acs-authentication
cvs checkout -r b3-5-0-patches acs-automated-testing
cvs checkout -r b3-5-0-patches acs-bootstrap-installer
cvs checkout -r b3-5-0-patches acs-content-repository
cvs checkout -r b3-5-0-patches acs-core-docs
cvs checkout -r b3-5-0-patches acs-datetime
cvs checkout -r b3-5-0-patches acs-developer-support
cvs checkout -r b3-5-0-patches acs-events
cvs checkout -r b3-5-0-patches acs-kernel
cvs checkout -r b3-5-0-patches acs-lang
cvs checkout -r b3-5-0-patches acs-mail
cvs checkout -r b3-5-0-patches acs-mail-lite
cvs checkout -r b3-5-0-patches acs-messaging
cvs checkout -r b3-5-0-patches acs-reference
cvs checkout -r b3-5-0-patches acs-service-contract
cvs checkout -r b3-5-0-patches acs-subsite
cvs checkout -r b3-5-0-patches acs-tcl
cvs checkout -r b3-5-0-patches acs-templating
cvs checkout -r b3-5-0-patches acs-translations
cvs checkout -r b3-5-0-patches acs-workflow

cvs checkout -r b3-5-0-patches auth-ldap
cvs checkout -r b3-5-0-patches auth-ldap-adldapsearch

cvs checkout -r b3-5-0-patches ajaxhelper
cvs checkout -r b3-5-0-patches ams
cvs checkout -r b3-5-0-patches batch-importer
cvs checkout -r b3-5-0-patches bug-tracker
cvs checkout -r b3-5-0-patches bulk-mail
cvs checkout -r b3-5-0-patches calendar
cvs checkout -r b3-5-0-patches categories
cvs checkout -r b3-5-0-patches contacts
cvs checkout -r b3-5-0-patches chat
cvs checkout -r b3-5-0-patches cms
cvs checkout -r b3-5-0-patches diagram
cvs checkout -r b3-5-0-patches ecommerce
cvs checkout -r b3-5-0-patches events
cvs checkout -r b3-5-0-patches faq
cvs checkout -r b3-5-0-patches general-comments

cvs checkout -r b3-5-0-patches intranet-amberjack
cvs checkout -r b3-5-0-patches intranet-audit
cvs checkout -r b3-5-0-patches intranet-baseline
cvs checkout -r b3-5-0-patches intranet-big-brother
cvs checkout -r b3-5-0-patches intranet-bug-tracker
cvs checkout -r b3-5-0-patches intranet-calendar
# Obsolete!
# cvs checkout -r b3-5-0-patches intranet-calendar-holidays
cvs checkout -r b3-5-0-patches intranet-confdb
cvs checkout -r b3-5-0-patches intranet-core
cvs checkout -r b3-5-0-patches intranet-cost
cvs checkout -r b3-5-0-patches intranet-cost-center
cvs checkout -r b3-5-0-patches intranet-crm-tracking

# cvs checkout -r b3-5-0-patches intranet-cust-baselkb
# cvs checkout -r b3-5-0-patches intranet-cust-cambridge
# cvs checkout -r b3-5-0-patches intranet-cust-issa
# cvs checkout -r b3-5-0-patches intranet-cust-lexcelera
# cvs checkout -r b3-5-0-patches intranet-cust-projop
# cvs checkout -r b3-5-0-patches intranet-cust-reinisch

cvs checkout -r b3-5-0-patches intranet-cvs-integration
cvs checkout -r b3-5-0-patches intranet-dw-light
cvs checkout -r b3-5-0-patches intranet-dynfield
cvs checkout -r b3-5-0-patches intranet-exchange-rate
cvs checkout -r b3-5-0-patches intranet-expenses
cvs checkout -r b3-5-0-patches intranet-expenses-workflow
cvs checkout -r b3-5-0-patches intranet-filestorage
cvs checkout -r b3-5-0-patches intranet-filestorage-openacs
cvs checkout -r b3-5-0-patches intranet-forum
cvs checkout -r b3-5-0-patches intranet-freelance
cvs checkout -r b3-5-0-patches intranet-freelance-invoices
cvs checkout -r b3-5-0-patches intranet-freelance-rfqs
cvs checkout -r b3-5-0-patches intranet-freelance-translation
cvs checkout -r b3-5-0-patches intranet-funambol
cvs checkout -r b3-5-0-patches intranet-ganttproject
cvs checkout -r b3-5-0-patches intranet-helpdesk
cvs checkout -r b3-5-0-patches intranet-hr
cvs checkout -r b3-5-0-patches intranet-pdf-htmldoc
cvs checkout -r b3-5-0-patches intranet-invoices
cvs checkout -r b3-5-0-patches intranet-invoices-templates
cvs checkout -r b3-5-0-patches intranet-mail-import
cvs checkout -r b3-5-0-patches intranet-material
cvs checkout -r b3-5-0-patches intranet-milestone
cvs checkout -r b3-5-0-patches intranet-nagios
cvs checkout -r b3-5-0-patches intranet-notes
cvs checkout -r b3-5-0-patches intranet-notes-tutorial
cvs checkout -r b3-5-0-patches intranet-ophelia
cvs checkout -r b3-5-0-patches intranet-otp
cvs checkout -r b3-5-0-patches intranet-payments
cvs checkout -r b3-5-0-patches intranet-portfolio-management
cvs checkout -r b3-5-0-patches intranet-release-mgmt
cvs checkout -r b3-5-0-patches intranet-reporting
cvs checkout -r b3-5-0-patches intranet-reporting-cubes
cvs checkout -r b3-5-0-patches intranet-reporting-dashboard
cvs checkout -r b3-5-0-patches intranet-reporting-finance
cvs checkout -r b3-5-0-patches intranet-reporting-indicators
cvs checkout -r b3-5-0-patches intranet-reporting-translation
cvs checkout -r b3-5-0-patches intranet-reporting-tutorial
cvs checkout -r b3-5-0-patches intranet-resource-management
cvs checkout -r b3-5-0-patches intranet-riskmanagement
cvs checkout -r b3-5-0-patches intranet-scrum
cvs checkout -r b3-5-0-patches intranet-search-pg
cvs checkout -r b3-5-0-patches intranet-search-pg-files
cvs checkout -r b3-5-0-patches intranet-security-update-client
cvs checkout -r b3-5-0-patches intranet-security-update-server
cvs checkout -r b3-5-0-patches intranet-simple-survey
cvs checkout -r b3-5-0-patches intranet-sharepoint
cvs checkout -r b3-5-0-patches intranet-spam
cvs checkout -r b3-5-0-patches intranet-sql-selectors
cvs checkout -r b3-5-0-patches intranet-sysconfig
cvs checkout -r b3-5-0-patches intranet-timesheet2
cvs checkout -r b3-5-0-patches intranet-timesheet2-invoices
cvs checkout -r b3-5-0-patches intranet-timesheet2-task-popup
cvs checkout -r b3-5-0-patches intranet-timesheet2-tasks
cvs checkout -r b3-5-0-patches intranet-timesheet2-workflow
cvs checkout -r b3-5-0-patches intranet-tinytm
cvs checkout -r b3-5-0-patches intranet-trans-invoices
cvs checkout -r b3-5-0-patches intranet-trans-project-wizard
# cvs checkout -r b3-5-0-patches intranet-trans-invoices-vaw
cvs checkout -r b3-5-0-patches intranet-translation
cvs checkout -r b3-5-0-patches intranet-trans-quality
cvs checkout -r b3-5-0-patches intranet-ubl
cvs checkout -r b3-5-0-patches intranet-update-client
cvs checkout -r b3-5-0-patches intranet-update-server
cvs checkout -r b3-5-0-patches intranet-wiki
cvs checkout -r b3-5-0-patches intranet-workflow
cvs checkout -r b3-5-0-patches intranet-xmlrpc

cvs checkout -r b3-5-0-patches lars-blogger
cvs checkout -r b3-5-0-patches mail-tracking
cvs checkout -r b3-5-0-patches notifications
cvs checkout -r b3-5-0-patches organizations
cvs checkout -r b3-5-0-patches oryx-ts-extensions
cvs checkout -r b3-5-0-patches postal-address

cvs checkout -r b3-5-0-patches ref-countries
cvs checkout -r b3-5-0-patches ref-language
cvs checkout -r b3-5-0-patches ref-timezones
cvs checkout -r b3-5-0-patches ref-us-counties
cvs checkout -r b3-5-0-patches ref-us-states
cvs checkout -r b3-5-0-patches ref-us-zipcodes

cvs checkout -r b3-5-0-patches rss-support
cvs checkout -r b3-5-0-patches search
cvs checkout -r b3-5-0-patches simple-survey
cvs checkout -r b3-5-0-patches telecom-number
cvs checkout -r b3-5-0-patches trackback
cvs checkout -r b3-5-0-patches wiki
cvs checkout -r b3-5-0-patches workflow
cvs checkout -r b3-5-0-patches xml-rpc

