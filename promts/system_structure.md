# ACTÚA COMO ARQUITECTO DE SOFTWARE SENIOR LARAVEL 12

Desarrolla un sistema Backend REST API profesional utilizando Laravel 12, PostgreSQL y JWT Authentication o Laravel Sanctum (solo API, sin Blade, sin Livewire, sin vistas web).

## OBJETIVO

Construir un sistema de gestión de tareas empresariales con:

* Autenticación por usuario (NO email).
* Control de acceso RBAC (Role Based Access Control).
* Gestión de usuarios.
* Gestión de cargos u ocupaciones.
* Gestión de tareas.
* Gestión de participantes.
* Gestión de archivos adjuntos.
* Auditoría de acciones.
* API REST documentada.

---

# REQUISITOS DE ARQUITECTURA

Aplicar:

* SOLID
* Clean Architecture
* Repository Pattern
* Service Layer
* Form Requests
* API Resources
* Policies
* Gates
* Middleware
* DTOs cuando sea necesario
* Validaciones centralizadas

Organizar controladores bajo:

NeoProyect\GestionProyectos\App\Http\Controllers\Api

Utilizar:

* Laravel 12
* PostgreSQL
* Eloquent ORM
* Migrations
* Seeders
* Factories
* Policies
* Events
* Queues para procesos pesados

---

# AUTENTICACIÓN

El usuario inicia sesión mediante:

* username
* password

NO utilizar email para autenticación.

Tabla users:

* id
* username
* password
* first_name
* last_name
* occupation_id
* status
* created_at
* updated_at

El username debe ser único.

Implementar:

POST /login
POST /logout
POST /refresh
GET /me

---

# CARGOS U OCUPACIONES

Crear tabla:

occupations

Campos:

* id
* name
* description
* status
* created_at
* updated_at

Relación:

occupation 1 -> N users

---

# RBAC

Implementar Role Based Access Control.

Tablas:

roles
permissions
role_permissions
user_roles

Permitir múltiples roles por usuario.

Ejemplos de roles:

* Super Admin
* Administrador de Tareas
* Supervisor
* Empleado

Ejemplos de permisos:

users.create
users.read
users.update
users.delete

tasks.create
tasks.read
tasks.update
tasks.delete

tasks.assign
tasks.close

reports.read

---

# REGLAS DE SEGURIDAD

Todo endpoint debe validar permisos.

Usar:

Policies
Middleware
Gates

No confiar únicamente en validaciones del frontend.

---

# PLANIFICACIÓN DE TAREAS

Crear migración:

tasks

Campos:

* id
* title
* description
* status
* priority
* start_date
* end_date
* estimated_hours
* created_by
* assigned_by
* assigned_to
* completed_at
* created_at
* updated_at

Estados:

pending
in_progress
completed
cancelled

Prioridades:

low
medium
high
critical

---

# REGLAS DE NEGOCIO DE TAREAS

Una tarea:

* Puede ser creada por cualquier usuario autorizado.
* Puede asignarse a otro usuario.
* Puede permanecer activa varios días o semanas.
* Tiene fecha de inicio y fecha final.
* Puede finalizarse manualmente.
* Puede cancelarse.
* Puede tener múltiples participantes.
* Puede tener múltiples reportes.
* Puede tener múltiples archivos.

Ejemplo:

Pedro crea tarea para María.

Pedro = assigned_by

María = assigned_to

---

# PARTICIPANTES

Crear tabla:

task_participants

Campos:

* id
* task_id
* user_id
* role_in_task
* created_at

Una tarea puede tener muchos participantes.

Un usuario puede participar en muchas tareas.

---

# REPORTES DE TRABAJO

Crear tabla:

task_reports

Campos:

* id
* task_id
* user_id
* report
* report_date
* hours_worked
* created_at

Reglas:

Solo participantes pueden crear reportes.

Cada participante puede registrar múltiples reportes.

---

# DOCUMENTOS ADJUNTOS

Crear tabla:

task_attachments

Campos:

* id
* task_id
* uploaded_by
* file_name
* file_path
* file_type
* file_size
* created_at

Permitir:

* PDF
* JPG
* JPEG
* PNG

Guardar archivos en Storage.

---

# VISIBILIDAD DE TAREAS

Regla crítica:

Un usuario normal SOLO puede:

* Ver tareas donde fue asignado.
* Ver tareas donde participa.
* Ver reportes donde participa.
* Ver historial de sus participaciones.

No puede:

* Ver tareas de otros usuarios.
* Modificar tareas ajenas.
* Eliminar tareas ajenas.

---

# ADMINISTRADOR DE TAREAS

Rol:

Administrador de Tareas

Puede:

* Ver todas las tareas.
* Ver tareas pendientes.
* Ver tareas en proceso.
* Ver tareas completadas.
* Ver historial global.
* Asignar tareas.
* Modificar cualquier tarea.
* Eliminar cualquier tarea.
* Gestionar participantes.

---

# ELIMINACIÓN DE TAREAS

Reglas:

Un usuario puede eliminar una tarea SOLO si:

* Fue quien la creó.

El Administrador de Tareas puede eliminar cualquier tarea.

Implementar Soft Deletes.

---

# AUDITORÍA

Crear tabla:

audit_logs

Registrar:

* usuario
* acción
* módulo
* registro afectado
* valores anteriores
* valores nuevos
* fecha

Auditar:

* login
* logout
* crear
* editar
* eliminar
* asignar tareas
* cerrar tareas

---

# API DOCUMENTATION

Generar:

* Endpoints
* Requests
* Responses
* Ejemplos JSON
* Códigos HTTP

Usar OpenAPI / Swagger.

---

# ENTREGABLES

Generar:

1. Migrations
2. Models
3. Relationships
4. Policies
5. Middleware
6. Form Requests
7. Repositories
8. Services
9. Controllers
10. Routes API
11. Seeders
12. Factories
13. Swagger Documentation
14. Pruebas Unitarias
15. Pruebas de Integración

No omitir código.

Generar código listo para producción siguiendo buenas prácticas de Laravel 12 y PostgreSQL.


# PRINCIPIO DE INDEPENDENCIA Y DESACOPLAMIENTO

El sistema debe diseñarse bajo principios de independencia entre capas y bajo acoplamiento.

Ninguna regla de negocio debe depender directamente de:

* Controllers
* Framework Laravel
* Base de datos PostgreSQL
* Middleware
* Requests HTTP
* Respuestas HTTP

Las reglas de negocio deben poder funcionar independientemente de la tecnología utilizada.

---

# SEPARACIÓN DE RESPONSABILIDADES

Controller:

* Recibe la petición.
* Valida autorización.
* Llama al Service correspondiente.
* Devuelve respuesta.

No debe contener lógica de negocio.

---

Service:

* Contiene toda la lógica de negocio.
* Orquesta procesos.
* Ejecuta validaciones de negocio.
* Utiliza repositorios.

---

Repository:

* Responsable únicamente del acceso a datos.
* No debe contener lógica de negocio.

---

Policies:

* Gestionan permisos y autorizaciones.
* No deben contener lógica de negocio.

---

Models:

* Representan entidades del dominio.
* Mantenerlos lo más limpios posible.

---

# DEPENDENCY INVERSION PRINCIPLE (DIP)

Los Services deben depender de Interfaces y no de implementaciones concretas.

Ejemplo:

TaskService
↓
TaskRepositoryInterface
↓
TaskRepository

Nunca:

TaskService
↓
TaskRepository

directamente.

Utilizar inyección de dependencias en todo el proyecto.

---

# CLEAN ARCHITECTURE

Organizar el sistema en capas:

Domain
├── Entities
├── Interfaces
├── Rules

Application
├── Services
├── DTOs
├── UseCases

Infrastructure
├── Repositories
├── Storage
├── Notifications
├── External Services

Presentation
├── Controllers
├── Requests
├── Resources
├── Routes

Las capas internas nunca deben depender de las externas.

---

# REGLA OBLIGATORIA

Si en algún momento una regla de negocio termina dentro de un Controller, Middleware, Request o Repository, debe considerarse un error de arquitectura y refactorizarse hacia la capa de dominio o servicios.

El objetivo es que el sistema pueda evolucionar, cambiar de base de datos, cambiar de método de autenticación o incluso cambiar de framework sin afectar las reglas de negocio principales.
