<?php
namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\TaskRepositoryInterface;
use App\Models\Task;
use App\Models\TaskParticipant;
use App\Models\TaskReport;
use App\Models\TaskAttachment;

class TaskRepository implements TaskRepositoryInterface
{
    public function getAllForUser($userId, $isAdmin)
    {
        $query = Task::with(['creator', 'assignee', 'participants.user', 'reports.user', 'attachments']);
        
        if (!$isAdmin) {
            $query->where(function($q) use ($userId) {
                $q->where('created_by', $userId)
                  ->orWhere('assigned_to', $userId)
                  ->orWhereHas('participants', function($pq) use ($userId) {
                      $pq->where('user_id', $userId);
                  });
            });
        }
        
        return $query->get();
    }

    public function findById($id)
    {
        return Task::with(['creator', 'assignee', 'participants.user', 'reports.user', 'attachments.uploader'])->findOrFail($id);
    }

    public function create(array $data)
    {
        return Task::create($data);
    }

    public function update(Task $task, array $data)
    {
        $task->update($data);
        return $task;
    }

    public function delete(Task $task)
    {
        return $task->delete();
    }

    public function addParticipant(Task $task, $userId, $role)
    {
        return TaskParticipant::create([
            'task_id' => $task->id,
            'user_id' => $userId,
            'role_in_task' => $role
        ]);
    }

    public function addReport(Task $task, array $data)
    {
        return TaskReport::create(array_merge($data, ['task_id' => $task->id]));
    }

    public function addAttachment(Task $task, array $data)
    {
        return TaskAttachment::create(array_merge($data, ['task_id' => $task->id]));
    }

    public function syncParticipants(Task $task, array $userIds)
    {
        // Eliminamos los participantes actuales
        TaskParticipant::where('task_id', $task->id)->delete();
        
        // Insertamos los nuevos
        foreach ($userIds as $userId) {
            TaskParticipant::create([
                'task_id' => $task->id,
                'user_id' => $userId,
                'role_in_task' => 'participant'
            ]);
        }
    }
}