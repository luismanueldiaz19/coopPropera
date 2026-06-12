<?php
namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\UserRepositoryInterface;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserRepository implements UserRepositoryInterface
{
    public function getAll()
    {
        return User::with(['occupation', 'roles'])->get();
    }

    public function findById($id)
    {
        return User::with(['occupation', 'roles'])->findOrFail($id);
    }

    public function create(array $data)
    {
        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }
        $user = User::create($data);
        if (isset($data['roles'])) {
            $user->roles()->sync($data['roles']);
        }
        return $user;
    }

    public function update($id, array $data)
    {
        $user = $this->findById($id);
        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }
        $user->update($data);
        if (isset($data['roles'])) {
            $user->roles()->sync($data['roles']);
        }
        return $user;
    }

    public function delete($id)
    {
        return $this->findById($id)->delete();
    }
}