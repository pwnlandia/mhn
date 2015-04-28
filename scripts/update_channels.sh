#!/bin/bash

set -e
set -x

. /opt/hpfeeds/env/bin/activate


# update the hpfeeds channels used by mnemosyne
IDENT="mnemosyne"
SECRET=`python /opt/hpfeeds/broker/get_secret.py $IDENT`
PUBLISH_CHAN=""
SUBSCRIBE_CHAN='amun.events,conpot.events,thug.events,beeswarm.hive,dionaea.capture,dionaea.connections,thug.files,beeswarn.feeder,cuckoo.analysis,kippo.sessions,glastopf.events,glastopf.files,mwbinary.dionaea.sensorunique,snort.alerts,wordpot.events,p0f.events,suricata.events,shockpot.events,elastichoney.events'
if [ ! -z "$SECRET" ] ; then
    python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$SUBSCRIBE_CHAN"
else
    echo "Warning: no SECRET found for IDENT=$IDENT, not updating hpfeeds user."
fi


# update the hpfeeds channels used by geoloc
IDENT="geoloc"
SECRET=`python /opt/hpfeeds/broker/get_secret.py $IDENT`
PUBLISH_CHAN='geoloc.events'
SUBSCRIBE_CHAN='amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,kippo.alerts,wordpot.events,shockpot.events,p0f.events,suricata.events,elastichoney.events'
if [ ! -z "$SECRET" ] ; then
    python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$SUBSCRIBE_CHAN"
else
    echo "Warning: no SECRET found for IDENT=$IDENT, not updating hpfeeds user."
fi

# update the hpfeeds channels used by honeymap and collector
for IDENT in "honeymap" "collector";
do
    SECRET=`python /opt/hpfeeds/broker/get_secret.py $IDENT`
    PUBLISH_CHAN=""
    SUBSCRIBE_CHAN='geoloc.events'
    if [ ! -z "$SECRET" ] ; then
        python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$SUBSCRIBE_CHAN"
    else
        echo "Warning: no SECRET found for IDENT=$IDENT, not updating hpfeeds user."
    fi
done

# update the hpfeeds-loggers
for IDENT in "hpfeeds-logger-splunk" "hpfeeds-logger-arcsight" "hpfeeds-logger";
do
    SECRET=`python /opt/hpfeeds/broker/get_secret.py $IDENT`
    PUBLISH_CHAN=""
    SUBSCRIBE_CHAN='amun.events,dionaea.connections,dionaea.capture,glastopf.events,beeswarm.hive,kippo.sessions,conpot.events,snort.alerts,suricata.events,wordpot.events,shockpot.events,p0f.events,elastichoney.events'
    if [ ! -z "$SECRET" ] ; then
        python /opt/hpfeeds/broker/add_user.py "$IDENT" "$SECRET" "$PUBLISH_CHAN" "$SUBSCRIBE_CHAN"
    else
        echo "Warning: no SECRET found for IDENT=$IDENT, not updating hpfeeds user."
    fi
done
