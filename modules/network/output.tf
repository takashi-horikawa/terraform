output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "subnets_a" {
  value = aws_subnet.subnets_a
}

output "subnets_c" {
  value = aws_subnet.subnets_c
}
