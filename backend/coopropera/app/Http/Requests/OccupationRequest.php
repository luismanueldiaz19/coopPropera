<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class OccupationRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Authorization should ideally be handled by Policies, so we return true here
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $rules = [
            'name' => 'required|string|max:255|unique:occupations,name',
            'description' => 'nullable|string',
            'status' => 'nullable|string|in:active,inactive',
        ];

        // If it's an update request, ignore the current occupation's ID for uniqueness
        if ($this->isMethod('put') || $this->isMethod('patch')) {
            $occupationId = $this->route('occupation');
            $rules['name'] = 'required|string|max:255|unique:occupations,name,' . $occupationId;
        }

        return $rules;
    }
}
