# Cloud Build branch-based caching

This repository contains a [Google Cloud Build](https://github.com/apps/google-cloud-build) configuration file ([`cloudbuild.yaml`](./cloudbuild.yaml)) that you can drop into your repository to speed up Docker builds by leveraging Google Container Registry as a remote build cache.

### How it works

Docker's local experience includes a delightful "incremental build" feature, wherein a well-crafted Dockerfile doesn't have to be rebuilt from scratch each time if only certain parts of a repository change. To accomplsih this, Docker uses the layers from images you've previously built as a "build cache" that it refers to in the course performing builds. You may recall seeing something like this the output of `docker build` commands:

```
Step 4/6 : RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*
---> Using cache
---> 6f6ccb9df263
```

The `Using cache` line means that Docker has found a layer in its cache that it can re-use instead of performing that operation. From Docker's [docs](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache) on this topic:

> When building an image, Docker steps through the instructions in your Dockerfile, executing each in the order specified. As each instruction is examined, Docker looks for an existing image in its cache that it can reuse, rather than creating a new (duplicate) image.

That's rad!

#### How this config uses GCR as a remote build cache

On each push to a branch:

1. Cloud Build will pull images tagged with `master` and `$BRANCH` from your GCP Project's Container Registry, ignoring failures.
1. Cloud Build will attempt to build an image using the `Dockerfile` in your repository, passing the names of the images from step one to the `--cache-from` argument on `docker build`. Layers from these images are reused if possible rather than executing the `RUN`, `ADD`, or `COPY` command in your Dockerfile.
1. Cloud Build pushes the image built in step two to GCR, tagged with `$BRANCH` so that subsequent pushes can re-use it in step one.

Here are some example PRs that show how it works in practice!

* [#2](https://github.com/urcomputeringpal/cloudbuild-branch-based-caching/pull/2) updates [`run.sh`](./run.sh), a file used in at the very end of our [`Dockerfile`](./Dockerfile). Much of the build is cached as a result.
* [#3](https://github.com/urcomputeringpal/cloudbuild-branch-based-caching/pull/2) updates [`README.md`](./README.md), a file used early on in our [`Dockerfile`](./Dockerfile). All steps after the one involving the readme are invalidated, resulting in most of the build steps being executed again.
* [#3 (comment)](https://github.com/urcomputeringpal/cloudbuild-branch-based-caching/pull/3#issuecomment-416950408) demonstrates how a subsequent change made on the branch for [#3](https://github.com/urcomputeringpal/cloudbuild-branch-based-caching/pull/2) uses a branch-specific image for its build cache to avoid re-evaluating the steps that differ between it and `master` each time.

## TODO

- GC state images?
