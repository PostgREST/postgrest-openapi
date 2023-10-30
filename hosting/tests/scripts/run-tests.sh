#!/bin/sh

cd /buildroot

set -o xtrace

make fixtures
make installcheck
