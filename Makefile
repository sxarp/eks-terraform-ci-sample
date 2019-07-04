terraform-start:
	docker-compose up -d; docker-compose exec terraform terraform init

terraform-stop:
	docker-compose down

terraform-plan:
	docker-compose exec terraform terraform plan -lock=false

terraform-init:
	docker-compose exec terraform terraform init

# ローカルからのapplyは非推奨!!
terraform-apply:
	docker-compose exec terraform terraform apply

eks-kubeconfig:
	aws eks update-kubeconfig --name terraform-eks-sample --profile eks

eks-delete:
	aws eks delete-cluster --name terraform-eks-sample

eks-register-workers:
	docker-compose exec terraform terraform output config_map_aws_auth | kubectl apply -f -

eks-delete-workers:
	aws autoscaling set-desired-capacity --auto-scaling-group-name terraform-eks-sample --desired-capacity 0

circleci-validate:
	circleci config validate
