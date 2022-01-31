# ORCA Ubuntu16.04 5.0to5.1 Upgrade Install Script
# 
# J-Medic inc.
#
#

# 作業ディレクトリの設定
WORKDIR=$(cd $(dirname $0);pwd)
cd $WORKDIR
echo "作業ディレクトリ：${WORKDIR}で作業します"
rm .git
rm .gitignore

# 作業年月日変数設定
YMD=`date +%Y%m%d`

# ORCAデータベースバックアップ
BACKUPFILE="pg_orca${YMD}.dmp"
echo "ORCA DBのバックアップを行います"
sudo -u orca pg_dump -Fc orca > $BACKUPFILE 
echo "info: backup done ${$BACKUPFILE}"

# DBスキーマチェックスクリプト取得
echo "DBスキーマチェックスクリプトを取得して実行します"
wget http://ftp.orca.med.or.jp/pub/etc/jma-receipt-dbscmchk.tgz
tar xvzf jma-receipt-dbscmchk.tgz
cd jma-receipt-dbscmchk
sudo bash jma-receipt-dbscmchk.sh
cd $WORKDIR

# aptの5.0用設定を削除
sudo rm /etc/apt/sources.list.d/jma-receipt-xenial50.list
# aptに5.1用設定を追加
sudo wget -q -O /etc/apt/sources.list.d/jma-receipt-xenial51.list http://ftp.orca.med.or.jp/pub/ubuntu/jma-receipt-xenial51.list
sudo apt-get update
sudo apt-get dist-upgrade -dy
sudo apt-get install jma-receipt
sudo apt-get dist-upgrade

# DBのエンコードがUTF-8になっていることを確認
# DBのエンコードがUTF-8の場合は、DBエンコード指定を行う
ORCADBENCODING=$(sudo -u orca psql -l | grep -E 'Encoding|orca' | gawk 'BEGIN{FS="|"}$1 ~ /orca/{print $3}')
if [[ ${ORCADBENCODING} eq 'UTF-8' ]]; then
    echo 'DBENCODING="UTF-8"' | sudo tee /etc/jma-receipt/db.conf
fi

# センターサーバーによる特別処理
# 移行マニュアルには無いので注意
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

