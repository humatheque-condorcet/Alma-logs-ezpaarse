#!/bin/bash

#=====================================
# send_log_extract_log_ezp.bash
# Description : envoi du log
# de l'extraction EZProxy
#=====================================

# Initialisation des variables
DESTINATAIRE="jerome.chiavassa-szenberg@campus-condorcet.fr"
LOGFILE="/home/admin/logs/log_extract_log_bash.`date +\%y\%m\%d`.log"
MESSAGE="Bonjour, veuillez trouver ci-joint le dernier résultat du traitement du log EZProxy :"
SUBJECT="Traitement mensuel du log EZProxy"

# Envoi du log
if test -f $LOGFILE
then
	# Le mail contient le message d'introduction, suivi du texte du log. Le fichier de log est aussi attaché au mail. 
  echo $MESSAGE | cat - $LOGFILE |  mutt -s "$SUBJECT" -a "$LOGFILE" -- $DESTINATAIRE
else
	echo "ERREUR : le mail avec $LOGFILE n'a pas pu être envoyé."
	exit 1
fi

exit 0
