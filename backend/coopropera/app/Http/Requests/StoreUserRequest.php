<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreUserRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:6',
            'first_name' => 'required|string',
            'last_name' => 'required|string',
            'occupation_id' => 'nullable|exists:occupations,id',
            'roles' => 'nullable|array',
            'roles.*' => 'exists:roles,id'
        ];
    }
}