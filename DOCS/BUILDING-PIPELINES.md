Steps to build pipelines:

1. Make a new project directory and run `newproj`

   - This should run a smoke test (verifying the scaffold runs), if not run it yourself to make sure boiler plate is good

2. Commit

3. Get appropriate test data and put it into TESTS/TEST_DATA

   1. use the `nf-core test-datasets` to help you with this

4. Populate `samplesheet.test.csv` with test data

5. Update `assets/schema_input.json`

6. Update your test profile `conf/test.config`

```
input = "${projectDir}/samplesheet.test.csv"
```

6. Commit

7. Sample sheet extraction will try to be handled `subworkflows/local/utils_nfcore_pipeline_pipeline/main.nf`.

although you might have to edit it:

```groovy
// BEFORE
   Channel
        .fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map {
            meta, fastq_1, fastq_2 ->
                if (!fastq_2) {
                    return [ meta.id, meta + [ single_end:true ], [ fastq_1 ] ]
                } else {
                    return [ meta.id, meta + [ single_end:false ], [ fastq_1, fastq_2 ] ]
                }
        }
        .groupTuple()
        .map { samplesheet ->
            validateInputSamplesheet(samplesheet)
        }
        .map {
            meta, fastqs ->
                return [ meta, fastqs.flatten() ]
        }
        .set { ch_samplesheet }

// AFTER
    Channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
        .map { meta, reads, primary_assembly, alternate_assembly ->
            return [meta, reads, primary_assembly, alternate_assembly]
        }
        .set { ch_samplesheet }
```

8. Check what the sample sheet extraction looks adding this to `workflows/main.nf`. Example:

```groovy
workflow PIPELINE {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_samplesheet.view() // Add this

    // OR

    ch_samplesheet.map { meta, reads, primary_assembly, alternate_assembly ->
        log.info("Processing sample: ${meta.id}")
        log.info("  Reads: ${reads}")
        log.info("  Primary assembly: ${primary_assembly}")
        log.info("  Alternate assembly: ${alternate_assembly}")

        // Return the processed data for further processing
        [meta, reads, primary_assembly, alternate_assembly]
    }


    ...
```

9. Now begin testing with nf-test. First, edit `nf-test.config` to use singularity 

```groovy
profile "singularity,test"
```

10. Modify `tests/default.nf.test` with all your desired tests

Then run

```bash
nf-test test tests/default.nf.test --verbose
```

11. If it's good, commit input handling.

```bash
git add .
git commit -m "update parsing samplesheet "
```


```bash
git add .
git commit -m "parse samplesheet correctly"
```

12. Begin adding modules using Test driven development.
1. Check if the program you're looking for is already an nf-core module, with `nf-core modules list remote`

   1. If it is, add it with `nf-core modules install`
    - By default, `nf-test init` will generate the following lines in `nf-test.config`
    ```groovy
    // ignore tests coming from the nf-core/modules repo
    ignore 'modules/nf-core/**/tests/*', 'subworkflows/nf-core/**/tests/*'
    ```
    - This means that any tests for modules and subworkflows you pull from nf-core will be ignored (you can verify this with `nf-test list`). 
    - You can therefore skip writing theses for these modules and just take for granted that they work.
    - However, if you want to test something to be sure, remember to remove these lines from the config file.
   2. If it isn't create one with with `nf-core modules create`

1. Create a new subworkflow to add your modules with `nf-core subworkflows create`


## Working with Seqera AI on the HPC

As of September 2025, working with Seqera AI on an HPC is a little bit finicky because it doesn't have cursor-style integration. It is only run through the website. So to be able to pass in your codebase on the HPC and quickly review the edits you need to use some remote repository intermediate. 

I have created a quick workflow to do this.

1. On the HPC, create a GitHub repository with your edits. 

2. Connect this repository to Seqera AI and ask it to do something for you.

3. When it's done, download the `.tar.gz` file, and I have created a helper script `~/custom-bash-scripts/upload-and-pr-seqera.sh` to create a branch on the remote repository with the Seqera AI edits.
    - Importantly, this runs `BRANCH_NAME="auto-upload-$(date +%Y%m%d%H%M%S)"`, which creates a new branch with a timestamp in your remote repository.

4. On the HPC, use git to integrate your changes

```bash
# Fetch the remote
git fetch

# View that the new branch is there
git branch -a

# Switch to your master/main branch
git checkout master

# Merge the new branch
git merge origin/auto-upload-20250908142426

# Review the edits

# Once done, delete the remote branch
git push origin --delete auto-upload-20250908142426
```
