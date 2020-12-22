# CCBench Silo logging 調査方法 (MASSTREE_USE=0)
田中昌宏　2020-12-22

## ソースコードの取得

```
git clone --recursive https://github.com/masa16/ccbench.git
git clone https://github.com/masa16/ex-silo-logging.git
```

## ビルド

```
cd ccbench/silo
./bootstrap.sh        # 3rd-party library のビルド
./build_test.sh
```

ディレクトリ `test_0log_noidx` と `test_nlog_noidx` の下に実行ファイル `silo.exe` を生成。

## PMEM の設定

NUMA node 0..7 にそれぞれ1つの PMEMモジュールが装着されている場合、
* fsdaxモードで `/mnt/pmem{0..7}` にマウントし、
* `/mnt/pmem{0..7}/$USER` というディレクトリを作成しておく。

(下記スクリプトで使われる `ccbench/silo/numa.rb` を実行すると、`/mnt/pmem{0..7}/$USER` の下へのシンボリックリンクが自動的に作成される)

## ベンチマーク実行

* write 100%

```
cd ex-silo-logging/noidx
./run-noidx-wo.sh
```

`noidx-wo.csv` `noidx-wo-pmem.csv`という結果ファイルを出力。

* write 50%

```
cd ex-silo-logging/noidx
./run-noidx-rw.sh
```

`noidx-rw.csv` `noidx-rw-pmem.csv` という結果ファイルを出力。


## プロット

プロットを実行するには、ruby と gnuplot と numo-gnuplot が必要。

numo-gnuplot のインストール方法はコマンドラインで

```
gem install numo-gnuplot
```

とする。

* プロットの実行：

```
ruby plot-noidx-wo.rb
ruby plot-noidx-rw.rb
```

`*.png, *.eps, *.emf` が作成される。
