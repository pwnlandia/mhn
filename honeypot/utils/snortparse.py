"""
Utility function to parse alerts out of Snort logs.
Works with Snort version 2.9.2 IPv6 GRE (Build 78)
"""

import itertools
from datetime import datetime

import pyparsing as pyp


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

    def __init__(self, *args):
        try:
            assert len(args) == 7
        except:
            raise ValueError("Unexpected number of attributes.")
        else:
            self.header = args[0]
            self.classification = args[1]
            self.priority = args[2]
            # Alert logs don't include year. Creating a datime object
            # with current year.
            date = datetime.strptime(args[3], '%m/%d-%H:%M:%S.%f')
            self.date = datetime(
                    datetime.now().year, date.month, date.day,
                    date.hour, date.minute, date.second, date.microsecond)
            self.source_ip = args[4]
            self.destination_ip = args[5]
            self.destination_port = args[6]

    def __repr__(self):
        return str(self.__dict__)


def snort_parse(logfile):
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
    #    01/10-00:08:23.598520 201.233.20.73:63035 -> 192.241.157.117:22
    #    TCP TTL:53 TOS:0x10 ID:2145 IpLen:20 DgmLen:100 DF
    #    ***AP*** Seq: 0xD34C30CE  Ack: 0x6B1F7D18  Win: 0x2000  TcpLen: 32
    #
    # Note: This format is known to change over versions.
    header = (
       pyp.Suppress("[**] [")
       + pyp.Combine(integer + ":" + integer + ":" + integer)
       + pyp.Suppress(pyp.SkipTo("[**]", include=True))
    )
    cls = (
        pyp.Suppress(pyp.Optional(pyp.Literal("[Classification:")))
        + pyp.Regex("[^]]*") + pyp.Suppress(']')
    )
    pri = pyp.Suppress("[Priority:") + integer + pyp.Suppress("]")
    date = pyp.Combine(
        integer + "/" + integer + '-' + integer + ':' + integer + ':' + integer + '.' + integer)
    src_ip = ip_addr + pyp.Suppress(port + "->")
    dest_ip = ip_addr
    dest_port = port
    bnf = header + cls + pri + date + src_ip + dest_ip + dest_port

    alerts = []
    with open(logfile) as snort_logfile:
        for has_content, grp in itertools.groupby(
                snort_logfile, key = lambda x: bool(x.strip())):
            if has_content:
                content = ''.join(grp)
                fields = bnf.searchString(content)
                if fields:
                    alerts.append(Alert(*fields[0]))
    return alerts


if __name__ ==  '__main__':
    print snort_parse('alert')
