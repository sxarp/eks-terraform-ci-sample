EKS+Terraform+CircleCI+Goな構成のサンプルアプリ

[解説記事](TODO)

# 構成図

![arch](https://user-images.githubusercontent.com/11193139/62423067-79506500-b6f7-11e9-9ef5-fd5ac7a86e44.png)


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

