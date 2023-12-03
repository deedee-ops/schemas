FROM public.ecr.aws/docker/library/python:3-slim-bookworm

ENV PUID=1000
ENV PGID=1000

COPY crd-extractor.sh /usr/bin/crd-extractor
COPY openapi2jsonschema.py /opt/openapi2jsonschema.py

# hadolint ignore=DL3008,DL3013
RUN apt-get update \
 && apt-get install --yes --no-install-recommends bash curl \
 && apt-get clean autoclean \
 && rm -rf /var/lib/apt/lists/* \
 && curl -L -o /usr/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
 && chmod +x /usr/bin/kubectl /usr/bin/crd-extractor \
 && pip install --no-cache-dir pyaml \
 && mkdir -p /crds /root/.datree \
 && ln -s /crds /root/.datree/crdSchemas

ENTRYPOINT ["/usr/bin/crd-extractor"]
