ods-pre-commit-hooks
====================

This repository provides pre-commit-hooks to support development of the opendevstack https://github.com/opendevstack ecosystem.


### Using terraformmoduleoutputs with pre-commit

Add this to your `.pre-commit-config.yaml`:

    -   repo: https://github.com/nichtraunzer/ods-pre-commit-hooks
        rev: ''  # Use the sha / tag you want to point at
        hooks:
        -   id: terraformmoduleoutputs
