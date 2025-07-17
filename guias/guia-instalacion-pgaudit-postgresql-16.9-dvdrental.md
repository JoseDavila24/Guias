
## 📋 Guía completa: Instalación y configuración de `pgAudit` en PostgreSQL 16.9 (`dvdrental`)

### ✅ 1. Clonar el repositorio oficial de `pgAudit`

```bash
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
```

### 🔀 2. Cambiar a la rama estable de PostgreSQL 16

```bash
git checkout REL_16_STABLE
```

### ⚠️ 3. Compilar con el comando correcto para PostgreSQL 16 instalado vía paquetes del sistema

> **Importante:** No uses `PG_CONFIG=/usr/pgsql-17/bin/pg_config`, ya que no aplica para tu versión.

Usa en su lugar:

```bash
sudo make install USE_PGXS=1 PG_CONFIG=/usr/bin/pg_config
```

Este comando asegura compatibilidad con PostgreSQL 16.9 si fue instalado con `apt`, `yum`, etc.

---

## ⚙️ 4. Configuración del servidor PostgreSQL

Edita `postgresql.conf`:

```conf
shared_preload_libraries = 'pgaudit'
log_line_prefix = '%m %u %d [%p]: '
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%a.log'
log_statement = 'none'
```

Reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
```

---

## 🧩 5. Activar la extensión en la base `dvdrental`

Conéctate como superusuario a la base `dvdrental`:

```sql
CREATE EXTENSION pgaudit;
```

---

## 🔧 6. Configurar auditoría global

```sql
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl';
ALTER SYSTEM SET pgaudit.log_relation = on;
```

Recarga la configuración:

```bash
sudo systemctl reload postgresql
```

---

## 🧪 7. Prueba con consultas sobre `dvdrental`

```sql
SELECT first_name FROM customer WHERE customer_id = 1;

UPDATE customer SET first_name = 'Juan' WHERE customer_id = 1;

DELETE FROM rental WHERE rental_id = 1;

CREATE TABLE auditoria_test (id serial PRIMARY KEY, descripcion text);
```

---

## 🔍 8. Verificar logs

Revisa los logs típicamente en:

```bash
cd /var/log/postgresql/
less postgresql-*.log
```

Debes ver entradas tipo:

```
AUDIT: SESSION,...,READ,SELECT,TABLE,public.customer,...
AUDIT: SESSION,...,WRITE,UPDATE,TABLE,public.customer,...
AUDIT: SESSION,...,DDL,CREATE TABLE,TABLE,public.auditoria_test,...
```

---

