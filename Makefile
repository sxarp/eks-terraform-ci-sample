terraform-start:
	docker-compose up -d; docker-compose exec terraform terraform init

terraform-stop:
	docker-compose down

terraform-plan:
	docker-compose exec terraform terraform plan

# ローカルからのapplyは非推奨!!
terraform-apply:
	docker-compose exec terraform terraform apply
