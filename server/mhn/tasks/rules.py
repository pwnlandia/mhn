import os
import tarfile
from datetime import datetime
try:
    from StringIO import cStringIO as StringIO
except ImportError:
    from StringIO import StringIO

from flask import current_app as app
import requests

from mhn.tasks import celery
from mhn.api.models import Rule, RuleSource
from mhn.common.ruleutils import from_buffer


@celery.task
def render_rules():
    app.logger.info('Rendering rules.')
    from flask import current_app
    sbuffer = Rule.renderall()
    fpath = current_app.config['RENDERED_RULES_PATH']
    with open(fpath, 'w') as rfile:
        rfile.write(sbuffer)
    app.logger.info('Finished rendering rules.')


@celery.task
def fetch_sources():
    app.logger.info('Fetching sources from {} sources.'.format(
        RuleSource.query.count()))
    rules = []
    for src in RuleSource.query:
        # Download rules from every source.
        app.logger.info('Downloading from "{}".'.format(src.uri))
        # If a gzip file, perform a streamed download
        # and save it to a temp file.
        stream = src.uri.endswith('gz')
        resp = requests.get(src.uri, stream=stream)
        if resp.status_code == 200:
            if stream:
                tmpdir = '/tmp/{}-{}/'.format(src.name,
                                              datetime.utcnow().isoformat())
                os.mkdir(tmpdir)
                ziprules = StringIO()
                for chunk in resp.iter_content():
                    ziprules.write(chunk)
                ziprules.seek(0)
                try:
                    zrules = tarfile.open(fileobj=ziprules, mode='r:gz')
                except tarfile.TarError as terr:
                    app.logger.warning(
                        'Error in rule file: {}\n{}'.format(src.uri, str(terr)))
                else:
                    ruleslist = []
                    for member in zrules.getmembers():
                        if member.name.endswith('.rules') and member.isfile():
                            # Keep track of extracted filenames.
                            ruleslist.append(member.name)
                            zrules.extract(member, path=tmpdir)
                    # All rule files found are now extracted into tmpdir.
                    for rname in ruleslist:
                        try:
                            rulepath = os.path.join(tmpdir, rname)
                            with open(rulepath, 'rb') as rfile:
                                rules.extend(from_buffer(rfile.read()))
                            os.remove(rulepath)
                        except Exception as e:
                            app.logger.exception("Unhandled exception: {}. Continuing".format(e))
                            continue

                    # A subdirectory /rules/ is created when extracting,
                    # removing that first then the whole tmpdir.
                    os.rmdir(os.path.join(tmpdir, 'rules'))
                    os.rmdir(tmpdir)
            else:
                # rules will contain all parsed rules.
                rules.extend(from_buffer(resp.text))
        else:
            pass
    app.logger.info('Bulk importing {} rules.'.format(len(rules)))
    Rule.bulk_import(rules)
    render_rules()
