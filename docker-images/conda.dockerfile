ARG CONDA_VERSION=4.9.2
ARG PYTHON_VERSION=3.7

FROM continuumio/miniconda3:$CONDA_VERSION

ARG PYTHON_VERSION
ARG CONDA_VERSION

LABEL maintainer="Landung Setiawan <landungs@uw.edu>"

ENV CONDA_DIR /opt/conda

RUN echo "### ARGS info ###" \
    && echo "# Python version: $PYTHON_VERSION" \
    && echo "# Conda version: $CONDA_VERSION" \
    && echo "######################"

RUN ${CONDA_DIR}/bin/conda install -c conda-forge \
    python=$PYTHON_VERSION \
    hypercorn \
    mamba \
    && ${CONDA_DIR}/bin/mamba clean -afy \
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
    && find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete

COPY ./start.sh /start.sh
RUN chmod +x /start.sh

COPY ./hypercorn_conf.py /hypercorn_conf.py

COPY ./start-reload.sh /start-reload.sh
RUN chmod +x /start-reload.sh

COPY ./app /app
WORKDIR /app/

ENV PYTHONPATH=/app

EXPOSE 80

# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Hypercorn
CMD ["/start.sh"]

# Only run these if used as a base image
# ----------------------
ONBUILD COPY . /tmp

ONBUILD RUN echo "Checking for 'app' folder" \
        ; if [ -d /tmp/app ] ; then \
        echo "Moving app" && rm -rf /app && mv /tmp/app /app \
        ; else \
        echo "Using default app" \
        ; fi

ONBUILD RUN echo "Checking for 'environment.yaml' file" \
        ; if [ -f /tmp/environment.yaml ] ; then \
        echo "Updating conda environment" \
        && ${CONDA_DIR}/bin/mamba env update --file /tmp/environment.yaml --name base \
        ; else \
        echo "Using default environment" \
        ; fi