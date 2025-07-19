# 🛡️ Guía Completa de Auditoría en PostgreSQL 16.9 con `pgAudit` (Ubuntu 24.04)

---

## 🔍 1. ¿Qué es pgAudit y por qué usarlo?

`pgAudit` (PostgreSQL Audit Extension) permite generar registros detallados de las acciones realizadas sobre una base de datos, esenciales para cumplir con normativas como ISO, financieras o gubernamentales.

A diferencia de `log_statement`, `pgAudit` ofrece logs estructurados con información sobre qué tabla fue accedida, qué tipo de operación se realizó, y más.

📎 Repositorio oficial: [https://github.com/pgaudit/pgaudit](https://github.com/pgaudit/pgaudit)
✔️ Para PostgreSQL 16, usa la rama `REL_16_STABLE`.

---

## 🧰 2. Instalación de `pgAudit` desde código fuente

### 2.1 Instala las dependencias necesarias

```bash
apt update
apt install -y make build-essential git libkrb5-dev postgresql-server-dev-16
```

### 2.2 Clona y compila la extensión `pgAudit`

```bash
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
git checkout REL_16_STABLE
make install USE_PGXS=1 PG_CONFIG=/usr/bin/pg_config
```

---

## ⚙️ 3. Configuración inicial en `postgresql.conf`

Edita el archivo de configuración principal de PostgreSQL:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Asegúrate de incluir o modificar estas líneas:

```conf
# Configuración básica de auditoría
shared_preload_libraries = 'pgaudit'

# Configuración de logs
logging_collector = on
log_destination = 'stderr'
log_directory = 'log'            # relativo a data_directory
log_filename = 'postgresql-%a.log'
log_line_prefix = '%m %u %d [%p]: '
log_statement = 'none'
```

Reinicia el servicio:

```bash
sudo systemctl restart postgresql
```

---

## 🔌 4. Activar `pgAudit` en tu base de datos

Conéctate a la base `dvdrental`:

```bash
sudo -u postgres psql -d dvdrental
```

Y ejecuta:

```sql
CREATE EXTENSION pgaudit;
```

---

## 🛠️ 5. Configurar auditoría con `pgAudit`

### ✅ Opción A — Configuración permanente desde archivo

Edita nuevamente el archivo `postgresql.conf`:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Agrega estas líneas:

```conf
pgaudit.log = 'read, write, ddl, function'
pgaudit.log_relation = on
pgaudit.log_parameter = on
```

Reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
```

### 🧪 Opción B — Configuración dinámica desde `psql` (para pruebas)

```sql
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl, function';
ALTER SYSTEM SET pgaudit.log_relation = on;
ALTER SYSTEM SET pgaudit.log_parameter = on;
SELECT pg_reload_conf();
```

---

## 🧪 6. Pruebas de auditoría con la base `dvdrental`

### a) Consulta `SELECT`

```sql
SELECT * FROM customer WHERE customer_id = 1;
```

➡️ Genera log `READ` para la tabla `customer`.

### b) Operaciones `UPDATE` y `DELETE`

```sql
UPDATE customer SET last_name = 'Ramos' WHERE customer_id = 2;
DELETE FROM rental WHERE rental_id = 1000;
```

➡️ Logs `WRITE` por cada tabla afectada.

### c) Cambios al esquema (`DDL`)

```sql
CREATE TABLE test_audit (id serial PRIMARY KEY);
ALTER TABLE test_audit ADD COLUMN activo boolean;
DROP TABLE test_audit;
```

➡️ Se generan logs `DDL`.

### d) Bloque anónimo (`DO`)

```sql
DO $$ BEGIN EXECUTE 'CREATE TABLE temp_test (x int)'; END $$;
```

➡️ Se genera un log `FUNCTION` y otro `DDL`.

---

## 🗂️ 7. Revisión y filtrado de logs generados

### a) Ubica tu directorio de datos:

```sql
SHOW data_directory;
```

### b) Revisa los archivos de log:

```bash
cd /var/lib/postgresql/16/main/log
ls -lh
tail -f postgresql-*.log | grep AUDIT
```

Ejemplo de salida:

```
2025-07-17 13:02:29.198 CST postgres dvdrental [34614]: LOG:  AUDIT: SESSION,3,1,READ,SELECT,TABLE,public.actor,select * from actor,<not logged>
```

---

## 🧾 8. Interpretación de logs `pgAudit`

Cada línea de log contiene:

* Tipo: `SESSION` u `OBJECT`
* Clase: `READ`, `WRITE`, `DDL`, etc.
* Objeto: `TABLE`, `VIEW`, etc.
* Nombre del objeto: Ej. `public.customer`
* Comando ejecutado
* Parámetros (si `log_parameter` está activado)

Ejemplo:

```
AUDIT: SESSION,3,1,READ,SELECT,TABLE,public.customer,SELECT * FROM customer,<not logged>
```

---

## ✅ 9. Clases más comunes de auditoría en `pgAudit`

| Clase      | Acciones auditadas                           |
| ---------- | -------------------------------------------- |
| `READ`     | `SELECT`, `COPY FROM`                        |
| `WRITE`    | `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`     |
| `DDL`      | Cambios de esquema (`CREATE`, `ALTER`, etc.) |
| `FUNCTION` | Bloques `DO` y funciones PL/pgSQL            |

---

## 🎯 10. Ventajas clave frente a `log_statement`

* 🎯 Estructura de log clara y parseable
* 🎯 Incluye tipo de operación, tabla y detalles
* 🎯 Fácil integración con sistemas de auditoría
* 🎯 Reduce ruido de operaciones irrelevantes (`pg_catalog`)
