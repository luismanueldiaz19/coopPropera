<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MetaDataController extends Controller
{
    public function getOccupations()
    {
        $occupations = DB::table('occupations')->get();
        return response()->json(['data' => $occupations]);
    }

    public function getRoles()
    {
        $roles = DB::table('roles')->get();
        return response()->json(['data' => $roles]);
    }
}
