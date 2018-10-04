import re


def _parse_plain(r):
    """
    Takes in a plain text rule and returns a dictionary
    object containing the parsed information.

    Adapted from: jasonish/idstools.py at GitHub.
    """
    option_patterns = (
        re.compile("(msg)\s*:\s*\"(.*?)\";"),
        re.compile("(sid)\s*:\s*(\d+);"),
        re.compile("(rev)\s*:\s*(\d+);"),
        re.compile("(reference)\s*:\s*(.*?);"),
        re.compile("(classtype)\s*:\s*(.*?);"),
    )
    actions = ("alert", "log", "pass", "activate",
            "dynamic", "drop", "reject", "sdrop")
    rule_pattern = re.compile(
        r"^(?P<enabled>#)*\s*"      # Enabled/disabled
        r"(?P<raw>"
        r"(?P<action>%s)\s*"        # Action
        r"[^\s]*\s*"                # Protocol
        r"[^\s]*\s*"                # Source address(es)
        r"[^\s]*\s*"                # Source port
        r"[-><]+\s*"                # Direction
        r"[^\s]*\s*"                # Destination address(es)
        r"[^\s]*\s*"                # Destination port
        r"\((?P<options>.*)\)\s*"   # Options
        r")"
        % "|".join(actions))
    rule = {}
    rule['references'] = []
    # 'Escaping' brackets for safe string formatting.
    rule_format = r.replace('{', '{{').replace('}', '}}')
    for p in option_patterns:
        m = rule_pattern.match(r)
        options = m.group('options')
        for opt, val in p.findall(options):
            rplctext = '{}:{};'
            rplctoken = '{' + opt + '};'
            if opt != 'rev':
                # Rev is the last option and doesn't have a trailing have space.
                rplctext += ' '
                rplctoken += ' '
            if opt in ["gid", "sid", "rev"]:
                rule[opt] = int(val)
            elif opt == "reference":
                rule['references'].append(val)
                if len(rule['references']) > 1:
                    rplctoken = ''
            elif opt == 'msg':
                rplctext = '{}:"{}"; '
                rule[opt] = val
            else:
                rule[opt] = val
            rule_format = rule_format.replace(
                    rplctext.format(opt, val), rplctoken)
    rule['rule_format'] = rule_format.strip()
    return rule


def from_buffer(rbuffer):
    """
    Takes in a buffer with rules in plain text and
    creates a list of parsed rules in dict objects.
    """
    rules = []
    rbuffer = rbuffer.decode(errors='ignore')
    for r in rbuffer.split('\n'):
        if not r.startswith('#') and r.strip():
            rules.append(_parse_plain(r))
    # A bit of cleanup
    rules = [ru for ru in rules if ru]
    return rules


def from_file(rfile):
    """
    Takes in an opened file object containig rules in plain text and
    creates a list of parsed rules in dict objects.
    """
    rules = []
    for r in rfile.readlines():
        if not r.startswith('#') and r.strip():
            rules.append(_parse_plain(r))
    # A bit of cleanup
    rules = [ru for ru in rules if ru]
    return rules
