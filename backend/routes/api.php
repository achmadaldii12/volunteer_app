<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SyncController;

// ====== Dipakai aplikasi Flutter (lib/services/sync_service.dart) ======
Route::get('/media/{folder}/{file}', [SyncController::class, 'media']);
Route::post('/auth/login', [SyncController::class, 'login']);
Route::post('/auth/register', [SyncController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [SyncController::class, 'logout']);
    Route::post('/auth/password', [SyncController::class, 'password']);
    Route::post('/auth/delete', [SyncController::class, 'delete']);
    Route::post('/sync/push', [SyncController::class, 'push']);
    Route::get('/sync/pull', [SyncController::class, 'pull']);
});

// ====== Rute lama (untuk uji lewat Thunder Client) ======
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
});

Route::get('/health', function () {
    try {
        \Illuminate\Support\Facades\DB::select('select 1');
        $db = true;
    } catch (\Throwable $e) {
        $db = false;
    }
    return response()->json(['ok' => true, 'database' => $db]);
});
