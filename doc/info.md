Why do we need ssh, and ssh-keygen?


I have a docker container (c1) that has apache spark installed in it, I have another docker container (c2) that has pyspark code. How to run spark code from c2 into c1?

To run Spark code from one Docker container (c2) against an Apache Spark installation in another Docker container (c1), you'll need to ensure that the containers can communicate with each other and that the necessary configurations are set up. Here are the general steps:

Networking:

Make sure that both containers are on the same Docker network so that they can communicate with each other. You can create a user-defined bridge network for this purpose.
bash
Copy code
- Create a network

docker network create spark_network

- Run c1 on the spark_network
```bash
docker run --network=spark_network --name=c1 your_spark_image
```

# Run c2 on the spark_network
docker run --network=spark_network --name=c2 your_pyspark_image
Spark Configuration in c1:

Make sure that Spark in c1 is configured properly to accept external connections.
Check Spark's spark-defaults.conf or other configuration files for settings like SPARK_MASTER_HOST and make sure it's set to allow connections from outside the container.
Spark Submit in c2:

In the c2 container, use spark-submit to submit your PySpark application. When submitting, you need to specify the master URL to point to the Spark master in c1.
bash
Copy code
docker exec c2 spark-submit --master spark://c1:7077 your_pyspark_script.py
Here, c1 is the hostname of the Spark master container. The --master flag should point to the Spark master's URL, and your_pyspark_script.py is the entry point of your PySpark application.

Check Firewall Rules:

Ensure that there are no firewall rules or security groups preventing communication between the two containers. The necessary ports for Spark, such as 7077 for the master and 4040 for the web UI, should be accessible.
Troubleshooting:

If you encounter issues, check the logs of both containers for any error messages.
Ensure that Spark dependencies and configurations are correctly set up in c2.
Verify that the Spark master URL in spark-submit is correct.
Example spark-submit command in c2 assuming the Spark master is running on c1:

bash
Copy code
docker exec c2 spark-submit --master spark://c1:7077 your_pyspark_script.py
Replace your_pyspark_script.py with the actual entry point of your PySpark application.

Note: Make sure that both containers have the necessary dependencies installed and that the Spark versions are compatible between the Spark installation in c1 and the PySpark code in c2.



For Spark Cluster, it will need one more dockerfile for spark. 


### Link airflow dag repo with de Environment repo.
- Create link to dag and plugin folder.                     -- Done
- Install vim in executor node.                             -- Done
- Add log directory to store log on local machine.          -- Done


- set ssh connection between airflow and spark node
- Create connection to connect to Spark box.                --#TODO
- Find a way to deploy and run spark job through airflow.   --#TODO
- Add spark code to the setup                               --#TODO
  - `spark-submit --py-files target/spark_etl-0.0.1.zip etl/etl_job.py --job-name air_asia_data_job`
- Mount executor code to avoid creating python file.
- Schedule spark logs directory
- Separate code for spark and others. 


## Running Spark Job from Airflow:
1. Setup sample spark code to run.    -- WIP
   - Using pyspark-boilerplate repo for this. 
2. 



### Start writing airflow jobs
- Create a separate airflow repo
- Airflow repo will mount to this environment as links/mount
    - DAGS
    - Plugins
- Same airflow repo will contain DAGS and Common Code
- Work on version of spark and edgenode
    



### Start on SQL runner library
- The library will be separate from ETL code
- Add tests to the sql runner library 
- Should have all basic features:
  - Logging, Dry Run, Save Temp Table etc.





### Create ETL POC in rust