FROM python:3.7-slim

RUN pip install pipenv

RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get install -y curl 

WORKDIR /usr/src/app
COPY . .
RUN pipenv install

ENV FLASK_APP app.py
CMD [ "pipenv", "run", "gunicorn", "-w", "4", "-b", ":8080","app:app" ]

