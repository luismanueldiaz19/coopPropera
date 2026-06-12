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
    private $userService;

    public function __construct(UserService $userService)
    {
        $this->userService = $userService;
    }

    public function index()
    {
        return UserResource::collection($this->userService->getAllUsers());
    }

    public function show($id)
    {
        return new UserResource($this->userService->getUserById($id));
    }

    public function store(StoreUserRequest $request)
    {
        $user = $this->userService->createUser($request->user(), $request->validated());
        return new UserResource($user);
    }

    public function update(UpdateUserRequest $request, $id)
    {
        $user = $this->userService->updateUser($request->user(), $id, $request->validated());
        return new UserResource($user);
    }

    public function destroy(Request $request, $id)
    {
        $this->userService->deleteUser($request->user(), $id);
        return response()->json(['message' => 'User deleted']);
    }
}