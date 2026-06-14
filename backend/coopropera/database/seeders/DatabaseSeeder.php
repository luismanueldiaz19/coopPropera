<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Occupation;
use App\Models\Role;
use App\Models\Permission;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Crear permisos
        $createTask = Permission::create(['name' => 'tasks.create']);
        $editTask = Permission::create(['name' => 'tasks.edit']);
        $viewTask = Permission::create(['name' => 'tasks.view']);
        $deleteTask = Permission::create(['name' => 'tasks.delete']);

        // Crear rol admin (Todos los permisos)
        $adminRole = Role::create(['name' => 'admin']);
        $adminRole->permissions()->attach([$createTask->id, $editTask->id, $viewTask->id, $deleteTask->id]);

        // Crear rol manager (Crea, edita y ve tareas)
        $managerRole = Role::create(['name' => 'gestión de tareas']);
        $managerRole->permissions()->attach([$createTask->id, $editTask->id, $viewTask->id]);

        // Crear rol empleado (Solo ve tareas)
        $employeeRole = Role::create(['name' => 'visialización de tareas']);
        $employeeRole->permissions()->attach([$viewTask->id]);

        // Crear ocupaciones
        Occupation::create(['name' => 'Gerente Gestión Humana']);
        Occupation::create(['name' => 'Gerente de Operaciones']);
        Occupation::create(['name' => 'Gerente Finanzas']);
        Occupation::create(['name' => 'Gerente Legal']);
        Occupation::create(['name' => 'Gerente Negocios']);
         Occupation::create(['name' => 'Gerente General']);
       
        $occupation = Occupation::create(['name' => 'Administrador']);
        Occupation::create(['name' => 'Asistente Administrativa']);

        $admin = User::create([
            'username' => 'admin',
            'first_name' => 'Lwader',
            'last_name' => 'Soft',
            'password' => \Hash::make('199512'),
            'occupation_id' => $occupation->id,
            'status' => 'active',
        ]);

        $admin->roles()->attach($adminRole->id);
    }
}
