# ManageEngine Password Manager Pro

![GitHub Actions CI](https://github.com/post-luxembourg/docker-pmp/workflows/GitHub%20Actions%20CI/badge.svg)

## Setup

1. Copy and edit the db config:

```bash
cp postgres.env.sample postgres.env
vim postgres.env
```

2. Run

```bash
docker-compose up
```

## Build

### GitHub Actions

To manually trigger a GitHub Actions:

1. Create a GitHub Personal Access Token and store it in `.envrc`:

```bash
echo "GITHUB_PERSONAL_ACCESS_TOKEN=$TOKEN" > .envrc
```

2. Execute:

```bash
./gh-actions-trigger-build.sh
```

### Locally

#### With docker buildx (recommended)

```bash
./buildx.sh
```

#### Without docker buildx (NOT recommended)

Please note that there is **no multiarch** support using this method.

```bash
./build.sh
```

## Similar projects

- https://github.com/babim/docker-me-pmp
- https://github.com/babim/docker-tag-options/tree/master/z%20ManageEngine
