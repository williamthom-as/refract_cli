# refract_cli

the `refract` command: quick answers and data jobs on csv files, built on
[refract](https://github.com/williamthom-as/refract_core).

```
refract columns --input customers.csv
refract stats --input customers.csv
refract where --match "Status=open" --input accounts.csv | refract select --col Customer
```

`where` reads numbers as refract does (`1,250.00`, `$100`); `query` reads csv as text.

## Build and install

```
git clone https://github.com/williamthom-as/refract_cli.git && cd refract_cli
mix deps.get
MIX_ENV=prod mix release
ln -s "$PWD/_build/prod/rel/refract_cli/bin/refract" ~/.local/bin/refract
```

## Tests

```
mix test
MIX_ENV=prod mix release --overwrite && mix test --only release
```

## Development

against local checkouts: `REFRACT_PATH=../refract mix test`

## License

Apache-2.0, see [LICENSE](LICENSE).
