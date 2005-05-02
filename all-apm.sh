#!/bin/csh
POVER="3.0.0.2"
export POVER
rm -f *.apm
/bin/tar czf intranet-big-brother-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-big-brother
/bin/tar czf intranet-core-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-core
/bin/tar czf intranet-cost-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-cost
/bin/tar czf intranet-crm-tracking-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-crm-tracking
/bin/tar czf intranet-dynvals-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-dynvals
/bin/tar czf intranet-filestorage-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-filestorage
/bin/tar czf intranet-forum-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-forum
/bin/tar czf intranet-freelance-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-freelance
/bin/tar czf intranet-freelance-invoices-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-freelance-invoices
/bin/tar czf intranet-freelance-recruiting-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-freelance-recruiting
/bin/tar czf intranet-hr-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-hr
/bin/tar czf intranet-invoices-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-invoices
/bin/tar czf intranet-payments-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-payments
/bin/tar czf intranet-riskmanagement-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-riskmanagement
/bin/tar czf intranet-timesheet-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-timesheet
/bin/tar czf intranet-spam-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-spam
/bin/tar czf intranet-trans-invoices-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-trans-invoices
/bin/tar czf intranet-translation-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-translation
/bin/tar czf intranet-trans-quality-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-trans-quality
/bin/tar czf intranet-travel-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-travel
/bin/tar czf intranet-update-client-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-update-client
/bin/tar czf intranet-update-server-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-update-server
/bin/tar czf intranet-wiki-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-wiki
