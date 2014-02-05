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
        resp = requests.get(src.uri)
        if resp.status_code == 200:
            # rules will contain all parsed rules.
            rules.extend(from_buffer(resp.text))
        else:
            pass
    app.logger.info('Bulk importing {} rules.'.format(len(rules)))
    Rule.bulk_import(rules)
    render_rules()
