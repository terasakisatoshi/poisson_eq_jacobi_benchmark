#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
g++ -O3 -march=native -mtune=native -std=c++23 -o poisson main.cpp
