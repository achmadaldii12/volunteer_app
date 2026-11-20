
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users')) {
            Schema::create('users', function (Blueprint $table) {
                $table->string('id', 64)->primary();
                $table->string('name', 150);
                $table->string('email', 190)->unique('uq_users_email');
                $table->string('password_hash', 255);
                $table->string('phone', 40)->default('');
                $table->string('city', 120)->default('');
                $table->text('bio')->nullable();
                $table->string('role', 20)->default('volunteer');
                $table->string('avatar_url', 255)->default('');
                $table->integer('past_events')->default(0);
                $table->integer('past_hours')->default(0);
                $table->integer('past_points')->default(0);
                $table->integer('past_impact')->default(0);
                $table->dateTime('created_at')->useCurrent();
                $table->dateTime('updated_at')
                    ->useCurrent()
                    ->useCurrentOnUpdate();
            });
        }
    }

    public function down(): void
    {
        // Sengaja tidak menghapus tabel users agar data lama tetap aman.
    }
};
