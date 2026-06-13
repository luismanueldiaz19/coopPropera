<?php
namespace App\Application\Services;

use App\Domain\Interfaces\TaskRepositoryInterface;
use App\Domain\Interfaces\AuditLogRepositoryInterface;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class TaskService
{
    private $taskRepo;
    private $auditRepo;

    public function __construct(TaskRepositoryInterface $taskRepo, AuditLogRepositoryInterface $auditRepo)
    {
        $this->taskRepo = $taskRepo;
        $this->auditRepo = $auditRepo;
    }

    public function getAllTasks($user)
    {
        $isAdmin = $user->hasRole('admin') || $user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin');
        return $this->taskRepo->getAllForUser($user->id, $isAdmin);
    }

    public function getTaskById($id)
    {
        return $this->taskRepo->findById($id);
    }

    public function createTask($user, array $data)
    {
        $data['created_by'] = $user->id;
        
        // Si no se indica asignación, por defecto se asigna al mismo usuario que la creó
        if (empty($data['assigned_to'])) {
            $data['assigned_to'] = $user->id;
        }

        $task = $this->taskRepo->create($data);
        $this->auditRepo->log($user->id, 'create', 'tasks', $task->id, null, $task->toArray());

        if (isset($data['participants']) && is_array($data['participants'])) {
            foreach ($data['participants'] as $participantId) {
                $this->taskRepo->addParticipant($task, $participantId, 'participant');
            }
        }
        
        return $task;
    }

    public function updateTask($user, $id, array $data)
    {
        $task = $this->taskRepo->findById($id);
        $oldValues = $task->toArray();
        $task = $this->taskRepo->update($task, $data);
        $this->auditRepo->log($user->id, 'update', 'tasks', $task->id, $oldValues, $task->toArray());
        return $task;
    }

    public function assignTask($user, $taskId, $assignedToUserId)
    {
        $task = $this->taskRepo->findById($taskId);
        $oldValues = $task->toArray();
        $task = $this->taskRepo->update($task, [
            'assigned_to' => $assignedToUserId,
            'assigned_by' => $user->id
        ]);
        $this->auditRepo->log($user->id, 'assign', 'tasks', $task->id, $oldValues, $task->toArray());
        return $task;
    }

    public function closeTask($user, $taskId)
    {
        $task = $this->taskRepo->findById($taskId);
        $oldValues = $task->toArray();
        $task = $this->taskRepo->update($task, [
            'status' => 'completed',
            'completed_at' => now()
        ]);
        $this->auditRepo->log($user->id, 'close', 'tasks', $task->id, $oldValues, $task->toArray());
        return $task;
    }

    public function deleteTask($user, $taskId)
    {
        $task = $this->taskRepo->findById($taskId);
        
        // Borrar archivos físicos
        foreach ($task->attachments as $attachment) {
            \Illuminate\Support\Facades\Storage::disk('public')->delete($attachment->file_path);
            $attachment->forceDelete();
        }

        // Borrar relaciones
        $task->participants()->delete();
        $task->reports()->delete();

        // Borrar la tarea definitivamente
        $oldValues = $task->toArray();
        $task->forceDelete();

        $this->auditRepo->log($user->id, 'delete_task', 'tasks', $taskId, $oldValues, null);
    }

    public function addAttachment($user, $taskId, UploadedFile $file)
    {
        $task = $this->taskRepo->findById($taskId);
        
        $path = $file->store('task_attachments', 'public');
        
        $attachment = $this->taskRepo->addAttachment($task, [
            'uploaded_by' => $user->id,
            'file_name' => $file->getClientOriginalName(),
            'file_path' => $path,
            'file_type' => $file->getMimeType(),
            'file_size' => $file->getSize()
        ]);
        
        $this->auditRepo->log($user->id, 'upload_attachment', 'tasks', $task->id, null, $attachment->toArray());
        
        return $attachment;
    }

    public function deleteAttachment($user, $taskId, $attachmentId)
    {
        $task = $this->taskRepo->findById($taskId);
        $attachment = \App\Models\TaskAttachment::findOrFail($attachmentId);
        
        if ($attachment->task_id != $taskId) {
            throw new \Exception("El anexo no pertenece a la tarea indicada");
        }

        // Delete from storage
        \Illuminate\Support\Facades\Storage::disk('public')->delete($attachment->file_path);
        
        $oldValues = $attachment->toArray();
        $attachment->delete();
        
        $this->auditRepo->log($user->id, 'delete_attachment', 'tasks', $task->id, $oldValues, null);
        
        return true;
    }

    public function addReport($user, $taskId, array $data)
    {
        $task = $this->taskRepo->findById($taskId);
        $data['user_id'] = $user->id;
        
        $report = $this->taskRepo->addReport($task, $data);
        
        $this->auditRepo->log($user->id, 'add_report', 'tasks', $task->id, null, $report->toArray());
        
        return $report;
    }

    public function syncParticipants($user, $taskId, array $participantIds)
    {
        $task = $this->taskRepo->findById($taskId);
        $oldParticipants = $task->participants->pluck('user_id')->toArray();
        
        $this->taskRepo->syncParticipants($task, $participantIds);
        
        $this->auditRepo->log($user->id, 'sync_participants', 'tasks', $task->id, ['old_participants' => $oldParticipants], ['new_participants' => $participantIds]);
        
        // Return refreshed task
        return $this->taskRepo->findById($taskId);
    }
}