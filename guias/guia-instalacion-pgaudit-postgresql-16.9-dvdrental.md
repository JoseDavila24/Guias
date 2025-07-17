## 📋 Guía completa: Instalación y configuración de `pgAudit` en PostgreSQL 16.9 con `dvdrental`

### 1. Clonar el repositorio oficial y checkout

```bash
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
git checkout REL_16_STABLE
```

---

### 2. Compilar e instalar

⚠️ **Importante:** Ajusta el comando final:

```bash
sudo make install USE_PGXS=1 PG_CONFIG=/usr/bin/pg_config
```

No uses rutas de versiones diferentes ya que no coincide con tu PostgreSQL 16.9 instalado desde paquetes del sistema.

---

### 3. Configuración del servidor PostgreSQL

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

Luego reinicia:

```bash
sudo systemctl restart postgresql
```

---

### 4. Habilitar `pgAudit` en la base `dvdrental`

Conéctate a `dvdrental`:

```sql
CREATE EXTENSION pgaudit;
```

---

### 5. Configurar auditoría a nivel global

```sql
ALTER SYSTEM SET pgaudit.log = 'read, write, ddl';
ALTER SYSTEM SET pgaudit.log_relation = on;
SELECT pg_reload_conf();
```

Esto activa auditoría para:

* **Lectura** (`SELECT`)
* **Escritura** (`INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`)
* **DDL** (`CREATE`, `DROP`, `ALTER`)
* Desglosa por relación (`log_relation = on`).

---

### 6. Ejemplos de auditoría con `dvdrental`

Conéctate y ejecuta lo siguiente:

#### a) Auditoría de DML y SELECT:

```sql
SELECT first_name, last_name FROM customer WHERE customer_id = 1;
UPDATE customer SET first_name = 'Pedro' WHERE customer_id = 2;
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
  VALUES (now(), 1, 2, now()+interval '1 day', 1);
DELETE FROM payment WHERE payment_id = 10;
```

**Resultado esperado en logs**:

```
AUDIT: SESSION,...,READ,SELECT,TABLE,public.customer,...
AUDIT: SESSION,...,WRITE,UPDATE,TABLE,public.customer,...
AUDIT: SESSION,...,WRITE,INSERT,TABLE,public.rental,...
AUDIT: SESSION,...,WRITE,DELETE,TABLE,public.payment,...
```

---

#### b) Auditoría de DDL

```sql
CREATE TABLE auditoria_prueba (id serial PRIMARY KEY, descripcion text);
ALTER TABLE auditoria_prueba ADD COLUMN creado timestamp;
DROP TABLE auditoria_prueba;
```

**En los logs verás**:

```
AUDIT: SESSION,...,DDL,CREATE TABLE,...
AUDIT: SESSION,...,DDL,ALTER TABLE,...
AUDIT: SESSION,...,DDL,DROP TABLE,...
```

---

#### c) Prueba con bloques `DO`

```sql
DO $$
BEGIN
  EXECUTE 'CREATE TABLE temp_dynamic (x int)';
END $$;
```

**pgAudit registrará de forma clara**:

```
AUDIT: SESSION,...,FUNCTION,DO,,,"DO $$ ... $$;"
AUDIT: SESSION,...,DDL,CREATE TABLE,TABLE,public.temp_dynamic,...
```

Gracias a la diferencia entre `FUNCTION` y `DDL`, podrás distinguir entre ejecución dinámica y cambios reales.

---

#### d) Auditoría con parámetros

Habilita parámetros y prueba con `PREPARE`+`EXECUTE`:

```sql
ALTER SYSTEM SET pgaudit.log_parameter = on;
SELECT pg_reload_conf();

PREPARE stmt (int) AS SELECT * FROM customer WHERE customer_id = $1;
EXECUTE stmt (1);
```

**En los logs verás**:

```
AUDIT: SESSION,...,READ,PREPARE,,,"PREPARE stmt ...",<none>
AUDIT: SESSION,...,READ,SELECT,TABLE,public.customer,"... WHERE customer_id = $1",1
```

El valor `1` está registrado gracias a `log_parameter` ([PostgreSQL][1], [postgrespro.com][2], [PostgreSQL][3]).

---

## 🧾 7. Verificación en logs

Accede a `/var/log/postgresql/postgresql-*.log` y busca entradas que comiencen con `AUDIT:`. Deberías encontrar combinaciones de:

* `SESSION,READ,WRITE,DDL`
* `FUNCTION` (bloques DO)
* Parámetros si están habilitados.

---

### 8. Recomendaciones avanzadas

* Establece `pgaudit.log_catalog = off` para evitar ruido de consultas internas ([PostgreSQL][3], [sources.debian.org][4]).
* Usa `object audit logging` para auditar solo ciertas tablas:

  ```sql
  CREATE ROLE auditor NOLOGIN;
  ALTER SYSTEM SET pgaudit.role = 'auditor';
  SELECT pg_reload_conf();
  GRANT SELECT, INSERT ON public.customer TO auditor;
  ```

  Ahora solo lo que afecte a `customer` será auditado detalladamente.
* Añade `log_rows = on` si requieres número de filas afectadas.
* Ajusta `log_parameter_max_size` para limitar el tamaño de los parámetros.

---

### ✅ Resumen

| Paso | Acción                                         |
| ---- | ---------------------------------------------- |
| 1    | Clonar y checkout de `REL_16_STABLE`           |
| 2    | `make install` con `pg_config` de `/usr/bin`   |
| 3    | Configurar `postgresql.conf` y reiniciar       |
| 4    | Crear extensión en `dvdrental`                 |
| 5    | Ajustar `pgaudit.log` y recargar configuración |
| 6    | Ejecutar consultas de prueba                   |
| 7    | Revisar logs de auditoría                      |
