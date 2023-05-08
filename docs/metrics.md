# Metrics Collection and Reporting

`rudder` is proactively enabled with metrics collection via prometheus.

## Config

Install Prometheus https://prometheus.io/download/ 

* Edit `/opt/homebrew/etc/prometheus.yml` for mac/m1.
or
* Edit `/usr/local/etc/prometheus.yml` for linux/x86.

Add the config for prometheus to pick up exported [rudder telemetry metrics](../lib/rudder/metrics/prometheus.yml).

Restart your prometheus server

```bash
brew services restart prometheus
```

Monitoring can be setup (for example) by plugging the endpoint serving in prometheus-format into a grafana plugin, which can be viewed in grafana - sliced and diced further as per need per metric.

## Metrics

The following metrics captured from rudder are exported with `/metrics` endpoint via prometheus.

```elixir
# TYPE rudder_events_rudder_pipeline_success_duration gauge
rudder_events_rudder_pipeline_success_duration{operation="pipeline_success",table="rudder_metrics"} 0.004265
# TYPE rudder_events_rudder_pipeline_success_count counter
rudder_events_rudder_pipeline_success_count{operation="pipeline_success",table="rudder_metrics"} 4
# TYPE rudder_events_journal_fetch_items_duration gauge
rudder_events_journal_fetch_items_duration{operation="fetch_items",table="journal_metrics"} 1.2e-5
# TYPE rudder_events_journal_fetch_items_count counter
rudder_events_journal_fetch_items_count{operation="fetch_items",table="journal_metrics"} 1
# TYPE rudder_events_journal_fetch_last_duration gauge
rudder_events_journal_fetch_last_duration{operation="fetch_last",table="journal_metrics"} 3.6e-5
# TYPE rudder_events_journal_fetch_last_count counter
rudder_events_journal_fetch_last_count{operation="fetch_last",table="journal_metrics"} 1
# TYPE rudder_events_brp_proof_duration gauge
rudder_events_brp_proof_duration{operation="proof",table="brp_metrics"} 6.259999999999999e-4
# TYPE rudder_events_brp_proof_count counter
rudder_events_brp_proof_count{operation="proof",table="brp_metrics"} 4
# TYPE rudder_events_brp_upload_success_duration gauge
rudder_events_brp_upload_success_duration{operation="upload_success",table="brp_metrics"} 0.0023769999999999998
# TYPE rudder_events_brp_upload_success_count counter
rudder_events_brp_upload_success_count{operation="upload_success",table="brp_metrics"} 4
# TYPE rudder_events_bsp_execute_duration gauge
rudder_events_bsp_execute_duration{operation="execute",table="bsp_metrics"} 2.1799999999999999e-4
# TYPE rudder_events_bsp_execute_count counter
rudder_events_bsp_execute_count{operation="execute",table="bsp_metrics"} 4
# TYPE rudder_events_bsp_decode_duration gauge
rudder_events_bsp_decode_duration{operation="decode",table="bsp_metrics"} 0.0
# TYPE rudder_events_bsp_decode_count counter
rudder_events_bsp_decode_count{operation="decode",table="bsp_metrics"} 4
# TYPE rudder_events_ipfs_fetch_duration gauge
rudder_events_ipfs_fetch_duration{operation="fetch",table="ipfs_metrics"} 0.001588
# TYPE rudder_events_ipfs_fetch_count counter
rudder_events_ipfs_fetch_count{operation="fetch",table="ipfs_metrics"} 4
# TYPE rudder_events_ipfs_pin_duration gauge
rudder_events_ipfs_pin_duration{operation="pin",table="ipfs_metrics"} 0.00174
# TYPE rudder_events_ipfs_pin_count counter
rudder_events_ipfs_pin_count{operation="pin",table="ipfs_metrics"} 4
```

## API

View exported gauges and counters using prometheus at the endpoint ->  http://localhost:9568/metrics.

Create graphs using prometheus at the endpoint -> http://localhost:9090/graph.

View timeseries and add alerting with grafana at the endpoint -> http://localhost:3000/explore.

Docker containers automatically export to this endpoint as well via exposed ports and port forwarding.
## Graph

Observe live the gauge time series graphs with plots for example with metrics for `pipeline_success` and `ipfs_fetch` -> http://localhost:9090/graph?g0.expr=rudder_events_rudder_pipeline_success_duration&g0.tab=0&g0.stacked=1&g0.show_exemplars=0&g0.range_input=15m&g0.step_input=1&g1.expr=rudder_events_ipfs_fetch_duration&g1.tab=0&g1.stacked=1&g1.show_exemplars=1&g1.range_input=15m&g1.step_input=1

![Observe](./prometheus.png)

## Monitor & Alert

For monitoring and alerting we advice using [Grafana (in conjunction with the aggregated prometheus metrics)](https://grafana.com/docs/grafana/latest/getting-started/get-started-grafana-prometheus/).

Install and start Grafana

```bash
brew install grafana
brew services start grafana
```

Ensure Grafana (default port 3000) and Prometheus (default port 9090) have started.

```bash
$ brew services list
Name          Status  User   File
grafana       started user ~/Library/LaunchAgents/homebrew.mxcl.grafana.plist
prometheus    started user ~/Library/LaunchAgents/homebrew.mxcl.prometheus.plist
```

Login to your Grafana dashboard -> http://localhost:3000/.

Make sure prometheus is added as a data source -> http://localhost:3000/datasources with the default values for prometheus. Click on [Explore](http://localhost:3000/explore?left=%7B%22datasource%22:%22lVZwdz8Vz%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22lVZwdz8Vz%22%7D%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D&orgId=1).

Select the metrics and time-series data to view from the dropdown with "Select Metric".
Below is an example of three selections `rudder_events_brp_upload_success_duration`, `rudder_events_rudder_pipeline_success_duration`, `rudder_events_ipfs_fetch_duration`.

This can directly be viewed [here](http://localhost:3000/explore?left=%7B%22datasource%22:%22lVZwdz8Vz%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22lVZwdz8Vz%22%7D,%22editorMode%22:%22builder%22,%22expr%22:%22rudder_events_brp_upload_success_duration%22,%22legendFormat%22:%22__auto%22,%22range%22:true,%22instant%22:true%7D,%7B%22refId%22:%22B%22,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22lVZwdz8Vz%22%7D,%22editorMode%22:%22builder%22,%22expr%22:%22rudder_events_rudder_pipeline_success_duration%22,%22legendFormat%22:%22__auto%22,%22range%22:true,%22instant%22:true%7D,%7B%22refId%22:%22C%22,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22lVZwdz8Vz%22%7D,%22editorMode%22:%22builder%22,%22expr%22:%22rudder_events_ipfs_fetch_duration%22,%22legendFormat%22:%22__auto%22,%22range%22:true,%22instant%22:true%7D%5D,%22range%22:%7B%22from%22:%22now-15m%22,%22to%22:%22now%22%7D%7D&orgId=1). You can also add operations on the exported data with aggregations like `sum` and range functions like `delta` etc as seen below.

![grafana](./grafana.png)
