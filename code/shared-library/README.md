# Jenkins shared library

```
vars/
  codeQuality.groovy   flake8, hadolint, shellcheck
  securityScan.groovy  bandit, trivyFs, trivyImage
  unitTest.groovy      pytest
  imageBuild.groovy    build, push, cleanup
  gitopsUpdate.groovy  bump image tag in a values file
```

Manage Jenkins -> System -> Global Pipeline Libraries:
- Name: `my-shared-library`, Default version: `main`
- Retrieval method: Modern SCM -> Git -> `https://github.com/shaharc20-bit/project1finel.git`
- Library Path: `code/shared-library/`

Usage: `code/Jenkinsfile.shared-lib`
