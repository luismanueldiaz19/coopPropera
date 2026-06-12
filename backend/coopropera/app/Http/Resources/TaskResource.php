<?php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'priority' => $this->priority,
            'start_date' => $this->start_date,
            'end_date' => $this->end_date,
            'estimated_hours' => $this->estimated_hours,
            'created_by' => $this->created_by,
            'creator' => $this->whenLoaded('creator'),
            'assigned_to' => $this->assigned_to,
            'assignee' => $this->whenLoaded('assignee'),
            'participants' => $this->whenLoaded('participants', function() { 
                return $this->participants->map(fn($p) => [
                    'id' => $p->user->id,
                    'username' => $p->user->username,
                    'full_name' => $p->user->first_name . ' ' . $p->user->last_name,
                ]); 
            }),
            'reports' => $this->whenLoaded('reports'),
            'attachments' => $this->whenLoaded('attachments'),
            'completed_at' => $this->completed_at,
            'created_at' => $this->created_at,
        ];
    }
}