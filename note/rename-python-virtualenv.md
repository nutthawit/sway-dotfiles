If you use virtualenvwrapper, a set of extensions for virtualenv, you can use the built-in copy function, though some users report it can be buggy.

1. Copy the virtual environment with the new name.
```sh
cpvirtualenv <old_env_name> <new_env_name>
```

2. Remove the old environment.
```bash
rmvirtualenv <old_env_name>
```
