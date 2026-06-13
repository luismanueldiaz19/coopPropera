<?php

namespace App\Policies;

use App\Models\Task;
use App\Models\User;

class TaskPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return $user->hasPermission('tasks.read');
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Task $task): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        // Puede ver si es creador, asignador, asignado o participante
        return $task->created_by == $user->id ||
               $task->assigned_by == $user->id ||
               $task->assigned_to == $user->id ||
               $task->participants()->where('user_id', $user->id)->exists();
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        // En Laravel, si este método se ejecuta es porque $user ya es un usuario autenticado (logueado).
        // Si no estuviera logueado, Laravel lo bloquearía antes de llegar aquí.
        // Por lo tanto, permitimos la creación a cualquier usuario autenticado:
        return $user->id !== null;
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Task $task): bool
    {
        // Bypass temporal para verificar si el problema es la política
        return true;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Task $task): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        return $task->created_by == $user->id;
    }

    /**
     * Determine whether the user can assign the task.
     */
    public function assign(User $user, Task $task): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        return $task->created_by == $user->id || $task->assigned_by == $user->id;
    }
}
