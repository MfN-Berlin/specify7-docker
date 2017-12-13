# Specify 7 in Docker

## Purpose

Dockerized version of [Specify 7](https://github.com/specify/specify7)


## Installation

- Clone this repository.
- Copy your Specify 6 client into the directory ```specify6_thick_client```, because Specify 7 is based on Specify 6 (all your forms and individual configurations will be preserved
- Rename ```example.local_specify_settings.py``` to ```local_specify_settings.py``` (see directory specify_config)
- Add your database connection details in ```local_specify_settings.py``` (you will find additional details as comments in the file itself)

- Build the Docker image
```
cd /your/path/to/cloned/repo/
docker build ./ --tag=specify7:latest
```

- Run the docker container
```
docker run -d  \
    --name "specify7" \
    --port 80:80 
    --volume "/your/path/to/cloned/repo/specify6_thick_client:/usr/local/specify6"
    --volume "/your/path/to/cloned/repo/specify7_config:/usr/local/specify_config"
    specify7:latest
```