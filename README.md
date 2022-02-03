# Playbooks
Play with Ansible

## Encrypted files

Encrypt:

```
gpg -a -r jysperm --encrypt secrets.yml
```

Decrypt:

```
gpg --decrypt secrets.yml.asc > secrets.yml
```
