<?php

namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\OccupationRepositoryInterface;
use App\Models\Occupation;
use Illuminate\Database\Eloquent\Collection;

class OccupationRepository implements OccupationRepositoryInterface
{
    public function getAll(): Collection
    {
        return Occupation::all();
    }

    public function getActive(): Collection
    {
        return Occupation::where('status', 'active')->get();
    }

    public function findById(int $id): ?Occupation
    {
        return Occupation::find($id);
    }

    public function create(array $data): Occupation
    {
        return Occupation::create($data);
    }

    public function update(int $id, array $data): bool
    {
        $occupation = $this->findById($id);
        if (!$occupation) {
            return false;
        }
        return $occupation->update($data);
    }

    public function delete(int $id): bool
    {
        $occupation = $this->findById($id);
        if (!$occupation) {
            return false;
        }
        // Assuming soft deletes or changing status to 'inactive'
        // For now, we update status to inactive instead of hard deleting to preserve referential integrity
        return $occupation->update(['status' => 'inactive']);
    }
}
