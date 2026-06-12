<?php
namespace App\Application\Services;

use App\Domain\Interfaces\UserRepositoryInterface;
use App\Domain\Interfaces\AuditLogRepositoryInterface;

class UserService
{
    private $userRepo;
    private $auditRepo;

    public function __construct(UserRepositoryInterface $userRepo, AuditLogRepositoryInterface $auditRepo)
    {
        $this->userRepo = $userRepo;
        $this->auditRepo = $auditRepo;
    }

    public function getAllUsers()
    {
        return $this->userRepo->getAll();
    }

    public function getUserById($id)
    {
        return $this->userRepo->findById($id);
    }

    public function createUser($adminUser, array $data)
    {
        $user = $this->userRepo->create($data);
        $this->auditRepo->log($adminUser->id, 'create', 'users', $user->id, null, $user->toArray());
        return $user;
    }

    public function updateUser($adminUser, $id, array $data)
    {
        $user = $this->userRepo->findById($id);
        $oldValues = $user->toArray();
        $user = $this->userRepo->update($id, $data);
        $this->auditRepo->log($adminUser->id, 'update', 'users', $user->id, $oldValues, $user->toArray());
        return $user;
    }

    public function deleteUser($adminUser, $id)
    {
        $user = $this->userRepo->findById($id);
        $oldValues = $user->toArray();
        $this->userRepo->delete($id);
        $this->auditRepo->log($adminUser->id, 'delete', 'users', $id, $oldValues, null);
    }
}