#! /bin/bash
### BEGIN INIT INFO
# Provides:            mhnclient
# Required-Start:
# Required-Stop:
# Should-Start:        $local_fs
# Should-Stop:         $local_fs
# Default-Start:       2 3 4 5
# Default-Stop:        0 1 6
# Short-Description:   ThreatStream MHN Client
# Description:         ThreatStream MHN Client
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="ThreatStream MHN Client"

for functions in /lib/lsb/init-functions /etc/init.d/functions; do
    [ -f $functions ] && . $functions
done

MHN_APP_PATH=/opt/threatstream/mhn
MHN_LINK_HOME=$MHN_APP_PATH/bin
MHN_CONFIG_FILE=/etc/mhnclient/mhnclient.conf
DAEMON=$MHN_LINK_HOME/mhnclient
DAEMONNAME=mhnclient

if [ ! -x $DAEMON ]; then
    echo "$DAEMON is not executable"
    exit 1
fi

PIDFILE=$MHN_APP_PATH/var/run/$DAEMONNAME.pid

is_running() {
    ps -jef | grep -v grep | grep -q $DAEMON
}

do_start() {
    if is_running; then
        echo $DAEMONNAME is already running
        exit 1
    fi

    echo -n "Starting $DESC: "
    if [ -x /sbin/start-stop-daemon ]; then # Modern distros
        COMMAND="exec $DAEMON -c $MHN_CONFIG_FILE -D $*"
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec /bin/bash -- -c "$COMMAND"
        if [ $? = 0 ]; then echo [OK]; else echo [FAILED]; fi
    else
        $DAEMON -p $PIDFILE $*
    fi
}

do_stop() {
    if ! is_running; then
        echo $DAEMONNAME is not running
        exit 1
    fi

    echo -n "Stopping $DESC: "
    if [ -x /sbin/start-stop-daemon ]; then # Modern distros
        start-stop-daemon --stop --quiet --oknodo --retry 5 --pidfile $PIDFILE --exec $DAEMON
        if [ $? = 0 ]; then echo [OK]; else echo [FAILED]; fi
    else
        killproc $DAEMON
    fi
    if is_running; then
        pkill -9 -f $DAEMON
    fi
    rm -f $PIDFILE
}

case "$1" in
    start)
        shift
        do_start $*
        ;;
    stop)
        do_stop
        ;;
    restart)
        if is_running; then
            do_stop
        fi
        do_start
        ;;
    status)
        if is_running; then
            echo 'Running'
        else
            echo 'Not running'
        fi
        ;;
    *)
	    echo "Usage: $0 {start|stop|restart|status}" >&2
	    exit 1
	    ;;
esac
