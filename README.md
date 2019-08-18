# AWS Security Group exporter for Prometheus

**[Motivation](#motivation)** |
**[How does it work](#how-does-it-work)** |
**[Requirements](#requirements)** |
**[Docker settings](#docker-settings)** |
**[Metrics](#metrics)** |
**[Examples](#examples)** |
**[Grafana](#grafana-setup)** |
**[Errors](#error-handling)**

[![Build Status](https://travis-ci.com/cytopia/aws-ec2-sg-exporter.svg?branch=master)](https://travis-ci.com/cytopia/aws-ec2-sg-exporter)
[![Tag](https://img.shields.io/github/tag/cytopia/aws-ec2-sg-exporter.svg)](https://github.com/cytopia/aws-ec2-sg-exporter/releases)
[![](https://images.microbadger.com/badges/version/cytopia/aws-ec2-sg-exporter:latest.svg?&kill_cache=1)](https://microbadger.com/images/cytopia/aws-ec2-sg-exporter:latest "aws-ec2-sg-exporter")
[![](https://images.microbadger.com/badges/image/cytopia/aws-ec2-sg-exporter:latest.svg?&kill_cache=1)](https://microbadger.com/images/cytopia/aws-ec2-sg-exporter:latest "aws-ec2-sg-exporter")
[![](https://img.shields.io/docker/pulls/cytopia/aws-ec2-sg-exporter.svg)](https://hub.docker.com/r/cytopia/aws-ec2-sg-exporter)
[![](https://img.shields.io/badge/github-cytopia%2Faws--ec2--sg--exporter-red.svg)](https://github.com/cytopia/aws-ec2-sg-exporter "github.com/cytopia/aws-ec2-sg-exporter")
[![License](https://img.shields.io/badge/license-MIT-%233DA639.svg)](https://opensource.org/licenses/MIT)

![Grafana](https://raw.githubusercontent.com/cytopia/aws-ec2-sg-exporter/master/doc/grafana-dash.png "Grafana Graph Example")

A dockerized<strong><sup>[1]</sup></strong> Prometheus exporter that compares desired/wanted
IPv4/IPv6 CIDR against currently applied inbound CIDR rules by protocol and port number in your AWS
security group(s) per region.

> <strong><sup>[1]</sup></strong>: If you want to use this exporter without Docker jump here: [Usage without Docker](#usage-without-docker)

[![Docker hub](http://dockeri.co/image/cytopia/aws-ec2-sg-exporter?&kill_cache=1)](https://hub.docker.com/r/cytopia/aws-ec2-sg-exporter)


## Motivation

Some IP addresses ranges such as Cloudfront edge nodes or SaaS hosts might change frequently and
you possibly want to ensure that those are always in sync with what you have currently defined in
your security group.
This exporter does exactly this and can easily be hooked up with Alertmanager to trigger alerts in
case you get out of sync.


## How does it work

#### Desired/Wanted IP address CIDR

You have to provide a command, which is parsable by bash's `eval` function and evalutes
**newline-separated** to your desired/wanted IP address CIDR. As a few examples:
```bash
# Note that for single IP addresses, AWS requires '/32' to be appended
eval "dig +short nat.travisci.net | xargs -n1 -I% echo \"%/32\""
eval "printf \"10.13.23.23/32\n192.168.0.0/24\n\""
```

#### Applied security Group CIDR

You have to provide the following in order to fetch your currently applied sg rules:

* Security group name (The `Name` tag)<strong><sup>[1]</sup></strong>
* AWS region where the security group resides
* Security group rule protocol (e.g.: `tcp`, `udp`, `icmp`, ...)
* Security group rule from port (e.g.: `80`, `443`, ...)

> <strong><sup>[1]</sup></strong>: The `*` wildcard is supported for the name, but you have to ensure to match exactly one security group

#### Output

The exporter will then output Prometheus readable information as such:
```bash
# HELP aws_ec2_sg_compare Determines If CIDR is applied to security group.
# TYPE aws_ec2_sg_compare counter
aws_ec2_sg_compare{name="sg-name",region="us-east-1",proto="tcp",from_port="80",ip="v4",cidr="10.4.1.1/32",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="sg-name",region="us-east-1",proto="tcp",from_port="80",ip="v4",cidr="10.4.1.5/32",sg_id="sg-xxxxx",errno="0",error=""} 0
```

* A value of `1` means the desired/wanted IP CIDR is applied to the security group
* A value of `0` means the desired/wanted IP CIDR is not applied to the security group

See [Metrics](#metrics) for an indepth description.


## Requirements

You will need AWS access key and secret with the following permission:
```yaml
ec2:DescribeSecurityGroups
```


## Docker settings

### Tagging

Ensure to **use Docker image tags** (which are the same as git tags from this repository) to prevent
any backwards incompatible changes. The `latest` tag should only be used for testing purposes.

Additionally do not blindly update Docker image tags before having tested it. Security group rule
checks are an important matter and you want to ensure your alerting is reliable.


### Environment variables

You can specify up to 4 security group checks: `SG1_*`, `SG2_*`, `SG3_*` and `SG4_*`.

| Variable                | Description |
|-------------------------|-------------|
| `AWS_ACCESS_KEY_ID`     | The AWS access key (required to connect to AWS to check the sg rules) |
| `AWS_SECRET_ACCESS_KEY` | The AWS secret key (required to connect to AWS to check the sg rules) |
| `AWS_SESSION_TOKEN`     | (Optional) The AWS session token |
| | |
| `UPDATE_TIME`           | Time interval in sec for how often to update metrics (default: `60`) |
| | |
| `SG1_NAME`              | Name of the security group on AWS |
| `SG1_REGION`            | Region the security group resides in |
| `SG1_PROTO`             | Security group rule protocol: `tcp`, `udp`, `icmp` or a protocol number |
| `SG1_FROM_PORT`         | Security group rule from port |
| `SG1_IP4_CMD`           | The command that evaluates to newline-separated IPv4 IP address CIDR <strong><sup>[1]</sup></strong> |
| `SG1_IP6_CMD`           | The command that evaluates to newline-separated IPv6 IP address CDIR <strong><sup>[1]</sup></strong> |
| | |
| `SG2_NAME`              | Name of the security group on AWS |
| `SG2_REGION`            | Region the security group resides in |
| `SG2_PROTO`             | Security group rule protocol: `tcp`, `udp`, `icmp` or a protocol number |
| `SG2_FROM_PORT`         | Security group rule from port |
| `SG2_IP4_CMD`           | The command that evaluates to newline-separated IPv4 IP address CIDR <strong><sup>[1]</sup></strong> |
| `SG2_IP6_CMD`           | The command that evaluates to newline-separated IPv6 IP address CDIR <strong><sup>[1]</sup></strong> |
| | |
| `SG3_NAME`              | Name of the security group on AWS |
| `SG3_REGION`            | Region the security group resides in |
| `SG3_PROTO`             | Security group rule protocol: `tcp`, `udp`, `icmp` or a protocol number |
| `SG3_FROM_PORT`         | Security group rule from port |
| `SG3_IP4_CMD`           | The command that evaluates to newline-separated IPv4 IP address CIDR <strong><sup>[1]</sup></strong> |
| `SG3_IP6_CMD`           | The command that evaluates to newline-separated IPv6 IP address CDIR <strong><sup>[1]</sup></strong> |
| | |
| `SG4_NAME`              | Name of the security group on AWS |
| `SG4_REGION`            | Region the security group resides in |
| `SG4_PROTO`             | Security group rule protocol: `tcp`, `udp`, `icmp` or a protocol number |
| `SG4_FROM_PORT`         | Security group rule from port |
| `SG4_IP4_CMD`           | The command that evaluates to newline-separated IPv4 IP address CIDR <strong><sup>[1]</sup></strong> |
| `SG4_IP6_CMD`           | The command that evaluates to newline-separated IPv6 IP address CDIR <strong><sup>[1]</sup></strong> |

> <strong><sup>[1]</sup></strong>: `SG*_IP4_CMD` and `SG*_IP6_CMD` are mutually exclusive. Also note that evaluated
IP address CIDR are only checked against security group rules that match the protocol (`SG*_PROTO`)
and also match the from port (`SG*_FROM_PORT`).


### Mount points

None - it's fully stateless


### Exposed ports

| External  | Internal | Description |
|-----------|----------|-------------|
| Up to you | `8080`   | Where the `aws-ec2-sg-exporter` provides metrics via HTTP |


## Metrics

This exporter outputs metrics in the following format:
```bash
# HELP aws_ec2_sg_compare Determines If CIDR is applied to security group.
# TYPE aws_ec2_sg_compare counter
aws_ec2_sg_compare{name="sg-name",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="10.4.1.1/32",sg_id="sg-xxxxx",errno="0",error=""} 1
```
The following table describes each of the key/value paris:

| Key         | Value |
|-------------|-------|
| `name`      | The security group name as specified by `SG*_NAME` |
| `region`    | The security group region as specified by `SG*_REGION` |
| `proto`     | The security group rule protocol as specified by `SG*_PROTO` |
| `from_port` | The security group rule from port as specified by `SG*_FROM_PORT` |
| `ip`        | IP version of desired/wanted CIDR to be available in your security group by `proto` and `from_port` |
| `cidr`      | The desired/wanted IP to be available in your security group by `proto` and `from_port` |
| `sg_id`     | The security group ID found by `name` and `region`. If this is empty then either zero or more multiple security groups were found. |
| `errno`     | 0: One security group was found (OK)<br/>1: No security group was found (ERR)<br/>2: Multiple security groups were found (ERR) |
| `error`     | The corresponding error message for `errno` |

* A value of `1` means the desired/wanted IP CIDR is applied to the security group
* A value of `0` means the desired/wanted IP CIDR is not applied to the security group


## Examples

### Scenario 1 - Travis
Check if your security group named `my-sg` (in us-east-1) allows all inbound IPv4 addresses from Travis-CI via `tcp` on `https`.

#### Desired/wanted IP CIDR
Ensure you have a working command which can be interpretated by `eval` and that outputs CIDR (with `/[0-9]+` appended) of your desired ranges:
```bash
$ eval "dig +short nat.travisci.net | xargs -n1 -I% echo \"%/32\""
```
```bash
35.184.226.236/32
35.188.1.99/32
35.188.73.34/32
35.192.85.2/32
35.192.136.167/32
...
```

#### Run `aws-ec2-sg-exporter`
```bash
docker run -it --rm \
	-p 9000:8080 \
	\
	-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
	-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
	\
	-e SG1_NAME="my-sg" \
	-e SG1_REGION="us-east-1" \
	-e SG1_PROTO="tcp" \
	-e SG1_FROM_PORT="443" \
	-e SG1_IP4_CMD="dig +short nat.travisci.net | xargs -n1 -I% echo \"%/32\"" \
	cytopia/aws-ec2-sg-exporter
```

#### Check output
Check the output via curl:
```bash
$ curl localhost:9000`
```
```bash
# HELP aws_ec2_sg_compare Determines If CIDR is applied to security group.
# TYPE aws_ec2_sg_compare counter
aws_ec2_sg_compare{name="my-sg",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="35.184.226.236/32",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="35.188.1.99/32",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="35.188.73.34/32",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="35.192.85.2/32",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="35.192.136.167/32",sg_id="sg-xxxxx",errno="0",error=""} 0
...
```

As you can see, the last line returns a `0`, which means this IP CIDR is missing in your security group.


### Scenario 2 - Cloudfront

* Check if your security group named `my-sg4` (in us-east-1) allows all inbound IPv4 addresses from Cloudfront edge-nodes via `tcp` on `https`.
* Check if your security group named `my-sg6` (in us-east-1) allows all inbound IPv6 addresses from Cloudfront edge-nodes via `tcp` on `https`.

#### Desired/wanted IP CIDR
Ensure you have a working command which can be interpretated by `eval` and that outputs CIDR (with `/[0-9]+` appended) of your desired ranges:
```bash
$ eval "curl -sS https://ip-ranges.amazonaws.com/ip-ranges.json \
	| jq -r '.prefixes \
		| sort_by(.ip_prefix)[] \
		| select( .service | contains(\"CLOUDFRONT\")) \
		| select ( .region | test(\"^(GLOBAL|us-|eu-)\")) \
		| .ip_prefix'"
```
```bash
13.224.0.0/14
13.249.0.0/16
13.32.0.0/15
13.35.0.0/16
13.52.204.0/23
...
```
```bash
$ eval "curl -sS https://ip-ranges.amazonaws.com/ip-ranges.json \
	| jq -r '.ipv6_prefixes \
		| sort_by(.ipv6_prefixes)[] \
		| select( .service | contains(\"CLOUDFRONT\")) \
		| select ( .region | test(\"^(GLOBAL|us-|eu-)\")) \
		| .ipv6_prefix'"
```
```bash
2600:9000:eee::/48
2600:9000:4000::/36
2600:9000:3000::/36
2600:9000:f000::/36
2600:9000:fff::/48
...
```

#### Run `aws-ec2-sg-exporter`
```bash
docker run -it --rm \
	-p 9000:8080 \
	\
	-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
	-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
	\
	-e SG1_NAME="my-sg4" \
	-e SG1_REGION="us-east-1" \
	-e SG1_PROTO="tcp" \
	-e SG1_FROM_PORT="443" \
	-e SG1_IP4_CMD="curl -sS https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.prefixes | sort_by(.ip_prefix)[] | select( .service | contains(\"CLOUDFRONT\")) | select ( .region | test(\"^(GLOBAL|us-|eu-)\")) | .ip_prefix'" \
	\
	-e SG2_NAME="my-sg6" \
	-e SG2_REGION="us-east-1" \
	-e SG2_PROTO="tcp" \
	-e SG2_FROM_PORT="443" \
	-e SG2_IP6_CMD="curl -sS https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.ipv6_prefixes | sort_by(.ipv6_prefixes)[] | select( .service | contains(\"CLOUDFRONT\")) | select ( .region | test(\"^(GLOBAL|us-|eu-)\")) | .ipv6_prefix'" \
	cytopia/aws-ec2-sg-exporter
```

#### Check output
Check the output via curl:
```bash
$ curl localhost:9000`
```
```bash
# HELP aws_ec2_sg_compare Determines If CIDR is applied to security group.
# TYPE aws_ec2_sg_compare counter
aws_ec2_sg_compare{name="my-sg4",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="13.224.0.0/14",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg4",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="13.249.0.0/16",sg_id="sg-xxxxx",errno="0",error=""} 0
aws_ec2_sg_compare{name="my-sg4",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="13.32.0.0/15",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg4",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="13.35.0.0/16",sg_id="sg-xxxxx",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg4",region="us-east-1",proto="tcp",from_port="443",ip="v4",cidr="13.52.204.0/23",sg_id="sg-xxxxx",errno="0",error=""} 1
...
aws_ec2_sg_compare{name="my-sg6",region="us-east-1",proto="tcp",from_port="443",ip="v6",cidr="2600:9000:eee::/48",sg_id="sg-yyyyy",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg6",region="us-east-1",proto="tcp",from_port="443",ip="v6",cidr="2600:9000:4000::/36",sg_id="sg-yyyyy",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg6",region="us-east-1",proto="tcp",from_port="443",ip="v6",cidr="2600:9000:3000::/36",sg_id="sg-yyyyy",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg6",region="us-east-1",proto="tcp",from_port="443",ip="v6",cidr="2600:9000:f000::/36",sg_id="sg-yyyyy",errno="0",error=""} 1
aws_ec2_sg_compare{name="my-sg6",region="us-east-1",proto="tcp",from_port="443",ip="v6",cidr="2600:9000:fff::/48",sg_id="sg-yyyyy",errno="0",error=""} 0
...
```

As you can see, the second line ipv4 address returns a `0` and the last ipv6 address returns a `0`, which means these IP CIDR are missing in your security groups.


## Grafana setup

### Graphs

* Align the `Min time interval` with what you have set `UPDATE_TIME` to.
* Add you metrics by the name of your specified security group name
* Set the legend to `{{ cidr }}` to have only the CIDR displayed

![Grafana](https://raw.githubusercontent.com/cytopia/aws-ec2-sg-exporter/master/doc/grafana-graph-setup.png "Grafana Graph Setup Example")

Once this is done, your graph will look similar to this one:

![Grafana](https://raw.githubusercontent.com/cytopia/aws-ec2-sg-exporter/master/doc/grafana-graph.png "Grafana Graph Example")

### Single Stat

* Align the `Min time interval` with what you have set `UPDATE_TIME` to.
* Add you metrics by the name of your specified security group name
* `sum()` gives your the total sum of values (`0` and `1`) and `count()` will give you the total number of available IP addresses

![Grafana](https://raw.githubusercontent.com/cytopia/aws-ec2-sg-exporter/master/doc/grafana-single-stat-setup.png "Grafana Single Stat Setup Example")

Once this is done, your single stat will look similar to this one:

![Grafana](https://raw.githubusercontent.com/cytopia/aws-ec2-sg-exporter/master/doc/grafana-single-stat.png "Grafana Single Stat Example")


## Usage without Docker

Docker is not necessarily required and you can simply use the exporter bash script: [aws-ec2-sg-exporter](data/src/aws-ec2-sg-exporter).

By doing so, you need to ensure you have all requirements installed on your system (`aws` and `jq` binary as well as `bash` itself).

Additionally you will have to make sure the script's `stdout` will somehow be served by a webserver.
The recommended method is to have some mechanism which writes the script's output atomically to a static html file and a web server will simply serve it.

[aws-ec2-sg-exporter](data/src/aws-ec2-sg-exporter) will read all configuration from the shell's environment, so in order to use this script you need to export
all values to your env. See [Environment variables](#environment-variables) for possible values.


## Error handling

The exporter writes all errors to `stderr` regardless of using Docker or the standalone [aws-ec2-sg-exporter](data/src/aws-ec2-sg-exporter) script.

### Expected errors

**`An error occurred (RequestExpired) when calling the DescribeSecurityGroups operation: Request has expired.`**

In case you are using IAM roles, your session has simply been expired and needs to be renewed. It
is recommended to user IAM users instead without session.


**`[ERR] 2019-08-18 10:55:11 (aws-ec2-sg-exporter): No sg found by name: sg-name22 in region: us-east-1`**

A security group could not be found by name and region. The exporter will continue to run and output
Prometheus metrics, but will mark all desired/wanted IP CIDR as not found in your security group.


**`[ERR] 2019-08-18 10:56:17 (aws-ec2-sg-exporter): Multiple sg found by name: sg-name-* in region: us-east-1: sg-xxxxx,sg-yyyyy`**

Multiple security groups have been found by the specified name and region. The exporter will continue to run and output
Prometheus metrics, but will mark all desired/wanted IP CIDR as not found in your security group.


### Unexpected errors

**`write error: Broken pipe`**

This is a very rare condition and will most likely be caused by using broken shell pipes (`|`)
in your commands specified via `SG*_IP4_CMD` or `SG*_IP6_CMD`.

In case you are using something like this:
```bash
curl http://some-page.tld | grep -E '^[.0-9]+/[0-9]+$';
```
Consider to add a buffer in between:
```
curl http://some-page.tld | dd obs=1M 2>/dev/null | grep -E '^[.0-9]+/[0-9]+$';
```

See here: https://superuser.com/a/642932/705357


## License

**[MIT License](LICENSE)**

Copyright (c) 2019 [cytopia](https://github.com/cytopia)
