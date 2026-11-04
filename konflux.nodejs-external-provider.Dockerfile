FROM registry.access.redhat.com/ubi9/go-toolset:1.26 AS builder
COPY --chown=1001:0 . /workspace

WORKDIR /workspace/external-providers/nodejs-external-provider
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 go build -tags strictfipsruntime -a -o nodejs-external-provider main.go

FROM registry.redhat.io/ubi9/ubi:latest

ENV NODEJS_VERSION=18

RUN dnf install -y nodejs npm openssl && \
    dnf clean all && \
    rm -rf /var/cache/dnf
COPY --from=builder /workspace/hack/build/typescript.tgz typescript.tgz
COPY --from=builder /workspace/hack/build/typescript-language-server.tgz typescript-language-server.tgz
RUN npm install -g typescript-language-server.tgz typescript.tgz
RUN typescript-language-server --version
RUN rm -r typescript.tgz typescript-language-server.tgz
# npm is only needed for the global install above. Its bundled node_modules ship
# vulnerable transitive libraries (brace-expansion: CVE-2026-69152, CVE-2026-102276,
# CVE-2026-102278) that are otherwise flagged in the runtime image. The provider
# only needs the node runtime plus the self-contained typescript-language-server
# bundle, so remove npm and its bundled modules from the final image.
RUN dnf remove -y npm && dnf clean all && rm -rf /usr/lib/node_modules/npm /var/cache/dnf

WORKDIR /addon
RUN chgrp -R 0 /addon && chmod -R g=u /addon
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
