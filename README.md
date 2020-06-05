# Fluent Bit Testing Environment

A docker-compose stack for a local [Fluent-Bit](https://fluentbit.io/) logging container, and optionally an [ElasticSearch/Kibana](https://www.elastic.co/) output destination, in order to test and debug Fluent-Bit parsing and filtering rules. Currently set up to test Kubernetes formatted log files.

## Usage Instructions

### Inputs

- Test input logs should go in the `/inputs` folder.

### Option #1: basic stack / view output in the console

- Add the configuration directives that you want to test in the folder `/config` - relevant files are:

  - fluent-bit-filter.conf
  - fluent-bit-service.conf
  - fluent-bit-input.conf
  - fluent-bit.conf
  - fluent-bit-output.stdout.conf
  - ~~fluent-bit-output.esout.conf~~ <-- this is used for ElasticSearch output

- Run `docker-compose -f docker-compose.stdout.yaml run fluent-bit`.

- Parsed logs will be passed to the console.

- Exiting the session stops the container.

### Option #2: full stack including Fluent-Bit, ElasticSearch and Kibana / view output in Kibana (and the console)

- `docker-compose.esout.yml` is configured to launch local instances of ElasticSearch (1 node cluster) and Kibana.
- Run `docker-compose -f docker-compose.esout.yaml up -d`.
- Parsed fluent-bit logs and outputs are available through the console: `docker-compose -f docker-compose.esout.yaml logs fluent-bit`.
- Similarly, ElasticSearch logs are also available for debugging unsuccessful log input: `docker-compose -f docker-compose.esout.yaml logs elasticsearch`.
- To view successful inputs on the Kibana dashboard, go to `localhost:5601` and first create an index mapping (Menu "management" > "index patterns")
- Shut down the stack by running `docker-compose -f docker-compose.esout.yaml down` from the project root folder.
- In most cases you will want to delete all the stored data from the ES cluster when you're done, otherwise next time you restart the container you will keep trying to process the same log files over and over again: `docker-compose -f docker-compose.esout.yaml down -v`.
- If filesystem buffering is enabled, you can view the buffers with the `flb-buffer` service (basic busybox container linked to Fluent-Bit's mounted volume)
