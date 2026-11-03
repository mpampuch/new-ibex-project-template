# Bioinformatics on Slurm HPC

## Discover local policy first
Inspect site documentation and existing scripts. Do not invent partition names, accounts, QOS values, module names, container paths, scratch locations, or scheduler limits. Record assumptions and ask when the correct local setting is unclear.

## Safe execution
- Start with a tiny diagnostic or dry-run when possible.
- Do not submit production workflows, large job arrays, or expensive workloads without explicit approval.
- Before an approved submission, summarize job count, command, partition/account/QOS, CPUs, memory, wall time, output paths, and likely cost/impact.
- Never cancel jobs, overwrite outputs, or delete shared data without approval.
- Inspect job status, exit code, stderr/stdout, and output completeness before retrying.
- Distinguish scheduler failures, node/infrastructure problems, environment failures, malformed inputs, and software defects.
- Do not interpret partial files as complete results.
- Follow cluster rules for scratch use, data retention, and cleanup.

## Resource correctness
- Keep process/thread counts consistent with allocated CPUs (`--cpus-per-task`).
- Avoid oversubscription from nested tools, OpenMP, BLAS, or workflow parallelism.
- Request memory and wall time based on evidence; document tuning assumptions.
- Use job arrays only when each task is independently addressable and resource bounds are understood.
- Use scheduler dependencies and logs deliberately for multi-step jobs.
- Do not use login nodes for heavy computation contrary to local policy.

## Reproducibility
Record as relevant: input IDs/checksums, software and container versions, parameters, reference/annotation versions, job IDs, resource requests, environment details, random seeds, exit statuses, and log locations. Preserve the exact command and configuration for reruns.

## Privacy and access
Never put passwords, tokens, private keys, or credentials in scripts or logs. Do not copy controlled-access data to unapproved storage or external services. Use least privilege and institutional data governance rules.
