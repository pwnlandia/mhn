# ********************************************************************************
# *                               Dionaea
# *                           - catches bugs -
# *
# *
# *
# * Copyright (C) 2010  Markus Koetter & Tan Kean Siong
# * Copyright (C) 2009  Paul Baecher & Markus Koetter & Mark Schloesser
# *
# * This program is free software; you can redistribute it and/or
# * modify it under the terms of the GNU General Public License
# * as published by the Free Software Foundation; either version 2
# * of the License, or (at your option) any later version.
# *
# * This program is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# * GNU General Public License for more details.
# *
# * You should have received a copy of the GNU General Public License
# * along with this program; if not, write to the Free Software
# * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# *
# *
# *             contact nepenthesdev@gmail.com
# *
# *******************************************************************************/

import logging
import os
import imp

from dionaea.core import g_dionaea

# service imports
import dionaea.tftp
import dionaea.cmd
import dionaea.emu
import dionaea.store
import dionaea.test
import dionaea.ftp

logger = logging.getLogger('ihandlers')
logger.setLevel(logging.DEBUG)

# reload service imports
# imp.reload(dionaea.tftp)
# imp.reload(dionaea.ftp)
# imp.reload(dionaea.cmd)
# imp.reload(dionaea.emu)
# imp.reload(dionaea.store)

# global handler list
# keeps a ref on our handlers
# allows restarting
global g_handlers


def start():
    logger.warn("START THE IHANDLERS")
    for i in g_handlers:
        method = getattr(i, "start", None)
        if method != None:
            method()


def new():
    global g_handlers
    g_handlers = []

    if "ftpdownload" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.ftp
        g_handlers.append(dionaea.ftp.ftpdownloadhandler('dionaea.download.offer'))

    if "tftpdownload" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        g_handlers.append(dionaea.tftp.tftpdownloadhandler('dionaea.download.offer'))

    if "emuprofile" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        g_handlers.append(dionaea.emu.emuprofilehandler('dionaea.module.emu.profile'))

    if "cmdshell" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        g_handlers.append(dionaea.cmd.cmdshellhandler('dionaea.service.shell.*'))

    if "store" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        g_handlers.append(dionaea.store.storehandler('dionaea.download.complete'))

    if "uniquedownload" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        g_handlers.append(dionaea.test.uniquedownloadihandler('dionaea.download.complete.unique'))

    if "surfids" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.surfids
        g_handlers.append(dionaea.surfids.surfidshandler('*'))

    if "logsql" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.logsql
        g_handlers.append(dionaea.logsql.logsqlhandler("*"))

    if "p0f" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.p0f
        g_handlers.append(dionaea.p0f.p0fhandler(g_dionaea.config()['modules']['python']['p0f']['path']))

    if "logxmpp" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.logxmpp
        from random import choice
        import string
        for client in g_dionaea.config()['modules']['python']['logxmpp']:
            conf = g_dionaea.config()['modules']['python']['logxmpp'][client]
            if 'resource' in conf:
                resource = conf['resource']
            else:
                resource = ''.join([choice(string.ascii_letters) for i in range(8)])
            print("client %s \n\tserver %s:%s username %s password %s resource %s muc %s\n\t%s" % (
            client, conf['server'], conf['port'], conf['username'], conf['password'], resource, conf['muc'],
            conf['config']))
            x = dionaea.logxmpp.logxmpp(conf['server'], int(conf['port']), conf['username'], conf['password'], resource,
                                        conf['muc'], conf['config'])
            g_handlers.append(x)

    if "nfq" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.nfq
        g_handlers.append(dionaea.nfq.nfqhandler())

    if "virustotal" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.virustotal
        g_handlers.append(dionaea.virustotal.virustotalhandler('*'))

    if "mwserv" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.mwserv
        g_handlers.append(dionaea.mwserv.mwservhandler('*'))

    if "submit_http" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.submit_http
        g_handlers.append(dionaea.submit_http.handler('*'))

    if "hpfeeds" in g_dionaea.config()['modules']['python']['ihandlers']['handlers'] and 'hpfeeds' in \
            g_dionaea.config()['modules']['python']:
        import dionaea.hpfeeds
        for client in g_dionaea.config()['modules']['python']['hpfeeds']:
            conf = g_dionaea.config()['modules']['python']['hpfeeds'][client]
            x = dionaea.hpfeeds.hpfeedihandler(conf)
            g_handlers.append(x)

    if "fail2ban" in g_dionaea.config()['modules']['python']['ihandlers']['handlers']:
        import dionaea.fail2ban
        g_handlers.append(dionaea.fail2ban.fail2banhandler())


def stop():
    global g_handlers
    for i in g_handlers:
        logger.debug("deleting %s" % str(i))
        i.stop()
        del i
    del g_handlers
