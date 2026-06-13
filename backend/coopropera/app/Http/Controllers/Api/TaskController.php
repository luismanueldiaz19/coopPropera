<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Application\Services\TaskService;
use App\Http\Requests\StoreTaskRequest;
use App\Http\Requests\UpdateTaskRequest;
use App\Http\Requests\AssignTaskRequest;
use App\Http\Requests\TaskAttachmentRequest;
use App\Http\Requests\TaskReportRequest;
use App\Http\Resources\TaskResource;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class TaskController extends Controller
{
    use AuthorizesRequests;

    private $taskService;

    public function __construct(TaskService $taskService)
    {
        $this->taskService = $taskService;
    }

    public function index(Request $request)
    {
        $tasks = $this->taskService->getAllTasks($request->user());
        return TaskResource::collection($tasks);
    }

    public function show(Request $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('view', $task);
        return new TaskResource($task);
    }

    public function store(StoreTaskRequest $request)
    {
        $this->authorize('create', \App\Models\Task::class);
        $task = $this->taskService->createTask($request->user(), $request->validated());
        return new TaskResource($task);
    }

    public function update(UpdateTaskRequest $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('update', $task);
        $updatedTask = $this->taskService->updateTask($request->user(), $id, $request->validated());
        return new TaskResource($updatedTask);
    }

    public function assign(AssignTaskRequest $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('assign', $task);
        $updatedTask = $this->taskService->assignTask($request->user(), $id, $request->assigned_to);
        return new TaskResource($updatedTask);
    }

    public function close(Request $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('update', $task);
        $updatedTask = $this->taskService->closeTask($request->user(), $id);
        return new TaskResource($updatedTask);
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $isAdmin = $user->hasRole('admin') || $user->hasRole('Administrador de Tareas') || $user->hasRole('Super Admin');
        
        if (!$isAdmin) {
            return response()->json(['message' => 'No tienes permisos para eliminar tareas. Sólo los administradores pueden hacerlo.'], 403);
        }

        $this->taskService->deleteTask($user, $id);
        
        return response()->json(['message' => 'Tarea eliminada exitosamente']);
    }

    public function uploadAttachment(TaskAttachmentRequest $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('view', $task); // Must be able to view task to upload
        $attachment = $this->taskService->addAttachment($request->user(), $id, $request->file('attachment'));
        return response()->json(['attachment' => $attachment], 201);
    }

    public function deleteAttachment(Request $request, $taskId, $attachmentId)
    {
        $task = $this->taskService->getTaskById($taskId);
        
        // Authorization: Solo admin, asignado o el que lo subió
        $user = $request->user();
        if (!$user->hasRole('Administrador de Tareas') && !$user->hasRole('Super Admin')) {
            $isAssignee = $task->participants()->where('user_id', $user->id)->exists();
            if (!$isAssignee) {
                // Check if user is the uploader of the attachment
                $attachment = \App\Models\TaskAttachment::findOrFail($attachmentId);
                if ($attachment->uploaded_by != $user->id) {
                    abort(403, 'Unauthorized action.');
                }
            }
        }

        $this->taskService->deleteAttachment($user, $taskId, $attachmentId);
        return response()->json(['message' => 'Attachment deleted successfully']);
    }

    public function addReport(TaskReportRequest $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('view', $task);
        $report = $this->taskService->addReport($request->user(), $id, $request->validated());
        return response()->json(['report' => $report], 201);
    }

    public function syncParticipants(Request $request, $id)
    {
        $task = $this->taskService->getTaskById($id);
        $this->authorize('update', $task);
        
        $request->validate([
            'participants' => 'nullable|array',
            'participants.*' => 'exists:users,id'
        ]);

        $updatedTask = $this->taskService->syncParticipants($request->user(), $id, $request->participants ?? []);
        return new TaskResource($updatedTask);
    }
}