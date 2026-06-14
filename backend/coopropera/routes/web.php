<?php

use Illuminate\Support\Facades\Route;

// Redirigir cualquier ruta que no sea de API al index.html generado por Flutter
Route::get('/{any}', function () {
    $path = public_path('index.html');
    if (file_exists($path)) {
        return file_get_contents($path);
    }
    abort(404);
})->where('any', '.*');
