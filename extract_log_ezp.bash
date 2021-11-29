#!/bin/bash

#=====================================
# traite_log_ezp_mensuel.bash
# Description : traitement du log 
# EZProxy du mois par EZpaarse et
# EZmesure
#=====================================

# Chargement de l'environnement EZPaarse/EZMesure
source /home/admin/ezpaarse/bin/env

# Initialisation des variables

# Répertoire des logs en général
LOGPATH="/home/admin/logs"

# Répertoire temporaire de travail
WORKPATH="$LOGPATH/tmp"

# Répertoire où l'on trouve le log détaré et dézippé
SOURCEPATH="$WORKPATH/usr/local/ezproxy/logs"

# Répertoire destination où la commande ezpaarse pourra trouver le fichier
EZPAARSELOGPATH="$LOGPATH/log_src_4_ezpaarse"

# Répertoire de stockage des analyses ezpaarse
EZPAARSEANALYSEPATH="/home/admin/analyse-ezp"

# Récupération du numéro du mois précédent et de l'année
read YYYY MM <<<$(date --date='-1 month' +'%Y %m')

LOG_MOIS_TARGZ="ezp$YYYY$MM.tar.gz"
LOG_MOIS_LOG="ezp$YYYY$MM.log"
LOG_MOIS_LOG_ANONYMISE_RENOMME="ezp$YYYY$MM-cc-ged.log"


echo "========================================="
echo "TRAITEMENT TRAITE_LOG_EZP_MENSUEL : DÉBUT"
echo "Date : " $(date)
echo
echo "=== VARIABLES ==="
echo "LOGPATH:$LOGPATH"
echo "WORKPATH:$WORKPATH"
echo "SOURCEPATH:$SOURCEPATH"
echo "Année traitée : $YYYY"
echo "Mois traité : $MM"
echo "LOG_MOIS_TARGZ : $LOG_MOIS_TARGZ"
echo "LOG_MOIS_LOG : $LOG_MOIS_LOG"
echo "LOG_MOIS_LOG_ANONYMISE_RENOMME : $LOG_MOIS_LOG_ANONYMISE_RENOMME"
echo

echo "=== TRAITEMENT ==="
# Recopie du log du mois à traiter : on le place dans WORKPATH
if test -f $LOGPATH/ezproxy/$LOG_MOIS_TARGZ
then
  cp $LOGPATH/ezproxy/$LOG_MOIS_TARGZ $WORKPATH
else
	echo "ERREUR : le fichier $LOG_MOIS_TARGZ n'existe pas"
	exit 1
fi

if [[ $? != 0 ]];
then
	echo "ERREUR : problème lors de la recopie de $LOGPATH/ezproxy/$LOG_MOIS_TARGZ vers $WORKPATH"
	exit 1
else
	echo "SUCCES : recopie de $LOGPATH/ezproxy/$LOG_MOIS_TARGZ vers $WORKPATH"
fi


# On détare/dézippe le log dans WORKPATH
tar -zxvf $WORKPATH/$LOG_MOIS_TARGZ -C $WORKPATH

if [[ $? != 0 ]];
then
	echo "ERREUR : probleme lors de l'extraction du fichier $WORKPATH/$LOG_MOIS_TARGZ"
	exit 1
else
	echo "SUCCES : extraction de $WORKPATH/$LOG_MOIS_TARGZ"
fi

# Si le fichier de log a bien été détaré et dézippé, on le traite pour retirer les adresses email
if test -f $SOURCEPATH/$LOG_MOIS_LOG
then
  sed -f $LOGPATH/anonymail.sed  $SOURCEPATH/$LOG_MOIS_LOG > $SOURCEPATH/$LOG_MOIS_LOG_ANONYMISE_RENOMME
  if [[ $? != 0 ]];
	then
		 echo "ERREUR : probleme lors de l'anonymisation et renommage du log par la commande sed"
		 exit 1
	else
		 echo "SUCCES : $SOURCEPATH/$LOG_MOIS_LOG anonymisé et renommé en $SOURCEPATH/$LOG_MOIS_LOG_ANONYMISE_RENOMME"
	fi
fi

# On met à disposition le fichier pour la commande ezpaarse
if test -f  $SOURCEPATH/$LOG_MOIS_LOG_ANONYMISE_RENOMME 
then
	cp  $SOURCEPATH/$LOG_MOIS_LOG_ANONYMISE_RENOMME $EZPAARSELOGPATH
	if [[ $? != 0 ]];
	then 
		echo "ERREUR : problème lors de la copie de $SOURCEPATH/$LOG_MOIS_LOG_ANONYMISE_RENOMME vers  $EZPAARSELOGPATH"
		exit 1
	else
		echo "SUCCES : fichier $EZPAARSELOGPATH/$LOG_MOIS_LOG_ANONYMISE_RENOMME disponible pour EZPaarse."
	fi
fi

# Avant de traiter le log par Ezpaarse, il faut nettoyer les répertoires
rm -f $WORKPATH/$LOG_MOIS_TARGZ
if [[ $? != 0 ]];
then
	echo "ERREUR NON BLOQUANTE : impossible de supprimer  $WORKPATH/$LOG_MOIS_TARGZ"
fi

rm -rf $SOURCEPATH
if [[ $? != 0 ]];
then
	echo "ERREUR NON BLOQUANTE : impossible de supprimer $SOURCEPATH"
fi


# Le log est maintenant traité par ezpaarse
export http_proxy='';
echo "INFORMATION : lancement de ezp bulk"
ezp bulk -v $EZPAARSELOGPATH $EZPAARSEANALYSEPATH
if [[ $? != 0 ]];
then
	echo "ERREUR : la commande ezp bulk a échoué, veuillez regarder les traces."
	exit 1
fi
echo "SUCCES : ezpaarse a bien parsé le fichier de log."

# Il reste à envoyer le fichier sur EZMesure.
echo "INFORMATION : lancement de ezm"
ezm indices insert campus-condorcet $EZPAARSEANALYSEPATH/*.csv
if [[ $? != 0 ]];
then
	echo "ERREUR : la commande ezm a échouté, veuillez regarder les traces."
	exit 1
fi
echo "SUCCES : le log a été envoyé dans ezmesure."

echo "=== TRAITEMENT TERMINE SANS ERREUR ==="
exit 0
