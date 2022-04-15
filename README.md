# Playbooks
My Linux server automation scripts

## Import SSH Key

```
mkdir -m 700 ~/.ssh
curl https://github.com/jysperm.keys >> ~/.ssh/authorized_keys
chown 600 ~/.ssh/authorized_keys
```

## Encrypted files

Encrypt:

```
gpg -a -r jysperm --encrypt secrets.yml
```

Decrypt:

```
gpg --decrypt secrets.yml.asc > secrets.yml
```
