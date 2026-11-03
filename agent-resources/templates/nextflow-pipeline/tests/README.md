# Pipeline test plan

Use nf-test or the project's established test framework.

Minimum plan:
- [ ] Process/module happy-path test with tiny fixture
- [ ] Workflow output contract and sample identity test
- [ ] Paired-end association test if applicable
- [ ] Invalid/missing input test
- [ ] Parameter/configuration test for supported modes
- [ ] Failure propagation test
- [ ] Regression test for each fixed bug
- [ ] Small integration run with representative data, where feasible

Document exact commands and the environment needed to run them.
