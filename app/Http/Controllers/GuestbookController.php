<?php

namespace App\Http\Controllers;

use App\Models\GuestbookEntry;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class GuestbookController extends Controller
{
    public function index(): View
    {
        return view('guestbook', [
            'entries' => GuestbookEntry::query()->latest()->limit(100)->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:80'],
            'location' => ['nullable', 'string', 'max:100'],
            'message' => ['required', 'string', 'max:1000'],
            'topic' => ['required', 'string', 'in:general,work,learnng'],
        ]);

        GuestbookEntry::create($validated);

        return redirect()->route('guestbook.index')->with('status', 'Your note was saved.');
    }

    public function health(): Response
    {
        try {
            DB::select('SELECT 1');

            return response('OK', 200)->header('Content-Type', 'text/plain');
        } catch (\Throwable $exception) {
            report($exception);

            return response('Unavailable', 503)->header('Content-Type', 'text/plain');
        }
    }
}
