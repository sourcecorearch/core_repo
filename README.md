# core_repo

Repositorio de paquetes de SourceCoreArch.

## Actualizar el repositorio

Desde `x86_64/`:

```bash
./update_repo.sh          # omite LFS y conserva sus entradas
./update_repo.sh --strict # aborta si hay LFS sin materializar
```

- **Modo normal:** indexa los paquetes reales, omite los punteros LFS (por ejemplo, los paquetes NVIDIA) y conserva sus entradas existentes en la base de datos.
- **`--strict`:** si hay paquetes LFS sin materializar, aborta antes de modificar la base de datos. Úsalo si prefieres ejecutar `git lfs pull` primero.
- La base de datos se construye en un directorio temporal y solo se reemplaza si `repo-add` termina correctamente, por lo que un fallo no deja el repositorio sin DB.

Para indexar una versión nueva de un paquete LFS, materialízalo antes con `git lfs pull`.
