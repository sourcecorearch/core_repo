#!/bin/bash

rm core_repo.*

echo "repo-add"

repo-add -n -R core_repo.db.tar.gz *.pkg.tar.zst
sleep 2

echo "#####"
echo "Repo Update!!"
echo "#####"
