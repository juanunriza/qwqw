# qwqw
Proyecto: Expense Tracker (esqueleto)

Este repositorio contiene un script SQL para inicializar la base de datos en Supabase para una aplicación de seguimiento de gastos.

Archivos relevantes
- `sql/supabase_schema.sql` — esquema SQL listo para ejecutar en Supabase.

Instrucciones rápidas

1) Ejecutar el script en Supabase (recomendado)

	- Abre el panel de SQL de tu proyecto Supabase y copia/pega el contenido de `sql/supabase_schema.sql`, o sube el archivo y ejecútalo.

2) Ejecutar con `psql` (alternativa)

```bash
# Exporta las credenciales de conexión (ejemplo):
export DATABASE_URL="postgres://user:password@host:5432/dbname"

# Ejecuta el script
psql "$DATABASE_URL" -f sql/supabase_schema.sql
```

3) Ejecutar con `supabase` CLI

```bash
# Inicia sesión y selecciona el proyecto, luego:
supabase db remote set <CONNECTION_STRING>
psql "$SUPABASE_DB_URL" -f sql/supabase_schema.sql
```

Variables de entorno para Vercel

- `NEXT_PUBLIC_SUPABASE_URL` — URL pública de Supabase.
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — clave anónima (solo operaciones permitidas por RLS).
- `SUPABASE_SERVICE_ROLE_KEY` — clave de servicio (no exponer en el cliente; usar solo en servidores o funciones privadas).

Notas importantes
- La tabla `profiles` está pensada para sincronizarse con `auth.users` de Supabase; su `id` debe ser `auth.uid()`.
- Las políticas RLS del script permiten que cada usuario solo acceda a sus propias filas.
- Ajusta precisión de campos monetarios y moneda según tus necesidades.

¿Quieres que añada un script `seed` con datos de ejemplo o un flujo de CI para ejecutar el SQL automáticamente al desplegar? PRÓXIMO PASO: puedo añadir un archivo `sql/seed.sql` si lo deseas.

Ejemplos de código añadidos

- `src/lib/supabaseClient.js` — cliente público para el frontend (usa `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY`).
- `src/lib/supabaseServer.js` — cliente server para tareas administrativas (usa `SUPABASE_SERVICE_ROLE_KEY`).
- `src/pages/signin.jsx` — página React mínima que envía Magic Links para iniciar sesión.
- `src/pages/api/seed.js` — endpoint API de ejemplo para insertar datos de seed (usa `supabaseAdmin`).

Uso rápido

1. Añade en Vercel las variables de entorno:

```text
NEXT_PUBLIC_SUPABASE_URL=https://...supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=public-anon-key
SUPABASE_SERVICE_ROLE_KEY=service-role-secret
```

2. Para probar la página de login localmente en un proyecto Next.js, navega a `/signin`.

3. Para seedear datos (solo en local o en entornos protegidos), llama al endpoint:

```bash
curl -X POST https://<your-site>/api/seed -H "Content-Type: application/json" -d '{"user_id":"<USER_UUID>"}'
```

Seguridad

- Nunca subas `SUPABASE_SERVICE_ROLE_KEY` al cliente ni lo expongas en repositorios públicos.
- Usa RLS (ya incluido en `sql/supabase_schema.sql`) para proteger filas por usuario.
# qwqw