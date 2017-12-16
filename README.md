# Specify 7 in Docker

## Purpose

Dockerized version of [Specify 7](https://github.com/specify/specify7).
This will not install any database for Specify, so you need to have a running Specify 6 instance in order to be able to run Specify 7 on top of the existing database. This is because Specify 7 is no standalone upgrade of Specify 7, but a complementary web interface of the Specify 6 desktop application.

## Installation

- If you have no Specify6 running, you need to install it (see http://www.specifysoftware.org/join/download/)
- Clone this repository.
```
git clone https://github.com/MfN-Berlin/specify7-docker
```
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
    --publish 80:80 \
    --restart "always" \
    --volume "/absolute/path/to/cloned/repo/specify6_thick_client:/usr/local/specify6" \
    --volume "/absolute/path/to/cloned/repo/specify7_config:/usr/local/specify_config" \
    specify7:latest
```

- Maybe you need to change the owner of the mounted volume and restart the container
```
docker exec -it specify7 chown -R root.specify /usr/local/specify6
docker restart specify7
```