# Jacobi benchmark results

- Date: 2026-09-30T11:47:16+0900
- Host: Darwin 25.6.0 arm64
- Device: `Apple M5`
- Working tree: `/Users/terasaki/work/terasakisatoshi/dirichlet_poisson_eq_jacobi`

The reported `time` is the solver time printed by each implementation. Each
implementation was run once with its own default benchmark parameters.

| Implementation | Language | Device | Time (s) | Iterations | Final update error | Max error | L2 error |
|---|---|---|---:|---:|---:|---:|---:|
| julia | Julia | Apple M5 | 3.977462 seconds | 100000 | 1.411484e-06 | 4.575793e-02 | 1.142521e-03 |
| julia_unsafe | Julia (unsafe) | Apple M5 | 3.443576 seconds | 100000 | 1.411484e-06 | 4.575793e-02 | 1.142521e-03 |
| python | Python + Numba | Apple M5 | 3.965009 seconds | 100000 | 1.411484e-06 | 4.575793e-02 | 1.142521e-03 |
| cxx | C++23 | Apple M5 | 3.582923 seconds | 100000 | 1.411484e-06 | 4.575793e-02 | 1.142521e-03 |
| fortran | Fortran 2008 | Apple M5 | 4.041347 seconds | 100000 | 1.411484E-06 | 4.575793E-02 | 1.142521E-03 |
| rust | Rust | Apple M5 | 4.620172 seconds | 100000 | 1.411484e-6 | 4.575793e-2 | 1.142521e-3 |
