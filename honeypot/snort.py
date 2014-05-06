import pyparsing as pyp
from itertools import groupby
from datetime import datetime
import json

class Alert(object):
    """
    Represents a Snort alert.
    """

    fields = (
        'header',
        'classification',
        'priority',
        'date',
        'source_ip',
        'destination_ip',
        'destination_port'
    )

    def __init__(self, sensor_uuid, *args):
        try:
            assert len(args) == 8
        except:
            raise ValueError("Unexpected number of attributes.")
        else:
            self.header = args[0]
            self.signature = args[1]
            self.classification = args[2]
            self.priority = args[3]
            # Alert logs don't include year. Creating a datime object
            # with current year.
            date = datetime.strptime(args[4], '%m/%d-%H:%M:%S.%f')
            self.date = datetime(
                    datetime.now().year, date.month, date.day,
                    date.hour, date.minute, date.second, date.microsecond)
            self.source_ip = args[5]
            self.destination_ip = args[6]
            self.destination_port = args[7]
            self.sensor = sensor_uuid

    def __repr__(self):
        return str(self.__dict__)

    def to_dict(self):
        return self.__dict__

    def to_json(self):
        _dict = self.to_dict().copy()
        _dict.update({'date': self.date.strftime("%Y-%m-%dT%H:%M:%S.%f%z")})
        return json.dumps(_dict)

    @classmethod
    def from_log(cls, sensor_uuid, logfile, mindate=None):
        """
        Reads the file logfile and parses out Snort alerts
        from the given alert format.
        Thanks to 'unutbu' at StackOverflow.
        """
        # Defining generic pyparsing objects.
        integer = pyp.Word(pyp.nums)
        ip_addr = pyp.Combine(integer + '.' + integer+ '.' + integer + '.' + integer)
        port = pyp.Suppress(':') + integer
        # Defining pyparsing objects from expected format:
        #
        #    [**] [1:160:2] COMMUNITY SIP TCP/IP message flooding directed to SIP proxy [**]
        #    [Classification: Attempted Denial of Service] [Priority: 2]
        #    01/10-00:08:23.598520 201.233.20.33:63035 -> 192.234.122.1:22
        #    TCP TTL:53 TOS:0x10 ID:2145 IpLen:20 DgmLen:100 DF
        #    ***AP*** Seq: 0xD34C30CE  Ack: 0x6B1F7D18  Win: 0x2000  TcpLen: 32
        #
        # Note: This format is known to change over versions.
        # Works with Snort version 2.9.2 IPv6 GRE (Build 78)

        header = (
            pyp.Suppress("[**] [")
            + pyp.Combine(integer + ":" + integer + ":" + integer)
            + pyp.Suppress("]")
        )
        signature = (
            pyp.Combine(pyp.SkipTo("[**]", include=False))
        )
        classif = (
            pyp.Suppress("[**]")
            + pyp.Suppress(pyp.Optional(pyp.Literal("[Classification:")))
            + pyp.Regex("[^]]*") + pyp.Suppress(']')
        )
        pri = pyp.Suppress("[Priority:") + integer + pyp.Suppress("]")
        date = pyp.Combine(
            integer + "/" + integer + '-' + integer + ':' + integer + ':' + integer + '.' + integer
        )
        src_ip = ip_addr + pyp.Suppress(port + "->")
        dest_ip = ip_addr
        dest_port = port
        bnf = header + signature + classif + pri + date + src_ip + dest_ip + dest_port

        alerts = []
        with open(logfile) as snort_logfile:
            for has_content, grp in groupby(
                    snort_logfile, key = lambda x: bool(x.strip())):
                if has_content:
                    content = ''.join(grp)
                    fields = bnf.searchString(content)

                    print "fields = %s"%fields

                    if fields:
                        if abs(datetime.utcnow() -  datetime.now()).total_seconds() > 1:
                            # Since snort doesn't log in UTC, a correction is needed to
                            # convert the logged time to UTC. The following code calculates
                            # the delta between local time and UTC and uses it to convert
                            # the logged time to UTC. Additional time formatting  makes
                            # sure the previous code doesn't break.
                            date = datetime.strptime(fields[0][4], '%m/%d-%H:%M:%S.%f')
                            date = datetime(
                               datetime.now().year, date.month, date.day,
                               date.hour, date.minute, date.second, date.microsecond)
                            toutc = datetime.utcnow() - datetime.now()
                            date = date + toutc
                            fields[0][4] = date.strftime('%m/%d-%H:%M:%S.%f')
                        alert = cls(sensor_uuid, *fields[0])
                        if (mindate and alert.date > mindate) or not mindate:
                            # If mindate parameter is passed, only newer
                            # alters will be appended.
                            alerts.append(alert)
        return alerts

if __name__ == "__main__":
    alerts =  Alert.from_log("12345", "/Users/jtrost/snort.log")

    print "---"

    for a in alerts:
        print a.to_json()