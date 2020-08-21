#!/bin/sh

set -e

DIR="$(cd "$(dirname "$0")/../" && pwd)"

echo "Running tests"
nimble test

echo "Building examples"
nimble task examples
