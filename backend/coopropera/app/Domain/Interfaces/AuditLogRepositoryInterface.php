<?php
namespace App\Domain\Interfaces;

interface AuditLogRepositoryInterface
{
    public function log($userId, $action, $module, $recordId = null, $oldValues = null, $newValues = null);
}