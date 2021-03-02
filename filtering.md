# Querying & filtering results

Profiling results can be restricted to a specific set of hosts in your fleet.

The Prodfiler user interface exposes this functionality through the "Filter" box in the user interface:

![filter box](./pictures/filter_box.png)


## Filter syntax

Conceptually, filtering consists of matching keys against values. Valid keys are defined by Prodfiler and documented below.

* A condition on a given key `key1` must be of the form `key1 ~ "regexp1"`.  
  The value must be a string in double quotes.
* `~` is currently the only supported comparison operator.  
  Literally, the `~` operator means "matches the following [RE2 regular expression](https://github.com/google/re2/wiki/Syntax)".
* Multiple conditions can be joined with the `AND` boolean operator. For example, the following has a valid syntax:  
  `key1 ~ "regexp1" AND key2 ~ "regexp2"`
* Other boolean operators (like `OR`) are not supported at the moment.
* The `NOT` operator can be used to negate a condition, for example:  
  `NOT key1 ~ "regexp1"`
* The `NOT` operator takes precedence over `AND`. This means that:  
  `NOT k1 ~ "r1" AND k2 ~ "r2"`  
  is equivalent to  
  `(NOT k1 ~ "r1") AND k2 ~ "r2"`
* Parentheses can be used freely. However, an `AND` condition cannot be negated with `NOT`. For example, the following is currently rejected:  
  `NOT (k1 ~ "r1" AND k2 ~ "r2")`

## A word of caution

Given that `~` operates on RE2 regular expressions, always keep in mind that values in conditions will be interpreted as such.  
While `19.*` is a valid regular expression, it will match `192.168.0.1` as well as `10.0.1.19`.

## Keys supported by Prodfiler

Currently, keys only allow filtering the results to restrict them to a set of hosts.  

For example, you currently cannot filter results to "only Python", or "only a particular process", or "only a specific container / pod".

There are currently 3 types of keys that can be provided to filter hosts:

### Host-derived keys

* `host:hostname`: the hostname of the machine that is running the Prodfiler agent.
* `host:ip`: the IP address of the machine.  
  In multiple IPs are possible, only one is used: the IP address of the interface through which the Prodfiler traffic is routed.
* `host:kernel_version`: the output of `uname -r` on the machine.
* `host:kernel_proc_version`: the contents of `/proc/version` on the machine.

#### Example

* To select hosts with IP starting with `10.1.`:  
  `host:ip ~ "^10\.1\."`  
  Note the use of `^` (beginning of line) so that `110.1.0.0` can't match the regular expression, and `\.` (escaped dot) so that `10.123.0.0` doesn't match.
* To select hosts with hostname starting with `prod-` or `dev-`:    
  `host:hostname ~ "^(prod|dev)-"`

### EC2-derived keys

The following keys are extracted from the AWS EC2 instance metadata service (if they are present):

Refer to the [EC2 documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-categories.html) to see the meaning and format of each value.
* `ec2:ami-id`
* `ec2:ami-manifest-path`
* `ec2:ancestor-ami-ids`
* `ec2:hostname`
* `ec2:instance-id`
* `ec2:instance-type`
* `ec2:instance-life-cycle`
* `ec2:local-hostname`
* `ec2:local-ipv4`
* `ec2:kernel-id`
* `ec2:mac`
* `ec2:profile`
* `ec2:public-hostname`
* `ec2:public-ipv4`
* `ec2:product-codes`
* `ec2:security-groups`
* `ec2:placement/availability-zone`
* `ec2:placement/availability-zone-id`
* `ec2:placement/region`

#### Examples

* To select instances launched from AMI `ami-123456789`:  
  `ec2:ami-id ~ "ami-123456789"`
* To select instances launched in availability zone `eu-west-1a`:  
  `ec2:placement/availability-zone ~ "eu-west-1a"`
* To select the instance with public IP `1.2.3.4`: 
  `ec2:public-ipv4 ~ "^1\.2\.3\.4$"`

### GCE-derived keys

The following keys are extracted from the Google Compute Engine instance metadata service (if they are present):

Refer to the [GCE documentation](https://cloud.google.com/compute/docs/metadata/default-metadata-values) to see the meaning and format of each value. 
* `gce:instance/id`
* `gce:instance/cpu-platform`
* `gce:instance/description`
* `gce:instance/hostname`
* `gce:instance/image`
* `gce:instance/machine-type`
* `gce:instance/name`
* `gce:instance/tags`
* `gce:instance/zone`
* `gce:instance/network-interfaces/<iface-index>/ip`
* `gce:instance/network-interfaces/<iface-index>/gateway`
* `gce:instance/network-interfaces/<iface-index>/mac`
* `gce:instance/network-interfaces/<iface-index>/network`
* `gce:instance/network-interfaces/<iface-index>/subnetmask`
* `gce:instance/network-interfaces/<iface-index>/access-configs/<cfg-index>/external-ip`

Where `<iface-index>` and `<cfg-index>` should usually only have `0` as a valid value, unless you are running with a more advanced network configuration.

#### Examples

* To select instances running on a Intel Haswell CPU:  
  `gce:instance/cpu-platform ~ "Haswell"`
* To select instances launched with public IP address starting with `35.227`:  
  `gce:instance/network-interfaces/0/access-configs/0/external-ip ~ "^35\.227"`

## FAQ

* **Q: Why is a query returning obscure errors?**  
  A: Currently, the error messages returned are not self-explanatory. Sorry! Make sure the query adheres to the above syntax, or feel free to contact us for assistance.
* **Q: Why are there not results returned?**  
  A: Some things to check:  
  * There is no validation on the key names. For example, if you use `ec3:ami-id` instead of `ec2:ami-id`, no results will be returned, and no error will be raised.
* **Q: Why are there too many results returned?**  
  A: Some things to check:
    * Make sure the values in the filter can be interpreted as RE2 regular expressions.
    Add beginning-of-line and end-of-line matchers if necessary (respectively, `^` and `$`), and remember that `.` matches any character.
* **Q: is it possible to know how many / what hosts were matched by a filter?**  
  Not at the moment.