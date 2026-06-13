<?php

namespace App\Application\Services;

use App\Domain\Interfaces\OccupationRepositoryInterface;
use App\Models\Occupation;
use Illuminate\Database\Eloquent\Collection;

class OccupationService
{
    protected $repository;

    public function __construct(OccupationRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function getAllOccupations(): Collection
    {
        return $this->repository->getAll();
    }

    public function getActiveOccupations(): Collection
    {
        return $this->repository->getActive();
    }

    public function getOccupationById(int $id): ?Occupation
    {
        return $this->repository->findById($id);
    }

    public function createOccupation(array $data): Occupation
    {
        // Enforce default status if not provided
        $data['status'] = $data['status'] ?? 'active';
        return $this->repository->create($data);
    }

    public function updateOccupation(int $id, array $data): bool
    {
        return $this->repository->update($id, $data);
    }

    public function deleteOccupation(int $id): bool
    {
        // Add any business logic here before deleting, e.g., checking if users are assigned
        return $this->repository->delete($id);
    }
}
