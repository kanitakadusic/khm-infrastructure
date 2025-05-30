resource "aws_ecs_cluster" "khm_ecs_cluster" {
  name = "khm_ecs_cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    "Name" = "khm_ecs_cluster"
  }
}

resource "aws_ecs_task_definition" "khm_ecs_task_definition_frontend" {
  container_definitions = jsonencode(
    [
      {
        command    = []
        cpu        = 256
        entryPoint = []
        environment = [
          {
            name  = "DB_NAME",
            value = "real_estate"
          },
          {
            name  = "DB_USER",
            value = var.db_user
          },
          {
            name  = "DB_PASSWORD",
            value = var.db_password
          },
          {
            name  = "DB_HOST",
            value = aws_instance.khm_server_private.private_ip
          },
          {
            name  = "DB_PORT",
            value = "3306"
          },
        ]
        essential   = true
        image       = "kkadusic2/real-estate-sales:latest"
        memory      = 512
        mountPoints = []
        name        = "nodejs-app"
        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          },
        ]
        volumesFrom = []
      },
    ]
  )
  execution_role_arn = data.aws_iam_role.lab_role.arn
  family             = "frontend-task"
  requires_compatibilities = [
    "EC2",
  ]
  task_role_arn = data.aws_iam_role.lab_role.arn

  placement_constraints {
    expression = "attribute:ecs.subnet-id in [${aws_subnet.khm_subnet_public.id}]"
    type       = "memberOf"
  }

  tags = {
    "Name" = "khm_ecs_task_definition_frontend"
  }
}

resource "aws_ecs_service" "khm_ecs_service_frontend" {
  cluster                            = aws_ecs_cluster.khm_ecs_cluster.id
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  name                               = "frontend-service"
  task_definition                    = aws_ecs_task_definition.khm_ecs_task_definition_frontend.arn
  depends_on = [
    aws_ecs_service.khm_ecs_service_database,
  ]

  tags = {
    "Name" = "khm_ecs_service_frontend"
  }
}

resource "aws_ecs_task_definition" "khm_ecs_task_definition_database" {
  container_definitions = jsonencode(
    [
      {
        command    = []
        cpu        = 256
        entryPoint = []
        environment = [
          {
            name  = "MYSQL_DATABASE"
            value = "real_estate"
          },
          {
            name  = "MYSQL_ROOT_PASSWORD"
            value = var.mysql_root_password
          },
        ]
        essential = true
        image     = "mysql:latest"
        memory    = 512
        mountPoints = [
          {
            sourceVolume  = "mysql-data"
            containerPath = "/var/lib/mysql"
            readOnly      = false
          },
        ]
        name = "mysql-db"
        portMappings = [
          {
            containerPort = 3306
            hostPort      = 3306
            protocol      = "tcp"
          },
        ]
        volumesFrom = []
      },
    ]
  )

  volume {
    name      = "mysql-data"
    host_path = "/mnt/mysql-data"
  }

  execution_role_arn = data.aws_iam_role.lab_role.arn
  family             = "database-task"
  requires_compatibilities = [
    "EC2",
  ]
  task_role_arn = data.aws_iam_role.lab_role.arn

  placement_constraints {
    expression = "attribute:ecs.subnet-id in [${aws_subnet.khm_subnet_private.id}]"
    type       = "memberOf"
  }

  tags = {
    "Name" = "khm_ecs_task_definition_database"
  }
}

resource "aws_ecs_service" "khm_ecs_service_database" {
  cluster                            = aws_ecs_cluster.khm_ecs_cluster.id
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  name                               = "database-service"
  task_definition                    = aws_ecs_task_definition.khm_ecs_task_definition_database.arn

  tags = {
    "Name" = "khm_ecs_service_database"
  }
}
