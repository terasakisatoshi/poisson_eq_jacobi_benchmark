#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
gfortran -O3 -mcpu=native -mtune=native -std=f2008 -o poisson main.f90
