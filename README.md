#runexp - experiment runner

runexp is a simple loader for executable scripts. It is capable of starting processes in remote servers using
a simple sockets-based protocol.

The simplicity of runexp means it can be executed on a network without need of root access. There is not need
to install anything on the remote machines.

This is not a load balancement manager. Each experiment server must be started with the number of experiments
it will run in parallel, adn each experiment server must have their own copies of any files the experiments will
require to run. The purpose of runexp is that dynamically dispatching experiments to the servers is more efficient
and easier than manually assigning experiments to each experiment server.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

**This software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.**


## Usage example

Here's the scenario: we want to test a program that is located in `/home/me/myexperiment`. This is a MATLAB program
and it is composed of several files (in other words, we can't write a standalone .m file for our jobs).

We want to test different parameters of the function `/home/me/myexperiment/myidea.m`. So we can write several jobs,
each one of them invoking that function with a different parameter value. For instance:

```Matlab
acc = myidea(5);
fprintf('Accuracy with parameter value ''5'' was %0.4f\n', acc);
fprintf('RES:done\n');
```

This is one job. We put this in a `runs`. It will run our experimen with parameter value `5` and report the outcome.
The last line prints a tag so that runexp knows the experiment was succesfully executed (this will change in the
future).

We save our job as a `.m` file in `/home/me/myexperiment/runs/job5.m`. That is all we need. Now to run that job:


### Step 1: starting the manager

1. Make sure the servers have the required files. In this case, the servers should have, somewhere, all the files
   of our program that is in `/home/me/myexperiment`.
1. Go to the path where the program is hosted (e.g., `/home/me/myexperiment`)
1. Launch the queue manager. For instance: `queuemanager -p 5432` (this will open the manager in the port 5432)



### Step 2: Starting the runner

1. Log into the experiment server
1. Go to the directory where the program we want to run is installed (it *could* be `/home/me/myexperiment`, but
   it does not need to be the same as the manager)
1. Launch the experiment runner, providing the number of simultaneous jobs and the URL:PORT configuration where
   the queue manager is installed. For instance: `runexp 8 -c 192.168.0.2:5432`



### Step 3: Check results

1. The manager will start sending jobs to the experiment runners and taking their output. For each job, an
   output file will be saved in the outputs dir (e.g., `/home/me/myexperiment/outputs/job5.res`)
1. The easiest way to see if everything was run is to start the queue manager again with the option `--print-jobs`.
   The queue manager will print the names of any jobs that didn't finish succesfully and quit


## Known limitations

- Failure/success detection is performed by reading the script output, and a particular string pattern is required
for that (or a custom failure/detection script must be written to read the script output)
- In case of failure, the script will only be executed if the queue manager and the remote servers are launched again
- No dependency check: scripts are executed in lexicographic order determined by the script file names
- All communication is performed naively: if the server or the runners disconnect, the behavior is unspecified


## Is this secure?

No.

There is no authentication, no encryption. The queue manager trusts that the runners are valid runexp programs.

If you are running this in a limited environment, there should be no danger. But, again, this program is shipped
**AS IS**. Don't use runexp with sensitive data, or if security is any kind of concern for you.
