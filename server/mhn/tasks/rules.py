import requests

from mhn.tasks import celery
from mhn.api.models import Rule
from mhn.common.ruleutils import from_buffer


@celery.task
def render_rules():
    from flask import current_app
    sbuffer = Rule.renderall()
    fpath = current_app.config['RENDERED_RULES_PATH']
    with open(fpath, 'w') as rfile:
        rfile.write(sbuffer)


@celery.task
def fetch_source(uri):
    resp = requests.get(uri)
    if resp.status_code == 200:
        rules = from_buffer(resp.text)
        Rule.bulk_import(rules)
        render_rules.delay()
    else:
        pass
