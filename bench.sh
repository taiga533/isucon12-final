#!/bin/bash
set -eu -o pipefail

# デプロイ先のサーバーを定義する
servers=("isucon12-1" "isucon12-2" "isucon12-3" "isucon12-4" "isucon12-5")

# ユーザー
user="isucon"


echo 'ろぐろーてーと'
for s in ${servers[@]} ;do
  echo $s
  ssh $user@$s 'sudo logrotate -f /etc/logrotate.d/nginx'
  ssh $user@$s 'sudo logrotate -f /etc/logrotate.d/mysql-server'
done

echo 'pprof仕掛ける'
ssh isucon12-1 -N -L 8081:127.0.0.1:8080 &
tunnel_pid=$!
sleep 3
go tool pprof -http=":8082" -seconds 150 http://127.0.0.1:8081/debug/pprof/profile &
pprof_pid=$!


echo
echo 'ベンチマークを実行してください。2分半後にログとプロファイル結果の収集が行われます'

sleep 155

echo 'ろぐかいしゅう'
mkdir -p bench_log/nginx
mkdir -p bench_log/mysql

for s in ${servers[@]} ;do
  echo $s
  ssh $user@$s 'sudo chmod 0755 /var/log/nginx/'
  ssh $user@$s 'sudo chmod 0755 /var/log/mysql/'
  ssh $user@$s 'sudo chmod 0644 /var/log/nginx/*'
  ssh $user@$s 'sudo chmod 0644 /var/log/mysql/*'
  scp $user@$s:/var/log/nginx/access.log bench_log/nginx/$s.log
  scp $user@$s:/var/log/mysql/slow_query.log bench_log/mysql/$s.log || true
done

kill $tunnel_pid
echo 'すべて完了しました！'

echo 'http://localhost:8082/ でプロファイル結果を確認できます。終了するにはエンター'
read hoge
kill $pprof_pid
