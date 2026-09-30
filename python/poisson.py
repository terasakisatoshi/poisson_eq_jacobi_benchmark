"""Numba-accelerated Jacobi solver for the unit-square Poisson problem."""

from __future__ import annotations

import math
import time

import numpy as np
from numba import njit


REPORT_INTERVAL = 1_000


@njit(cache=True)
def jacobi(
    u: np.ndarray,
    u_new: np.ndarray,
    rhs: np.ndarray,
    h2: float,
    tolerance: float,
    max_iterations: int,
) -> tuple[np.ndarray, int, float]:
    """Run Jacobi iteration and return the latest buffer and diagnostics."""
    n = u.shape[0]
    update_error = math.inf
    iterations = 0

    for iteration in range(1, max_iterations + 1):
        report = iteration % REPORT_INTERVAL == 0 or iteration == max_iterations
        if report:
            update_error = 0.0

        # NumPy arrays are C-contiguous, so the last (j) index is the
        # contiguous lane. Keep it in the innermost loop for cache locality.
        for i in range(1, n - 1):
            for j in range(1, n - 1):
                value = 0.25 * (
                    u[i + 1, j]
                    + u[i - 1, j]
                    + u[i, j + 1]
                    + u[i, j - 1]
                    + h2 * rhs[i, j]
                )
                if report:
                    delta = abs(value - u[i, j])
                    if delta > update_error:
                        update_error = delta
                u_new[i, j] = value

        u, u_new = u_new, u
        iterations = iteration

        if report and update_error < tolerance:
            break

    return u, iterations, update_error


def exact_solution(x: np.ndarray, y: np.ndarray) -> np.ndarray:
    return np.sin(math.pi * x)[:, None] * np.sin(math.pi * y)[None, :]


def forcing(x: np.ndarray, y: np.ndarray) -> np.ndarray:
    return 2.0 * math.pi**2 * exact_solution(x, y)


def main() -> None:
    n = 401
    tolerance = 1.0e-10
    max_iterations = 100_000
    h = 1.0 / (n - 1)

    x = np.linspace(0.0, 1.0, n)
    y = np.linspace(0.0, 1.0, n)
    rhs = forcing(x, y)
    u = np.zeros((n, n), dtype=np.float64)
    u_new = np.zeros_like(u)

    # Compile the same float64 specialization before timing the full solve.
    warm_u = np.zeros((3, 3), dtype=np.float64)
    warm_rhs = np.zeros_like(warm_u)
    jacobi(
        warm_u,
        np.zeros_like(warm_u),
        warm_rhs,
        0.25,
        tolerance,
        1,
    )

    print(f"N = {n}")
    print(f"h = {h:.6e}")

    start = time.perf_counter()
    u, iterations, update_error = jacobi(
        u,
        u_new,
        rhs,
        h * h,
        tolerance,
        max_iterations,
    )
    duration = time.perf_counter() - start

    exact = exact_solution(x, y)
    difference = u - exact
    absolute_error = np.abs(difference)
    max_error = float(np.max(absolute_error))
    l2_error = float(np.sqrt(np.sum(difference**2) * h * h) / math.sqrt(n))

    print()
    print(f"time = {duration:.6f} seconds")
    print(f"Jacobi iterations = {iterations}")
    print(f"final update error = {update_error:.6e}")
    print()
    print(f"max error = {max_error:.6e}")
    print(f"L2 error  = {l2_error:.6e}")


if __name__ == "__main__":
    main()
