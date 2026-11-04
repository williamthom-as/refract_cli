# refract_cli

the `refract` command: quick answers and data jobs on csv files, built on
[refract](https://github.com/williamthom-as/refract).

```
refract columns --input customers.csv
refract stats --input customers.csv
```

## Build and install

```
MIX_ENV=prod mix release
ln -s "$PWD/_build/prod/rel/refract_cli/bin/refract" ~/.local/bin/refract
```

## Tests

```
mix test
MIX_ENV=prod mix release --overwrite && mix test --only release
```
