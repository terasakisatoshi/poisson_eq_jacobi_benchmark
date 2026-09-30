# Poisson 方程式の Jacobi 法ベンチマーク

単位正方形上の 2 次元 Poisson 方程式を、Julia、Python、C++、Fortran、Rust で解く小さな比較環境です。各実装は同じ格子、右辺、Jacobi 反復を使い、実行時間と誤差を比較します。

## 問題設定

領域は

$$
\Omega=(0,1)\times(0,1)
$$

で、斉次 Dirichlet 条件を課します。

$$
\begin{aligned}
-\Delta u &= f && \text{in }\Omega,\\
u &= 0 && \text{on }\partial\Omega.
\end{aligned}
$$

厳密解と右辺は次のように選びます。

$$
u(x,y)=\sin(\pi x)\sin(\pi y),
\qquad
f(x,y)=2\pi^2\sin(\pi x)\sin(\pi y).
$$

各方向の格子点数は $N=401$、格子幅は $h=1/(N-1)$ です。内部点では 5 点差分を使います。

$$
\frac{4u_{i,j}-u_{i-1,j}-u_{i+1,j}-u_{i,j-1}-u_{i,j+1}}{h^2}=f_{i,j}.
$$

Jacobi 更新は次の形です。

$$
u_{i,j}^{(k+1)}=
\frac{1}{4}\left(
u_{i-1,j}^{(k)}+u_{i+1,j}^{(k)}+
u_{i,j-1}^{(k)}+u_{i,j+1}^{(k)}+h^2f_{i,j}
\right).
$$

境界値は常に 0 のままです。許容更新幅は $10^{-10}$、最大反復回数は 100,000 回です。この格子では通常、許容値に到達する前に最大反復回数に達します。

## ディレクトリ

| ディレクトリ | 言語 | 実装 |
|---|---|---|
| `julia/` | Julia | `LoopVectorization.@turbo` を使う通常の Jacobi 法 |
| `julia_unsafe/` | Julia | raw pointer、SIMD、時間ブロッキングを使う高速 Jacobi 法 |
| `python/` | Python | uv 管理環境で Numba の `@njit` を使うシングルスレッド Jacobi 法 |
| `cxx/` | C++23 | `std::span`、`std::println`、値型 `Grid`、バッファ交換 |
| `fortran/` | Fortran 2008 | allocatable 配列と選択フラグによるバッファ交換 |
| `rust/` | Rust | `pulp` による実行時 SIMD dispatch と 2 反復パイプライン |

## 実行

以下のコマンドはすべて、この README.md があるリポジトリルートで実行してください。

### Julia

依存パッケージを初めて使う場合は、先に環境を準備します。

```sh
julia --project=julia -e 'using Pkg; Pkg.instantiate()'
```

実行します。

```sh
julia --project=julia julia/poisson.jl
```

### Python + Numba

依存環境は uv で作成します。

```sh
uv sync --project python
uv run --project python python/poisson.py
```

### Julia unsafe

依存パッケージを初めて使う場合は、先に環境を準備します。

```sh
julia --project=julia_unsafe -e 'using Pkg; Pkg.instantiate()'
```

リポジトリルートから実行します。

```sh
julia --project=julia_unsafe julia_unsafe/poisson.jl
```

### C++

`cxx/main.cpp` は C++23 の `<print>` / `std::println` を使います。

```sh
./cxx/build.sh
./cxx/poisson
```

ビルドコマンドは次と同じです。

```sh
g++ -O3 -march=native -mtune=native -std=c++23 -o cxx/poisson cxx/main.cpp
```

### Fortran

Fortran 2008 の機能を使っています。

```sh
./fortran/build.sh
./fortran/poisson
```

ビルドコマンドは次と同じです。

```sh
gfortran -O3 -mcpu=native -mtune=native -std=f2008 -o fortran/poisson fortran/main.f90
```

### Rust

`rust/.cargo/config.toml` で `target-cpu=native` を指定しています。

```sh
cargo run --release --manifest-path rust/Cargo.toml
```

C++、Fortran、Rust のプログラムは解の可視化を `poisson_jacobi.png` として生成します。これは生成物なので `.gitignore` により管理対象外です。Julia 実装はベンチマーク時の描画を行いません。

## ベンチマーク

全実装を順にビルド・実行し、標準出力から時間、反復回数、更新幅、誤差を抽出します。実行ホストのデバイス名も結果表に記録されます。

```sh
./benchmark/run.sh
```

結果は [benchmark/RESULT.md](benchmark/RESULT.md) に保存されます。計測対象の `time` は各プログラムが出力する solver 部分の時間です。

## 整理方針

ソース、依存定義、テスト、ビルドスクリプトは各言語ディレクトリに残します。コンパイル済み実行ファイル、Rust の `target/`、実行時に生成される PNG は再生成可能なため、ルートの [.gitignore](.gitignore) で除外しています。
# poisson_eq_jacobi_benchmark
