# Evmos on AKT

## Build

```sh
docker buildx build --platform linux/amd64,linux/arm64 --push -t elhachon/evmos-on-akash:v6.0.1-r4-fullindex .
```

## Usage

```sh
docker pull elhachon/evmos-on-akash
# or
git clone https://github.com/hanchon-live/evmos-on-akash.git
cd evmos-on-akash
docker-compose up
```
