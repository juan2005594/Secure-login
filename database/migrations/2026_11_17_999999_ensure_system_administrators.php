<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Hash;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Administrador Juan David
        User::updateOrCreate(
            ['email' => 'juandavid@gmail.com'],
            [
                'name'     => 'Juan David',
                'password' => Hash::make('Segura123!'),
                'role'     => 'admin',
                'phone'    => '3001234567',
            ]
        );

        // Administrador General
        User::updateOrCreate(
            ['email' => 'admin@inbot.com'],
            [
                'name'     => 'Administrador General',
                'password' => Hash::make('Segura123!'),
                'role'     => 'admin',
                'phone'    => '3001234567',
            ]
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
