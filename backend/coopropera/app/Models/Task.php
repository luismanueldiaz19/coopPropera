<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Task extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'title', 'description', 'status', 'priority', 'start_date', 'end_date',
        'estimated_hours', 'created_by', 'assigned_by', 'assigned_to', 'completed_at'
    ];

    protected $casts = [
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function assigner()
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }

    public function assignee()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    public function participants()
    {
        return $this->hasMany(TaskParticipant::class);
    }

    public function reports()
    {
        return $this->hasMany(TaskReport::class);
    }

    public function attachments()
    {
        return $this->hasMany(TaskAttachment::class);
    }
}