#!/bin/bash
sed -E 's/([^[:digit:]]?|^)[[:digit:]]{10}([^[:digit:]]|$)/\1##########\2/g'
