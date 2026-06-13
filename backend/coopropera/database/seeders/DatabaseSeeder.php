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
        $managerRole = Role::create(['name' => 'manager']);
        $managerRole->permissions()->attach([$createTask->id, $editTask->id, $viewTask->id]);

        // Crear rol empleado (Solo ve tareas)
        $employeeRole = Role::create(['name' => 'employee']);
        $employeeRole->permissions()->attach([$viewTask->id]);

        // Crear una ocupacion base
        $occupation = Occupation::create(['name' => 'Gerente']);

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
