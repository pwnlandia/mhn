celery -A mhn.tasks --config=config beat &
celery -A mhn.tasks --config=config worker &
python manage.py run
