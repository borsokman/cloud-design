resource "aws_efs_file_system" "db_storage" {
  creation_token = "microservices-db-storage"
  encrypted      = true # Security best practice
}

resource "aws_efs_mount_target" "db_storage_mt_1" {
  file_system_id  = aws_efs_file_system.db_storage.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.internal_sg.id]
}

resource "aws_efs_mount_target" "db_storage_mt_2" {
  file_system_id  = aws_efs_file_system.db_storage.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.internal_sg.id]
}