# minio-image

This repository builds a MinIO container image from the upstream source
and publishes it to `ghcr.io/veltmanj/minio-server`.

MinIO removed its public images from Docker Hub and Quay, and its binary
archive at `dl.min.io` answers 410. The GitHub repositories `minio/minio`
and `minio/mc` are archived, but they still hold the source tags. This
image uses those tags. Nobody changes the source.

## The image

```
ghcr.io/veltmanj/minio-server:RELEASE.2023-09-04T19-57-37Z
```

| Part | Upstream tag | Commit |
| --- | --- | --- |
| Server | [`minio/minio` `RELEASE.2023-09-04T19-57-37Z`](https://github.com/minio/minio/tree/RELEASE.2023-09-04T19-57-37Z) | `1c99fb106c3e1448ed92f8465d5695d055d432e7` |
| Client | [`minio/mc` `RELEASE.2023-09-02T21-28-03Z`](https://github.com/minio/mc/tree/RELEASE.2023-09-02T21-28-03Z) | `e2056fb057897a515d2cad25aa461f5dfd32695d` |

- Platforms: `linux/amd64` and `linux/arm64`.
- The image keeps the upstream entrypoint, so `server /data` operates as
  in the upstream image. The `mc` client is in the image.
- The build stops if a tag does not point at its commit.
- The version stamp is the upstream one: `minio --version` shows
  `RELEASE.2023-09-04T19-57-37Z`.

## Use

```sh
docker run -p 9000:9000 \
  -e MINIO_ROOT_USER=<user> -e MINIO_ROOT_PASSWORD=<password> \
  ghcr.io/veltmanj/minio-server:RELEASE.2023-09-04T19-57-37Z server /data
```

## Publish

The `Publish` workflow runs when a change to `Dockerfile` or to the
workflow reaches `main`. You can also start it by hand. It runs a smoke
test and then pushes both platforms. It writes each tag one time only. To
publish a changed build, change `MINIO_TAG` or add a suffix to it.

## Security

The upstream repositories are archived. No security fixes come from
upstream for this version. Do not expose this image to the internet
without a separate risk decision.

## Licence

MinIO and mc use the GNU Affero General Public License v3.0. The image
contains the upstream `LICENSE` and `CREDITS` files in `/licenses`. The
corresponding source is the upstream tags in the table above, built by
the `Dockerfile` in this repository without changes.
