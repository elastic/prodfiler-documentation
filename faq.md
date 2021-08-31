# Frequently Asked Questions

## I have questions not answered here! Where should I ask them?

On our [community page](https://community.prodfiler.com).

## What language runtimes does Prodfiler support?

The following programming languages are currently supported:

* C/C++
* Go
* Rust
* Java HotSpot (JDK 7-16, AOT and compressed pointers are not supported)
* Python 3.6-3.9
* PHP 7.3-7.4
* Ruby 2.5-3.0.1
* Perl 5.28-5.32

## How much CPU and RAM will the agent consume?

The Prodfiler agent is designed to be used continuously in production and has
a tiny performance footprint (< 1% CPU, ~200MB of RAM).

## Can Prodfiler crash my kernel?

Prodfiler makes use of eBPF to load programs into the kernel. An eBPF program must
pass the eBPF verifier, which ensures that the program is safe to run, before it's
loaded into the kernel. This means that even if the eBPF program is buggy, it can
not crash the kernel.

## How many machines can I deploy the agent to without your backend infrastructure melting?

There is a maximum number of projects (`1`) and a per-project host limit (`20`)
for new accounts. Please contact us to have that limit raised.

## Filtering

* **Q: Why is a query returning obscure errors?**

  **A:** Currently, the error messages returned are not self-explanatory. Sorry! Make sure the query adheres to the filtering syntax, or feel free to contact us for assistance.

* **Q: Why are there no results returned?**

  **A:** Some things to check:
  * There is no validation on the key names. For example, if you use `ec3:ami-id` instead of `ec2:ami-id`, no results will be returned, and no error will be raised.

* **Q: Why are there too many results returned?**

  **A:** Some things to check:
    * Make sure the values in the filter can be interpreted as [RE2](https://github.com/google/re2/wiki/Syntax) regular expressions.
    Add beginning-of-line and end-of-line matchers if necessary (respectively, `^` and `$`), and remember that `.` matches any character.

* **Q: Is it possible to know how many / what hosts were matched by a filter?**

  **A:** Not at the moment.

