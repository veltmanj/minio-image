# MinIO server and mc client, built from the archived upstream source without changes.
# MinIO removed its public images and archived binaries, so the source tags are the only way to get
# this version. The build stops when a tag does not point at the commit below.

ARG MINIO_TAG=RELEASE.2023-09-04T19-57-37Z
ARG MINIO_COMMIT=1c99fb106c3e1448ed92f8465d5695d055d432e7
ARG MC_TAG=RELEASE.2023-09-02T21-28-03Z
ARG MC_COMMIT=e2056fb057897a515d2cad25aa461f5dfd32695d

# Go cross-compiles, so the build stage runs on the build platform without an emulator.
FROM --platform=$BUILDPLATFORM golang:1.21-bookworm@sha256:c6a5b9308b3f3095e8fde83c8bf4d68bd101fce606c1a0a1394522542509dda9 AS build

ARG MINIO_TAG
ARG MINIO_COMMIT
ARG MC_TAG
ARG MC_COMMIT
ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

RUN git clone --quiet --depth 1 --branch "$MINIO_TAG" https://github.com/minio/minio.git minio \
    && test "$(git -C minio rev-parse HEAD)" = "$MINIO_COMMIT" \
    && git clone --quiet --depth 1 --branch "$MC_TAG" https://github.com/minio/mc.git mc \
    && test "$(git -C mc rev-parse HEAD)" = "$MC_COMMIT"

# The ldflags come from each project's own gen-ldflags.go with the release time as its argument,
# which is how upstream stamped its releases. They run for the build platform, before GOARCH is set.
RUN cd minio \
    && go mod download \
    && release_time=$(echo "${MINIO_TAG#RELEASE.}" | sed -E 's/T([0-9]{2})-([0-9]{2})-([0-9]{2})Z$/T\1:\2:\3Z/') \
    && ldflags=$(MINIO_RELEASE=RELEASE go run buildscripts/gen-ldflags.go "$release_time") \
    && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
       go build -tags kqueue -trimpath -ldflags "$ldflags" -o /out/minio

RUN cd mc \
    && go mod download \
    && release_time=$(echo "${MC_TAG#RELEASE.}" | sed -E 's/T([0-9]{2})-([0-9]{2})-([0-9]{2})Z$/T\1:\2:\3Z/') \
    && ldflags=$(MC_RELEASE=RELEASE go run buildscripts/gen-ldflags.go "$release_time") \
    && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
       go build -tags kqueue -trimpath -ldflags "$ldflags" -o /out/mc

# The upstream entrypoint needs /bin/sh.
FROM alpine:3.20@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc

ARG MINIO_TAG
ARG MINIO_COMMIT

LABEL org.opencontainers.image.title="MinIO" \
      org.opencontainers.image.description="MinIO server and mc client, built from the archived upstream source without changes" \
      org.opencontainers.image.source="https://github.com/veltmanj/minio-image" \
      org.opencontainers.image.version="${MINIO_TAG}" \
      org.opencontainers.image.revision="${MINIO_COMMIT}" \
      org.opencontainers.image.licenses="AGPL-3.0"

# The upstream image's environment, unchanged.
ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_SECRET_KEY_FILE=kms_master_key \
    MINIO_CONFIG_ENV_FILE=config.env \
    PATH=/opt/bin:$PATH

RUN apk add --no-cache ca-certificates

COPY --from=build /out/minio /out/mc /opt/bin/
COPY --from=build --chmod=755 /src/minio/dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
COPY --from=build /src/minio/LICENSE /src/minio/CREDITS /licenses/

EXPOSE 9000

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

VOLUME ["/data"]

CMD ["minio"]
