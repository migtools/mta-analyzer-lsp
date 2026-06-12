FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder
COPY --chown=1001:0 . /workspace

WORKDIR /workspace/external-providers/nodejs-external-provider
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 go build -tags strictfipsruntime -a -o nodejs-external-provider main.go

FROM registry.redhat.io/ubi9/ubi:latest

ENV NODEJS_VERSION=18
RUN echo -e "[nodejs]\nname=nodejs\nstream=${NODEJS_VERSION}\nprofiles=\nstate=enabled\n" > /etc/dnf/modules.d/nodejs.module
RUN dnf install -y nodejs npm openssl && \
    dnf clean all && \
    rm -rf /var/cache/dnf

WORKDIR /addon
RUN chgrp -R 0 /addon && chmod -R g=u /addon

# Add steps for cachi2
ENV REMOTE_SOURCES=${REMOTE_SOURCES:-"./hack/cachi2-nodejs"}
ENV REMOTE_SOURCES_DIR=${REMOTE_SOURCES_DIR:-"/remote-sources"}
COPY ${REMOTE_SOURCES} ${REMOTE_SOURCES_DIR}
COPY hack/cachi2-nodejs/install.sh .
RUN chmod +x install.sh && ./install.sh

USER 1001

COPY --from=builder /workspace/external-providers/nodejs-external-provider/nodejs-external-provider /usr/local/bin/nodejs-external-provider
COPY --from=builder /workspace/LICENSE /licenses/

ENV HOME /addon
ENTRYPOINT ["/usr/local/bin/nodejs-external-provider"]

LABEL \
        description="Migration Toolkit for Applications - Node.js External Provider" \
        io.k8s.description="Migration Toolkit for Applications - Node.js External Provider" \
        io.k8s.display-name="MTA - Node.js External Provider" \
        io.openshift.maintainer.project="MTA" \
        io.openshift.tags="migration,modernization,mta,tackle,konveyor" \
        summary="Migration Toolkit for Applications - Node.js External Provider"
