What is this?
==

runexp: simple script to run experiments in several servers

runexp is a simple loader for executable scripts. It is capable of starting processes in remote servers using
distributed filesystem communication.

The simplicity of runexp means it can be executed on a network without need of root access. There is not need
to install anything on the remote machines, provided that a distributed filesystem is available.

This is not a load balancement manager. Each experiment server must be started with the number of experiments
it will run in parallel. The purpose of this script is that dynamically dispatching experiments to the servers
is more efficient and easier than manually assigning experiments to each experiment server.



Preparing
---------

- Create a directory with the experiments to be executed (default ./runs)
- Each job in the run directory should be a valid job file (currently shellscripts or Matlab scripts)
- Create a directory for the outputs of your programs (default ./outputs)



Starting the master
-------------------

- Run queueexp on the base directory



Starting the slaves
-------------------

- Log into each remote server with SSH
- Run runexp on the base directory



Avoid repeated experiments
--------------------------

- By default, the experiment system will check if an experiment has already been executing by testing for a specific
  pattern in a log file in the outputs directory (it must have the same name as the job with .res extension). The
  pattern is "RES:" and it is usually followed by an experimental result. This test may be performed instead by an
  external application. The application must be placed in the outputs directory and must be called testrun.exp. The
  application will be called by either Perl or bash and must be executable. The appliction will receive as argument the
  job name, the job path and the output file path. It must return false (not 0) if the experiment was already executed
  and 0 if the experiment should be executed again.



Known limitations
-----------

- Requires that a distributed filesystem is present
- Has some overhead due to the need of filesystem synchronization to avoid race conditions
- Might possibly run into a race condition that will lock the remote server if the network is too slow (this has not
been observer yet, though; but it is theoretically possible)
- Failure/success detection is performed by reading the script output, and a particular string pattern is required
for that (or a custom failure/detection script must be written to read the script output)
- In case of failure, the script will only be executed if the queue manager and the remote servers are launched again
- No dependency check: scripts are executed in lexicographic order determined by the script file names
