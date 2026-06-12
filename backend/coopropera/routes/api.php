<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TaskController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\MetaDataController;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // MetaData
    Route::get('/occupations', [MetaDataController::class, 'getOccupations']);
    Route::get('/roles', [MetaDataController::class, 'getRoles']);

    // Tareas
    Route::apiResource('tasks', TaskController::class);
    Route::post('tasks/{task}/assign', [TaskController::class, 'assign']);
    Route::post('tasks/{task}/close', [TaskController::class, 'close']);
    Route::post('tasks/{task}/attachments', [TaskController::class, 'uploadAttachment']);
    Route::post('tasks/{task}/reports', [TaskController::class, 'addReport']);
    Route::post('tasks/{task}/participants', [TaskController::class, 'syncParticipants']);

    // Usuarios (Solo administradores)
    Route::middleware('role:admin,Administrador de Tareas,Super Admin')->group(function () {
        Route::apiResource('users', UserController::class);
    });
});
