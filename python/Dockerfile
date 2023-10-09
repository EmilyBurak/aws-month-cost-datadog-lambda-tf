FROM python:3.8.2-slim-buster

RUN mkdir /app 

RUN addgroup --system app && adduser --system --group app

ENV HOME=/app
WORKDIR $HOME

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install system dependencies
RUN apt-get update \
    && apt-get -y install netcat gcc \
    && apt-get clean

# install python dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# add app
COPY . /app

# app user gains ownership
RUN chown -R app:app $HOME

# change to app user
USER app

# run app
ENTRYPOINT ["python", "app.py"]