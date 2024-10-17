FROM r-base:4.4.1

# Create a non-root user and switch to it
RUN addgroup kapigroup && adduser -S kapivara -G kapigroup
USER kapivara

WORKDIR ~/kapp

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y git wget curl

