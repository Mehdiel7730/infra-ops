output "instance_id"        { value = aws_instance.app.id }
output "private_ip"         { value = aws_instance.app.private_ip }
output "public_ip"          { value = aws_eip.app.public_ip }
output "ami_id"             { value = aws_instance.app.ami }
