# original from https://github.com/metabase/metabase/blob/master/Dockerfile
FROM java:openjdk-8-jre-alpine

ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH /usr/local/bin:$PATH
ENV LEIN_ROOT 1

ENV FC_LANG en-US
ENV LC_CTYPE en_US.UTF-8

# install core build tools
RUN apk add --update nodejs git wget bash python make g++ java-cacerts ttf-dejavu fontconfig && \
    npm install -g yarn && \
    ln -sf "${JAVA_HOME}/bin/"* "/usr/bin/"

# fix broken cacerts
RUN rm -f /usr/lib/jvm/default-jvm/jre/lib/security/cacerts && \
    ln -s /etc/ssl/certs/java/cacerts /usr/lib/jvm/default-jvm/jre/lib/security/cacerts

# install lein
ADD https://raw.github.com/technomancy/leiningen/stable/bin/lein /usr/local/bin/lein
RUN chmod 744 /usr/local/bin/lein

# add the application source to the image

RUN git clone https://github.com/metabase/metabase.git

RUN mkdir /app/

RUN mv metabase /app/source

# build the app
WORKDIR /app/source
RUN apk add --update curl patch
RUN git config --global user.email "you@example.com"; git config --global user.name "Your Name"

# merge pull request Allow LDAP group mapping for rfc2307 scheme #7098
RUN curl -L https://github.com/metabase/metabase/pull/7098.patch | git apply
# merge pull request Increase MAX_SERIES from 20 to 200 #5592
RUN curl -L -O https://github.com/metabase/metabase/pull/5592.patch ; patch -F 6 5592.patch ; rm -f 5592.patch

RUN bin/build
RUN cp ./target/uberjar/metabase.jar /app/
RUN cp /app/source/bin/docker/run_metabase.sh /app/

# remove unnecessary packages & tidy up
RUN apk del nodejs git wget python make g++ patch
RUN rm -rf /root/.lein /root/.m2 /root/.node-gyp /root/.npm /root/.yarn /root/.yarn-cache /tmp/* /var/cache/apk/* /app/source/node_modules
RUN rm -rf /app/source

# expose our default runtime port
EXPOSE 3000


# run it
ENTRYPOINT ["/app/run_metabase.sh"]