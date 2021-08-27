# Microsoft Japan Digital Days 2021

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)

## About <a name = "about"></a>

このリポジトリは、Microsoft Japan Digital Days 2021 セッション M08 "あなたの知らないAzureインフラの世界" の検証環境構築コード、テストコード、結果データを公開しています。

## Getting Started <a name = "getting_started"></a>

以下3つの検証シナリオについて、コードと結果データを公開しています。

* [レイテンシ検証](./nw-latency)
* [VM起動時間検証](./vm-startup-time)
* [疑似障害注入検証](./nw-chaos)

### テスト済み環境

* Windows Sysbsystem for Linux
  * Ubuntu 20.04.3 LTS
  * VMへのsshとprovisioner向けに、キーペアを事前作成
    * ~/.ssh/id_rsa
    * ~/.ssh/id_rsa.pub
* Terraform: 1.0.5
  * hashicorp/azurerm: 2.73
* Packer: 1.7.4

### 検証手順と結果データ

#### レイテンシ検証

* [最上位ディレクトリで](./nw-latency)、Terraformのセットアップ(init)と環境構築(plan、apply)を行う
  * apply時に、各VMのパブリック/プライベートIPが標準出力へ出力される
* 任意のVMにsshし、[ethr](https://github.com/microsoft/ethr)コマンドでレイテンシを確認
  * 各VMの構成パラメータ: [locals.tf](./nw-latency/locals.tf) を参照
  * ユーザー名: [locals.tf](./nw-latency/locals.tf) を参照
  * ehtrはVMに[セットアップ済み](./nw-latency/init.sh)
  * 先にサーバー側を -s オプションで起動
  * クライアント側は -c <サーバーのプライベートIP> -t l -p tcp オプションで起動
  * 参考スクリプト: [scripts](./nw-latency/scripts)
* 結果データ: [results](./nw-latency/results)
* 検証後は削除(terraform destroy)を忘れずに

#### VM起動時間検証

* [最上位ディレクトリで](./vm-startup-time)、Terraformのセットアップ(init)を行う
* [imageディレクトリ](./vm-startup-time/image)でカスタムイメージを作成
  * Packerでイメージ作成
    * 参考定義ファイル: [ubuntu-vanilla.pkr.hcl](././vm-startup-time/image/packer/ubuntu-vanilla.pkr.hcl)
    * 変数 "subscription_id" を指定
  * Terraformで共有イメージギャラリーへ登録
    * 参考定義ファイル: [locals.tf](./vm-startup-time/image/terraform/locals.tf)
    * 変数 "publisher_name" を指定
* [scriptsディレクトリ](./vm-startup-time/scripts)で、[検証スクリプト](./vm-startup-time/scripts/test.sh)を編集、実行
  * 検証スクリプトの変数 "SERIES"に、シリーズ番号を指定
    * [results](./vm-startup-time/results)/シリーズ番号 ディレクトリに、結果データが出力される
    * すでに結果データがあるため、実行の際には既存の結果データを削除するか、他のシリーズ番号を指定
  * 変数 "NUM_ATTEMPT" で指定した回数だけ、Terraformで全VMの作成と削除が行われ、結果データが出力される
* 結果データ: [results](./vm-startup-time/results)

#### 疑似障害注入検証
* [最上位ディレクトリで](./nw-chaos)、Terraformのセットアップ(init)と環境構築(plan、apply)を行う
  * apply時に、各VMのパブリック/プライベートIPが標準出力へ出力される
* 任意のVMにsshし、ethrによるレイテンシ検証と疑似障害注入を行う
  * ethrの利用法はレイテンシ検証と同様
  * NSGルールの注入と削除は、[locals.tf](./nw-chaos/locals.tf) を編集し、applyする
    * Terraformの実行環境はssh先のVMではないので注意
  * TCサンプルスクリプト: [scripts](./nw-chaos/scripts)
    * VMセットアップ時にVMへコピーされている
    * qdisc設定のリセットは、[reset-qdisc.sh](./nw-chaos/scripts/reset-qdisc.sh)を参考に
  * [BPF Compiler Collection](https://github.com/iovisor/bcc)は[セットアップ済み](./nw-chaos/init.sh)
    * セットアップに数分かかるので注意
    * ツールは /usr/share/bcc/tools/ に配置
* 検証後は削除(terraform destroy)を忘れずに
