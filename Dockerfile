###########
# BUILDER #
###########

# pull official base image
FROM python:3.10.13-bookworm as builder

# set work directory
WORKDIR /usr/src/jobathon

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# copy project files & lint
COPY . .
RUN pip install --upgrade pip
# RUN pip install flake8==3.9.2
# RUN flake8 --ignore=E501,E722,F401,F403 .

# install dependencies
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/jobathon/wheels -r requirements/base.txt
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/jobathon/wheels -r requirements/dev.txt
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/jobathon/wheels -r requirements/prod.txt


#########
# FINAL #
#########

# pull official base image
FROM python:3.10.13-bookworm

# create directory for the jobathon-project user
RUN mkdir -p /home/jobathon

# create the jobathon-project user
RUN addgroup --system jobathon-group && adduser --system --uid 1000 jobathon-user && usermod -aG jobathon-group jobathon-user

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
# create the appropriate directories
ENV HOME=/home/jobathon
ENV APP_HOME=/home/jobathon/web
RUN mkdir $APP_HOME
RUN mkdir $HOME/media_root
RUN mkdir $HOME/static_root
WORKDIR $APP_HOME

# create debug logs files
RUN touch ${APP_HOME}/debug.log
RUN touch ${APP_HOME}/gunicorn.log

# install dependencies
COPY --from=builder /usr/src/jobathon/wheels /wheels
COPY --from=builder /usr/src/jobathon/requirements .
RUN pip install --no-cache /wheels/*
RUN apt update && apt dist-upgrade -y
RUN apt install -y postgresql-client
RUN apt install -y nano netcat-traditional  # netcat is used as nc in entrypoint bash script

# move pgpass
COPY ./.pgpass $HOME
RUN chown jobathon-user:jobathon-group $HOME/.pgpass
RUN chmod 600 $HOME/.pgpass

# copy entrypoint
COPY ./entrypoint.sh .
RUN sed -i 's/\r$//g'  $APP_HOME/entrypoint.sh
RUN chmod +x  $APP_HOME/entrypoint.sh

# copy project
COPY . $APP_HOME

# chown all the files to the jobathon-project user
RUN chown -R jobathon-user:jobathon-group $APP_HOME
RUN chown -R jobathon-user:jobathon-group $HOME/media_root
RUN chown -R jobathon-user:jobathon-group $HOME/static_root

# add user to sudo group
RUN apt -y install sudo
RUN chpasswd && adduser jobathon-user sudo
# change to the jobathon-project user
USER jobathon-user

# run entrypoint.prod.sh
ENTRYPOINT [ "/home/jobathon/web/entrypoint.sh" ]
