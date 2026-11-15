<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\GuestbookController;

Route::get('/', [GuestbookController::class, 'index'])->name('guestbook.index');
Route::post('/entries', [GuestbookController::class, 'store'])->name('guestbook.store');
Route::get('/health', [GuestbookController::class, 'health']);
