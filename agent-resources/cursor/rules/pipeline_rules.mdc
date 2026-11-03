---
alwaysApply: false
---

# Notes Rules for Agentic AI

Guidelines for creating effective, concise, and well-structured Nextflow pipelines.

## Documentatation

Documentaiion and guidelines for the required technologies can be found here. Refer to them if you are unsure about something.

- Nextflow documentation: https://www.nextflow.io/docs/latest/
- nf-core documentation: https://nf-co.re/docs/
- nf-core guidelines: https://nf-co.re/docs/guidelines/
- nf-core tools documentation: https://nf-co.re/docs/nf-core-tools
- nf-test documentation: https://www.nf-test.com/docs/getting-started/
- nf-schema documentation: https://nextflow-io.github.io/nf-schema/latest/

### Other Helpul Documentation

Below are links to the documentation for other important technologies that Nextflow and nf-core often interact with. Refer to them when necessary.

- MultiQC documentation: https://docs.seqera.io/multiqc
- Wave containers documentation: https://docs.seqera.io/wave
- Fusion file system documentation: https://docs.seqera.io/fusion

## General Nextflow Guidelines

### DSL2 Syntax Requirements
- Always use `nextflow.enable.dsl = 2` at the top of scripts
- Use explicit closure parameters instead of implicit `it`
- Use `def` for variable declarations without type annotations
- Prefer explicit parameter declarations in closures

### Script Structure
- Separate script declarations from statements
- Use proper include statements for modules
- Define workflows, processes, and functions as top-level declarations
- Keep entry workflow clean and focused

### Channel Best Practices
- Channels are automatically forked in DSL2 when connecting multiple consumers
- Use descriptive channel names with snake_case
- Properly handle metadata propagation through channels
- Use appropriate channel factories (Channel.fromPath, Channel.fromFilePairs, etc.)

### Process Guidelines
- Use uppercase names with underscores (e.g., `PROCESS_NAME`)
- Include proper input/output channel definitions
- Include `publishDir` for important outputs
- Use `script:` section explicitly when other sections are present
- Avoid `when:` sections - implement conditional logic in workflows instead
  - The exception to this is `task.ext.when == null || task.ext.when`. This is valid code to be `when:` sections.

### Error Handling
- Use `process.shell = ['/bin/bash', '-euo', 'pipefail']` in config
- Handle exit codes properly in process scripts
- Use appropriate error strategies in process directives

## nf-core Specific Guidelines

### Module Standards
- One tool per module (atomic modules)
- Use naming convention: `tool/subtool` for complex tools
- Include proper meta.yml documentation
- Implement stub blocks for testing
- Include version reporting in `versions.yml`

### Process Requirements
- Use `$task.ext.args` for optional arguments
- Implement proper resource labels (process_low, process_medium, etc.)
- Use `${task.cpus}` for multithreading support

### Input/Output Conventions
- Use `tuple val(meta), path(files)` pattern for metadata propagation
- Name outputs with `emit:` keyword
- Mark optional outputs with `optional: true`
- Use `${prefix}` for output file naming

### Configuration Best Practices
- Use `modules.config` for process-specific configurations
- Implement proper resource allocation
- Use profiles for different execution environments
- Enable Wave for container management

### Testing Requirements
- Follow the best practices of test-driven development
- Use nf-test framework for testing
- Test all processes and workflows
- Include minimal test datasets
- Use assertAll() for comprehensive testing
- Test both success and failure scenarios
- Test names should be descriptive and indicate what is being tested.
  - Good test names should:
    - Start with "Should" to make it clear what the expected behavior is
    - Describe the specific functionality or scenario being tested
    - Be clear enough that if the test fails, you know what functionality is broken
  - Examples:
    - "Should convert input to uppercase" - when testing specific functionality
    - "Should handle empty input gracefully" - when testing edge cases
    - "Should respect max memory parameter" - when testing resource constraints
    - "Should create expected output files" - when testing file generation

Describe the specific functionality or scenario being tested

### Documentation Standards
- Include comprehensive README.md
- Document all parameters in nextflow_schema.json
- Use proper keywords for discoverability
- Include usage examples and test commands
- Document software requirements and versions

### CI/CD Requirements
- Test with different execution profiles (singularity, conda)

### Software Dependencies
- Avoid hardcoded paths and URLs
- Use environment variables for sensitive data
- Implement proper secret management

### Performance Optimization
- Use appropriate resource allocation
- Implement proper caching strategies
- Use Fusion file system for cloud deployments
- Optimize channel operations
- Avoid unnecessary data copying

### Error Prevention
- Validate input parameters
- Use proper file existence checks
- Implement graceful error handling
- Provide meaningful error messages
- Use appropriate retry strategies

### File Naming Conventions
- Use lowercase with hyphens for file names
- Use snake_case for variable names
- Use camelCase for function names
- Use UPPERCASE for process names
- Use descriptive, meaningful names throughout
