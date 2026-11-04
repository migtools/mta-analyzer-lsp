FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder
COPY --chown=1001:0 . /workspace

WORKDIR /workspace/external-providers/python-external-provider
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 go build -tags strictfipsruntime -a -o python-external-provider main.go

FROM registry.redhat.io/ubi9/ubi:latest

RUN dnf install -y gcc gcc-c++ python3 python3-devel openssl && \
    python3 -m ensurepip --upgrade

WORKDIR /addon
RUN chgrp -R 0 /addon && chmod -R g=u /addon

# Add steps for cachi2
ENV REMOTE_SOURCES=${REMOTE_SOURCES:-"./hack/cachi2"}
ENV REMOTE_SOURCES_DIR=${REMOTE_SOURCES_DIR:-"/remote-sources"}
COPY ${REMOTE_SOURCES} ${REMOTE_SOURCES_DIR}
COPY hack/cachi2/install.sh .
RUN chmod +x install.sh && ./install.sh

# Remove packages which are only needed for cachi2
RUN dnf remove -y gcc gcc-c++ && \
    dnf clean all && \
    rm -rf /var/cache/dnf

USER 1001

COPY --from=builder /workspace/external-providers/python-external-provider/python-external-provider /usr/local/bin/python-external-provider
COPY --from=builder /workspace/LICENSE /licenses/

ENV HOME /addon
ENTRYPOINT ["/usr/local/bin/python-external-provider"]

LABEL \
        description="Migration Toolkit for Applications - Python External Provider" \
        io.k8s.description="Migration Toolkit for Applications - Python External Provider" \
        io.k8s.display-name="MTA - Python External Provider" \
        io.openshift.maintainer.project="MTA" \
        io.openshift.tags="migration,modernization,mta,tackle,konveyor" \
        summary="Migration Toolkit for Applications - Python External Provider"
