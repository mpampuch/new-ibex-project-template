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
Now all the files and programs you to complete your specific data analysis project will be stored in the folder you created. Copy or move all the data you need into this folder to make sure you stay organized.

## Activating a conda environment

Conda is used for managing your programs and software packages. You need to make sure you are able to activate the enviroment in the `env` folder found in your new project for the following steps to work. The `env` folder is created using the the `environment.yml` file. Modify this file to include any softwares or packages that you will need to perform your data analysis. To find out how to correctly install the tool that you need, search for it on https://anaconda.org/ and copy the name of the tool exactly as it appears on the website into the `dependencies:` section of the `environment.yml` file. Once you have all the tools you need to conduct your analysis, run the following commands.

```bash
# Make sure you are in your new project folder before starting
conda activate mamba
mamba env create --prefix ./env --file environment.yml --force
conda activate "$(pwd)/env"
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

### A note on installing dependencies

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

# Activate your conda environment
conda activate "$(pwd)/env"

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
watch -d -n 10 squeue -u YOUR_IBEX_USERNAME
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
> In my opinion, the Bearded Theme Monokai Reversed (from the Bearded Theme v9.3.0 extension) is the best color theme to use code-server with.

## Activating RStudio Server

Eventually you will need to use R to analyze some data. The only viable way to use R is within RStudio. In order to get access to RStudio but have it run on the IBEX use the following instructions.

```bash
# Make sure you are in your project folder before starting

# Activate your conda environment
conda activate "$(pwd)/env"

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

### NEW APPROACH

`rsync` suffers when trying to move a lot of small files. It's better to just move one really big file.

Therefore, it may be a good idea to combine all your data into one big `tar` folder and then compress it using `gzip`. Transferring a single big file is much easier and then you can uncompress it at your destination. 

Here is the approach I would use to backup a really big folder to the `ssb-drive`

1. Create a new folder for moving the files

```
work-directory
└── to-move-to-ssb
    └── move-data-here-and-tar-this-folder
```

2. Create one file that contains all your files with `tar`

```bash
tar -cvf move-data-here-and-tar-this-folder.tar move-data-here-and-tar-this-folder/
```

> [!WARNING]
> This by default will copy your file folder. If your original folder is 500Gb, this will create **ANOTHER** 500Gb file (the resulting `.tar` file). Make sure you have space to do this OR figure out a way to do this in-place.

3. ...gzip...

4. ...transfer...

5. ...uncompress... (idk if this should come before or after verifying)

6. ...verify correct data transfer with `md5sum`...

```bash
# On source file
pv move-data-here-and-tar-this-folder.tar | md5sum

# On destination file
pv move-data-here-and-tar-this-folder.tar | md5sum

# Compare the outputs and make sure they match
```

7. ...unpack `.tar`...


### OLD APPROACH

The problem with just natively using `rsync` is that it can be very slow. This is why it's often a good idea to run mulitple `rsync` commands at once, one for each sub-directory of your project. 

Below are examples of `rsync` commands I have used to move large amounts of data around.

To move large amounts of data from my personal laptop to the ssbdrive:

```bash
find /Users/markpampuch/to_learn_share -mindepth 1 -maxdepth 1 -type d | while read -r subdir; do subdir_name=$(basename "$subdir"); rsync -avh --partial --progress --append "/Users/markpampuch/to_learn_share/${subdir_name}/" "/Volumes/ssbdrive/0 Staff and Coworkers/3 PhD Students/Pampuch-Mark/untitled-folder/${subdir_name}/" & [ $(jobs | wc -l) -ge 5 ] && wait -n; done; wait
```

To move large amounts of data from the IBEX work directory to the ssbdrive:

```bash
ssh pampum@ilogin.ibex.kaust.edu.sa 'find /ibex/user/pampum/to-move-to-ssb -mindepth 1 -maxdepth 1 -type d' | while read -r subdir; do subdir_name=$(basename "$subdir"); rsync -avhz --partial --progress --append "pampum@ilogin.ibex.kaust.edu.sa:/ibex/user/pampum/to-move-to-ssb/${subdir_name}/" "/Volumes/ssbdrive/0 Staff and Coworkers/3 PhD Students/Pampuch-Mark/untitled-folder/ibex-data/${subdir_name}/" & [ $(jobs | wc -l) -ge 5 ] && wait -n; done; wait
```

> [!NOTE]
> You can `ssh` into the KAUST IBEX to get some sort of `stdout`, which you can then pipe into the rest of your command.


### ACTUAL WAY

```bash
rsync -avP /ibex/user/pampum/to-move-to-ssb/make-this-a-tar-folder.tar.gz dm.kaust.edu.sa:/datawaha/ssbdrive/97_ibex-backups/ibex-transfer-attempt
```