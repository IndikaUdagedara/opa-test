# sopa
Simple OPA

## What is this?

I have come across few situations where you need to validate configuration, usually in `json` or `yaml`, against certain policies. Fortunately, there's a tool that does exactly that, `OPA` ! `OPA` and the accompanying `Rego` language is probably the _industry standard_ tool for this purpose. But what I found is that, it doesn't make it trivial to validate policies across configuration files structured in an arbitrary directory structure -- you need to bundle them in a specific format or `POST` them to an `OPA` server instance. This simple shell script (`sopa`) attempts to make that process more palatable. It doesn't use a `OPA` running in server mode but `OPA` CLI's `opa test` functionality.

There's no better way to explain than an example. Consider the following configuration files stored in a directory hierachy

```
$ tree example
example
├── foo
│   └── y.yaml
├── tests.rego
└── x.yaml
```

`x.yaml` contains some configuration
```
$ cat example/x.yaml
a: 1
b: 2
```

and, `foo/y.yaml` also contains some configuration
```
$ cat example/foo/y.yaml
c: 2
d: 5
```

Now, we want to validate the configuration with following policies
1. `x.yaml`.`a` should be greater than `foo/y.yaml`.`c`
2. `x.yaml`.`b` should be less than `foo/y.yaml`.`d`

Therefore we have the following `OPA` test writting in `Rego`
```
package example

test_x_a_should_be_greater_than_foo_y_c {
  data.x.a > data.foo.y.c
}

test_x_b_should_be_less_than_foo_y_d {
  data.x.b < data.foo.y.d
}
```
`OPA` tests are simply `Rego` [rules](https://www.openpolicyagent.org/docs/latest/policy-language/#rules) that have a `test_` prefix. `Rego` can obviously do much more sophisticated policy validation than the above example.

Policy validation can be executed by

```
./sopa.sh -b bundle -d example -t example
```

This gives
```
FAILURES
--------------------------------------------------------------------------------
data.example.test_x_a_should_be_greater_than_foo_y_c: FAIL (286.939µs)

  query:1                  Enter data.example.test_x_a_should_be_greater_than_foo_y_c = _
  /bundle/tests.rego:3     | Enter data.example.test_x_a_should_be_greater_than_foo_y_c
  /bundle/tests.rego:4     | | Fail gt(__local0__, __local1__)
  query:1                  | Fail data.example.test_x_a_should_be_greater_than_foo_y_c = _

SUMMARY
--------------------------------------------------------------------------------
data.example.test_x_a_should_be_greater_than_foo_y_c: FAIL (286.939µs)
data.example.test_x_b_should_be_less_than_foo_y_d: PASS (192.86µs)
--------------------------------------------------------------------------------
PASS: 1/2
FAIL: 1/2
```

As expected, the first test failed.


## Usage
