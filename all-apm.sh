#!/bin/csh
POVER="3.0.0.0.3"
export POVER

mkdir -p ${POVER}
/bin/tar czf ${POVER}/intranet-big-brother-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-big-brother
/bin/tar czf ${POVER}/intranet-core-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-core
/bin/tar czf ${POVER}/intranet-cost-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-cost
/bin/tar czf ${POVER}/intranet-crm-tracking-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-crm-tracking
# /bin/tar czf ${POVER}/intranet-dynvals-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-dynvals
/bin/tar czf ${POVER}/intranet-filestorage-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-filestorage
/bin/tar czf ${POVER}/intranet-forum-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-forum
# /bin/tar czf ${POVER}/intranet-freelance-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-freelance
# /bin/tar czf ${POVER}/intranet-freelance-invoices-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-freelance-invoices
# /bin/tar czf ${POVER}/intranet-freelance-recruiting-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-freelance-recruiting
/bin/tar czf ${POVER}/intranet-hr-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-hr
/bin/tar czf ${POVER}/intranet-invoices-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-invoices
/bin/tar czf ${POVER}/intranet-payments-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-payments
/bin/tar czf ${POVER}/intranet-riskmanagement-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-riskmanagement
/bin/tar czf ${POVER}/intranet-timesheet-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-timesheet
/bin/tar czf ${POVER}/intranet-spam-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-spam
/bin/tar czf ${POVER}/intranet-trans-invoices-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-trans-invoices
/bin/tar czf ${POVER}/intranet-translation-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-translation
# /bin/tar czf ${POVER}/intranet-trans-quality-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-trans-quality
# /bin/tar czf ${POVER}/intranet-travel-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-travel
/bin/tar czf ${POVER}/intranet-update-client-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-update-client
/bin/tar czf ${POVER}/intranet-update-server-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-update-server
/bin/tar czf ${POVER}/intranet-wiki-${POVER}.apm --exclude='*CVS*' --exclude='*~' intranet-wiki
/bin/tar czf ${POVER}/wiki-${POVER}.apm --exclude='*CVS*' --exclude='*~' wiki
