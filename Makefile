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
terraform-init:
	$(exec-terraform) init

# terraform planを実行する
# -lock=falseな理由は、CIのplanとぶつかると邪魔くさいため(どうせCIでplanは確認するので問題ない)
terraform-plan:
	$(exec-terraform) plan -lock=false

# terraform applyする
# 開発の都合上用意しているが、ローカルからのapplyは特に本番環境の場合は非推奨なので注意
# (CI経由でなくローカルから直接デプロイがイケてないのと一緒)
terraform-apply:
	$(exec-terraform) apply

# ---------- EKS -------------

# kubecltをEKSに向ける
eks-kubeconfig:
	aws eks update-kubeconfig --name $(cluster-name) --profile eks

# worker nodeをクラスタに参加させる
eks-register-workers:
	$(exec-terraform) output config_map_aws_auth | kubectl apply -f -

# worker nodeを落とす
eks-delete-workers:
	aws autoscaling set-desired-capacity --auto-scaling-group-name $(cluster-name) --desired-capacity 0

# EKSを削除する(開発用)
eks-delete:
	aws eks delete-cluster --name $(cluster-name)

# ---------- App ------------

# テストを実行する(事前に`make start`を打っておくこと)
app-test:
	docker-compose exec app go test -v ./...

# ファイルが変更された時にテストをまわす
# entrが入ってない場合は`brew install entr`
app-watch:
	find app -name '*.go' | entr make app-test

# serverを起動する、Port 8080でlistenしている
app-server-start:
	docker-compose exec app go run ./...

# ---------- Utilities -------------

# .circleci/config.ymlをチェックする、config.ymlをイジった後打つと捗る
circleci-validate:
	circleci config validate
