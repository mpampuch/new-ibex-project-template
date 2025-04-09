# new-ibex-project-template
This repository contiains all the necessary files and instructions to initialize a new directory on the KAUST IBEX for a data analysis project.

## Quick Setup

If you want to quickly set up a new project directory on the IBEX with all the default configurations I set up here, you can just run this inside your new project directory:

```bash
newproj
```

I created this alias for myself and it simply sources [this script](https://github.com/mpampuch/dot_files/blob/main/kaust-ibex/CUSTOM_SCRIPTS/newproj.sh) for me, which is just a consolidations of the rest of the initialization instructions in this notebook.


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
Now all the files and programs you need to complete your specific data analysis project will be stored in the folder you created. Copy or move all the data you need into this folder to make sure you stay organized.

## Activating your virual environment

## Using IBEX Modules

Modules on HPCs like the IBEX are a way to manage software environments and dependencies on supercomputers or clusters. They allow users to easily load, unload, and switch between different versions of software, libraries, or tools without conflicting with each other. They help manage environment variables (e.g., `PATH`, `LD_LIBRARY_PATH`) to ensure the correct software and libraries are available for your jobs. They allow you to dynamically modify your environment without permanently changing it. They also help with dependency handling because modules ensure that the correct dependencies are loaded automatically for each software packages. They are also isolated, so they prevent conflicts between different software versions or libraries that might otherwise interfere with each other.

To view available modules on the IBEX, you can use:

```bash
module avail
```

To load a specific module, run:

```bash
module load <module_name>
```

Unloading modules is done the same way except with `unload` instead of `load`.

To list all the loaded modules in your environment you can use:

```bash
module list
```

On IBEX, the two key softwares that I use for most of my projects are `nextflow` and `singularity` (and `nf-core` but that comes bundled with `nextflow` now). I have created a file called `env.sh` that automatically loads these modules so that you can quickly prepare you software environment for each new project. Simply run:

```bash
source env.sh
```

If you would like to use more IBEX modules in your enviroment, simply modify the `env.sh` file with your desired IBEX module and re-run the above command.

### Modulefiles

Behind the scenes, modules are defined by modulefiles, which are scripts that set environment variables and load dependencies. These files are typically located in directories like `/usr/share/modules/modulefiles` or `/opt/apps/modulefiles`.

Example of a simple modulefile:

```bash
#%Module1.0
set version 3.8
set prefix /opt/apps/python/$version
prepend-path PATH $prefix/bin
prepend-path LD_LIBRARY_PATH $prefix/lib
```

If you want to mess around with the modulefules, you might need to reach out to the IBEX administrators. For the most part you won't ever have to do this.

## Using Conda

> [!NOTE] 
> Building your own conda environments is not recommended by the KAUST Supercomputing Core Labs team, especially for softwares that need permissions properly configured (like Singularity and other container technologies). It's if the software is available through IBEX modules, then it's recommended to just use those because are already prebuilt and optimized for the IBEX. However, building your own environment can be really useful especially when using softwares that aren't pre-available on the IBEX. If you decide that using a enviroment with IBEX modules will be insufficient for your project, follow these instructions instead.

Conda is used for managing your programs and software packages. You need to make sure you are able to activate the enviroment in the `env` folder found in your new project for the following steps to work. The `env` folder is created using the the `environment.yml` file. Modify this file to include any softwares or packages that you will need to perform your data analysis. To find out how to correctly install the tool that you need, search for it on https://anaconda.org/ and copy the name of the tool exactly as it appears on the website into the `dependencies:` section of the `environment.yml` file. Once you have all the tools you need to conduct your analysis, run the following commands.

```bash
# Make sure you are in your new project folder before starting
conda activate mamba
mamba env create --prefix ./env --file environment.yml --force
conda activate $(realpath env/)
```

If you don't have a conda environment called mamba, run the following code first before retrying the above

```bash
conda create --name mamba
conda activate mamba
conda env create -f .mamba_environment.yml
# conda install -c conda-forge mamba=1.5.3  ## If the above doesn't work, try this
# conda install -c conda-forge mamba  ## If the above still doesn't work, try this
conda deactivate mamba
```

If that still doesn't work, make sure you have conda installed. Try to troubleshoot using this video: https://www.youtube.com/watch?v=X-W7aVXH3_w

**Side note:** This is the best video on what conda is and how and why to use it. It's 3h long and very dry but it's extremely useful in order to know how to effectively stay organized before analyzing large data https://www.youtube.com/watch?v=GW9_AXz-G5s

#### A note on installing dependencies

Most of the dependencies you will need should be able to be found on https://anaconda.org/. However, some Python packages may not be able to be found in the anaconda repository and may need to be installed using `pip` ([see here for more info](https://pypi.org/project/pip/)). To install packages using conda as well as pip, you need to create a `requirements.txt` file in addition to your `environment.yml` file. 
1. Inside `requirements.txt` add all your Python specific packages (and optionally with versions that you want to install using pip). See [here](https://learnpython.com/blog/python-requirements-file/) for further instructions.
2. Inside `environment.yml`, under the `dependencies:` section add the following code:
```yml
dependencies:
  - pip
  - pip:
      - '-r requirements.txt'
```
- You may need to prefix `file:` to your `requirements.txt`. Example:
```yml
dependencies:
  - pip
  - pip:
      - '-r file:requirements.txt'
```

With these adjustments, you should be able to install every software needed for your data analysis project.

## Activating VSCode (code-server)

Trying to do data science projects in your Terminal will make you go insane. Using code-server (VSCode for a remote machine) will make writing code and working on a remote machine 10x easier.

To activate run

```bash
# Make sure you are in your project folder before starting

# Activate your environment
source env.sh

# Run the script to launch code-server
sbatch bin/launch-code-server.sbatch

# Monitor your SLURM process until your job starts running
watch -d -n 10 "(squeue -u $USER | awk '{print \$5}' | grep -v 'ST' | sort | uniq -c) && (squeue -u $USER -o \"%.8i %.70j %.8u %.2t %.8M %.5D %R %Z\" | awk '{print \$0}' | sort)"
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

**Do not close this terminal.** If you do the code-server session will stop running. Move it to the background somewhere or minimize the window.

Now open a browser on your local machine.

```bash
# In your browser, paste the URL generated by the code-server initialiation, it will be something like this
localhost:${CODE_SERVER_PORT}/?folder=${PROJECT_DIR}
```

Now you should be able to have a VSCode-like view of your IBEX directory through your browser window. Any files or work you do here are directly saved on the IBEX.

## Running a job on IBEX

Jobs on IBEX should be executed using the SLURM job scheduler. The best way to do this is to put the program you want to execute inside the `launch-job.sbatch` script. Modify the resource requirements for the job at the top of the script and add the commands needed to execute your job at the bottom of your script. You can use this tool to help you configure your jobs https://www.hpc.kaust.edu.sa/ibex/job.
Once your job file is finished, run it as follows:

```bash
sbatch launch-job.sbatch
```

You can monitor your job using `squeue`

```bash
# Monitor your SLURM process to see when your job starts running
watch -d -n 10 "(squeue -u $USER | awk '{print \$5}' | grep -v 'ST' | sort | uniq -c) && (squeue -u $USER -o \"%.8i %.70j %.8u %.2t %.8M %.5D %R %Z\" | awk '{print \$0}' | sort)"
# Note: You can use Ctrl + C (on Mac) to get out of this view
```

**Note:** Jobs should only be submitted on *login nodes* on IBEX. It's often tempting to run all your jobs from code-server because that's where you'll be doing most of your work, but in order to get code-server up and running you had to run the initialization through a job so code-server is running on a *compute node*. The way I like to do my workflow is to have a split screen of my code-server window and my terminal. On code-server is where I write all my programs and configurations, and on the terminal is where I execute the jobs when I'm ready.

Example: 

![IBEX working environment](https://i.imgur.com/hNDYT1c.jpg)



## Backing up your code-server extensions

This repository contains all the files for the extensions I downloaded for use on code-server on the KAUST IBEX https://github.com/mpampuch/ibex-code-server-extensions-backup.

Code server extensions are really helpful for a variety of tasks and make writing programs less tedius and less error-prone. I've curated the most essential ones in my opinion for using and performing data analysis on code-server. 

When initializing code-server on the IBEX from a new project folder, sometimes your extensions don't get saved to this new code-server instance. It would be very annoying to have to re-install every single extension you downloaded from a previous instance every single time you open up code-server so as a work-around I've created a backup folder with all the extension files so that you can just import them all with one command. 

This is how I recommend doing it.

### Copy the extension backups into your home folder

Your IBEX home directory stores is found at `/home/YOUR_KAUST_USERNAME`. No work is supposed to be done here, but it is a good place for storing configuration files. I would recommend cloning these extensions to your home directory and storing them there.

```bash
# Change into your home directory
cd /home/YOUR_KAUST_USERNAME # or just do cd ~

# Clone this repository into your home directory
git pull https://github.com/mpampuch/ibex-code-server-extensions-backup
# You may have to run module load git if you don't have git activated
```

### Import the extensions into your project

In order for code-server to read your extensions, they have to be in this folder `/ibex/user/YOUR_KAUST_USERNAME/YOUR_PROJECT_NAME/env/share/code-server/extensions/`
- In order to have the `env` folder, make sure you have created a conda environment using the instructions found above.

If this folder is empty or your extensions aren't loading in your code-server, run this command

```bash
# Make sure you are in your project folder before starting 
# Also make sure your extensions backup folder is in your home directory

# Copy all your extensions to your project folder
cp -rv ~/ibex-code-server-extensions-backup/* ./env/share/code-server/extensions/
```

Once this is done, launch or refresh your code-server instance and all your code-server extensions should be installed.
- Some extensions need a reload of the code-server instance, so to get all of them installed you might need to reload twice.

Now you're ready to work effectively.

### Creating a new backup

If you install any extensions whlie you're working in code-server, it's probably a good idea to back them up because there's a good chance they'll be useful to you in the future. To do this, simply do what was done previously in reverse. Copy all the files out of your code-server extensions folder and into your home directory.

```bash
# Make sure you are in your project folder before starting 
# Also make sure your extensions backup folder is in your home directory

# Copy all your extensions to your home folder
cp -rv ./env/share/code-server/extensions/* ~/ibex-code-server-extensions-backup/ 
```

Now all your backups should be up to date. From here you can pull them off the IBEX or push them to a GitHub repository if you want extra security.

> [!TIP]
> In my opinion, the Bearded Theme Monokai themes (from the Bearded Theme v9.3.0 extension) are the best color themes to use code-server with.

## Activating RStudio Server

Eventually you will need to use R to analyze some data. The only viable way to use R is within RStudio. In order to get access to RStudio but have it run on the IBEX use the following instructions.

```bash
# Make sure you are in your project folder before starting

# Activate your environment
source env.sh

# Run the script to launch RStudio Server
sbatch bin/launch-rstudio-server.sbatch

# Monitor your SLURM process until your job starts running
watch -d -n 10 "(squeue -u $USER | awk '{print \$5}' | grep -v 'ST' | sort | uniq -c) && (squeue -u $USER -o \"%.8i %.70j %.8u %.2t %.8M %.5D %R %Z\" | awk '{print \$0}' | sort)"
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

**Do not close this terminal.** If you do the RStudio Server session will stop running. Move it to the background somewhere or minimize the window.

Now open a browser on your local machine.

```bash
# In your browser, paste the URL generated by the RStudio Server initialiation, it will be something like this
http://localhost:${PORT}
```

You should be redirected to RStudio Server.

RStudio Server requires you to be authenticated. The credentials should be in the RStudio Server initialiation output

```bash
user: KAUST_USERNAME
password: RANDOMLY_GENERATED_PASSWORD
```

After this you should finally be in RStudio on the IBEX (viewed in your browser). Before you can start doing any work, make sure to enter the following command in the R Console.

```R
setwd("/mnt")
```

And in the `Files` pane, click on  `More` (the gear icon) -> `Go To Working Directory`

Now you're finally ready to begin working in RStudio Server. You can now access all the data you have in your project folder on IBEX and any files you create will automatically appear in this folder.

> [!NOTE] 
> If you are creating a new R project from RStudio Server, make sure you create the project as a subdirectory of `/mnt`

## Backing up your IBEX data

Your work folder on IBEX (`/ibex/user/YOUR_KAUST_USERNAME`) has a maximum storage size of 1.5TB. You'll often find yourself cleaning it up to make space for your new projects. Instead of just removing everything, it's a good idea to keep back-ups of your old projects in case you want to refer to them quickly. You can move them to a back up drive (such as the `datawaha/ssbdrive`, which has ~20TB of free space). 

Moving large amounts of data is best performed with the `rsync` command. 
`rsync` is often considered superior to `scp` due to its efficiency, flexibility, and advanced features for file synchronization. Unlike `scp`, which transfers entire files every time and lacks resuming capabilities, `rsync` only transfers changed parts of files, reducing bandwidth usage and time, and can resume interrupted transfers. `rsync` also supports data compression, preserves file attributes, and provides advanced options for excluding files and synchronizing directories, making it ideal for frequent updates and backup tasks. While `scp` is straightforward and secure, `rsync`’s ability to handle large transfers more efficiently and its versatile synchronization options generally make it a better choice for most scenarios.

I created a script to help do this. The code can be found inside this repository at `utils/copy-ibex-folder-to-datawaha.sh`.

I've also configured my ibex environment to take the alias `ibex2dw` for this purpose. An example of how I backup my data is as follows:

```bash
ibex2dw 20241118_P41U1_KSAlib-rapid-barcode
```
