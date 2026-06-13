<?php

namespace App\Http\Controllers\Api;

use App\Application\Services\OccupationService;
use App\Http\Controllers\Controller;
use App\Http\Requests\OccupationRequest;
use App\Http\Resources\OccupationResource;
use Illuminate\Http\JsonResponse;

class OccupationController extends Controller
{
    protected $occupationService;

    public function __construct(OccupationService $occupationService)
    {
        $this->occupationService = $occupationService;
    }

    /**
     * Display a listing of the resource.
     */
    public function index(): JsonResponse
    {
        $occupations = $this->occupationService->getAllOccupations();
        return response()->json([
            'data' => OccupationResource::collection($occupations)
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(OccupationRequest $request): JsonResponse
    {
        $occupation = $this->occupationService->createOccupation($request->validated());
        
        return response()->json([
            'message' => 'Occupation created successfully',
            'data' => new OccupationResource($occupation)
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(int $id): JsonResponse
    {
        $occupation = $this->occupationService->getOccupationById($id);
        
        if (!$occupation) {
            return response()->json(['message' => 'Occupation not found'], 404);
        }

        return response()->json([
            'data' => new OccupationResource($occupation)
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(OccupationRequest $request, int $id): JsonResponse
    {
        $updated = $this->occupationService->updateOccupation($id, $request->validated());
        
        if (!$updated) {
            return response()->json(['message' => 'Occupation not found or could not be updated'], 404);
        }

        $occupation = $this->occupationService->getOccupationById($id);

        return response()->json([
            'message' => 'Occupation updated successfully',
            'data' => new OccupationResource($occupation)
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(int $id): JsonResponse
    {
        $deleted = $this->occupationService->deleteOccupation($id);

        if (!$deleted) {
            return response()->json(['message' => 'Occupation not found or could not be deleted'], 404);
        }

        return response()->json([
            'message' => 'Occupation deactivated successfully'
        ]);
    }
}
