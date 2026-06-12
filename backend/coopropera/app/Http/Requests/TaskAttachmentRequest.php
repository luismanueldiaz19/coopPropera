<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TaskAttachmentRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        // 15MB limit = 15360 kilobytes
        return [
            'attachment' => 'required|file|mimes:pdf,jpg,jpeg,png|max:15360',
        ];
    }
}