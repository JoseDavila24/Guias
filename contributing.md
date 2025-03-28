# 🤝 Guía para contribuir

¡Gracias por tu interés en contribuir a este proyecto! 🎉  
Queremos que contribuir sea un proceso claro, inclusivo y eficiente para todos.

## 🧾 Tabla de contenido

- [Cómo contribuir](#cómo-contribuir)
- [Buenas prácticas](#buenas-prácticas)
- [Estructura de ramas](#estructura-de-ramas)
- [Commits claros](#commits-claros)
- [Pull Requests](#pull-requests)
- [Código de conducta](#código-de-conducta)

---

## Cómo contribuir

1. **Haz un fork** del repositorio.
2. **Clona tu fork** localmente:
   ```bash
   git clone https://github.com/tu-usuario/nombre-del-repo.git
   cd nombre-del-repo
   ```
3. Crea una nueva rama:
   ```bash
   git checkout -b nombre-de-tu-rama
   ```
4. Realiza tus cambios y haz commit:
   ```bash
   git add .
   git commit -m "Descripción clara del cambio"
   ```
5. Haz push a tu rama:
   ```bash
   git push origin nombre-de-tu-rama
   ```
6. Abre un **Pull Request (PR)** desde tu rama hacia `main`.

---

## Buenas prácticas

- Escribe código limpio, comentado y documentado.
- Añade pruebas si es necesario.
- Verifica que tu código no rompa funcionalidades existentes.
- Usa nombres descriptivos para ramas y commits.

---

## Estructura de ramas

- `main`: versión estable del proyecto.
- `develop`: cambios en desarrollo (opcional, si tienes flujo Git Flow).
- `feature/*`: nuevas funcionalidades.
- `fix/*`: correcciones de errores.
- `docs/*`: cambios en la documentación.

---

## Commits claros

Sigue esta estructura para tus mensajes de commit:

```
tipo: mensaje breve del cambio

Ejemplos:
feat: agrega componente de usuario
fix: corrige error de carga en el login
docs: mejora la documentación del README
```

Tipos válidos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## Pull Requests

- Describe brevemente los cambios realizados.
- Menciona si hay algo pendiente o si necesita revisión especial.
- Relaciona el PR con un issue si aplica: `Closes #número-del-issue`

---

## Código de conducta

Este proyecto sigue un [Código de Conducta](./CODE_OF_CONDUCT.md) para asegurar un entorno colaborativo, seguro y respetuoso para todos. Por favor, léelo antes de contribuir.

---

¡Gracias por hacer que este proyecto sea mejor! 🙌
```

---
