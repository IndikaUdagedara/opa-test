#!/bin/bash
set -eo pipefail


usage() {
  cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [options]

Options:

-h, --help         Print this help and exit.
-b, --bundle name  Directory to store the bundle. Needs to be an empty directory.
-k                Keep bundle directory (useful for debugging). By default it will be deleted.
-d, --data name    Directory containing data files. Can be json or yaml files.
-t, --tests name   Directory containing Rego tests. Could be the same as data directory.
EOF
  exit
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--bundle)
      BUNDLE_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -k)
      KEEP_BUNDLE=true
      shift
      ;;
    -d|--data)
      DATA_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--tests)
      TESTS_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      usage
      exit 1
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      echo "Unknown arg $1"
      exit 1
      ;;
  esac
done

if [[ -z "$BUNDLE_DIR" ]]; then
  echo "Missing bundle directory" && exit 1
fi
if [[ -z "$DATA_DIR" ]]; then
  echo "Missing data directory" && exit 1
fi
if [[ -z "$TESTS_DIR" ]]; then
  echo "Missing tests directory" && exit 1
fi

copy_data() {
  for f in $(find $DATA_DIR -name "*.json" -or -name "*.yaml" -type f); do
    relative_path=$(echo $f | sed "s,^$DATA_DIR/,,")
    dir_path=$(dirname $relative_path)
    filename=$(basename $relative_path)
    file_prefix=$(sed -e 's/\..*$//' <<< $filename)
    file_extension=$(sed -E 's/(.*)\.(.*$)/\2/' <<< $filename)
    copied_path=$BUNDLE_DIR/$dir_path/$file_prefix
    mkdir -p $copied_path
    cp $f $copied_path/data.$file_extension
  done
}

copy_tests() {
  for f in $(find $TESTS_DIR -name "*.rego" -type f); do
    relative_path=$(echo $f | sed "s,^$TESTS_DIR/,,")
    dir_path=$(dirname $relative_path)
    filename=$(basename $relative_path)
    copied_path=$BUNDLE_DIR/$dir_path/
    mkdir -p $copied_path
    cp $f $copied_path/$filename
  done
}

mkdir -p $BUNDLE_DIR
if [[ -nz "$(ls -A $BUNDLE_DIR)" ]]; then
  echo "Bundle directory not empty" && exit 1
fi

copy_data
copy_tests

opa build $BUNDLE_DIR

if [[ -z $KEEP_BUNDLE ]]; then
  rm -rf $BUNDLE_DIR
fi

opa test -v -b bundle.tar.gz

