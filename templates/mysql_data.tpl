#!/bin/bash

echo "Creating MySQL data directory"
mkdir -p /mnt/mysql-data
chown -R mysql:mysql /mnt/mysql-data
chmod 700 /mnt/mysql-data

echo "Configuring ECS agent"
cat <<'EOF' | sudo tee /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance
EOF