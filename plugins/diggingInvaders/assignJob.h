#pragma once

#include "edgeCost.h"

#include "modules/MapCache.h"

#include <unordered_map>
#include <unordered_set>

using namespace std;

int32_t assignJob(color_ostream& out, Edge firstImportantEdge, unordered_map<df::coord,df::coord,PointHash> parentMap, unordered_map<df::coord,int64_t,PointHash>& costMap, vector<df::unit*>& invaders, unordered_set<df::coord,PointHash>& requiresZNeg, unordered_set<df::coord,PointHash>& requiresZPos, MapExtras::MapCache& cache, unordered_set<int32_t>& diggingRaces);

