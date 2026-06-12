<?php

$baseDir = __DIR__ . '/app';

$dirs = [
    $baseDir . '/Domain/Interfaces',
    $baseDir . '/Application/Services',
    $baseDir . '/Application/DTOs',
    $baseDir . '/Infrastructure/Repositories',
];

foreach ($dirs as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
}

$files = [
    // Interfaces
    'Domain/Interfaces/TaskRepositoryInterface.php' => <<<PHP
<?php
namespace App\Domain\Interfaces;

use App\Models\Task;

interface TaskRepositoryInterface
{
    public function getAllForUser(\$userId, \$isAdmin);
    public function findById(\$id);
    public function create(array \$data);
    public function update(Task \$task, array \$data);
    public function delete(Task \$task);
    public function addParticipant(Task \$task, \$userId, \$role);
    public function addReport(Task \$task, array \$data);
    public function addAttachment(Task \$task, array \$data);
}
PHP,
    'Domain/Interfaces/UserRepositoryInterface.php' => <<<PHP
<?php
namespace App\Domain\Interfaces;

interface UserRepositoryInterface
{
    public function getAll();
    public function findById(\$id);
    public function create(array \$data);
    public function update(\$id, array \$data);
    public function delete(\$id);
}
PHP,
    'Domain/Interfaces/AuditLogRepositoryInterface.php' => <<<PHP
<?php
namespace App\Domain\Interfaces;

interface AuditLogRepositoryInterface
{
    public function log(\$userId, \$action, \$module, \$recordId = null, \$oldValues = null, \$newValues = null);
}
PHP,

    // Repositories
    'Infrastructure/Repositories/TaskRepository.php' => <<<PHP
<?php
namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\TaskRepositoryInterface;
use App\Models\Task;
use App\Models\TaskParticipant;
use App\Models\TaskReport;
use App\Models\TaskAttachment;

class TaskRepository implements TaskRepositoryInterface
{
    public function getAllForUser(\$userId, \$isAdmin)
    {
        \$query = Task::with(['creator', 'assignee', 'participants.user']);
        
        if (!\$isAdmin) {
            \$query->where(function(\$q) use (\$userId) {
                \$q->where('created_by', \$userId)
                  ->orWhere('assigned_to', \$userId)
                  ->orWhereHas('participants', function(\$pq) use (\$userId) {
                      \$pq->where('user_id', \$userId);
                  });
            });
        }
        
        return \$query->get();
    }

    public function findById(\$id)
    {
        return Task::with(['creator', 'assignee', 'participants.user', 'reports.user', 'attachments.uploader'])->findOrFail(\$id);
    }

    public function create(array \$data)
    {
        return Task::create(\$data);
    }

    public function update(Task \$task, array \$data)
    {
        \$task->update(\$data);
        return \$task;
    }

    public function delete(Task \$task)
    {
        return \$task->delete();
    }

    public function addParticipant(Task \$task, \$userId, \$role)
    {
        return TaskParticipant::create([
            'task_id' => \$task->id,
            'user_id' => \$userId,
            'role_in_task' => \$role
        ]);
    }

    public function addReport(Task \$task, array \$data)
    {
        return TaskReport::create(array_merge(\$data, ['task_id' => \$task->id]));
    }

    public function addAttachment(Task \$task, array \$data)
    {
        return TaskAttachment::create(array_merge(\$data, ['task_id' => \$task->id]));
    }
}
PHP,
    'Infrastructure/Repositories/UserRepository.php' => <<<PHP
<?php
namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\UserRepositoryInterface;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserRepository implements UserRepositoryInterface
{
    public function getAll()
    {
        return User::with(['occupation', 'roles'])->get();
    }

    public function findById(\$id)
    {
        return User::with(['occupation', 'roles'])->findOrFail(\$id);
    }

    public function create(array \$data)
    {
        if (isset(\$data['password'])) {
            \$data['password'] = Hash::make(\$data['password']);
        }
        \$user = User::create(\$data);
        if (isset(\$data['roles'])) {
            \$user->roles()->sync(\$data['roles']);
        }
        return \$user;
    }

    public function update(\$id, array \$data)
    {
        \$user = \$this->findById(\$id);
        if (isset(\$data['password'])) {
            \$data['password'] = Hash::make(\$data['password']);
        }
        \$user->update(\$data);
        if (isset(\$data['roles'])) {
            \$user->roles()->sync(\$data['roles']);
        }
        return \$user;
    }

    public function delete(\$id)
    {
        return \$this->findById(\$id)->delete();
    }
}
PHP,
    'Infrastructure/Repositories/AuditLogRepository.php' => <<<PHP
<?php
namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\AuditLogRepositoryInterface;
use App\Models\AuditLog;

class AuditLogRepository implements AuditLogRepositoryInterface
{
    public function log(\$userId, \$action, \$module, \$recordId = null, \$oldValues = null, \$newValues = null)
    {
        return AuditLog::create([
            'user_id' => \$userId,
            'action' => \$action,
            'module' => \$module,
            'record_id' => \$recordId,
            'old_values' => \$oldValues,
            'new_values' => \$newValues
        ]);
    }
}
PHP,

    // Services
    'Application/Services/TaskService.php' => <<<PHP
<?php
namespace App\Application\Services;

use App\Domain\Interfaces\TaskRepositoryInterface;
use App\Domain\Interfaces\AuditLogRepositoryInterface;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class TaskService
{
    private \$taskRepo;
    private \$auditRepo;

    public function __construct(TaskRepositoryInterface \$taskRepo, AuditLogRepositoryInterface \$auditRepo)
    {
        \$this->taskRepo = \$taskRepo;
        \$this->auditRepo = \$auditRepo;
    }

    public function getAllTasks(\$user)
    {
        \$isAdmin = \$user->hasRole('Administrador de Tareas') || \$user->hasRole('Super Admin');
        return \$this->taskRepo->getAllForUser(\$user->id, \$isAdmin);
    }

    public function getTaskById(\$id)
    {
        return \$this->taskRepo->findById(\$id);
    }

    public function createTask(\$user, array \$data)
    {
        \$data['created_by'] = \$user->id;
        \$task = \$this->taskRepo->create(\$data);
        \$this->auditRepo->log(\$user->id, 'create', 'tasks', \$task->id, null, \$task->toArray());

        if (isset(\$data['participants']) && is_array(\$data['participants'])) {
            foreach (\$data['participants'] as \$participantId) {
                \$this->taskRepo->addParticipant(\$task, \$participantId, 'participant');
            }
        }
        
        return \$task;
    }

    public function updateTask(\$user, \$id, array \$data)
    {
        \$task = \$this->taskRepo->findById(\$id);
        \$oldValues = \$task->toArray();
        \$task = \$this->taskRepo->update(\$task, \$data);
        \$this->auditRepo->log(\$user->id, 'update', 'tasks', \$task->id, \$oldValues, \$task->toArray());
        return \$task;
    }

    public function assignTask(\$user, \$taskId, \$assignedToUserId)
    {
        \$task = \$this->taskRepo->findById(\$taskId);
        \$oldValues = \$task->toArray();
        \$task = \$this->taskRepo->update(\$task, [
            'assigned_to' => \$assignedToUserId,
            'assigned_by' => \$user->id
        ]);
        \$this->auditRepo->log(\$user->id, 'assign', 'tasks', \$task->id, \$oldValues, \$task->toArray());
        return \$task;
    }

    public function closeTask(\$user, \$taskId)
    {
        \$task = \$this->taskRepo->findById(\$taskId);
        \$oldValues = \$task->toArray();
        \$task = \$this->taskRepo->update(\$task, [
            'status' => 'completed',
            'completed_at' => now()
        ]);
        \$this->auditRepo->log(\$user->id, 'close', 'tasks', \$task->id, \$oldValues, \$task->toArray());
        return \$task;
    }

    public function deleteTask(\$user, \$taskId)
    {
        \$task = \$this->taskRepo->findById(\$taskId);
        \$oldValues = \$task->toArray();
        \$this->taskRepo->delete(\$task);
        \$this->auditRepo->log(\$user->id, 'delete', 'tasks', \$task->id, \$oldValues, null);
    }

    public function addAttachment(\$user, \$taskId, UploadedFile \$file)
    {
        \$task = \$this->taskRepo->findById(\$taskId);
        
        \$path = \$file->store('task_attachments', 'public');
        
        \$attachment = \$this->taskRepo->addAttachment(\$task, [
            'uploaded_by' => \$user->id,
            'file_name' => \$file->getClientOriginalName(),
            'file_path' => \$path,
            'file_type' => \$file->getMimeType(),
            'file_size' => \$file->getSize()
        ]);
        
        \$this->auditRepo->log(\$user->id, 'upload_attachment', 'tasks', \$task->id, null, \$attachment->toArray());
        
        return \$attachment;
    }

    public function addReport(\$user, \$taskId, array \$data)
    {
        \$task = \$this->taskRepo->findById(\$taskId);
        \$data['user_id'] = \$user->id;
        
        \$report = \$this->taskRepo->addReport(\$task, \$data);
        
        \$this->auditRepo->log(\$user->id, 'add_report', 'tasks', \$task->id, null, \$report->toArray());
        
        return \$report;
    }
}
PHP,
    'Application/Services/UserService.php' => <<<PHP
<?php
namespace App\Application\Services;

use App\Domain\Interfaces\UserRepositoryInterface;
use App\Domain\Interfaces\AuditLogRepositoryInterface;

class UserService
{
    private \$userRepo;
    private \$auditRepo;

    public function __construct(UserRepositoryInterface \$userRepo, AuditLogRepositoryInterface \$auditRepo)
    {
        \$this->userRepo = \$userRepo;
        \$this->auditRepo = \$auditRepo;
    }

    public function getAllUsers()
    {
        return \$this->userRepo->getAll();
    }

    public function getUserById(\$id)
    {
        return \$this->userRepo->findById(\$id);
    }

    public function createUser(\$adminUser, array \$data)
    {
        \$user = \$this->userRepo->create(\$data);
        \$this->auditRepo->log(\$adminUser->id, 'create', 'users', \$user->id, null, \$user->toArray());
        return \$user;
    }

    public function updateUser(\$adminUser, \$id, array \$data)
    {
        \$user = \$this->userRepo->findById(\$id);
        \$oldValues = \$user->toArray();
        \$user = \$this->userRepo->update(\$id, \$data);
        \$this->auditRepo->log(\$adminUser->id, 'update', 'users', \$user->id, \$oldValues, \$user->toArray());
        return \$user;
    }

    public function deleteUser(\$adminUser, \$id)
    {
        \$user = \$this->userRepo->findById(\$id);
        \$oldValues = \$user->toArray();
        \$this->userRepo->delete(\$id);
        \$this->auditRepo->log(\$adminUser->id, 'delete', 'users', \$id, \$oldValues, null);
    }
}
PHP,
];

foreach ($files as $file => $content) {
    // Unescape $ properly
    $content = str_replace('\$','$', $content);
    file_put_contents($baseDir . '/' . $file, $content);
}

echo "Domain scaffold completed.\n";
