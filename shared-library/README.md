# shared-library/ - Jenkins shared library (optional)

```
vars/
  codeQuality.groovy    flake8, hadolint, shellcheck, helmLint
  securityScan.groovy   bandit, trivyFs, trivyImage
  unitTest.groovy       pytest (moto)
  imageBuild.groovy     build, push to Docker Hub, cleanup
  gitopsUpdate.groovy   set the image tag in a gitops values file and push
Jenkinsfile.shared-lib  the same pipeline as the root Jenkinsfile, written with these steps
```

## What was implemented
All steps of the pipeline as reusable functions under `vars/` (the folder name the exam asks for).

## Missing / blockers
The running pipeline uses the root `Jenkinsfile` (self-contained). `Jenkinsfile.shared-lib` needs the library to be configured in Jenkins first, and was syntax-checked but not run.

## Use
1. Manage Jenkins -> System -> Global Pipeline Libraries: name `my-shared-library`, default version `main`, Modern SCM -> Git -> `https://github.com/shaharc20-bit/project1finel.git`, Library Path `shared-library/`.
2. Create a pipeline job whose script path is `shared-library/Jenkinsfile.shared-lib`.
