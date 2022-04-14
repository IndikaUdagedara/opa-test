#!/bin/bash
set -eo pipefail


usage() {
  cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [options]

Options:

-h, --help         Print this help and exit.
-b, --bundle name  Directory to store intermediate files (bundle). Needs to be an empty directory.
-c                 Clean the bundle directory. By default it will be re-used if exists.
-d, --data name    Directory containing data files. Can be json or yaml files.
-t, --tests name   Directory containing Rego tests. Could be the same as data directory.
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--bundle)
      BUNDLE_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    -c)
      CLEAN_BUNDLE=true
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
      exit 0
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
    file_prefix=$(sed -E 's/\..[(json)(yaml)]+$//' <<< $filename)
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

if [[ $CLEAN_BUNDLE -eq true ]]; then
  rm -rf $BUNDLE_DIR
fi

mkdir -p $BUNDLE_DIR

copy_data
copy_tests

opa test --explain notes $BUNDLE_DIR 