# Block Processor

## evm server

We use the evm tool which is expected to be setup as a http server in order to serve requests.
To run the http server, follow instructions in the [covalenthq/erigon](https://github.com/covalenthq/erigon/pull/11/files#diff-d74525d4a32983b50da784e0960ab0b7a8adb537dba1535e893bfc1b60dc2427)

e.g. (copied from `covalenthq/erigon`) 


```bash
➜ curl -v -F filedata=@/Users/user/repos/rudder/test-data/block-specimen/15892740.specimen.json http://127.0.0.1:3002/process
```

