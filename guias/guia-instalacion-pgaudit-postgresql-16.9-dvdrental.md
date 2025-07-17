## 📋 Guía Completa: Auditoría con `pgAudit` en PostgreSQL 16.9 usando la base `dvdrental`

### 🔍 1. Revisión previa

Antes de comenzar, revisa el repositorio oficial de `pgAudit`:

📎 [https://github.com/pgaudit/pgaudit](https://github.com/pgaudit/pgaudit)

🔧 Asegúrate de que estás usando la **rama compatible** con tu versión de PostgreSQL. Para PostgreSQL 16, debe ser `REL_16_STABLE`.

---

### 🛠️ 2. Configuración en `postgresql.conf`

Edita el archivo, por ejemplo:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Agrega o modifica:

```conf
shared_preload_libraries = 'pgaudit'
logging_collector = on
log_destination = 'stderr'
log_directory = 'log'            # relativo al data_directory
log_filename = 'postgresql-%a.log'
log_line_prefix = '%m %u %d [%p]: '
log_statement = 'none'
```

Luego reinicia:

```bash
sudo systemctl restart postgresql
```

---

### 🧩 3. Activar `pgAudit` en la base `dvdrental`

Conéctate:

```bash
psql -U postgres -d dvdrental
```

Ejecuta:

```sql
CREATE EXTENSION pgaudit;
```

---

### ⚙️ 4. Configurar auditoría

```sql
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl';
ALTER SYSTEM SET pgaudit.log_relation = on;
SELECT pg_reload_conf();
```

---

### 🧪 5. Ejemplos explicados con `dvdrental`

#### 📌 a) Consulta de lectura

```sql
SELECT first_name FROM customer WHERE customer_id = 1;
```

➡️ Se genera un log `READ` para `customer`.

---

#### 📌 b) Operaciones de escritura

```sql
UPDATE customer SET first_name = 'Ana' WHERE customer_id = 2;
DELETE FROM payment WHERE payment_id = 10;
```

➡️ Se generan logs `WRITE`, uno por tabla afectada.

---

#### 📌 c) Cambios de esquema (DDL)

```sql
CREATE TABLE auditoria_test (id serial PRIMARY KEY);
ALTER TABLE auditoria_test ADD COLUMN activo boolean;
DROP TABLE auditoria_test;
```

➡️ Logs `DDL` indicando los cambios de estructura.

---

#### 📌 d) Bloques anónimos `DO`

```sql
DO $$
BEGIN
  EXECUTE 'CREATE TABLE temp_dynamic (x int)';
END $$;
```

➡️ Se genera un log `FUNCTION` y uno `DDL` para la tabla creada dinámicamente.

---

### 🔍 6. Verificación de logs

Verifica la ubicación del directorio de datos:

```sql
SHOW data_directory;
```

Luego en terminal:

```bash
cd /var/lib/postgresql/16/main/log
ls -lh
tail -f postgresql-*.log | grep AUDIT
```

Ejemplo de entrada esperada:

```
AUDIT: SESSION,105,1,READ,SELECT,TABLE,public.customer,SELECT ...
```

---

## ✅ Clases comunes de auditoría

| Clase      | Acciones auditadas                       |
| ---------- | ---------------------------------------- |
| `READ`     | `SELECT`, `COPY FROM`                    |
| `WRITE`    | `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` |
| `DDL`      | Cambios de esquema                       |
| `FUNCTION` | Bloques `DO` o funciones                 |

---
