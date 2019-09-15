#!/bin/bash

set -eu
rm -rf function.zip
zip -g function.zip lambda_function.py
