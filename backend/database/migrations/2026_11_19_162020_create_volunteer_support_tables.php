
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. API TOKENS
        if (!Schema::hasTable('api_tokens')) {
            Schema::create('api_tokens', function (Blueprint $table) {
                $table->char('token_hash', 64)->primary();
                $table->string('user_id', 64);
                $table->dateTime('created_at')->useCurrent();
                $table->dateTime('expires_at');
                $table->index('user_id', 'idx_tokens_user');
            });
        }

        // 2. EVENTS
        if (!Schema::hasTable('events')) {
            Schema::create('events', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('owner_id', 64)->default('');
                $table->string('title', 255)->default('');
                $table->string('category', 60)->default('');
                $table->string('organizer', 190)->default('');
                $table->string('location', 255)->default('');
                $table->text('description')->nullable();
                $table->string('image_url', 255)->default('');
                $table->string('event_time', 60)->default('');
                $table->dateTime('event_date')->nullable();
                $table->integer('quota')->default(0);
                $table->integer('base_participants')->default(0);
                $table->integer('points')->default(0);
                $table->integer('hours')->default(0);
                $table->integer('impact')->default(0);
                $table->integer('price')->default(0);
                $table->string('status', 20)->default('published');
                $table->dateTime('deadline')->nullable();
                $table->boolean('require_approval')->default(false);
                $table->boolean('is_deleted')->default(false);
                $table->longText('data')->nullable();
                $table->dateTime('created_at')->useCurrent();
                $table->dateTime('updated_at')
                    ->useCurrent()->useCurrentOnUpdate();
                $table->index('owner_id', 'idx_events_owner');
                $table->index('status', 'idx_events_status');
            });
        }

        // 3. REGISTRATIONS
        if (!Schema::hasTable('registrations')) {
            Schema::create('registrations', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('user_id', 64);
                $table->string('event_id', 64);
                $table->string('code', 40)->default('');
                $table->string('status', 20)->default('registered');
                $table->string('approval', 20)->default('');
                $table->string('checked_in_at', 40)->default('');
                $table->string('checked_out_at', 40)->default('');
                $table->dateTime('registered_at')->nullable();
                $table->longText('data')->nullable();
                $table->dateTime('updated_at')
                    ->useCurrent()->useCurrentOnUpdate();
                $table->index('user_id', 'idx_reg_user');
                $table->index('event_id', 'idx_reg_event');
            });
        }

        // 4. NOTIFICATIONS
        if (!Schema::hasTable('notifications')) {
            Schema::create('notifications', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('user_id', 64);
                $table->string('title', 255)->default('');
                $table->text('body')->nullable();
                $table->string('kind', 80)->default('info');
                $table->boolean('is_read')->default(false);
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
                $table->index('user_id', 'idx_notif_user');
            });
        }

        // 5. POINT ENTRIES
        if (!Schema::hasTable('point_entries')) {
            Schema::create('point_entries', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('user_id', 64);
                $table->string('event_id', 64)->nullable();
                $table->string('type', 30)->default('event');
                $table->integer('points')->default(0);
                $table->boolean('verified')->default(true);
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
                $table->index('user_id', 'idx_points_user');
            });
        }

        // 6. CERTIFICATES
        if (!Schema::hasTable('certificates')) {
            Schema::create('certificates', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('reg_id', 64);
                $table->string('user_id', 64);
                $table->string('event_id', 64);
                $table->string('number', 60)->default('');
                $table->dateTime('issued_at')->nullable();
                $table->longText('data')->nullable();
                $table->index('user_id', 'idx_cert_user');
            });
        }

        // 7. ORG MESSAGES
        if (!Schema::hasTable('org_messages')) {
            Schema::create('org_messages', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('owner_id', 64);
                $table->string('kind', 30)->default('');
                $table->string('title', 255)->default('');
                $table->text('body')->nullable();
                $table->string('event_id', 64)->nullable();
                $table->integer('recipient_count')->default(0);
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
                $table->index('owner_id', 'idx_orgmsg_owner');
            });
        }

        // 8. FEEDBACKS
        if (!Schema::hasTable('feedbacks')) {
            Schema::create('feedbacks', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('user_id', 64);
                $table->string('event_title', 255)->default('');
                $table->integer('rating')->default(0);
                $table->text('text')->nullable();
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
                $table->index('user_id', 'idx_fb_user');
            });
        }

        // 9. COMM MESSAGES
        if (!Schema::hasTable('comm_messages')) {
            Schema::create('comm_messages', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('room_id', 40)->default('umum');
                $table->string('sender_id', 64);
                $table->string('sender_name', 150)->default('');
                $table->text('text')->nullable();
                $table->string('type', 20)->default('text');
                $table->string('event_id', 64)->nullable();
                $table->string('reply_to_id', 64)->nullable();
                $table->string('image_url', 255)->default('');
                $table->boolean('is_deleted')->default(false);
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
                $table->index('room_id', 'idx_cm_room');
                $table->index('sender_id', 'idx_cm_sender');
            });
        }

        // 10. COMM ANNOUNCEMENTS
        if (!Schema::hasTable('comm_announcements')) {
            Schema::create('comm_announcements', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('author_id', 64);
                $table->string('author_name', 150)->default('');
                $table->string('title', 255)->default('');
                $table->text('body')->nullable();
                $table->boolean('important')->default(false);
                $table->string('event_id', 64)->nullable();
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
            });
        }

        // 11. COMM POLLS
        if (!Schema::hasTable('comm_polls')) {
            Schema::create('comm_polls', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('creator_id', 64);
                $table->string('creator_name', 150)->default('');
                $table->string('question', 500)->default('');
                $table->dateTime('ends_at')->nullable();
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
            });
        }

        // 12. COMM REPORTS
        if (!Schema::hasTable('comm_reports')) {
            Schema::create('comm_reports', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('message_id', 64);
                $table->string('reporter_id', 64);
                $table->string('reason', 255)->default('');
                $table->dateTime('created_at')->nullable();
                $table->longText('data')->nullable();
            });
        }

        // 13. ORG PROFILES
        if (!Schema::hasTable('org_profiles')) {
            Schema::create('org_profiles', function (Blueprint $table) {
                $table->string('user_id', 64)->primary();
                $table->string('logo_url', 255)->default('');
                $table->longText('data')->nullable();
                $table->dateTime('updated_at')
                    ->useCurrent()->useCurrentOnUpdate();
            });
        }

        // 14. USER KV
        if (!Schema::hasTable('user_kv')) {
            Schema::create('user_kv', function (Blueprint $table) {
                $table->string('id', 140)->primary();
                $table->string('user_id', 64);
                $table->string('k', 60);
                $table->longText('value')->nullable();
                $table->dateTime('updated_at')
                    ->useCurrent()->useCurrentOnUpdate();
                $table->index('user_id', 'idx_kv_user');
            });
        }

        // 15. UPLOADS
        if (!Schema::hasTable('uploads')) {
            Schema::create('uploads', function (Blueprint $table) {
                $table->increments('id');
                $table->string('user_id', 64);
                $table->string('kind', 30);
                $table->string('path', 255);
                $table->string('mime', 60);
                $table->integer('size_bytes')->default(0);
                $table->dateTime('created_at')->useCurrent();
                $table->index('user_id', 'idx_up_user');
            });
        }
    }

    public function down(): void
    {
        // Tidak menghapus tabel agar data Volunteer lama tetap aman.
    }
};
