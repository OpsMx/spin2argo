FROM alpine:3.16

RUN apk add yq git bash

COPY spin2argo.sh /spin2argo.sh

CMD [ "/spin2argo.sh" ]