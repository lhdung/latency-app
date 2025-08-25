# Simple Development Environment Configuration

aws_region = "us-east-1"

# SSH Key - Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/latency-monitor
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCXR7GKbJ68aZGvSzweMY+d5UxHFf6cvaQOwPpKKhARWH0TjsSnTYu9Mu/JzzkbR/Bp3CEzZL3NJ36oegz2l5pYaFP3KsT1DmKbSlPPtBQTljhX5FW7fSt1d0QIEzO5dJPQb1mEpmocxROf1sZpYLix4I05m1NTKqqCbIRmnxAc6tJhr8Cvk233hFkga0Khbtn2EkJvZoneH0+Xc6IDOx0dOLw+Ds9WJiQxBveYClGWHQisEK/K6vM6l8sy1N+zJgCYlbn/QoxrqXXaFRh0OcfU1A1Hd3n/nQX73vTuy4IXb/r9+ZME9O8o5EH3P94e4TqZvDoWdeud2sry7qWBZ2VSAqz5lDsflSZBV9TSfP4PcnrUJLbtWB6e5z8mjnmTaTsCKR4fOOXwVbSxhdIA0g4HKD7P7aAyNlBQzg76h50KqG2maXL4+qRxh93gQc0QVKYT57784FAPjhobLyIwW3VjWuIYJi+IIjOMYncUVnoHt+sRMtDOFBe2pI8bDIymIiwCRDDQg4lvdqbtRoB5o+EteVBi9iwEj3z96y1iZtx4XY90gWei4EOq/DpEq7nB68NbJsSIE+rb3bKb7/mDpFlM/4gThlO/xiDTPnz0cGS6WedEwh8Yka9QfX3+EfEJxCPzoCv8Z0J8yFrF+qO8p3MyPN8vGXfKkvr02K5PsX0bww== Dung.LeH@VN-Mac-FLQKL40M9Y"

# Network Access
ssh_allowed_cidr = ["0.0.0.0/0"]

# Application
docker_image = "lhdung/latency-app:latest"

# Team Info
owner = "lhdung"
cost_center = "lhdung"