# new-ibex-project-template
This repository contiains all the necessary files and instructions to initialize a new directory on the KAUST IBEX for a data analysis project.

## Cloning this directory into IBEX

On IBEX, all work should be performed in your work folder. This is found at `/ibex/user/YOUR_KAUST_USERNAME`
```bash
# Change into your work folder
cd /ibex/user/YOUR_KAUST_USERNAME

# Create a directory for your data analysis project and change into it
mkdir YOUR_PROJECT_NAME
cd YOUR_PROJECT_NAME

# Copy all the files in this repository into your new project directory
git clone --depth 1 https://github.com/mpampuch/new-ibex-project-template temp_folder && rsync -av temp_folder/ . && rm -rf temp_folder
```

## Activating a conda environement

Conda is used for managing your programs and software packages. You need to make sure you are able to activate the enviroment in the `env` folder found in your new project for the following steps to work. To do so, try running the commands

```bash
# Make sure you are in your new project folder before starting
conda activate mamba
mamba env create --prefix ./env --file environment.yml --force
conda activate $(pwd)/env
```

If you don't have a conda environment called mamba, run the following code first before retrying the above

```bash
conda create --name mamba
conda activate mamba
conda install -c conda-forge mamba
conda deactivate mamba
```

If that still doesn't work, make sure you have conda installed. Try to troubleshoot using this video: https://www.youtube.com/watch?v=X-W7aVXH3_w

**Side note:** This is the best video on what conda is and how and why to use it. It's 3h long and very dry but it's extremely useful in order to know how to effectively stay organized before analyzing large data https://www.youtube.com/watch?v=GW9_AXz-G5s

## Activating VSCode (code-server)

Trying to do data science projects in your Terminal will make you go insane. Using code-server (VSCode for a remote machine) will make writing code and working on a remote machine 10x easier.

To activate run

```bash
# Make sure you are in your project folder before starting

# Activate your conda environment
conda activate $(pwd)/env

# Run the script to launch code-server
sbatch bin/launch-code-server.sbatch

# Monitor your SLURM process until your job starts running
watch -d -n 10 squeue -u YOUR_IBEX_USERNAME
# Once your job is running, continue with the following steps
# Note: You can use Ctrl + C (on Mac) to get out of this view

# code-server should now be activating. This should be almost instantaneous or very quick. Monitor it (and view the output of the initialization) by running
tail -n 1000 -f bin/launch-code-server-*
# Note: You can use Ctrl + C (on Mac) to get out of this view

# Once it's finished, proceed to the next steps
```

At this point switch over to your local machine and open a new terminal 

```bash
# Paste the SSH command outputted by the code-server initialiation, it will be something like this
ssh -L ${CODE_SERVER_PORT}:${COMPUTE_NODE}:${CODE_SERVER_PORT} ${USER}@ilogin.ibex.kaust.edu.sa 
```

Do not close this terminal. If you do the code-server session will stop running. Move it to the background somewhere or minimize the window.

Now open a browser on your local machine.

```bash
# In your browser, paste the URL generated by the code-server initialiation, it will be something like this
localhost:${CODE_SERVER_PORT}/?folder=${PROJECT_DIR}
```

Now you should be able to have a VSCode-like view of your IBEX directory through your browser window. Any files or work you do here are directly saved on the IBEX.

## Running a job on IBEX

Jobs on IBEX should be executed using the SLURM job scheduler. The best way to do this is to put the program you want to execute inside the `launch-job.sbatch` script and then run it as follows:

```bash
sbatch launch-job.sbatch
```

You can monitor your job using `squeue`

```bash
# Monitor your SLURM process to see when your job starts running
watch -d -n 10 squeue -u YOUR_IBEX_USERNAME
# Note: You can use Ctrl + C (on Mac) to get out of this view
```

**Note:** Jobs should only be submitted on *login nodes* on IBEX. It's often tempting to run all your jobs from code-server because that's where you'll be doing most of your work, but in order to get code-server up and running you had to run the initialization through a job so code-server is running on a *compute node*. The way I like to do my workflow is to have a split screen of my code-server window and my terminal. On code-server is where I write all my programs and configurations, and on the terminal is where I execute the jobs when I'm ready.

Example: 

![IBEX working environment](https://i.imgur.com/hNDYT1c.jpg)



## Backing up your code-server-extensions

Will update this when I figure it out

## Activating RStudio Server

Eventually you will need to use R to analyze some data. The only viable way to use R is within RStudio. In order to get access to RStudio but have it run on the IBEX use the following instructions.

```bash
# Make sure you are in your project folder before starting

# Activate your conda environment
conda activate $(pwd)/env

# Run the script to launch RStudio Server
sbatch bin/launch-rstudio-server.sbatch

# Monitor your SLURM process until your job starts running
watch -d -n 10 squeue -u YOUR_IBEX_USERNAME
# Once your job is running, continue with the following steps
# Note: You can use Ctrl + C (on Mac) to get out of this view

# RStudio Server should now be activating. This could take upwards of 10 minutes. Monitor it (and view the output of the initialization) by running
tail -n 1000 -f bin/launch-rstudio-server-*
# Note: You can use Ctrl + C (on Mac) to get out of this view

# Once it's finished, proceed to the next steps
```

At this point switch over to your local machine and open a new terminal 

```bash
# Paste the SSH command outputted by the RStudio Server initialiation, it will be something like this
ssh -L ${PORT}:${HOSTNAME}:${PORT} ${SINGULARITYENV_USER}@ilogin.ibex.kaust.edu.sa
```

Do not close this terminal. If you do the RStudio Server session will stop running. Move it to the background somewhere or minimize the window.

Now open a browser on your local machine.

```bash
# In your browser, paste the URL generated by the RStudio Server initialiation, it will be something like this
http://localhost:${PORT}
```

You should be redirected to RStudio Server.

RStudio Server requires you to be authenticated. The credentials should be in the Studio Server initialiation output

```bash
user: KAUST_USERNAME
password: RANDOMLY_GENERATED_PASSWORD
```

After this you should finally be in RStudio on the IBEX (viewed in your browser). Before you can start doing any work, make sure to enter the following command in the R Console.

```R
setwd("/mnt")
```

And in the `Files` pane, click on  `More` (the gear icon) -> `Go To Working Directory`

Now you're finally ready to begin working in RStudio Server. Any files you create will automatically appear in your project directory in IBEX.

NOTE: If you are creating a new R project from RStudio Server, make sure you create the project as a subdirectory of /mnt
