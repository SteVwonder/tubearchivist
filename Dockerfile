# build the tube archivist image from default python slim image

FROM python:3.9.7-slim-bullseye

ENV PYTHONUNBUFFERED 1

# install distro packages needed
RUN apt-get clean && apt-get -y update && apt-get -y install --no-install-recommends \
    build-essential \
    nginx \
    curl && rm -rf /var/lib/apt/lists/*

# get newes patched ffmpeg and ffprobe builds
RUN curl -s https://api.github.com/repos/yt-dlp/FFmpeg-Builds/releases/autobuild-2021-09-28-12-38 \
    | grep browser_download_url \
    | grep linux64 \
    | grep ffmpeg-n \
    | cut -d '"' -f 4 \
    | xargs curl -L --output ffmpeg.tar.xz && \
    tar -xf ffmpeg.tar.xz --strip-components=2 --no-anchored -C /usr/bin/ "ffmpeg" && \
    tar -xf ffmpeg.tar.xz --strip-components=2 --no-anchored -C /usr/bin/ "ffprobe" && \
    rm ffmpeg.tar.xz

# copy config files
COPY nginx.conf /etc/nginx/conf.d/

# make folders
RUN mkdir /cache
RUN mkdir /youtube
RUN mkdir /app

# install python dependencies
COPY ./tubearchivist/requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r requirements.txt --src /usr/local/src

# copy application into container
COPY ./tubearchivist /app
COPY ./run.sh /app
COPY ./uwsgi.ini /app

# volumes
VOLUME /cache
VOLUME /youtube

# start
WORKDIR /app
EXPOSE 8000

RUN chmod +x ./run.sh

CMD ["./run.sh"]
