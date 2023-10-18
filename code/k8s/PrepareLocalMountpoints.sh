#!/bin/sh
for i in $(seq 1 5); do
  vol="vol$i"
  sudo mkdir -p /local-storage/$vol
  sudo mount --bind /local-storage/$vol /local-storage/$vol
done