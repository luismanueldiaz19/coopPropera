<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TaskController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\MetaDataController;
use App\Http\Controllers\Api\OccupationController;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/profile', [AuthController::class, 'updateProfile']);

    // MetaData
    Route::get('/occupations', [MetaDataController::class, 'getOccupations']);
    Route::get('/roles', [MetaDataController::class, 'getRoles']);

    // Tareas
    Route::apiResource('tasks', TaskController::class);
    Route::post('tasks/{task}/assign', [TaskController::class, 'assign']);
    Route::post('tasks/{task}/close', [TaskController::class, 'close']);
    Route::post('tasks/{task}/attachments', [TaskController::class, 'uploadAttachment']);
    Route::delete('tasks/{task}/attachments/{attachment}', [TaskController::class, 'deleteAttachment']);
    Route::post('tasks/{task}/reports', [TaskController::class, 'addReport']);
    Route::post('tasks/{task}/participants', [TaskController::class, 'syncParticipants']);

    // Usuarios: Lectura pública para poder asignar tareas
    Route::get('users', [UserController::class, 'index']);

    // Usuarios (Solo administradores)
    Route::middleware('role:admin,Administrador de Tareas,Super Admin')->group(function () {
        Route::apiResource('users', UserController::class)->except(['index']);
        Route::apiResource('occupations', OccupationController::class);
    });
});
