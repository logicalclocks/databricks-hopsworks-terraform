terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
  }
}

variable "artifact_location" {
  default = "/hopsworks/10.224.156.127/"
}

variable "metastore_uri" {
  default = "thrift://10.224.156.127:9083"
}

variable "cluster_name" {
  default = "fabio"
}

variable "jar_libraries" {
  type = map(string)
  default = {
    hsfs = "dbfs:///hopsworks/10.224.156.127/hsfs-spark-3.4.2-RC0.jar"
    hopsfs_client = "dbfs:///hopsworks/10.224.156.127/hopsfs-client-3.2.0.5-EE-SNAPSHOT.jar"
    hopsfs_client_api = "dbfs:///hopsworks/10.224.156.127/hopsfs-client-api-3.2.0.5-EE-SNAPSHOT.jar" 
    hudi = "dbfs:///hopsworks/10.224.156.127/hudi-spark3.3-bundle_2.12-0.12.3.1.jar"
  }
}

variable "credentials" {
  type = map(string)
  default = {
    keystore = "/dbfs/hopsworks/10.224.156.127/dbint__fabiolca/dbint__fabiolca__kstore.jks"
    truststore = "/dbfs/hopsworks/10.224.156.127/dbint__fabiolca/dbint__fabiolca__tstore.jks"
    passwd = "/dbfs/hopsworks/10.224.156.127/dbint__fabiolca/dbint__fabiolca__cert.key"
  }
}

data "databricks_node_type" "smallest" {
  category = "General Purpose"  
  local_disk = "true" 
}

data "databricks_spark_version" "ver" {
    spark_version = "3.3.2"
}

## Configure the cluster
resource "databricks_cluster" "this" {
  cluster_name            = var.cluster_name
  node_type_id            = data.databricks_node_type.smallest.id
  spark_version           = data.databricks_spark_version.ver.id
  autotermination_minutes = 30 
  num_workers             = 1 
  data_security_mode      = "SINGLE_USER"
  spark_conf = {
    "spark.hadoop.hops.ssl.trustore.name": var.credentials.truststore,
    "spark.hadoop.hops.ssl.keystore.name": var.credentials.keystore,
    "spark.hadoop.hops.ssl.keystores.passwd.name": var.credentials.passwd,
    "spark.hadoop.hops.rpc.socket.factory.class.default": "io.hops.hadoop.shaded.org.apache.hadoop.net.HopsSSLSocketFactory",
    "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
    "spark.hadoop.hops.ssl.hostname.verifier": "ALLOW_ALL",
    "spark.hadoop.fs.hopsfs.impl": "io.hops.hopsfs.client.HopsFileSystem",
    "spark.hadoop.hops.ipc.server.ssl.enabled": "true",
    "spark.sql.hive.metastore.jars": "/hopsworks_metastore_jar/lib/*",
    "spark.hadoop.client.rpc.ssl.enabled.protocol": "TLSv1.2",
    "spark.hadoop.hive.metastore.uris": var.metastore_uri 
  }
  init_scripts {
    dbfs {
      destination = "dbfs://${var.artifact_location}dbint__fabiolca/initScript.sh"
    }
  }
}

## Install the libraries to read/write from Hopsworks
resource "databricks_library" "cli" {
  cluster_id = databricks_cluster.this.id 
  pypi {
    package = "hopsworks"
  }
}

resource "databricks_library" "app" {
  for_each = var.jar_libraries
  cluster_id = databricks_cluster.this.id
  jar        = each.value 
}


