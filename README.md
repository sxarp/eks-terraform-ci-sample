# eks
EKS infrastructure

# terraform
- `.env`を`.env.sample`を参考にしながらセットアップしてください

`terraform plan`の実行

```sh
$ make terraform-plan`で`terraform plan
```

# k8s

kubectlが打てるように設定します。

クラスターが存在することを確認

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

以下を打ってkubectlの設定する([クラスターを作成したprofileが指定されていないと失敗するので注意](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized))

```sh
$ aws eks update-kubeconfig --name terraform-eks-sample --profile $USER_CREATED_CLUSTER
```

kubectlが正しく設定されていることを確認

```sh
$ kubectl get namespaces
NAME          STATUS    AGE
default       Active    36m
kube-public   Active    36m
kube-system   Active    36m
```

# app

テストの実行

```sh
$ make app-test
```

サーバーの起動
```sh
$ make app-server-start
```
