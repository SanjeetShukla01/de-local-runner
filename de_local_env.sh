#!/bin/bash

AIRFLOW_VERSION=2_8
DOCKER_COMPOSE_PROJECT_NAME=airflow-local-runner-$AIRFLOW_VERSION

display_help() {
   # Display Help
   echo "======================================"
   echo "   Airflow Local Runner CLI"
   echo "======================================"
   echo "Syntax: airflow-local-runner [command]"
   echo "Airflow version $AIRFLOW_VERSION"
   echo "---commands---"
   echo "help                   Print CLI help"
   echo "generate-ssh-key       Generate ssh key in root directory"
   echo "build-image            Build Image Locally"
   echo "reset-db               Reset local PostgresDB container."
   echo "start                  Start Airflow local environment. (LocalExecutor, Using postgres DB)"
   echo "test-requirements      Install requirements on an ephemeral instance of the container."
   echo "package-requirements   Download requirements WHL files into plugins folder."
   echo "test-startup-script    Execute shell script on an ephemeral instance of the container."
   echo "validate-prereqs       Validate pre-reqs installed (docker, docker-compose, python3, pip3)"
   echo
}

validate_prereqs() {
   docker -v >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "'docker' is not installed or not runnable without sudo. \xE2\x9D\x8C"
   else
      echo -e "Docker is Installed. \xE2\x9C\x94"
   fi

   docker-compose -v >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "'docker-compose' is not installed. \xE2\x9D\x8C"
   else
      echo -e "Docker compose is Installed. \xE2\x9C\x94"
   fi

   python3 --version >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "Python3 is not installed. \xE2\x9D\x8C"
   else
      echo -e "Python3 is Installed \xE2\x9C\x94"
   fi

   pip3 --version >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "Pip3 is not installed. \xE2\x9D\x8C"
   else
      echo -e "Pip3 is Installed. \xE2\x9C\x94"
   fi
}

generate_ssh_key(){
  rm -rf "./docker/id_rsa" && ssh-keygen -t rsa -C "codexecutor@gmail.com" -f "./docker/id_rsa" -P "" -q
}

build_image() {
    cp $BASE_DIR/my-common-python/setup.py ./docker
    cp $BASE_DIR/*.jar ./docker
    docker build --rm --compress -t edgenode:latest ./docker -f ./docker/edgenode.Dockerfile \
    --build-arg MY_JOB_ENVIRONMENT=$MY_JOB_ENVIRONMENT \
    --build-arg SAVE_TEMP_TABLE=$SAVE_TEMP_TABLE \
    --build-arg MY_SNOWFLAKE_WAREHOUSE_OVERRIDE=$MY_SNOWFLAKE_WAREHOUSE_OVERRIDE \
    --build-arg MY_SNOWFLAKE_DATABASE_OVERRIDE=$MY_SNOWFLAKE_DATABASE_OVERRIDE \
    --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    --build-arg AWS_CLI_DOWNLOAD_PATH=$AWS_CLI_DOWNLOAD_PATH \
    --build-arg S3_TO_DATAWAREHOUSE=$S3_TO_DATAWAREHOUSE_JAR
   docker build --rm --compress -t airflow-dev:$AIRFLOW_VERSION ./docker -f ./docker/airflow.Dockerfile
   docker build --rm --compress -t spark1n:latest ./docker -f ./docker/spark.Dockerfile
}

case "$1" in
validate-prereqs)
   validate_prereqs
   ;;
test-requirements)
   BUILT_IMAGE=$(docker images -q airflow-dev:$AIRFLOW_VERSION)
   if [[ -n "$BUILT_IMAGE" ]]; then
     echo "Container airflow-dev:$AIRFLOW_VERSION exists. Skipping build"
   else
     echo "Container airflow-dev:$AIRFLOW_VERSION not built. Building locally."
     build_image
   fi
   docker run -v $(pwd)/dags:/usr/local/airflow/dags -v $(pwd)/plugins:/usr/local/airflow/plugins -v $(pwd)/requirements:/usr/local/airflow/requirements -it airflow-dev:$AIRFLOW_VERSION test-requirements
   ;;
test-startup-script)
   BUILT_IMAGE=$(docker images -q airflow-dev:$AIRFLOW_VERSION)
   if [[ -n "$BUILT_IMAGE" ]]; then
      echo "Container airflow-dev:$AIRFLOW_VERSION exists. Skipping build"
   else
      echo "Container airflow-dev:$AIRFLOW_VERSION not built. Building locally."
      build_image
   fi
   docker run -v $(pwd)/startup_script:/usr/local/airflow/startup -it airflow-dev:$AIRFLOW_VERSION test-startup-script
   ;;
package-requirements)
   BUILT_IMAGE=$(docker images -q airflow-dev:$AIRFLOW_VERSION)
   if [[ -n "$BUILT_IMAGE" ]]; then
     echo "Container airflow-dev:$AIRFLOW_VERSION exists. Skipping build"
   else
     echo "Container airflow-dev:$AIRFLOW_VERSION not built. Building locally."
     build_image
   fi
   docker run -v $(pwd)/dags:/usr/local/airflow/dags -v $(pwd)/plugins:/usr/local/airflow/plugins -v $(pwd)/requirements:/usr/local/airflow/requirements -it airflow-dev:$AIRFLOW_VERSION package-requirements
   ;;
build-image)
   build_image
   ;;
generate-ssh-key)
  generate_ssh_key
  ;;
reset-db)
   docker-compose -p $DOCKER_COMPOSE_PROJECT_NAME -f ./docker/docker-compose-resetdb.yml up --abort-on-container-exit
   ;;
start)
   docker-compose -p $DOCKER_COMPOSE_PROJECT_NAME -f ./docker/docker-compose-local.yml up
   ;;
help)
   display_help
   ;;
*)
   echo "No command specified, displaying help"
   display_help
   ;;
esac