# Guía Completa de Auditoría en PostgreSQL 16.9 con `pgAudit` (Ubuntu 24.04)

## 1. Introducción: ¿Qué es `pgAudit` y por qué utilizarlo?

`pgAudit` (PostgreSQL Audit Extension) es una extensión que permite generar registros detallados de las operaciones ejecutadas en una base de datos. Su propósito principal es facilitar el cumplimiento de normativas de seguridad y auditoría, como estándares ISO, regulaciones financieras o gubernamentales.

A diferencia de la opción nativa `log_statement`, `pgAudit` proporciona registros estructurados, en los que se especifica qué tabla fue accedida, qué tipo de operación se realizó y con qué parámetros.

Repositorio oficial: [https://github.com/pgaudit/pgaudit](https://github.com/pgaudit/pgaudit)
Para PostgreSQL 16, debe utilizarse la rama **`REL_16_STABLE`**.

---

## 2. Instalación de `pgAudit` desde código fuente

### 2.1 Instalación de dependencias

```bash
apt update
apt install -y make build-essential git libkrb5-dev postgresql-server-dev-16
```

### 2.2 Clonado y compilación de la extensión

```bash
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
git checkout REL_16_STABLE
make install USE_PGXS=1 PG_CONFIG=/usr/bin/pg_config
```

Verificación de la versión de PostgreSQL:

```bash
pg_config --version
```

---

## 3. Configuración inicial en `postgresql.conf`

Edite el archivo de configuración principal:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Parámetros recomendados:

```conf
shared_preload_libraries = 'pgaudit'

logging_collector = on
log_destination = 'stderr'
log_directory = 'log'
log_filename = 'postgresql-%a.log'
log_line_prefix = '%m [%c] %u@%d %p: '
log_statement = 'none'
log_timezone = 'UTC'
```

Nota: la opción `shared_preload_libraries` requiere reiniciar el servicio.

```bash
sudo systemctl restart postgresql
```

---

## 4. Activación de `pgAudit` en una base de datos

Conexión a la base de datos:

```bash
sudo -u postgres psql -d dvdrental
```

Creación de la extensión:

```sql
CREATE EXTENSION pgaudit;
```

---

## 5. Configuración de auditoría con `pgAudit`

### 5.1 Configuración permanente en `postgresql.conf`

```conf
pgaudit.log = 'read, write, ddl, function'
pgaudit.log_relation = on
pgaudit.log_parameter = on
```

Aplicación de cambios:

```bash
sudo systemctl restart postgresql
```

### 5.2 Configuración dinámica desde `psql`

```sql
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl, function';
ALTER SYSTEM SET pgaudit.log_relation = on;
ALTER SYSTEM SET pgaudit.log_parameter = on;
SELECT pg_reload_conf();
```

---

## 6. Pruebas de auditoría con la base de datos `dvdrental`

* **Consulta SELECT**

```sql
SELECT * FROM customer WHERE customer_id = 1;
```

Genera un registro de tipo `READ`.

* **Operaciones de escritura**

```sql
UPDATE customer SET last_name = 'Ramos' WHERE customer_id = 2;
DELETE FROM rental WHERE rental_id = 1000;
```

Genera registros de tipo `WRITE`.

* **Operaciones DDL**

```sql
CREATE TABLE test_audit (id serial PRIMARY KEY);
ALTER TABLE test_audit ADD COLUMN activo boolean;
DROP TABLE test_audit;
```

Genera registros de tipo `DDL`.

* **Bloque anónimo**

```sql
DO $$ BEGIN EXECUTE 'CREATE TABLE temp_test (x int)'; END $$;
```

Genera registros de tipo `FUNCTION` y `DDL`.

---

## 7. Revisión y filtrado de registros

Ubicación del directorio de datos:

```sql
SHOW data_directory;
```

Revisión de archivos de log:

```bash
cd /var/lib/postgresql/16/main/log
ls -lh
tail -f postgresql-*.log | grep AUDIT
```

Ejemplo de salida:

```
2025-07-17 13:02:29.198 CST [5f3b15c5.876e] postgres@dvdrental 34614: LOG:  AUDIT: SESSION,3,1,READ,SELECT,TABLE,public.actor,select * from actor,<not logged>
```

---

## 8. Interpretación de los registros de `pgAudit`

| Campo             | Descripción                                                              |
| ----------------- | ------------------------------------------------------------------------ |
| `SESSION`         | Tipo de auditoría (`SESSION` u `OBJECT`).                                |
| `3,1`             | Identificador de sesión y sub-identificador.                             |
| `READ`            | Categoría de la acción (`READ`, `WRITE`, etc.).                          |
| `SELECT`          | Comando SQL ejecutado.                                                   |
| `TABLE`           | Tipo de objeto afectado.                                                 |
| `public.customer` | Objeto sobre el que se ejecutó la acción.                                |
| `SELECT *...`     | Sentencia SQL completa.                                                  |
| `<not logged>`    | Parámetros no registrados (si `pgaudit.log_parameter` está desactivado). |

---

## 9. Clases principales de auditoría en `pgAudit`

| Clase      | Acciones auditadas                                 |
| ---------- | -------------------------------------------------- |
| `READ`     | Consultas `SELECT` y operaciones `COPY FROM`.      |
| `WRITE`    | `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`.          |
| `DDL`      | Cambios en el esquema (`CREATE`, `ALTER`, `DROP`). |
| `FUNCTION` | Ejecución de funciones y bloques anónimos.         |

---

## 10. Ventajas frente a `log_statement`

* Registros estructurados y fácilmente procesables.
* Inclusión explícita de tipo de operación y objeto afectado.
* Compatibilidad con sistemas de auditoría externos.
* Reducción de ruido generado por consultas internas del sistema.

---

## 11. Buenas prácticas adicionales

* **Permisos restrictivos sobre los archivos de log**

```bash
chmod 640 /var/lib/postgresql/16/main/log/*
```

* **Rotación de registros**

```conf
log_rotation_age = 1d
log_rotation_size = 100MB
```

* **Centralización de logs**
  Configurar envío a sistemas como `syslog`, `rsyslog`, `fluentd` o `journalbeat`.

* **Integración con plataformas de análisis**
  Uso de herramientas como **ELK Stack**, **Splunk**, **Datadog** o **pganalyze**.

* **Definición de políticas de retención**
  Establecer políticas de acuerdo con normativas aplicables (por ejemplo, GDPR, SOX).

---
