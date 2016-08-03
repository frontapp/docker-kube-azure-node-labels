FROM alpine:3.4
RUN apk add --update curl jq && rm -rf /var/cache/apk/*
COPY apply_labels.sh /
ENTRYPOINT [ "/apply_labels.sh" ]
CMD [ "" ]
