# ---------- General -------------

# ローカル開発環境立ち上げ
start:
	docker-compose up -d

# ローカル開発環境停止
stop:
	docker-compose down

# ---------- aliases -------------
exec-terraform=docker-compose exec terraform terraform
cluster-name=terraform-eks-sample

# ---------- terraform -------------

# terraformを初期化する(最初に打つ必要あり)
terraform-init: start
	$(exec-terraform) init

# terraform planを実行する
terraform-plan: terraform-init
	$(exec-terraform) plan

# terraform planを実行する
# stateを更新せずlockも取らないので雑に/頻繁に実行できる
terraform-check:
	$(exec-terraform) plan -refresh=false -lock=false

# terraform applyする
# 開発の都合上用意しているが、ローカルからのapplyは特に本番環境の場合は非推奨なので注意
# (CI経由でなくローカルから直接デプロイがイケてないのと一緒)
terraform-apply: terraform-init
	$(exec-terraform) apply

# ---------- EKS -------------

# kubecltをEKSに向ける
eks-kubeconfig:
	aws eks update-kubeconfig --name $(cluster-name) --profile eks

# worker nodeをクラスタに参加させる
eks-register-workers: terraform-init eks-kubeconfig
	$(exec-terraform) output config_map_aws_auth | kubectl apply -f -

# worker nodeを落とす
eks-delete-workers:
	aws autoscaling set-desired-capacity --auto-scaling-group-name $(cluster-name) --desired-capacity 0

# EKSを削除する(開発用)
eks-delete:
	aws eks delete-cluster --name $(cluster-name)

# ---------- App ------------

# テストを実行する(事前に`make start`を打っておくこと)
app-test: start
	docker-compose exec app go test -v ./...

# ファイルが変更された時にテストをまわす
# entrが入ってない場合は`brew install entr`
app-watch: start
	find app -name '*.go' | entr make app-test

# serverを起動する、Port 8080でlistenしている
app-server-start: start
	docker-compose exec app go run ./...

# ---------- Utilities -------------

# .circleci/config.ymlをチェックする、config.ymlをイジった後打つと捗る
circleci-validate:
	circleci config validate

# ALBの削除
alb-delete:
	aws elbv2 delete-load-balancer --load-balancer-arn $$(aws elbv2 describe-load-balancers | jq -r '.LoadBalancers | map(select(.LoadBalancerName=="eks-sample"))[0].LoadBalancerArn')

# ALBのDNS名の取得
# 使用例 `curl $(make -s alb-endpoint)/test`
alb-endpoint:
	aws elbv2 describe-load-balancers | jq -r '.LoadBalancers | map(select(.LoadBalancerName=="eks-sample"))[0].DNSName'

# 負荷試験(Autoscalerの挙動確認用)
stress-start:
	kubectl run stress --image=bash:5.0.7 -n=staging -- bash -c 'for i in $$(seq 1 20); do (while true; do wget -O /dev/null sample/slow; done) & done; sleep 3600'
stress-stop:
	kubectl delete deployments.app stress
