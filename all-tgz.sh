#!/bin/bash

VER=3.0.alpha4a

rm -f *.tgz


cd /web; tar czf /tmp/pobase-$VER.tgz projop \
    --exclude '*CVS*' \
    --exclude '*~' \
    --exclude projop/packages/intranet-cost \
    --exclude projop/packages/intranet-crm-tracking \
    --exclude projop/packages/intranet-dynvals \
    --exclude projop/packages/intranet-filestorage \
    --exclude projop/packages/intranet-forum \
    --exclude projop/packages/intranet-freelance \
    --exclude projop/packages/intranet-invoices \
    --exclude projop/packages/intranet-trans-invoices \
    --exclude projop/packages/intranet-translation


cd /web; tar czf /tmp/popackages-$VER.tgz \
    --exclude '*CVS*' \
    --exclude '*~' \
    projop/packages/intranet-cost \
    projop/packages/intranet-crm-tracking \
    projop/packages/intranet-dynvals \
    projop/packages/intranet-filestorage \
    projop/packages/intranet-forum \
    projop/packages/intranet-freelance \
    projop/packages/intranet-invoices \
    projop/packages/intranet-trans-invoices \
    projop/packages/intranet-translation

