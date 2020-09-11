#!/bin/bash
ps -e --sort -pcpu --format="user comm %cpu" | awk '{if ($3>"'0.0'") {print $1,$2,$3}}'
