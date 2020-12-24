# CCBench Silo logging 調査方法
田中昌宏　2020-12-15

## ソースコードの取得

```
git clone --recursive git@github.com:masa16/ccbench.git
git clone --recursive https://github.com/masa16/ccbench.git
git clone https://github.com/masa16/ex-silo-logging.git
git clone git@github.com:masa16/ex-silo-logging.git
```

## ビルド

```
cd ccbench/silo
./bootstrap.sh        # 3rd-party library のビルド
./build_test.sh
```

ディレクトリ `test_0log` と `test_nlog` の下に実行ファイル `silo.exe` を生成。

## PMEM の設定

NUMA node 0..7 にそれぞれ1つの PMEMモジュールが装着されている場合、
* fsdaxモードで `/mnt/pmem{0..7}` にマウントし、
* `/mnt/pmem{0..7}/$USER` というディレクトリを作成しておく。

(下記スクリプトで使われる `ccbench/silo/numa.rb` を実行すると、`/mnt/pmem{0..7}/$USER` の下へのシンボリックリンクが自動的に作成される)

## ベンチマーク実行

* スレッド数対トランザクションスループットの測定

```
cd ex-silo-logging/deim/fig1
./run1.sh
```

`run1.csv` という結果ファイルを出力。

## プロット

プロットを実行するには、ruby と gnuplot と numo-gnuplot が必要。

numo-gnuplot のインストール方法はコマンドラインで

```
gem install numo-gnuplot
```

とする。

* プロットの実行：

```
ruby plot-test1.rb run-test1.csv
ruby plot-test2.rb run-test2.csv
```

`*.png, *.eps, *.emf` が作成される。
