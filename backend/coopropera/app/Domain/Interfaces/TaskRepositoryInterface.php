<?php
namespace App\Domain\Interfaces;

use App\Models\Task;

interface TaskRepositoryInterface
{
    public function getAllForUser($userId, $isAdmin);
    public function findById($id);
    public function create(array $data);
    public function update(Task $task, array $data);
    public function delete(Task $task);
    public function addParticipant(Task $task, $userId, $role);
    public function addReport(Task $task, array $data);
    public function addAttachment(Task $task, array $data);
}