<?php

$baseDir = __DIR__ . '/app';

$dirs = [
    $baseDir . '/Http/Controllers/Api',
    $baseDir . '/Http/Requests',
    $baseDir . '/Http/Resources',
];

foreach ($dirs as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
}

$files = [
    // Controllers
    'Http/Controllers/Api/TaskController.php' => <<<PHP
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

class TaskController extends Controller
{
    private \$taskService;

    public function __construct(TaskService \$taskService)
    {
        \$this->taskService = \$taskService;
    }

    public function index(Request \$request)
    {
        \$tasks = \$this->taskService->getAllTasks(\$request->user());
        return TaskResource::collection(\$tasks);
    }

    public function show(Request \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('view', \$task);
        return new TaskResource(\$task);
    }

    public function store(StoreTaskRequest \$request)
    {
        \$this->authorize('create', \App\Models\Task::class);
        \$task = \$this->taskService->createTask(\$request->user(), \$request->validated());
        return new TaskResource(\$task);
    }

    public function update(UpdateTaskRequest \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('update', \$task);
        \$updatedTask = \$this->taskService->updateTask(\$request->user(), \$id, \$request->validated());
        return new TaskResource(\$updatedTask);
    }

    public function assign(AssignTaskRequest \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('assign', \$task);
        \$updatedTask = \$this->taskService->assignTask(\$request->user(), \$id, \$request->assigned_to);
        return new TaskResource(\$updatedTask);
    }

    public function close(Request \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('update', \$task);
        \$updatedTask = \$this->taskService->closeTask(\$request->user(), \$id);
        return new TaskResource(\$updatedTask);
    }

    public function destroy(Request \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('delete', \$task);
        \$this->taskService->deleteTask(\$request->user(), \$id);
        return response()->json(['message' => 'Task deleted']);
    }

    public function uploadAttachment(TaskAttachmentRequest \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('view', \$task); // Must be able to view task to upload
        \$attachment = \$this->taskService->addAttachment(\$request->user(), \$id, \$request->file('attachment'));
        return response()->json(['attachment' => \$attachment], 201);
    }

    public function addReport(TaskReportRequest \$request, \$id)
    {
        \$task = \$this->taskService->getTaskById(\$id);
        \$this->authorize('view', \$task);
        \$report = \$this->taskService->addReport(\$request->user(), \$id, \$request->validated());
        return response()->json(['report' => \$report], 201);
    }
}
PHP,
    'Http/Controllers/Api/UserController.php' => <<<PHP
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Application\Services\UserService;
use App\Http\Requests\StoreUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;

class UserController extends Controller
{
    private \$userService;

    public function __construct(UserService \$userService)
    {
        \$this->userService = \$userService;
    }

    public function index()
    {
        return UserResource::collection(\$this->userService->getAllUsers());
    }

    public function show(\$id)
    {
        return new UserResource(\$this->userService->getUserById(\$id));
    }

    public function store(StoreUserRequest \$request)
    {
        \$user = \$this->userService->createUser(\$request->user(), \$request->validated());
        return new UserResource(\$user);
    }

    public function update(UpdateUserRequest \$request, \$id)
    {
        \$user = \$this->userService->updateUser(\$request->user(), \$id, \$request->validated());
        return new UserResource(\$user);
    }

    public function destroy(Request \$request, \$id)
    {
        \$this->userService->deleteUser(\$request->user(), \$id);
        return response()->json(['message' => 'User deleted']);
    }
}
PHP,

    // Form Requests
    'Http/Requests/StoreTaskRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTaskRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'priority' => 'nullable|in:low,medium,high,critical',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'estimated_hours' => 'nullable|numeric|min:0',
            'assigned_to' => 'nullable|exists:users,id',
            'participants' => 'nullable|array',
            'participants.*' => 'exists:users,id'
        ];
    }
}
PHP,
    'Http/Requests/UpdateTaskRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTaskRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'priority' => 'nullable|in:low,medium,high,critical',
            'status' => 'nullable|in:pending,in_progress,completed,cancelled',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'estimated_hours' => 'nullable|numeric|min:0',
        ];
    }
}
PHP,
    'Http/Requests/AssignTaskRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AssignTaskRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'assigned_to' => 'required|exists:users,id',
        ];
    }
}
PHP,
    'Http/Requests/TaskAttachmentRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TaskAttachmentRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        // 15MB limit = 15360 kilobytes
        return [
            'attachment' => 'required|file|mimes:pdf,jpg,jpeg,png|max:15360',
        ];
    }
}
PHP,
    'Http/Requests/TaskReportRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TaskReportRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'report' => 'required|string',
            'report_date' => 'required|date',
            'hours_worked' => 'nullable|numeric|min:0',
        ];
    }
}
PHP,
    'Http/Requests/StoreUserRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreUserRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:6',
            'first_name' => 'required|string',
            'last_name' => 'required|string',
            'occupation_id' => 'nullable|exists:occupations,id',
            'roles' => 'nullable|array',
            'roles.*' => 'exists:roles,id'
        ];
    }
}
PHP,
    'Http/Requests/UpdateUserRequest.php' => <<<PHP
<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'username' => 'nullable|string|unique:users,username,'.\$this->route('user'),
            'password' => 'nullable|string|min:6',
            'first_name' => 'nullable|string',
            'last_name' => 'nullable|string',
            'occupation_id' => 'nullable|exists:occupations,id',
            'status' => 'nullable|in:active,inactive',
            'roles' => 'nullable|array',
            'roles.*' => 'exists:roles,id'
        ];
    }
}
PHP,

    // Resources
    'Http/Resources/TaskResource.php' => <<<PHP
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    public function toArray(Request \$request): array
    {
        return [
            'id' => \$this->id,
            'title' => \$this->title,
            'description' => \$this->description,
            'status' => \$this->status,
            'priority' => \$this->priority,
            'start_date' => \$this->start_date,
            'end_date' => \$this->end_date,
            'estimated_hours' => \$this->estimated_hours,
            'created_by' => \$this->whenLoaded('creator', function() { return \$this->creator->username; }),
            'assigned_to' => \$this->whenLoaded('assignee', function() { return \$this->assignee ? \$this->assignee->username : null; }),
            'participants' => \$this->whenLoaded('participants', function() { return \$this->participants->map(fn(\$p) => \$p->user->username); }),
            'reports' => \$this->whenLoaded('reports'),
            'attachments' => \$this->whenLoaded('attachments'),
            'completed_at' => \$this->completed_at,
            'created_at' => \$this->created_at,
        ];
    }
}
PHP,
    'Http/Resources/UserResource.php' => <<<PHP
<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request \$request): array
    {
        return [
            'id' => \$this->id,
            'username' => \$this->username,
            'first_name' => \$this->first_name,
            'last_name' => \$this->last_name,
            'occupation' => \$this->whenLoaded('occupation', function() { return \$this->occupation->name; }),
            'status' => \$this->status,
            'roles' => \$this->whenLoaded('roles', function() { return \$this->roles->pluck('name'); }),
            'created_at' => \$this->created_at,
        ];
    }
}
PHP,

];

foreach ($files as $file => $content) {
    $content = str_replace('\$','$', $content);
    file_put_contents($baseDir . '/' . $file, $content);
}

echo "API scaffold completed.\n";
