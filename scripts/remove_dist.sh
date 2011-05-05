#!/bin/bash

DIST=$1
DISTDIR=$2

echo -e "suppression de la distribution $DIST installee dans ${DISTDIR} \n"
if [ -e "$DISTDIR" ]; then
rm -R "${DISTDIR}"
fi

echo -e "Suppression de $DIST... ok \n"
