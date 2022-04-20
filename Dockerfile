FROM docker.io/requarks/wiki:2

USER root

RUN mkdir /wiki/data/sideload
ADD https://raw.githubusercontent.com/requarks/wiki-localization/master/locales.json /wiki/data/sideload
ADD https://raw.githubusercontent.com/requarks/wiki-localization/master/en.json /wiki/data/sideload
RUN echo "offline: true" >> /wiki/config.yml
RUN chgrp -R 0 /wiki /logs && chmod -R g=u /wiki /logs

USER 1001
