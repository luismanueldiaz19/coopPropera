<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'username' => 'nullable|string|unique:users,username,'.$this->route('user'),
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