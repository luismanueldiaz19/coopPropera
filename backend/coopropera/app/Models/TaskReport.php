<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaskReport extends Model
{
    protected $fillable = ['task_id', 'user_id', 'report', 'report_date', 'hours_worked', 'start_time', 'end_time'];

    protected $casts = [
        'report_date' => 'date',
    ];

    public function task()
    {
        return $this->belongsTo(Task::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}