EKS+Terraform+CircleCI+Goな構成のサンプルアプリ

[解説記事](https://qiita.com/sxarp/items/e93331169c5b76c75525)

# 構成図

![architecture diagram](https://user-images.githubusercontent.com/11193139/62509169-21c00f80-b845-11e9-87bd-6568c3d32b8c.png)

# Terraformセットアップ

## `.env`をセットアップ

```sh
$ cp .env.sample .env && cat .env
AWS_ACCESS_KEY_ID="Ask someone to get the ID."
AWS_SECRET_ACCESS_KEY="Ask someone to get the key."
```

## `terraform plan`の実行

```sh
$ make terraform-plan
```

# kubectlセットアップ

## AWS-CLIが正しく設定されていることを確認

クラスターが見えていることを確認

```sh
$ aws eks list-clusters
{
    "clusters": [
        "terraform-eks-sample"
    ]
}
```

以下が打てることを確認([参考](https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html))

```sh
$ aws eks get-token --cluster-name terraform-eks-sample
```

失敗したらaws-cliを更新

```sh
$ pip3 install awscli --upgrade --user
```

## kubecltをEKSに向ける

```sh
$ make eks-kubeconfig
aws eks update-kubeconfig --name terraform-eks-sample --profile eks
Updated context arn:aws:eks:ap-northeast-1:705180747189:cluster/terraform-eks-sample in /Users/hogehoge/.kube/config
```

このとき`eks`のprofileでクラスターを作成したユーザーのクレデンシャルが指定されていること([参考](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized))。

## kubectlが正しく設定されていることを確認

```sh
$ kubectl get namespaces
NAME          STATUS    AGE
default       Active    36m
kube-public   Active    36m
kube-system   Active    36m
```

# アプリの開発環境立ち上げ

## テストの実行

```sh
$ make app-test
```

## サーバーの起動
```sh
$ make app-server-start
```

# 動作確認

## Podが起動していること

```sh
kubectl get po -n staging --selector app=sample
NAME                      READY   STATUS    RESTARTS   AGE
sample-5cc67946db-6c5rn   1/1     Running   0          16m
sample-5cc67946db-nv9n5   1/1     Running   0          17m
```

## ALBからのHealthCheckが来ていること

```sh
$ kubectl logs -n staging --selector app=sample | tail -n 3
2019/08/04 12:57:10 /health
2019/08/04 12:57:52 /health
2019/08/04 12:58:22 /health
```

## ALB越しにリクエスト/レスポンスが通ること

```sh
$ curl $(make -s alb-endpoint)/test
Hello, test!%
```

## オートスケールが機能していること

### 負荷をかける前

Pod

```sh
$ kubectl top po -n staging
NAME                      CPU(cores)   MEMORY(bytes)
sample-5cc67946db-6c5rn   0m           1Mi
sample-5cc67946db-nv9n5   0m           1Mi
```

Node

```sh
$ kubectl top node
NAME                                              CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
ip-10-101-1-145.ap-northeast-1.compute.internal   39m          3%     420Mi           22%
```

### 負荷をかける

```sh
$ make stress-start
kubectl run stress --image=bash:5.0.7 -n=staging -- bash -c 'for i in $(seq 1 20); do (while true; do wget -O /dev/null sample/slow; done) & done; sleep 3600'
kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
deployment.apps/stress created
```

### 負荷をかけた後

Pod

```sh
$ kubectl top po -n staging
NAME                      CPU(cores)   MEMORY(bytes)
sample-5cc67946db-6c5rn   150m         1Mi
sample-5cc67946db-bkww5   84m          1Mi
sample-5cc67946db-g5g4b   0m           0Mi
sample-5cc67946db-jt6sp   150m         1Mi
sample-5cc67946db-mmjvl   107m         1Mi
sample-5cc67946db-n8xq4   21m          1Mi
sample-5cc67946db-nv9n5   75m          1Mi
stress-6c5c5c844c-lf69r   2m           7Mi
```
Node

```sh
$ kubectl top node
NAME                                              CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
ip-10-101-0-210.ap-northeast-1.compute.internal   508m         50%    360Mi           19%
ip-10-101-0-30.ap-northeast-1.compute.internal    756m         75%    351Mi           18%
ip-10-101-1-134.ap-northeast-1.compute.internal   642m         64%    366Mi           19%
ip-10-101-1-145.ap-northeast-1.compute.internal   328m         32%    457Mi           24%
```

# ディレクトリ構成

## terraform

Terraformのファイルが置かれている。
CIでこのディレクトリ全体が`cd terraform && terraform apply`される。

## k8s

- baseディレクトリはKustomizeのbase
- stagingディレクトリはbaseへのstaging環境の差分
- clusterはクラスターにkube-system配下にインストールされるマニフェストの置き場

## app
Golang製のアプリの置き場。
CI/CDに絡む部分だけで中身はほぼ空。

