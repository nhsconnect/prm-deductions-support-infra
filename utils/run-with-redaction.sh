#!/bin/bash
echo "Running command '$*' with redaction..."
./utils/redactor < <($* 2>&1)
