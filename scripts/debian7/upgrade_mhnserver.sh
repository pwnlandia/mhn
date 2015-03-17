#!/bin/bash

set -e
set -x

# update the hpfeeds channels used by mnemosyne
. /opt/hpfeeds/env/bin/activate

IDENT=mnemosyne
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`
SUBSCRIBE_CHAN='amun.events,conpot.events,thug.events,beeswarm.hive,dionaea.capture,dionaea.connections,thug.files,beeswarn.feeder,cuckoo.analysis,kippo.sessions,glastopf.events,glastopf.files,mwbinary.dionaea.sensorunique,snort.alerts,wordpot.events,p0f.events,suricata.events,shockpot.events'

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$SUBSCRIBE_CHAN"

unset IDENT
unset SECRET
unset SUBSCRIBE_CHAN

# update the hpfeeds channels used by honeymap

IDENT=honeymap
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`
SUBSCRIBE_CHAN='geoloc.events'

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "" "$SUBSCRIBE_CHAN"

unset IDENT
unset SECRET
unset SUBSCRIBE_CHAN

# update the hpfeeds channels used by geoloc

IDENT=geoloc
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`
PUBLISH_CHAN='geoloc.events'
SUBSCIRBE_CHAN='amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,kippo.alerts,wordpot.events,shockpot.events,p0f.events,suricata.events'

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$SUBSCIRBE_CHAN"

unset IDENT
unset SECRET
unset PUBLISH_CHAN
unset SUBSCIRBE_CHAN

# update the hpfeeds channels used by collector

IDENT=collector
SECRET=`python -c "import pymongo;print pymongo.MongoClient().hpfeeds.auth_key.find({'identifier':'$IDENT'},{'secret':'1','_id':0})[0]"|grep -o "[a-z0-9]\{32\}"`
SUBSCRIBE_CHAN='geoloc.events'

python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$SUBSCIRBE_CHAN"

unset IDENT
unset SECRET
unset SUBSCIRBE_CHAN

deactivate

supervisorctl reload
