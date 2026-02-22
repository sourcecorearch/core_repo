#!/bin/bash

set -e

echo "🧹 Cleaning old repo files..."
rm -f core_repo.db core_repo.db.tar.gz core_repo.files core_repo.files.tar.gz

echo "📦 Running repo-add..."
repo-add -n -R core_repo.db.tar.gz *.pkg.tar.zst

echo "🔁 Fixing GitHub symlink issue..."
rm -f core_repo.db core_repo.files
cp core_repo.db.tar.gz core_repo.db
cp core_repo.files.tar.gz core_repo.files

echo "#####"
echo "Repo Update!!"
echo "#####"
