# Numba 実装

`poisson.py` は、Numba の `@njit` で 5 点差分 Jacobi 反復を JIT 化したシングルスレッド実装です。Numba の並列実行は使いません。NumPy の C-order に合わせた走査でホットループを短縮しています。初回の JIT コンパイル時間を計測から除外するため、3×3 の格子でウォームアップしてから N=401 の求解を計測します。

## uv で実行

以下のコマンドはリポジトリルートで実行してください。

```sh
uv sync --project python
uv run --project python python/poisson.py
```

依存環境は `python/pyproject.toml` と `python/uv.lock` で管理します。
