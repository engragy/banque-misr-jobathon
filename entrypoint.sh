#!/bin/bash

if [ "$DATABASE" = "postgres" ]
then
  echo "EntryPoint::Waiting-for-postgres..."

  while ! nc -z ${POSTGRES_HOST} ${POSTGRES_PORT}; do
    sleep 0.1
  done

  echo "EntryPoint::testing-PostgreSQL::started"

  # check if a specific file is present in the filesystem.
  # if not, create it and executes your """JUST_ONCE code""".
  # next time the container starts restarts, the file is in the filesystem so the code is not executed.
  CONTAINER_ALREADY_STARTED="CONTAINER_ALREADY_STARTED_PLACEHOLDER"
  if [ ! -e $CONTAINER_ALREADY_STARTED ]
  then
    touch $CONTAINER_ALREADY_STARTED

    echo "EntryPoint::First-time-container-startup:: preparing database"
    # python init_db.py

    echo "EntryPoint::migrate / collectstatic / fixtures"
    python manage.py makemigrations
    echo "EntryPoint::makemigrations Done ."
    python manage.py migrate
    echo "EntryPoint::migrate Done ."
    python manage.py collectstatic --no-input
    echo "EntryPoint::collectstatic Done ."
    python manage.py shell -c "from django.contrib.sites.models import Site; s = Site.objects.first(); s.domain = '${SITE_DOMAIN}'; s.name = '${SITE_NAME}'; s.save();"
    echo "EntryPoint::Adding Site Done ."
  else
    echo "EntryPoint::Not-First-time-container-startup"
    python manage.py makemigrations
    python manage.py migrate
    python manage.py collectstatic --no-input
  fi

fi

exec "$@"