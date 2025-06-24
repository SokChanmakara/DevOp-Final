<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTerrainRequest;
use App\Http\Requests\UpdateTerrainRequest;
use App\Models\Terrain;

class TerrainController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreTerrainRequest $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(Terrain $terrain)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Terrain $terrain)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateTerrainRequest $request, Terrain $terrain)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Terrain $terrain)
    {
        //
    }
}
