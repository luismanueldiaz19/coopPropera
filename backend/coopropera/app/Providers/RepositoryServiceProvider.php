<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        $this->app->bind(
            \App\Domain\Interfaces\TaskRepositoryInterface::class,
            \App\Infrastructure\Repositories\TaskRepository::class
        );
        $this->app->bind(
            \App\Domain\Interfaces\UserRepositoryInterface::class,
            \App\Infrastructure\Repositories\UserRepository::class
        );
        $this->app->bind(
            \App\Domain\Interfaces\AuditLogRepositoryInterface::class,
            \App\Infrastructure\Repositories\AuditLogRepository::class
        );
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        //
    }
}
