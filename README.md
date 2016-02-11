What is this?
==

runexp: simple script to run experiments in several servers

runexp is a simple loader for executable scripts. It is capable of starting processes in remote servers using
distributed filesystem communication.

The simplicity of runexp means it can be executed on a network without need of root access. There is not need
to install anything on the remote machines, provided that a distributed filesystem is available.

This version of runexp uses sockets for communication between the queue manager and the runners. It is an ongoing
work to stop using files on a distributed filesystem for communication. However, the distributed filesystem is
still required for the runners to have access to the jobs, and for the master to have access to the outputs. This
is planned to be changed as well.

This is not a load balancement manager. Each experiment server must be started with the number of experiments
it will run in parallel. The purpose of this script is that dynamically dispatching experiments to the servers
is more efficient and easier than manually assigning experiments to each experiment server.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in
compliance with the License. You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

**This software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied.**



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
  pattern is "RES:" and it is usually followed by an experimental result. 


Known limitations
-----------

- Requires that a distributed filesystem is present
- Failure/success detection is performed by reading the script output, and a particular string pattern is required
for that (or a custom failure/detection script must be written to read the script output)
- In case of failure, the script will only be executed if the queue manager and the remote servers are launched again
- No dependency check: scripts are executed in lexicographic order determined by the script file names
- All communication is performed naively: if the server or the runners disconnect, the behavior is unspecified
