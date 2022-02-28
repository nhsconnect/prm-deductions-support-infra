#!/bin/bash
echo "Running command '$*' with redaction..."
./utils/redactor < <($*)
