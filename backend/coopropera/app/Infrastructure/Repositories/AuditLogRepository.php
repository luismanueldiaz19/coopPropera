<?php
namespace App\Infrastructure\Repositories;

use App\Domain\Interfaces\AuditLogRepositoryInterface;
use App\Models\AuditLog;

class AuditLogRepository implements AuditLogRepositoryInterface
{
    public function log($userId, $action, $module, $recordId = null, $oldValues = null, $newValues = null)
    {
        return AuditLog::create([
            'user_id' => $userId,
            'action' => $action,
            'module' => $module,
            'record_id' => $recordId,
            'old_values' => $oldValues,
            'new_values' => $newValues
        ]);
    }
}