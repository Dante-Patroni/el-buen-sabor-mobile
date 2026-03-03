# Contrato Front-Back para Release

Fecha: 2026-03-03  
Proyecto: El Buen Sabor (Front Flutter)

## 1) Tabla Contractual (Frontend ↔ Backend)

| Endpoint | Request esperado | Response esperada | Archivo front |
|---|---|---|---|
| `POST /api/usuarios/login` | JSON: `{ legajo, password }` | `200/201` con `{ token, usuario }` | `lib/features/auth/data/datasources/auth_datasource.dart` |
| `GET /api/mesas` | Header `Authorization: Bearer <token>` | `200` array de mesas formateadas | `lib/features/mesas/data/datasources/mesa_datasource.dart` |
| `POST /api/mesas/:id/abrir` | Header auth + JSON `{ idMozo }` | `200` con mesa abierta | `lib/features/mesas/data/datasources/mesa_datasource.dart` |
| `POST /api/pedidos/cerrar-mesa` | Header auth + JSON `{ mesaId }` | `200` con `totalCobrado` | `lib/features/mesas/data/datasources/mesa_datasource.dart` |
| `GET /api/platos` | Header auth | `200` array de platos | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |
| `GET /api/rubros` | Header auth | `200` array de rubros | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |
| `GET /api/pedidos` | Header auth | `200` array o `{ data: [] }` con detalles | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |
| `GET /api/pedidos/mesa/:mesa` | Header auth | `200` array o `{ data: [] }` con detalles | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |
| `POST /api/pedidos` | Header auth + JSON `{ mesa, cliente, productos[] }` | `201/200` con `id` | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |
| `PUT /api/pedidos/modificar` | Header auth + JSON `{ id, mesa, cliente, productos[] }` | `200/201` OK | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |
| `DELETE /api/pedidos/:id` | Header auth | `200/204` OK | `lib/features/pedidos/data/datasources/pedido_datasource.dart` |

## 2) Riesgos Abiertos

1. `PUT /api/pedidos/modificar` no aparece documentado en el diagrama backend, pero el front lo consume. Confirmar en backend o documentarlo formalmente.
2. Respuesta de `GET /api/pedidos` y `GET /api/pedidos/mesa/:mesa` puede venir como array o `{ data: [] }`; el front acepta ambos formatos. Mantener coherencia en backend evita divergencias futuras.

## 3) Checklist de Aceptación (Validación Manual)

1. Login devuelve `{ token, usuario }` y el token se guarda correctamente.  
2. La app arranca en `Salón` si hay JWT válido; si no, arranca en `Login`.  
3. `GET /api/mesas` funciona con JWT; si `401/403`, se indica sesión expirada.  
4. `POST /api/mesas/:id/abrir` asigna mozo y refresca mesas.  
5. `POST /api/pedidos` crea pedido con `mesa`, `cliente`, `productos[]` y actualiza total en mesa.  
6. `GET /api/pedidos/mesa/:mesa` carga pedidos por mesa sin traer todo el histórico.  
7. Eliminar ítem: si hay más de un ítem se modifica pedido; si queda uno, se elimina pedido completo.  
8. `DELETE /api/pedidos/:id` devuelve `200/204`; si falla, la UI muestra error real.  
9. `POST /api/pedidos/cerrar-mesa` devuelve `totalCobrado` y deja mesa en estado libre.  
10. Logout borra token, limpia usuario y vuelve a login.  

## 4) Resultado de Pruebas

- `flutter analyze`: OK  
- `flutter test`: OK (38 tests)

## 5) Aprobación

Responsable Front: _______________________  
Responsable Back: ________________________  
Fecha de aprobación: _____________________

