#!/bin/bash

DIST=$1
DISTDIR=$2

echo -e "suppression de la distribution $DIST installee dans ${DISTDIR} \n"
rm -R "${DISTDIR}"

echo -e "Suppression de $DIST... ok \n"