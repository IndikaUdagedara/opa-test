# opa-test
OPA Test Runner: Apply policies to arbitrary `json` or `yaml` data using `OPA` and `Rego`.

- [What is this?](#what-is-this)
- [Example](#example)
- [Usage](#usage)


## What is this?

I have come across quite a few situations where arbitrary structured data (usually in `json` or `yaml` format) needed to be validated against policies. Examples are: Validating `replicas` is a certain value in Production environment in a Kubernetes `Deployment` or  validating `MultiAZ` is set in RDS Cloudformation template or validating custom rules in a json configuration file with a bespoke schema.

Fortunately, there's a tool that is purpose-built for arbitrary policy validation, [`OPA`](https://www.openpolicyagent.org/docs/latest/). `OPA` and the accompanying `Rego` language is probably the _industry standard_ for this. But, in my experience, `OPA` doesn't make it trivial to validate policies across configuration files structured in an arbitrary directory structure -- you need to bundle them in a specific format or `POST` them to an `OPA` server instance. **This shell script (`opa-test`) attempts to make that process more palatable. It doesn't use `OPA` running in server mode but `OPA` CLI's `opa test` functionality to validate arbitrary `json` or `yaml` files against policies defined in `Rego` language.**

## Example

There's no better way to explain than an example. Consider the following configuration files stored in a directory hierarchy

```
$ tree example
example
├── foo
│   └── y.yaml
├── tests.rego
└── x.yaml
```

`x.yaml` and `foo/y.yaml` contain some configuration
```
$ cat example/x.yaml
a: 1
b: 2
$ cat example/foo/y.yaml
c: 4
d: 5
e: abc
```

Now, we want to validate the configuration with following policies
1. `x.yaml` → `a` should be greater than `foo/y.yaml` → `c`
2. `x.yaml` → `b` should be less than `foo/y.yaml` → `d`
3. `foo/y.yaml` → `e` should be a lower case string

Therefore we have the following `OPA` test, written in `Rego`
```
$ cat tests.rego
package example

# `x.yaml` → `a` should be greater than `foo/y.yaml` → `c`
test_x_a_should_be_greater_than_foo_y_c {
  data.x.a > data.foo.y.c
}

# `x.yaml` → `b` should be less than `foo/y.yaml` → `d`
test_x_b_should_be_less_than_foo_y_d {
  data.x.b < data.foo.y.d
}

# `foo/y.yaml` → `e` should be a lower case string
test_foo_y_e_should_be_lower_case {
  data.foo.y.e = lower(data.foo.y.e)
}
```

Note that in the test, we reference the properties (keys) of `Rego`'s omnipresent `data` object that map to the directory and file structure of the configuration files e.g. `foo/y.yaml` → `d` is referenced as `data.foo.y.d`. **This mapping is essentially what `opa-test` provides.**

`OPA` tests are simply `Rego` [rules](https://www.openpolicyagent.org/docs/latest/policy-language/#rules) that have a `test_` prefix. `Rego` can obviously do much more sophisticated policy validation than the above example.

Using `opa-test`, validating the above configuration using the policies in `tests.rego` can be done by

```
./opa-test.sh -b bundle -d example -t example
```
`-d` is the path to the data directory and `-t` is the path to the directory containing policies/tests. In this example, they are in the same directory.

This gives
```
$ ./opa-test.sh -d example -t example -b bundle
FAILURES
--------------------------------------------------------------------------------
data.example.test_x_a_should_be_greater_than_foo_y_c: FAIL (299.031µs)


SUMMARY
--------------------------------------------------------------------------------
data.example.test_x_a_should_be_greater_than_foo_y_c: FAIL (299.031µs)
data.example.test_x_b_should_be_less_than_foo_y_d: PASS (263.243µs)
data.example.test_foo_y_e_should_be_lower_case: PASS (127.862µs)
--------------------------------------------------------------------------------
PASS: 2/3
FAIL: 1/3
```

As expected, the first test failed.


## Usage

### Local installation

Prerequisite: `OPA` CLI is installed and available in `$PATH`

```
$ ./opa-test.sh -h
Usage: opa-test.sh [options]

Options:

-h, --help         Print this help and exit.
-b, --bundle name  Directory to store intermediate files (bundle). Needs to be an empty directory.
-c                 Clean the bundle directory. By default it will be re-used if exists.
-d, --data name    Directory containing data files. Can be json or yaml files.
-t, --tests name   Directory containing Rego tests. Could be the same as data directory.
```

### Docker

1. Build image from Dockerfile or get from DockerHub
```
$ docker build -t opa-test .
# or
$ docker pull indikaudagedara/opa-test
```

2. Run
```
$ docker run -v /example:/data/example -it indikaudagedara/opa-test -b ./bundle -d ./example -t ./example
```
