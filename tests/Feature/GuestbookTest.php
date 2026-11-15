<?php

namespace Tests\Feature;

use App\Models\GuestbookEntry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GuestbookTest extends TestCase
{
    use RefreshDatabase;

    public function test_visitors_can_add_and_read_guestbook_entries(): void
    {
        $this->post(route('guestbook.store'), [
            'name' => 'Haroon',
            'message' => 'Deployment survives a refresh.',
            'topic' => 'learning',
        ])->assertRedirect(route('guestbook.index'));

        $this->assertDatabaseHas('guestbook_entries', [
            'name' => 'Haroon',
            'message' => 'Deployment survives a refresh.',
            'topic' => 'learning',
        ]);

        $this->get(route('guestbook.index'))
            ->assertOk()
            ->assertSeeText('Deployment survives a refresh.')
            ->assertSeeText('Learning');
    }

    public function test_health_check_confirms_database_connectivity(): void
    {
        GuestbookEntry::query()->count();

        $this->get('/health')
            ->assertOk()
            ->assertSeeText('OK');
    }
}
