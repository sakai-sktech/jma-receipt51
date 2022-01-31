# ORCA移行手順書 5.0->5.1

## Ubuntu 16.04環境での移行手順

2021.9.30でVer5.0のサポートは終了しています。

## 移行手順

# ORCA Ubuntu16.04 5.0to5.1 Upgrade Install Script
# 
# J-Medic inc.
#
#

### 作業環境の設定
ORCA作業用のユーザーとして`ormaster`が登録されているものとして進めます。
```shell
# 作業ディレクトリ設定
WORKDIR=/home/ormaster/tmp
if [[ ! -d $WORKDIR ]]; then
  mkdir $WORKDIR
fi
cd $WORKDIR

# 作業年月日変数設定
YMD=`date +%Y%m%d`

# ORCAデータベースバックアップ
sudo -u orca pg_dump -Fc orca > pg_orca${YMD}.dmp
```

### DBスキーマチェック
```shell
wget http://ftp.orca.med.or.jp/pub/etc/jma-receipt-dbscmchk.tgz
tar xvzf jma-receipt-dbscmchk.tgz
cd jma-receipt-dbscmchk
sudo bash jma-receipt-dbscmchk.sh
cd $WORKDIR
```

### パッケージ更新用の設定変更とパッケージ更新
```shell
# aptの5.0用設定を削除
sudo rm /etc/apt/sources.list.d/jma-receipt-xenial50.list
# aptに5.1用設定を追加
sudo wget -q -O /etc/apt/sources.list.d/jma-receipt-xenial51.list http://ftp.orca.med.or.jp/pub/ubuntu/jma-receipt-xenial51.list
sudo apt-get update
sudo apt-get dist-upgrade -dy
sudo apt-get install jma-receipt
sudo apt-get dist-upgrade
```

### DB構造変更処理
DBエンコードの確認
```
# DBのエンコードがUTF-8になっているかどうかを確認
sudo -u orca psql -l | grep -E 'Encoding|orca'
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
 orca      | orca     | UTF8     | C           | C           |

# UTF-8の設定ファイルがあるかどうか確認
sudo cat /etc/jma-receipt/db.conf 
```

上記の確認をして、UTF-8なら設定ファイルを作成するスクリプト
```
ORCADBENCODING=$(sudo -u orca psql -l | grep -E 'Encoding|orca' | gawk 'BEGIN{FS="|"}$1 ~ /orca/{print $3}')

if [[ ${ORCADBENCODING} eq 'UTF-8' ]]; then
  echo 'DBENCODING="UTF-8"' | sudo tee /etc/jma-receipt/db.conf.test
fi
```

```
# センターサーバーによる特別処理
wget http://ftp.orca.med.or.jp/pub/etc/install_modules_for_ftp.tgz 
tar xvzf install_modules_for_ftp.tgz
cd install_modules_for_ftp
sudo -u orca ./install_modules.sh
cd $WORKDIR

# jma-setup実行
sudo jma-setup

# ormaster@ubuntu:~/tmp$ sudo jma-setup
# DBHOST:		OK (PostgreSQL:localhost)
# DBUSER:		OK (orca)
# DATABASE:	OK (orca)
# DBENCODING:	OK (UTF-8)
# DBKANRI		OK (tbl_dbkanri)
# UPDATE CHECK:	OK (online)
# DBLIST:		OK (050100-1)
# LIST DOWNLOAD:	FILE (59)
# DOWNLOAD:	...........................................................OK
# EXTRACT:	...........................................................OK
# UPDATE:	...........................................................OK
# DBVERSION:	OK (0501001)
# データベース構造変更処理は終了しました
```

ここまでで、データベース構造変更処理は完了


