#!/bin/sh
sleep 10
tar -xf /dbfs/hopsworks/10.224.156.127/apache-hive-*-bin.tar.gz -C /tmp
mv -f /tmp/apache-hive-*-bin /hopsworks_metastore_jar
