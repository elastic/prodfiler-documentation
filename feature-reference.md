# Prodfiler feature reference

* [Managing projects](#managing-projects)
* [Traces](#the-traces-view)
* [Functions](#the-functions-view)
* [Flamegraph](#the-flamegraph-view)
* [Filtering the results](#filtering-the-results)
* [Missing symbols](#dealing-with-missing-symbols)

## Managing projects

### Sharing your project with other users

You can share a single project among multiple users by clicking on the three dots to the right of
the project name and selecting "People":

![share project1](./pictures/share-project-1.png)
![share project2](./pictures/share-project-2.png)

You will need to write the full email address of the other user you wish to share the project
with.

## The Traces view

This is a view of all stack traces recorded over time.

![sign up page](./pictures/data-arrives.png)

Normally, you will have a large chunk (80%+) of traces in the category "other" (which means they
are quite rare individually, and are grouped into a big chunk), and a few hundred stack traces
shown in the "Top XXX" list below.

The UI subdivides the time interval that you are looking at into smaller chunks, and for each time
chunk Prodfiler retrieves the top-50 most common stack traces. These are then displayed in the
diagram. Because each time chunk may have a different top-50-most-common stack trace, you may end
up with a few hundred stack traces that are made explicit (e.g. not grouped into the "other"
category).

The number of traces collected at a given point in time is correlated to overall CPU load - an idle
machine will generate fewer traces than a machine running at full load, as cores sent to sleep will
not generate traces in Prodfiler.

Clicking on one of the "30M", "1H", "24H", "7D", "30D" buttons will switch the web interface to
display the current point in time minus 30 minutes, 1 hour, etc.

Click-and-drag into the chart allows you to drill down on a particular timeframe. Single-click on
a block in the diagram will pull up the last two stack frames associated with that trace, providing
a bit more context -- a double-click will pop up a window with all stack frames of the trace.

![traces single click screenshot](./pictures/traces-single-click.png)
![traces double click screenshot](./pictures/traces-double-click.png)

## The Functions view

Aside from inspecting the most common traces, you can also inspect the most common **functions**.
Simply click on the "functions" button in the top navigation bar. The time interval you have
already selected will stay the same.

![top n functions screenshot](./pictures/top-n-functions.png)

### Comparing the Top-N functions between two time intervals

It can often be helpful to compare two timeframes or subsets of machines - identifying which
functions got relatively more expensive or relatively less expensive. In the "differential Top-N"
view, you can do just that: Specify two different time frames (or two different subsets of machines
using the filter language), and see which functions got more expensive or less expensive.

![top n functions comparison screenshot](./pictures/top-n-functions-comparison.png)

## The Flamegraph view

Flamegraphs are a common way of visualizing collections of stack traces. By clicking on the
"Flamegraph" button in the top navigation bar, the construction of a flamegraph is triggered on
the backend, and the result will be loaded in the browser. **Please note that this is a somewhat
heavy operation, and it can take 30s or longer to generate and load a flame graph**.

The runtimes to which a particular stack frame belongs are marked by different colors: Brown-ish
hues represent python, mint-ish hues represent native userspace code, green-ish hues are JVM, and
blue-ish hues are from the Linux kernel.

![framegraph screenshot](./pictures/flamegraph-multicolor.png)

![flamegraph kernel screenshot](./pictures/flamegraph-kernel.png)

Your mousewheel should allow navigating the flamegraph on the vertical axis; clicking on individual
frames will re-scale the flamegraph to make the frame the center of the screen. Clicking on an
already-selected frame will pop up a window that provides estimates for the overall CPU consumed
by the frame in question - both in the selected timeframe, but also annualized under the assumption
that the current workload is representative.

## Filtering the results

The filtering language has its own documentation [page](./filtering.md).

## Dealing with missing symbols

By default, Prodfiler should symbolize stack frames for upstream binaries from the Ubuntu and Debian
package repositories.

For many other executables, it may happen that Prodfiler does not immediately have access to the
symbols in question. This will be visible in the stacktraces and flamegraphs:

![no symbols](./pictures/no-syms.png)

In order to provide symbols to Prodfiler, please use the bash script located in
[./scripts/upload_symbols.sh](https://github.com/optimyze/prodfiler-documentation/blob/main/scripts/upload-symbols.sh).

Please be aware that this process can take some time: Even if the symbols are
present in our backend, there can be significant lag (up to 30 minutes) between the backend having
the symbols and the corresponding frames being symbolized properly.

### Unstripped Golang binaries

For unstripped Golang binaries, the easiest way to get the stack frames symbolized is simply running
```
./upload_symbols.sh -u [your email address] -d ./[the executable in question]
```

**Please note that this sends the binary to our backend infrastructure! Do not do this if you
are not comfortable with the executable being processed and stored outside of your infrastructure.**

### Stripped Golang binaries

Stripped Golang binaries still retain a lot of the relevant information in the `.gopclntab` section.
This means you can submit the symbols from these executables by doing

```
./upload_symbols.sh -u [your email address] -d ./[the executable in question] -p
```

This has some downsides: In particular, cgo frames will likely not be symbolized. Whenever
possible, try to provide full DWARF symbols.

### Unstripped C/C++ binaries

Unstripped C/C++ binaries can be uploaded just like unstripped Golang binaries.

### C/C++ binaries with separate DWARF file

Many Linux distributions (but also some build systems) generate the DWARF information into a
separate ELF file. This is the default on Debian and Ubuntu-based systems.

```
./upload_symbols.sh -u [your email address] -d ./[the executable in question] -g ./[dwarf file]
```

### Stripped C/C++ binaries

Sometimes it is difficult to get any DWARF information for an already-deployed binary. We are
working on a solution that - in extreme circumstances - can be used to import symbols from a
*similar* executable, e.g. the same software and version compiled from scratch. Please reach out
if you have a need for this so we can prioritize development accordingly.



