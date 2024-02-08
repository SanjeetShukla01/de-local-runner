# Image used on ec2 boxes: ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210223

FROM python:3.11.6
ENV PYTHONBUFFERED = 1

RUN apt-get update &&  \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/IST apt-get install -y netcat ssh iputils-ping sudo python3-pip dfault-jdk && \
    mkdir /var/run/sshd && \
    chmod 0755 /var/run/sshd && \
    ssh-keygen -A && \
    useradd -p $(openssl passwd codexecutoradmin) --create-home --shell /bin/bash --groups sudo codexecutor


# Make repository for your common python code if there (my-common-python)
RUN mkdir -p var/lib/my-python
RUN chown -R codexecutor /var/lib/my-common-python
RUN service ssh start

ARG MY_JOB_ENVIRONMENT=${MY_JOB_ENVIRONMENT}
ARG SAVE_TEMP_TABLE=${SAVE_TEMP_TABLE}
ARG MY_SNOWFLAKE_WAREHOUSE_OVERRIDE=${MY_SNOWFLAKE_WAREHOUSE_OVERRIDE}
ARG MY_SNOWFLAKE_DATABASE_OVERRIDE=${MY_SNOWFLAKE_DATABASE_OVERRIDE}
ARG AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ARG AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ARG AWS_CLI_DOWNLOAD_PATH=${AWS_CLI_DOWNLOAD_PATH}
ARG ADDITIOANL_JAR_PATH=${ADDITIOANL_JAR_PATH}
# Make directory for your etl code
RUN mkdir -p /usr/local/sf_data_pipeline && chown codexecutor:codexecutor /usr/local/sf_data_pipeline
RUN mkdir -p /usr/local/pyspark_pipeline && chown codexecutor:codexecutor /usr/local/pyspark_pipeline

USER codexecutor
RUN mkdir -p /home/codexecutor/environments
RUN mkdir /home/codexecutor/.ssh && chmod 700 /home/codexecutor/.ssh
RUN echo "export MY_JOB_ENVIRONMENT=$MY_JOB_ENVIRONMENT" > home/codexecutor/.bash_profile && \
    echo "export MY_SNOWFLAKE_WAREHOUSE_OVERRIDE=$MY_SNOWFLAKE_WAREHOUSE_OVERRIDE" >> home/codexecutor/.bash_profile && \
    echo "export MY_SNOWFLAKE_DATABASE_OVERRIDE=$MY_SNOWFLAKE_DATABASE_OVERRIDE" >> home/codexecutor/.bash_profile && \
    echo "export AWS_REGION=us-east-1" >> home/codexecutor/.bash_profile && \
    echo "export SAVE_TEMP_TABLES=$SAVE_TEMP_TABLES" >> home/codexecutor/.bash_profile && \
    mkdir -p /home/codexecutor/.aws && \
    echo "[default]" >> /home/codexecutor/.aws/credentials && \
    echo "AWS_ACCESS_KEY=$AWS_ACCESS_KEY" >> /home/codexecutor/.aws/credentials && \
    echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /home/codexecutor/.aws/credentials && \
    echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> /home/codexecutor/.aws/credentials \
# Copy common python setup.py to environments
COPY setup.py /home/codexecutor/environments
COPY /var/lib/my-common-python/sf-data-pipeline/requirements.txt /home/codexecutor/environments
COPY aws_config /home/codexecutor/.aws/config
COPY --chown=codexecutor:codexecutor id_rsa.pub /home/codexecutor/.ssh/authorized_keys
RUN chmod 600 /home/codexecutor/.ssh/authorized_keys && \
    pip3 install virtualenv && \
    /home/codexecutor/.local/bin/virtualenv /home/codexecutor/environments/my-virtualenv-python3_11 && \
    pip3 install /home/codexecutor/environments && \
    pip3 install /home/codexecutor/environments/requirements.txt
COPY *.jar /usr/local/sf_data_pipeline

USER root
EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]