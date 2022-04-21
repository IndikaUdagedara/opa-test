FROM alpine

RUN apk update
RUN apk add curl bash
RUN cd /usr/local/bin && curl -L -o opa https://openpolicyagent.org/downloads/v0.39.0/opa_linux_amd64_static && chmod +x opa
COPY opa-test.sh /usr/local/bin 
RUN chmod +x /usr/local/bin/opa-test.sh

WORKDIR /data

ENTRYPOINT ["opa-test.sh"]