# Seguridad Firebase

La app ya usa Firebase SDK cliente (`firebase_core`, `cloud_firestore`, `firebase_storage`, `firebase_auth`).

## Estado actual

Firebase Authentication todavia no esta inicializado en el proyecto `futbol-salvi`.
La activacion por API respondio que requiere billing, asi que por ahora la app conserva un modo de compatibilidad para no bloquear el uso.

## Pasos para activar reglas por usuario

1. En Firebase Console, abrir el proyecto `futbol-salvi`.
2. Ir a Authentication.
3. Presionar Comenzar / Get started.
4. En Sign-in method, habilitar Anonymous / Anonimo.
5. Abrir la app una vez en el celular para que reclame los registros viejos con `ownerUid`.
6. Desplegar reglas:

```powershell
firebase deploy --only firestore:rules,storage --project futbol-salvi
```

Las reglas estan en:

- `firestore.rules`
- `storage.rules`

Despues de desplegarlas, cada usuario autenticado solo podra leer y editar sus propios partidos.
