<?php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TaskReportRequest extends FormRequest
{
    public function authorize() { return true; }
    public function rules()
    {
        return [
            'report' => 'nullable|string',
            'report_date' => 'required|date',
            'hours_worked' => 'nullable|numeric|min:0',
            'start_time' => 'nullable|date',
            'end_time' => 'nullable|date|after:start_time',
        ];
    }
}