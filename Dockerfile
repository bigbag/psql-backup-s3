FROM postgres:16.0-alpine3.18

RUN apk --update --no-cache add postgresql-client \
    aws-cli \
    coreutils \
    bash

ENV APP_HOME=/opt/app

RUN addgroup -S user && \
  adduser -S -G user user && \
  mkdir -p $APP_HOME && \
  chown user:user $APP_HOME

USER user

WORKDIR $APP_HOME

COPY --chown=user:user ./psql-backup-s3.sh .

RUN chmod 744 ./psql-backup-s3.sh

CMD ["./psql-backup-s3.sh"]
