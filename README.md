# DB proxy using pgbouncer
> https://hub.docker.com/r/bitnami/pgbouncer/

Update .env with DB credentials

## Generate certificates
```bash
./generate-certs.sh
```

## Source DB certificates
### AWS
> https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL-certificate-rotation.html

```bash
curl -sS "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" > certs/source-cert.pem
```

## Create users

Create user in database

```sql
-- Create a group
CREATE ROLE full_readaccess;

-- Grant access to existing tables
GRANT USAGE ON SCHEMA public TO full_readaccess;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO full_readaccess;

-- Grant access to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO full_readaccess;

-- Create a final user with password
CREATE USER user_name WITH PASSWORD 'random_password';
-- ALTER USER user_name WITH PASSWORD 'random_password';
GRANT full_readaccess TO user_name;
```

---

Allow new user in proxy using **userlist.txt**
```bash
echo -n 'md5'; echo -n "passworduser" | md5sum | awk '{print $1}'
# Then add the output as "user" "md5....." to userlist.txt
```

---

Generate client certificate
```bash
openssl req -x509 -keyout client-key.pem -out client-cert.pem -days 365 -nodes -subj '/CN=localhost'
```

Add `client-cert.pem` to `certs/clients-cert.pem`
> NOTE: We can add verbose information outside `-----BEGIN FOO----- and -----END FOO-----`

Use `client-key.pem` when connecting to database using SQL client


## Connect to database

```config
Enable SSL: True
# Server Certificates
CA Cert: proxy-cert.pem
# User certificates
Certificate: client-cert.pem
Key File: client-key.pem
```
