#!/bin/bash
set -euo pipefail

echo Running startup script...
export password="${password}"
export nodeCount="${nodeCount}"
export goog_cm_deployment_name="${goog_cm_deployment_name}"

echo "Installing Graph Database..."
rpm --import https://debian.neo4j.com/neotechnology.gpg.key
echo "[neo4j]
name=Neo4j RPM Repository
baseurl=https://yum.neo4j.com/stable/latest
enabled=1
gpgcheck=1" > /etc/yum.repos.d/neo4j.repo
export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
yum -y install neo4j-enterprise

echo "Configuring network in neo4j.conf..."

EXTERNALIP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

sed -i "s/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g" /etc/neo4j/neo4j.conf
sed -i "s/#server.default_advertised_address=localhost/server.default_advertised_address=$EXTERNALIP/g" /etc/neo4j/neo4j.conf
sed -i "s/#server.bolt.listen_address=:7687/server.bolt.listen_address=0.0.0.0:7687/g" /etc/neo4j/neo4j.conf
sed -i "s/#server.bolt.advertised_address=:7687/server.bolt.advertised_address=$EXTERNALIP:7687/g" /etc/neo4j/neo4j.conf
sed -i "s/#server.http.listen_address=:7474/server.http.listen_address=0.0.0.0:7474/g" /etc/neo4j/neo4j.conf
sed -i "s/#server.http.advertised_address=:7474/server.http.advertised_address=$EXTERNALIP:7474/g" /etc/neo4j/neo4j.conf

if [[ $nodeCount == 1 ]]; then
  echo "Running on a single node."
else
  echo "Running on multiple nodes."
  sed -i "s/#initial.dbms.default_primaries_count=1/initial.dbms.default_primaries_count=3/g" /etc/neo4j/neo4j.conf

  INTERNALIP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

  sed -i "s/#server.cluster.listen_address=:6000/server.cluster.listen_address=0.0.0.0:6000/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.cluster.advertised_address=:6000/server.cluster.advertised_address=$INTERNALIP:6000/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.routing.listen_address=:7688/server.routing.listen_address=0.0.0.0:7688/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.routing.advertised_address=:7688/server.routing.advertised_address=$INTERNALIP:7688/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.cluster.raft.listen_address=:7000/server.cluster.raft.listen_address=0.0.0.0:7000/g" /etc/neo4j/neo4j.conf
  sed -i "s/#server.cluster.raft.advertised_address=:7000/server.cluster.raft.advertised_address=$INTERNALIP:7000/g" /etc/neo4j/neo4j.conf

  echo "Configuring membership in neo4j.conf..."

COREMEMBERS=""
goog_cm_deployment_name=neo4j-tf
nodeCount=3

for i in {0..$nodeCount}; do
  NODE_NAME="${goog_cm_deployment_name}-instance-$i"
  COREMEMBERS+="$NODE_NAME:6000,"
done

# Remove trailing comma from the list of core members
COREMEMBERS=$${COREMEMBERS::-1}
echo COREMEMBERS: $COREMEMBERS

  sed -i "s/#dbms.cluster.endpoints=localhost:6000,localhost:6001,localhost:6002/dbms.cluster.endpoints=$COREMEMBERS/g" /etc/neo4j/neo4j.conf
fi

echo "Starting Neo4j..."
neo4j-admin dbms set-initial-password "$password"

# The RPM creates this script which does OS checks that incorrectly fail on GC RH platform images.  Neo4j eng is working on a fix.
rm -f /etc/init.d/neo4j

systemctl enable neo4j
service neo4j start
