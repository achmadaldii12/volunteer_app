<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/** Membuat akun penyelenggara (sama dengan akun contoh di aplikasi). */
class OrganizerSeeder extends Seeder
{
    public function run(): void
    {
        $data = [
            'name' => 'Volunteer Indonesia',
            'password_hash' => Hash::make('organizer123'),
            'phone' => '031-5551234',
            'city' => 'Surabaya',
            'bio' => 'Akun penyelenggara contoh.',
            'role' => 'organizer',
        ];

        $existing = User::where('email', 'organizer@volunteer.id')->first();
        if ($existing) {
            DB::table('users')->where('email', 'organizer@volunteer.id')->update($data + ['id' => 'u_org_demo']);
        } else {
            User::create($data + ['id' => 'u_org_demo', 'email' => 'organizer@volunteer.id']);
        }
    }
}
