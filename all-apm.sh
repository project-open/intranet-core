#!/bin/bash

VER=3.0.alpha4

rm -f *.apm


tar czf intranet-big-brother-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-big-brother
tar czf intranet-core-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-core
tar czf intranet-cost-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-cost
tar czf intranet-crm-tracking-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-crm-tracking
tar czf intranet-dynvals-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-dynvals
tar czf intranet-filestorage-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-filestorage
tar czf intranet-forum-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-forum
tar czf intranet-freelance-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-freelance
tar czf intranet-hr-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-hr
tar czf intranet-invoices-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-invoices
tar czf intranet-payments-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-payments
tar czf intranet-riskmanagement-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-riskmanagement
tar czf intranet-timesheet-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-timesheet
tar czf intranet-trans-invoices-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-trans-invoices
tar czf intranet-translation-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-translation
tar czf intranet-trans-quality-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-trans-quality
tar czf intranet-travel-$VER.apm --exclude='*CVS*' --exclude='*~' intranet-travel

