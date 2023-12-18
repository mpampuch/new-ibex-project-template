# new-ibex-project-template
This repository contains all the coded to initialize a new directory on the KAUST IBEX that contains all the necessary files to start a data analysis project.

## Cloning this directory into IBEX


```bash
mkdir YOUR_PROJECT_NAME
cd YOUR_PROJECT_NAME

git clone --depth 1 https://github.com/mpampuch/new-ibex-project-template temp_folder && rsync -av temp_folder/ . && rm -rf temp_folder

```

## Activating a conda environement

```bash
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

If that still doesn't work, try to troubleshoot using this video: https://www.youtube.com/watch?v=X-W7aVXH3_w

Side note: This is the best video on what conda is and how and why to use it. It's 3h long and very dry but it's extremely useful in order to know how to effectively stay organized before analyzing large data https://www.youtube.com/watch?v=GW9_AXz-G5s

## Activating VSCode (Code Server)

Trying to do data science projects in your Terminal will make you go insane. Using Code Server (VSCode for a remote machine) will make writing code and working on a remote machine 10x easier.

To activate run

```bash
# Make sure you are in your project folder before starting

# Activate your conda environment
conda activate $(pwd)/env

# Run the script to launch RStudio Server
sbatch bin/launch-code-server.sbatch

# Monitor your SLURM process until your job starts running
watch -d -n 60 squeue -u YOUR_IBEX_USERNAME
# Once your job is running, continue with the following steps

# Code Server should now be activating. This should be almost instantaneous or very quick. Monitor it (and view the output of the initialization) by running
tail -n 1000 -f bin/launch-code-server-*
# Note: You can use Ctrl + C to get out of this view

# Once it's finished, proceed to the next steps
```

At this point switch over to your local machine and open a new terminal 

```bash
# Paste the SSH command outputted by the Code Server initialiation, it will be something like this
ssh -L ${CODE_SERVER_PORT}:${COMPUTE_NODE}:${CODE_SERVER_PORT} ${USER}@ilogin.ibex.kaust.edu.sa 
```

Do not close this terminal. If you do the RStudio Server session will stop running. Move it to the background somewhere or minimize the window.

Now open a browser on your local machine.

```bash
# In your browser, paste the URL generated by the Code Server initialiation, it will be something like this
localhost:${CODE_SERVER_PORT}/?folder=${PROJECT_DIR}
```

Now you should be able to have a VSCode-like view of your IBEX directory through your browser window. Any files or work you do here are directly saved on the IBEX.


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
watch -d -n 60 squeue -u YOUR_IBEX_USERNAME
# Once your job is running, continue with the following steps

# RStudio Server should now be activating. This could take upwards of 10 minutes. Monitor it (and view the output of the initialization) by running
tail -n 1000 -f bin/launch-rstudio-server-*
# Note: You can use Ctrl + C to get out of this view

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
