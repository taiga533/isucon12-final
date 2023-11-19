#!/bin/bash
set -eu -o pipefail

echo 'netdata用にsshトンネルを張ります'
for i in `seq 1 1 5` ;do
    h=isucon12-$i
    p=1999$i
    echo "connect to $h from http://localhost:$p"
    ssh $h -N -L $p:127.0.0.1:19999 &
done

echo トンネルを閉じるにはなにか入力してください
read hoge
kill `jobs -p`
