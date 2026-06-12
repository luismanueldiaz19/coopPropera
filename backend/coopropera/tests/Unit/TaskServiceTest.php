<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Application\Services\TaskService;
use App\Domain\Interfaces\TaskRepositoryInterface;
use App\Domain\Interfaces\AuditLogRepositoryInterface;
use App\Models\User;
use App\Models\Task;
use Mockery;

class TaskServiceTest extends TestCase
{
    public function test_get_all_tasks_for_admin_user()
    {
        $taskRepo = Mockery::mock(TaskRepositoryInterface::class);
        $auditRepo = Mockery::mock(AuditLogRepositoryInterface::class);
        
        $user = Mockery::mock(User::class)->makePartial();
        $user->shouldReceive('hasRole')->with('Administrador de Tareas')->andReturn(true);
        $user->id = 1;

        $taskRepo->shouldReceive('getAllForUser')->with(1, true)->once()->andReturn(collect([new Task()]));

        $service = new TaskService($taskRepo, $auditRepo);
        
        $tasks = $service->getAllTasks($user);
        
        $this->assertCount(1, $tasks);
    }
}