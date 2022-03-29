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