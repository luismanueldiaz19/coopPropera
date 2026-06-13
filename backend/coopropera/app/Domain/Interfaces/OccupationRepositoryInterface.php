<?php

namespace App\Domain\Interfaces;

use App\Models\Occupation;
use Illuminate\Database\Eloquent\Collection;

interface OccupationRepositoryInterface
{
    public function getAll(): Collection;
    public function getActive(): Collection;
    public function findById(int $id): ?Occupation;
    public function create(array $data): Occupation;
    public function update(int $id, array $data): bool;
    public function delete(int $id): bool;
}
