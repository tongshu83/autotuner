import files;
import io;
import launch;
import stats;
import string;
import sys;

(void v) setup_run(string dir, string confile, string infile) "turbine" "0.0"
[
"""
	file delete -force -- <<dir>>
	file mkdir <<dir>>
	cd <<dir>>
	file copy -force -- <<confile>> adios2.xml
	file copy -force -- <<infile>> settings-files.json
"""
];

(void v) clearup_run(string dir) "turbine" "0.0"
[
"""
	cd <<dir>>
	file delete -force -- gs.bp
"""
];

(float exectime) launch_wrapper(string run_id, int params[], boolean input = false, int count = 0)
{
	int time_limit = 2;
	if (count < time_limit)
	{
		int gs_cs = params[0];		// gray-scott: the cube size of global array (L x L x L)
		int gs_step = params[1];	// gray-scott: the total number of steps to simulate
		int gs_proc = params[2];	// gray-scott: the total number of processes
		int gs_ppw = params[3];		// gray-scott: the number of processes per worker

		string turbine_output = getenv("TURBINE_OUTPUT");
		string dir = "%s/run/%s" % (turbine_output, run_id);
		string confile = "%s/adios2.xml" % turbine_output;
		string infile = "%s/settings-files.json" % turbine_output;

		int exit_code0;
		string cmd0[];
		if (input)
		{
			string workflow_root = getenv("WORKFLOW_ROOT");
			cmd0 = [ workflow_root/"gs.sh", int2string(gs_cs), int2string(gs_step), dir/"settings-files.json" ];
			setup_run(dir, confile, infile) => 
				(output0, exit_code0) = system(cmd0);
		}
		else
		{
			setup_run(dir, confile, infile) => 
				exit_code0 = 0;
		}

		if (exit_code0 != 0)
		{
			printf("swift: %s failed with exit code %d for the parameters (%d, %d, %d, %d).", 
					cmd0[0]+" "+cmd0[1]+" "+cmd0[2]+" "+cmd0[3], exit_code0, 
					params[0], params[1], params[2], params[3]);
			sleep(1) =>
				exectime = launch_wrapper(run_id, params, input, count + 1);
		}
		else
		{
			int nwork1;
			if (gs_proc %% gs_ppw == 0) {
				nwork1 = gs_proc %/ gs_ppw;
			} else {
				nwork1 = gs_proc %/ gs_ppw + 1;
			}
			int timeout;
			timeout = 1200 * float2int(2 ** count);

			string cmd1 = "../../../../../gray-scott/build/gray-scott"; 

			string args1[] = split("settings-files.json", " ");	// mpiexec -n 8 build/gray-scott settings-files.json

			string envs1[] = [ "swift_chdir="+dir, 
			       "swift_output="+dir/"output_gray-scott.txt", 
			       "swift_exectime="+dir/"time_gray-scott.txt",
			       "swift_timeout=%i" % timeout,
			       "swift_numproc=%i" % gs_proc,
			       "swift_ppw=%i" % gs_ppw ];

			printf("swift: launching with environment variables: %s (%s, %s)", cmd1, envs1[4], envs1[5]);
			sleep(1) =>
				exit_code1 = @par=nwork1 launch_envs(cmd1, args1, envs1) =>
				sleep(1) =>
				clearup_run(dir);

			if (exit_code1 == 124)
			{
				sleep(1) =>
					exectime = launch_wrapper(run_id, params, input, count + 1);
			}
			else
			{
				if (exit_code1 != 0)
				{
					exectime = -1.0;
					failure(run_id, params);
					printf("swift: The launched application %s with parameters (%d, %d, %d, %d) did not succeed with exit code: %d.", 
							cmd1, params[0], params[1], params[2], params[3], exit_code1);
				}
				else
				{
					exectime = get_exectime(run_id, params);
				}
			}
		}
	}
	else
	{
		exectime = -1.0;
		failure(run_id, params);
		printf("swift: The launched application with parameters (%d, %d, %d, %d) did not succeed %d times.",
				params[0], params[1], params[2], params[3], time_limit);
	}
}

(void v) failure(string run_id, int params[])
{
	string turbine_output = getenv("TURBINE_OUTPUT");
	string dir = "%s/run/%s" % (turbine_output, run_id);
	string output = "%0.3i\t%0.3i\t%0.4i\t%0.2i\t%s"
		% (params[0], params[1], params[2], params[3], "inf");
	file out <dir/"time.txt"> = write(output);
	v = propagate();
}

(float exectime) get_exectime(string run_id, int params[], int count = 0)
{
	int time_limit = 3;
	if (count < time_limit)
	{
		string turbine_output = getenv("TURBINE_OUTPUT");
		string dir = "%s/run/%s" % (turbine_output, run_id);

		string cmd[] = [ turbine_output/"get_maxtime.sh", dir/"time_gray-scott.txt" ];
		sleep(1) =>
			(time_output, time_exit_code) = system(cmd);

		if (time_exit_code != 0)
		{
			sleep(1) =>
				exectime = get_exectime(run_id, params, count + 1);
		}                       
		else                    
		{
			exectime = string2float(time_output);
			if (exectime >= 0.0)
			{
				printf("exectime(%i, %i, %i, %i): %f", params[0], params[1], params[2], params[3], exectime);
				string output = "%0.3i\t%0.3i\t%0.4i\t%0.2i\t%f" 
					% (params[0], params[1], params[2], params[3], exectime);
				file out <dir/"time.txt"> = write(output);
			}
			else
			{
				printf("swift: The execution time (%f seconds) of the launched application with parameters (%d, %d, %d, %d) is negative.", 
						exectime, params[0], params[1], params[2], params[3]);
			}
		}
	}
	else
	{
		exectime = -1.0;
		printf("swift: Failed to get the execution time of the launched application of parameters (%d, %d, %d, %d) %d times.",
				params[0], params[1], params[2], params[3], time_limit);
	}
}

main()
{
	int ppn = 36;   // bebop
	int wpn = string2int(getenv("PPN"));
	int ppw = ppn %/ wpn - 1;
	int workers;
	if (string2int(getenv("PROCS")) - 2 < 31) {
		workers = string2int(getenv("PROCS")) - 2;
	} else {
		workers = 31;
	}

	// 0) gray-scott: the cube size of global array (L x L x L)
	// 1) gray-scott: the total number of steps to simulate
	// 2) gray-scott: the total number of processes
	// 3) gray-scott: the number of processes per worker
	int sample_num = 2;
	conf_samples = file_lines(input("smpl_gs.csv"));

	float exectime[];
	int codes[];
	foreach i in [0 : sample_num - 1 : 1]
	{
		params_str = split(conf_samples[i], "\t");
		int params[];
		foreach j in [0 : 3 : 1]
		{
			params[j] = string2int(params_str[j]);
		}
		if (params[3] <= ppw)
		{
			int nwork;
			if (params[2] %% params[3] == 0) {
				nwork = params[2] %/ params[3];
			} else {
				nwork = params[2] %/ params[3] + 1;
			}
			if (nwork <= workers)
			{
				exectime[i] = launch_wrapper("%0.3i_%0.3i_%0.4i_%0.2i" 
						% (params[0], params[1], params[2], params[3]),
						params, false);

				if (exectime[i] >= 0.0) {
					codes[i] = 0;
				} else {
					codes[i] = 1;
				}
			}
		}
	}
	int failure_num = sum_integer(codes);
	if (failure_num == 0) {
		printf("swift: all the launched applications succeed.");
	} else {
		printf("swift: %d of %d launched applications did not succeed.", failure_num, sample_num);
	}
}

