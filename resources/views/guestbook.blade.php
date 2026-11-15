<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Taskify Deployment Guestbook</title>
    <style>
        :root { color-scheme: light; font-family: system-ui, sans-serif; background: #f3f6fb; color: #172033; }
        body { max-width: 760px; margin: 3rem auto; padding: 0 1rem; }
        h1 { margin-bottom: .25rem; } .muted { color: #60708b; }
        form, article { background: white; border: 1px solid #dbe2ef; border-radius: 12px; padding: 1.2rem; margin: 1rem 0; }
        label { display: block; font-weight: 650; margin: .8rem 0 .3rem; }
        input, textarea, button { box-sizing: border-box; width: 100%; padding: .7rem; font: inherit; border: 1px solid #bdc9dc; border-radius: 7px; }
        textarea { min-height: 110px; } button { margin-top: 1rem; background: #2558d8; color: white; border: 0; cursor: pointer; font-weight: 700; }
        .status { padding: .8rem; background: #e7f8ee; border-radius: 8px; } .error { color: #a32020; }
        article p { white-space: pre-wrap; overflow-wrap: anywhere; }
    </style>
</head>
<body>
    <header>
        <p class="muted">Laravel deployment assignment</p>
        <h1>Taskify Deployment Guestbook</h1>
        <p class="muted">Every note is stored in MySQL and survives a deployment.</p>
    </header>

    @if (session('status')) <p class="status">{{ session('status') }}</p> @endif

    <form method="post" action="{{ route('guestbook.store') }}">
        @csrf
        <label for="name">Your name</label>
        <input id="name" name="name" value="{{ old('name') }}" maxlength="80" required>
        @error('name') <p class="error">{{ $message }}</p> @enderror

        <label for="message">Your note</label>
        <textarea id="message" name="message" maxlength="1000" required>{{ old('message') }}</textarea>
        @error('message') <p class="error">{{ $message }}</p> @enderror

        <label for="topic">Topic</label>
        <select id="topic" name="topic" required>
            <option value="general" @selected(old('topic', 'general') === 'general')>General</option>
            <option value="work" @selected(old('topic') === 'work')>Work</option>
            <option value="learning" @selected(old('topic') === 'learning')>Learning</option>
        </select>
        @error('topic') <p class="error">{{ $message }}</p> @enderror
        <button type="submit">Save note</button>
    </form>

    <h2>Recent notes ({{ $entries->count() }})</h2>
    @forelse ($entries as $entry)
        <article>
            <strong>{{ $entry->name }}</strong>
            <small class="muted"> · {{ ucfirst($entry->topic) }}</small>
            <p>{{ $entry->message }}</p>
            <small class="muted">{{ $entry->created_at->toDayDateTimeString() }}</small>
        </article>
    @empty
        <p class="muted">No notes yet. Add the first one above.</p>
    @endforelse
</body>
</html>
