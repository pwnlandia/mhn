#!/bin/bash

set -e

echo "==========================================================="
echo "  Configuration - MongoDB"
echo "==========================================================="

while true;
do
    echo -n "Would you like to use remote mongodb (must be installed and configured before installing mhn)? (y/n) "
    read MONGO
    if [ "$MONGO" == "y" -o "$MONGO" == "Y" ]
    then
        REMOTE_MONGO=true
        echo -n "MongoDB Host: "
        read MONGO_HOST
        echo -n "MongoDB Port: "
        read MONGO_PORT
        echo "Using mongodb server $MONGO_HOST:$MONGO_PORT"
        break
    elif [ "$MONGO" == "n" -o "$MONGO" == "N" ]
    then
        REMOTE_MONGO=false
        MONGO_HOST='localhost'
        MONGO_PORT=27017
        echo "Using default configuration:"
        echo "    MongoDB Host: localhost"
        echo "    MongoDB Port: 27017"
        break
    fi
done

# Remote Mongo -> ask for authentication
if [ "$MONGO" == "y" -o "$MONGO" == "Y" ]
then
    while true;
    do
        echo -n "Would you like to use authentication for mongodb? (y/n) "
        read MONGO_AUTH
        if [ "$MONGO_AUTH" == "y" -o "$MONGO_AUTH" == "Y" ]
        then
            MONGO_AUTH='true'
            echo -n "MongoDB user: "
            read MONGO_USER
            echo -n "MongoDB password: "
            read MONGO_PASSWORD
#            TODO add new authentication method to evnet
#            echo -n "MongoDB authentication mechanism < SCRAM-SHA-1 | MONGODB-CR >:"
#            read MONGO_AUTH_MECHANISM
            MONGO_AUTH_MECHANISM="MONGODB-CR"
            echo "The mongo will use username: $MONGO_USER and authentication mechanism $MONGO_AUTH_MECHANISM"
            break
        elif [ "$MONGO_AUTH" == "n" -o "$MONGO_AUTH" == "N" ]
        then
            MONGO_AUTH='false'
            MONGO_USER='null'
            MONGO_PASSWORD='null'
            MONGO_AUTH_MECHANISM='null'
            break
        fi
    done
else
    MONGO_AUTH='false'
    MONGO_USER='null'
    MONGO_PASSWORD='null'
    MONGO_AUTH_MECHANISM='null'
fi

# set environment variable in supevisord.conf
sed -i "s/\(^\[supervisord\]\)$/\1\nenvironment=REMOTE_MONGO=\"$REMOTE_MONGO\",MONGO_HOST=\"$MONGO_HOST\",MONGO_PORT=$MONGO_PORT,MONGO_AUTH=$MONGO_AUTH,MONGO_USER=$MONGO_USER,MONGO_PASSWORD=$MONGO_PASSWORD,MONGO_AUTH_MECHANISM=$MONGO_AUTH_MECHANISM/" /etc/supervisor/supervisord.conf

