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
        return $task->created_by === $user->id ||
               $task->assigned_by === $user->id ||
               $task->assigned_to === $user->id ||
               $task->participants()->where('user_id', $user->id)->exists();
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return $user->hasPermission('tasks.create');
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Task $task): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        // Solo creador o asignador pueden actualizar a nivel general, o alguien con permisos específicos (gestionado en service)
        return $task->created_by === $user->id || $task->assigned_by === $user->id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Task $task): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        return $task->created_by === $user->id;
    }

    /**
     * Determine whether the user can assign the task.
     */
    public function assign(User $user, Task $task): bool
    {
        if ($user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin')) {
            return true;
        }

        return $task->created_by === $user->id || $task->assigned_by === $user->id;
    }
}
