<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AssignTaskRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'assigned_to' => 'required|exists:users,id',
        ];
    }
}