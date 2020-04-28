variable "name" {
  type = "string"
}

# ECSクラスタ
# ホストサーバーを束ねるリソース
# ECSサービスの大元
resource "aws_ecs_cluster" "this" {
  name = var.name
}

output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}
